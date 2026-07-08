import json
import logging
import re
from datetime import date
from typing import Optional

from sqlalchemy.orm import Session

from app.repositories.user_repository import UserRepository
from app.schemas.product_category import (
    CATEGORY_FALLBACK_MAP,
    ProductCategory,
    VALID_PRODUCT_CATEGORY_VALUES,
)
from app.services.gemini_service import GeminiService

logger = logging.getLogger(__name__)
_rekomendasi_cache: dict = {}
_VALID_CATEGORY_PROMPT = ", ".join(VALID_PRODUCT_CATEGORY_VALUES)

# Contoh pembeda format fisik per kategori, dipakai supaya Gemini tidak
# menganggap produk "serupa" hanya karena masuk kategori besar yang sama.
_FORMAT_HINTS = {
    "mie_instan": "mi goreng instan vs mi kuah instan vs bihun instan vs pasta instan — format beda, JANGAN tukar antar jenis.",
    "keripik_snack": "keripik/chips (mis. Chitato, Lays) vs snack ekstrudat/puff (mis. Taro, Cheetos) vs kerupuk vs kacang goreng vs snack bar/energy bar (mis. Fitbar) — SEMUA FORMAT BERBEDA meski sama-sama 'snack'. Snack ekstrudat asin WAJIB direkomendasikan sesama snack ekstrudat/keripik asin, BUKAN bar/biskuit.",
    "minuman_kemasan": "teh kemasan vs kopi kemasan vs jus vs minuman berkarbonasi/soda vs minuman isotonik/elektrolit vs air mineral berperisa — format beda.",
    "biskuit_roti": "roti tawar vs roti manis/isi vs biskuit kering vs crackers — format beda.",
    "biskuit": "biskuit kering/marie vs wafer vs sandwich cookies — format beda.",
    "makanan_kaleng": "sarden/ikan kaleng vs kornet vs sayur kaleng vs sup kaleng — format beda.",
    "sereal": "sereal jagung/corn flakes vs granola vs oatmeal instan — format beda.",
    "susu": "susu UHT cair vs susu bubuk vs susu kental manis vs yogurt/produk fermentasi susu — format beda.",
    "frozen_food": "nugget vs sosis vs bakso vs dimsum/dumpling beku vs kentang goreng beku — format beda.",
}


def _fallback_tips(sodium_mg: int) -> dict:
    return {
        "rekomendasi": [],
        "tips": f"Pilih produk dengan natrium di bawah {sodium_mg} mg per sajian sebagai alternatif yang lebih sehat.",
        "is_fallback": False,
        "disclaimer": None,
    }


def _strip_markdown_fences(text: str) -> str:
    stripped = text.strip()
    stripped = re.sub(r'^```(?:json)?\s*', '', stripped, flags=re.IGNORECASE)
    stripped = re.sub(r'\s*```$', '', stripped)
    return stripped.strip()


def _parse_json_safe(text: str) -> dict:
    text = _strip_markdown_fences(text)
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        last_bracket = text.rfind(']')
        last_brace = text.rfind('}')
        cut = max(last_bracket, last_brace)
        if cut > 0:
            candidate = text[:cut + 1]
            open_braces = candidate.count('{') - candidate.count('}')
            open_brackets = candidate.count('[') - candidate.count(']')
            candidate += '}' * open_braces + ']' * open_brackets
            try:
                return json.loads(candidate)
            except json.JSONDecodeError:
                pass
        raise


def _normalize_product_name(product_name: Optional[str]) -> str:
    if not product_name:
        return ""
    return re.sub(r"\s+", " ", product_name.strip().lower())


def _category_value(kategori: ProductCategory | str) -> str:
    value = kategori.value if isinstance(kategori, ProductCategory) else str(kategori)
    if value not in VALID_PRODUCT_CATEGORY_VALUES:
        raise ValueError(f"Invalid product category: {value}")
    return value


def _category_values(kategori_list: list[ProductCategory | str]) -> set[str]:
    return {_category_value(kategori) for kategori in kategori_list}


def _validate_rekomendasi(
    parsed: dict,
    sodium_mg: int,
    allowed_categories: list[ProductCategory | str],
) -> dict | None:
    """
    Pastikan setiap item rekomendasi punya sodium_per_sajian_mg yang valid (angka).
    Jika Gemini tidak memberi angka yang valid, pakai sodium_mg produk scan
    sebagai estimasi agar rekomendasi tetap bisa ditampilkan.
    """
    allowed_category_values = _category_values(allowed_categories)
    items = parsed.get("rekomendasi", [])
    valid_items = []

    for item in items:
        item_category = item.get("kategori")
        if item_category not in allowed_category_values:
            logger.warning(
                "Dropping recommendation with mismatched category: allowed=%s actual=%s item=%s",
                sorted(allowed_category_values),
                item_category,
                item.get("nama_produk"),
            )
            continue

        sodium_val = item.get("sodium_per_sajian_mg")
        if (
            not isinstance(sodium_val, (int, float))
            or isinstance(sodium_val, bool)
            or sodium_val <= 0
        ):
            item["sodium_per_sajian_mg"] = sodium_mg
        valid_items.append(item)

    if not valid_items:
        # Semua item invalid, atau memang tidak ada rekomendasi (array kosong)
        # -> fallback ke tips, JANGAN dianggap valid result
        return None

    parsed["rekomendasi"] = valid_items
    parsed.pop("tips", None)
    return parsed


def _recommendation_count(result: dict | None) -> int:
    return len((result or {}).get("rekomendasi") or [])


def _recommended_product_names(result: dict | None) -> set[str]:
    names: set[str] = set()
    for item in (result or {}).get("rekomendasi") or []:
        name = str(item.get("nama_produk") or "").strip().lower()
        if name:
            names.add(name)
    return names


def _merge_rekomendasi(base: dict, extra: dict | None, jumlah: int) -> dict:
    if extra is None:
        return base

    merged_items = []
    seen_names: set[str] = set()
    for item in (base.get("rekomendasi") or []) + (extra.get("rekomendasi") or []):
        name = str(item.get("nama_produk") or "").strip().lower()
        if name and name in seen_names:
            continue
        if name:
            seen_names.add(name)
        merged_items.append(item)
        if len(merged_items) >= jumlah:
            break

    base["rekomendasi"] = merged_items
    return base


def _age_years(birth_date) -> int | None:
    if birth_date is None:
        return None
    today = date.today()
    years = today.year - birth_date.year
    if (today.month, today.day) < (birth_date.month, birth_date.day):
        years -= 1
    return years


def _user_recommendation_context(db: Session | None, user_id: Optional[int]) -> str:
    if db is None or user_id is None:
        return ""

    try:
        profile = UserRepository.get_profile(db, user_id)
    except Exception:
        profile = None

    if profile is None:
        return ""

    age = _age_years(profile.birth_date)
    if age is None:
        age_rule = "Usia tidak diketahui: gunakan rekomendasi umum sesuai kategori."
        age_text = "Tidak diketahui"
    elif age < 12:
        age_rule = "Usia < 12: rekomendasikan produk snack anak-anak."
        age_text = f"{age} tahun"
    elif age <= 17:
        age_rule = "Usia 12-17: rekomendasikan snack yang sesuai remaja, bukan baby food dan bukan produk kesehatan khusus dewasa."
        age_text = f"{age} tahun"
    elif age <= 59:
        age_rule = "Usia 18-59: rekomendasikan produk dewasa reguler."
        age_text = f"{age} tahun"
    else:
        age_rule = "Usia 60+: rekomendasikan pilihan senior-friendly dan rendah natrium."
        age_text = f"{age} tahun"

    hypertension_rule = (
        "User memiliki hipertensi: prioritaskan produk dengan natrium di bawah 100 mg per sajian."
        if profile.has_hypertension
        else "User tidak memiliki hipertensi: tetap prioritaskan natrium lebih rendah dari produk yang discan."
    )
    pregnancy_status = profile.pregnancy_status or "Tidak ada"
    pregnancy_rule = (
        "User hamil: hindari produk yang sangat processed atau tinggi pengawet."
        if pregnancy_status.lower() not in {"", "tidak ada", "none", "no", "false"}
        else "User tidak hamil / status kehamilan tidak relevan."
    )

    return (
        "KONTEKS PROFIL USER UNTUK REKOMENDASI:\n"
        f"- Usia: {age_text}\n"
        f"- Status hipertensi: {'Ya' if profile.has_hypertension else 'Tidak'}\n"
        f"- Status kehamilan: {pregnancy_status}\n"
        f"- Aturan usia: {age_rule}\n"
        f"- Aturan hipertensi: {hypertension_rule}\n"
        f"- Aturan kehamilan: {pregnancy_rule}"
    )


def _build_subtype_rule(kategori: str, normalized_product_name: str) -> str:
    if kategori == "saus_bumbu" and normalized_product_name:
        return """KHUSUS kategori "saus_bumbu":
- Pertama, cocokkan subtype/kegunaan dari nama produk input berdasarkan kata seperti: tiram, kecap, sambal, tomat, mayones, teriyaki, barbeque, penyedap, kaldu, bumbu racik.
- Jika nama produk input mengandung "tiram", prioritaskan rekomendasi produk saus tiram/oyster sauce lain, bukan kecap, sambal, mayones, atau jenis bumbu lain.
- Terapkan pola yang sama untuk subtype lain: kecap dengan kecap, sambal dengan sambal, tomat dengan saus tomat, mayones dengan mayones, teriyaki dengan teriyaki, barbeque dengan barbeque, penyedap/kaldu dengan penyedap/kaldu, bumbu racik dengan bumbu racik.
- Hanya jika subtype tidak jelas dari nama produk, boleh fallback ke kecocokan kategori "saus_bumbu" umum."""

    if normalized_product_name:
        hint = _FORMAT_HINTS.get(kategori, "")
        hint_line = f'- Contoh pembeda format dalam kategori ini: {hint}' if hint else ""
        return f"""KHUSUS kategori "{kategori}":
- Tentukan dulu FORMAT/BENTUK FISIK produk input dari namanya.
{hint_line}
- WAJIB rekomendasikan produk dengan FORMAT/BENTUK FISIK YANG SAMA dengan produk input.
- JANGAN anggap dua produk "serupa" hanya karena masuk kategori besar "{kategori}" yang sama. Fungsi konsumsi dan bentuknya harus sama.
- Hanya jika format tidak bisa disimpulkan dari nama produk, boleh fallback ke kecocokan kategori "{kategori}" umum."""

    return f'Nama produk input tidak tersedia, jadi fallback ke kecocokan kategori "{kategori}" secara umum.'


def _build_recommendation_prompt(
    *,
    kategori: str,
    sodium_mg: int,
    jumlah: int,
    product_context: str,
    user_context: str,
    subtype_rule: str,
    personalization_rule: str,
    allowed_categories: list[str],
    excluded_product_names: set[str] | None = None,
    is_fallback: bool = False,
) -> str:
    allowed_category_prompt = ", ".join(allowed_categories)
    example_category = allowed_categories[0] if allowed_categories else kategori
    example_count = min(max(jumlah, 1), 3)
    example_items = ",\n".join(
        f'''    {{
      "nama_produk": "Contoh Produk {index}",
      "kategori": "{example_category}",
      "sodium_per_sajian_mg": {index * 10},
      "alasan": "satu kalimat alasan mengapa ini pilihan lebih baik"
    }}'''
        for index in range(1, example_count + 1)
    )
    exclusion_block = ""
    if excluded_product_names:
        excluded_names = "\n".join(f"- {name}" for name in sorted(excluded_product_names))
        exclusion_block = f"""
PRODUK YANG SUDAH DIREKOMENDASIKAN (JANGAN ULANGI):
{excluded_names}
"""
    if is_fallback:
        category_opening = (
            "dengan kategori fallback yang WAJIB salah satu dari "
            f"[{allowed_category_prompt}]"
        )
        required_category_block = (
            f'KATEGORI ORIGINAL TIDAK MENEMUKAN HASIL VALID: "{kategori}"\n'
            f'KATEGORI FALLBACK YANG BOLEH DIPAKAI: {allowed_category_prompt}\n'
            "Gunakan HANYA kategori fallback di atas. Jangan gunakan kategori lain."
        )
        field_category_rule = (
            'Field "kategori" pada setiap rekomendasi WAJIB diisi persis salah satu '
            f"dari [{allowed_category_prompt}], bukan label bebas dan bukan nama kategori baru."
        )
        category_rule = (
            f'Kategori produk rekomendasi WAJIB EXACT match dengan salah satu kategori fallback: '
            f"{allowed_category_prompt}. Jangan gunakan kategori di luar daftar fallback ini."
        )
    else:
        category_opening = f'dengan kategori EXACT "{kategori}"'
        required_category_block = f'KATEGORI WAJIB UNTUK SEMUA REKOMENDASI: "{kategori}"'
        field_category_rule = (
            f'Field "kategori" pada setiap rekomendasi WAJIB diisi persis "{kategori}", '
            "bukan kategori mirip, bukan label bebas, dan bukan nama kategori baru."
        )
        category_rule = (
            f'Kategori produk rekomendasi WAJIB EXACT match dengan kategori "{kategori}". '
            'Nilai "kategori" WAJIB salah satu enum valid di DAFTAR KATEGORI VALID dan '
            f'untuk request ini harus persis "{kategori}". Jangan gunakan kategori "serupa".'
        )

    return f'''Berikan {jumlah} rekomendasi produk kemasan yang dijual di Indonesia
{category_opening} yang memiliki kandungan natrium lebih rendah
atau sebanding dengan {sodium_mg} mg per sajian, atau yang dikenal sebagai
pilihan lebih sehat untuk produk input berikut.

PRODUK INPUT:
- Nama produk: {product_context}
- Kategori: {kategori}
- Natrium per sajian: {sodium_mg} mg
- Jumlah rekomendasi yang diminta: {jumlah}

DAFTAR KATEGORI VALID (enum tertutup, jangan buat nama kategori baru):
{_VALID_CATEGORY_PROMPT}

{required_category_block}
{exclusion_block}

{user_context}

ATURAN KECOCOKAN PRODUK:
- Prioritaskan produk rekomendasi dengan subtype/kegunaan spesifik yang sama dengan produk input.
- Jangan hanya mencocokkan kategori besar jika nama produk menunjukkan subtype yang jelas.
- Jika subtype tidak bisa disimpulkan dari nama produk, gunakan fallback kecocokan kategori yang diizinkan untuk request ini.
- {field_category_rule}
{subtype_rule}

Respons WAJIB hanya raw JSON tanpa markdown, tanpa penjelasan apapun.

{{
  "rekomendasi": [
{example_items}
  ]
}}

ATURAN:
1. Hanya produk kemasan nyata yang beredar di supermarket Indonesia (Indomaret, Alfamart, Hypermart, dll)
2. nama_produk harus include nama merek lengkap
3. {category_rule}
{personalization_rule}
5. sodium_per_sajian_mg WAJIB diisi angka asli, estimasi diperbolehkan asal masuk akal
6. Jumlah item dalam array rekomendasi WAJIB {jumlah}. Jika benar-benar tidak ada cukup produk valid, boleh kurang, tapi JANGAN isi dengan kategori/format yang salah hanya demi memenuhi jumlah.
6. JIKA tidak ada produk dengan format/subtype yang sama persis dan lebih rendah natrium, kembalikan rekomendasi kosong (array kosong) â€” JANGAN memaksakan produk dari format berbeda hanya demi mengisi rekomendasi.
7. Semua angka harus NUMBER bukan string
8. Jangan tambahkan teks apapun selain JSON'''


def _generate_validated_recommendations(
    *,
    kategori: str,
    sodium_mg: int,
    jumlah: int,
    product_context: str,
    user_context: str,
    subtype_rule: str,
    personalization_rule: str,
    allowed_categories: list[str],
    is_fallback: bool = False,
    excluded_product_names: set[str] | None = None,
    log_prefix: str = "REKO",
) -> dict | None:
    prompt = _build_recommendation_prompt(
        kategori=kategori,
        sodium_mg=sodium_mg,
        jumlah=jumlah,
        product_context=product_context,
        user_context=user_context,
        subtype_rule=subtype_rule,
        personalization_rule=personalization_rule,
        allowed_categories=allowed_categories,
        excluded_product_names=excluded_product_names,
        is_fallback=is_fallback,
    )
    response_text = GeminiService._generate_content(
        prompt,
        model="gemini-2.5-flash",
        temperature=0,
        max_tokens=2048,
    )
    print(f"=== {log_prefix} RESPONSE: {response_text}")
    parsed = _parse_json_safe(response_text)
    print(f"=== {log_prefix} PARSED: {parsed}")
    return _validate_rekomendasi(parsed, sodium_mg, allowed_categories)


async def get_rekomendasi(
    kategori: ProductCategory | str,
    sodium_mg: int,
    user_id: Optional[int] = None,
    db: Session | None = None,
    product_name: Optional[str] = None,
    jumlah: int = 1,
) -> dict:
    kategori = _category_value(kategori)
    jumlah = max(1, int(jumlah or 1))
    normalized_product_name = _normalize_product_name(product_name)
    product_context = product_name.strip() if normalized_product_name else "Tidak tersedia"
    cache_key = f"{kategori}_{sodium_mg}_{user_id}_{normalized_product_name}_{jumlah}"
    if cache_key in _rekomendasi_cache:
        print(f"=== REKO CACHE HIT: {cache_key}")
        return _rekomendasi_cache[cache_key]

    if kategori == "lainnya":
        result = {
            "rekomendasi": [],
            "tips": f"Saat membeli produk kemasan apapun, pilih yang natrium per sajiannya di bawah {sodium_mg} mg per sajian.",
            "is_fallback": False,
            "disclaimer": None,
        }
        _rekomendasi_cache[cache_key] = result
        logger.info(
            "Returning 0/%s recommendations for category %s (caller-specified), fallback_used=%s",
            jumlah,
            kategori,
            False,
        )
        return result

    user_context = _user_recommendation_context(db, user_id)
    personalization_rule = (
        """4. Terapkan aturan profil user:
   - Age < 12: recommend children's snack products
   - Age 12-17: recommend teen-appropriate snacks, no baby food, no adult health products
   - Age 18-59: recommend regular adult products
   - Age 60+: recommend senior-friendly, low-sodium options
   - Jika hipertensi: prioritaskan produk di bawah 100 mg natrium per sajian
   - Jika hamil: hindari produk highly processed atau tinggi pengawet"""
        if user_context
        else "4. Gunakan rekomendasi umum sesuai kategori dan prioritaskan natrium lebih rendah dari produk yang discan"
    )

    subtype_rule = _build_subtype_rule(kategori, normalized_product_name)

    prompt = f'''Berikan 1 rekomendasi produk kemasan yang dijual di Indonesia
dengan kategori EXACT "{kategori}" yang memiliki kandungan natrium lebih rendah
atau sebanding dengan {sodium_mg} mg per sajian, atau yang dikenal sebagai
pilihan lebih sehat untuk produk input berikut.

PRODUK INPUT:
- Nama produk: {product_context}
- Kategori: {kategori}
- Natrium per sajian: {sodium_mg} mg

DAFTAR KATEGORI VALID (enum tertutup, jangan buat nama kategori baru):
{_VALID_CATEGORY_PROMPT}

KATEGORI WAJIB UNTUK SEMUA REKOMENDASI: "{kategori}"

{user_context}

ATURAN KECOCOKAN PRODUK:
- Prioritaskan produk rekomendasi dengan subtype/kegunaan spesifik yang sama dengan produk input.
- Jangan hanya mencocokkan kategori besar jika nama produk menunjukkan subtype yang jelas.
- Jika subtype tidak bisa disimpulkan dari nama produk, gunakan fallback kecocokan kategori "{kategori}".
- Field "kategori" pada setiap rekomendasi WAJIB diisi persis "{kategori}", bukan kategori mirip, bukan label bebas, dan bukan nama kategori baru.
{subtype_rule}

Respons WAJIB hanya raw JSON tanpa markdown, tanpa penjelasan apapun.

{{
  "rekomendasi": [
    {{
      "nama_produk": "nama merek + produk, contoh: Indomie Goreng Light",
      "kategori": "{kategori}",
      "sodium_per_sajian_mg": 0,
      "alasan": "satu kalimat alasan mengapa ini pilihan lebih baik"
    }}
  ]
}}

ATURAN:
1. Hanya produk kemasan nyata yang beredar di supermarket Indonesia (Indomaret, Alfamart, Hypermart, dll)
2. nama_produk harus include nama merek lengkap
3. Kategori produk rekomendasi WAJIB EXACT match dengan kategori "{kategori}". Nilai "kategori" WAJIB salah satu enum valid di DAFTAR KATEGORI VALID dan untuk request ini harus persis "{kategori}". Jangan gunakan kategori "serupa".
{personalization_rule}
5. sodium_per_sajian_mg WAJIB diisi angka asli, estimasi diperbolehkan asal masuk akal
6. JIKA tidak ada produk dengan format/subtype yang sama persis dan lebih rendah natrium, kembalikan rekomendasi kosong (array kosong) — JANGAN memaksakan produk dari format berbeda hanya demi mengisi rekomendasi.
7. Semua angka harus NUMBER bukan string
8. Jangan tambahkan teks apapun selain JSON'''

    try:
        validated = _generate_validated_recommendations(
            kategori=kategori,
            sodium_mg=sodium_mg,
            jumlah=jumlah,
            product_context=product_context,
            user_context=user_context,
            subtype_rule=subtype_rule,
            personalization_rule=personalization_rule,
            allowed_categories=[kategori],
            log_prefix="REKO",
        )
        if validated is None:
            fallback_categories = CATEGORY_FALLBACK_MAP.get(ProductCategory(kategori), [])
            fallback_category_values = [category.value for category in fallback_categories]
            if not fallback_category_values:
                print(f"=== REKO ALL ITEMS INVALID atau kosong, no fallback category")
                logger.info(
                    "Returning 0/%s recommendations for category %s (caller-specified), fallback_used=%s",
                    jumlah,
                    kategori,
                    False,
                )
                return _fallback_tips(sodium_mg)

            logger.info(
                "Primary recommendation returned no valid category matches; trying fallback categories: original=%s fallback=%s",
                kategori,
                fallback_category_values,
            )
            fallback_validated = _generate_validated_recommendations(
                kategori=kategori,
                sodium_mg=sodium_mg,
                jumlah=jumlah,
                product_context=product_context,
                user_context=user_context,
                subtype_rule=subtype_rule,
                personalization_rule=personalization_rule,
                allowed_categories=fallback_category_values,
                is_fallback=True,
                log_prefix="REKO FALLBACK",
            )
            if fallback_validated is None:
                print("=== REKO FALLBACK ALL ITEMS INVALID atau kosong")
                logger.info(
                    "Returning 0/%s recommendations for category %s (caller-specified), fallback_used=%s",
                    jumlah,
                    kategori,
                    False,
                )
                return _fallback_tips(sodium_mg)

            if 0 < _recommendation_count(fallback_validated) < jumlah:
                top_up_count = jumlah - _recommendation_count(fallback_validated)
                logger.info(
                    "Fallback recommendation returned %s/%s valid items; requesting top-up for fallback categories %s",
                    _recommendation_count(fallback_validated),
                    jumlah,
                    fallback_category_values,
                )
                fallback_top_up = _generate_validated_recommendations(
                    kategori=kategori,
                    sodium_mg=sodium_mg,
                    jumlah=top_up_count,
                    product_context=product_context,
                    user_context=user_context,
                    subtype_rule=subtype_rule,
                    personalization_rule=personalization_rule,
                    allowed_categories=fallback_category_values,
                    excluded_product_names=_recommended_product_names(fallback_validated),
                    is_fallback=True,
                    log_prefix="REKO FALLBACK TOPUP",
                )
                fallback_validated = _merge_rekomendasi(
                    fallback_validated,
                    fallback_top_up,
                    jumlah,
                )

            fallback_validated["is_fallback"] = True
            fallback_validated["disclaimer"] = (
                "Tidak ditemukan alternatif di kategori yang sama, berikut rekomendasi dari kategori yang serupa."
            )
            fallback_validated.pop("tips", None)
            _rekomendasi_cache[cache_key] = fallback_validated
            logger.info(
                "Returning %s/%s recommendations for category %s (caller-specified), fallback_used=%s",
                _recommendation_count(fallback_validated),
                jumlah,
                kategori,
                True,
            )
            return fallback_validated

        if 0 < _recommendation_count(validated) < jumlah:
            top_up_count = jumlah - _recommendation_count(validated)
            logger.info(
                "Primary recommendation returned %s/%s valid items; requesting top-up for category %s",
                _recommendation_count(validated),
                jumlah,
                kategori,
            )
            top_up = _generate_validated_recommendations(
                kategori=kategori,
                sodium_mg=sodium_mg,
                jumlah=top_up_count,
                product_context=product_context,
                user_context=user_context,
                subtype_rule=subtype_rule,
                personalization_rule=personalization_rule,
                allowed_categories=[kategori],
                excluded_product_names=_recommended_product_names(validated),
                log_prefix="REKO TOPUP",
            )
            validated = _merge_rekomendasi(validated, top_up, jumlah)

        validated["is_fallback"] = False
        validated["disclaimer"] = None
        _rekomendasi_cache[cache_key] = validated
        logger.info(
            "Returning %s/%s recommendations for category %s (caller-specified), fallback_used=%s",
            _recommendation_count(validated),
            jumlah,
            kategori,
            False,
        )
        return validated
    except json.JSONDecodeError as e:
        print(f"=== JSON ERROR: {e}")
        logger.info(
            "Returning 0/%s recommendations for category %s (caller-specified), fallback_used=%s",
            jumlah,
            kategori,
            False,
        )
        return _fallback_tips(sodium_mg)
    except Exception as e:
        print(f"=== EXCEPTION: {e}")
        logger.info(
            "Returning 0/%s recommendations for category %s (caller-specified), fallback_used=%s",
            jumlah,
            kategori,
            False,
        )
        return _fallback_tips(sodium_mg)
