"""Personalized prompt builders for authenticated SKENNA chatbot workflows."""

from __future__ import annotations

import re
from decimal import Decimal, InvalidOperation
from datetime import date, datetime, timedelta, timezone
from app.services.sodium_limit_service import compute_daily_limit_mg

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.food_label_scan import FoodLabelScan
from app.models.intake_history import IntakeHistory
from app.repositories.user_repository import UserRepository
from app.services.sodium_classifier_service import SodiumClassifierService


BOLD_FORMAT_INSTRUCTION = (
	"Always bold key information using **text** markdown. Bold: numbers, medical thresholds, "
	"product names, sodium amounts, percentages, and section headers. Never write long "
	"paragraphs without any bold text."
)

USER_PROFILE_CONTEXT_INSTRUCTION = (
	"Kamu sudah memiliki data profil lengkap pengguna di atas.\n"
	"Gunakan informasi ini untuk:\n"
	"- Menyebut nama pengguna sesekali dalam percakapan\n"
	"- Menggunakan batas natrium hariannya yang spesifik (JANGAN pernah bilang tidak tahu batas natrium pengguna)\n"
	"- Mempertimbangkan status hipertensi dalam setiap saran\n"
	"- Mempertimbangkan status kehamilan jika relevan\n"
	"- Menggunakan tekanan darah aktual jika tersedia\n"
	"Aturan personalisasi rekomendasi produk:\n"
	"- Age < 12: recommend children's snack products only\n"
	"- Age 12-17: recommend teen-appropriate snacks, never recommend baby food or adult health products\n"
	"- Age 18-59: recommend regular adult products\n"
	"- Age 60+: recommend senior-friendly, low-sodium options\n"
	"- If hypertension: prioritize products under 100mg sodium per serving\n"
	"- If pregnant: avoid highly processed or high-preservative products\n"
	"- Recommendations must match the scanned product category exactly\n"
	"- Max 5 bullet points for recommendations, no unnecessary filler text"
)


def _format_package_number(value: object, default: str = "1") -> str:
	if value is None:
		return default
	try:
		number = Decimal(str(value).strip().replace(",", "."))
	except (InvalidOperation, ValueError):
		return default
	if number == number.to_integral_value():
		return str(int(number))
	return format(number.normalize(), "f").rstrip("0").rstrip(".")


class ChatbotPersonalizationService:
	@staticmethod
	def build_user_context(db: Session | None, user_id: int | None) -> str:
		"""Build complete user profile context for Gemini prompts."""
		if db is None or user_id is None:
			return "[PROFIL PENGGUNA]\nNama: Pengguna\n(Data profil belum diisi)"

		try:
			user = UserRepository.get_by_id(db, user_id)
			full_name = re.sub(r"\s+", " ", str(user.full_name or "")).strip() if user else ""
		except Exception:
			full_name = ""
		full_name = full_name or "Pengguna"

		try:
			profile = UserRepository.get_profile(db, user_id)
		except Exception:
			profile = None

		if profile is None:
			return f"[PROFIL PENGGUNA]\nNama: {full_name}\n(Data profil belum diisi)"

		age = (date.today() - profile.birth_date).days // 365 if profile.birth_date else None
		age_str = f"{age} tahun" if age else "Tidak diketahui"
		daily_limit = ChatbotPersonalizationService._daily_limit(db, user_id)


		if profile.systolic_pressure and profile.diastolic_pressure:
			td_str = f"{profile.systolic_pressure}/{profile.diastolic_pressure} mmHg"
		else:
			td_str = "Belum diisi"

		pregnancy = profile.pregnancy_status or "Tidak ada"

		return (
			"[PROFIL PENGGUNA]\n"
			f"Nama: {full_name}\n"
			f"Usia: {age_str}\n"
			f"Jenis Kelamin: {profile.gender}\n"
			f"Status Hipertensi: {'Ya' if profile.has_hypertension else 'Tidak'}\n"
			f"Kondisi Hipertensi: {profile.hypertension_condition or 'Tidak ada'}\n"
			f"Tekanan Darah: {td_str}\n"
			f"Status Kehamilan: {pregnancy}\n"
			f"Batas Natrium Harian: {int(daily_limit)} mg/hari (berdasarkan rule-based sistem Skenna)"
		)

	@staticmethod
	def can_handle(question: str) -> bool:
		q = question.lower()
		return any(
			keyword in q
			for keyword in [
				"bandingkan produk",
				"bandingkan",
				"compare",
				"perbandingan produk",
				"lebih baik mana",
				"mana yang lebih",
				"vs",
				"versus",
				"rekap natrium",
				"rekap hari ini",
				"natrium hari ini",
				"mulai edukasi",
				"mode edukasi",
				"edukasi",
				"belajar",
				"ajarin",
			]
		)

	@staticmethod
	def build_prompt(db: Session, user_id: int, question: str, rag_context: str, user_context: str = "") -> str:
		q = question.lower()
		if any(keyword in q for keyword in ["bandingkan", "compare", "perbandingan produk", "lebih baik mana", "mana yang lebih", " vs ", "versus"]):
			return ChatbotPersonalizationService.product_comparison_prompt(db, user_id, question, rag_context, user_context)
		if "rekap" in q or "natrium hari ini" in q:
			return ChatbotPersonalizationService.daily_sodium_recap_prompt(db, user_id, question, rag_context, user_context)
		if any(keyword in q for keyword in ["edukasi", "belajar", "ajarin"]):
			return ChatbotPersonalizationService.education_prompt(question, rag_context, user_context)
		return _base_personal_prompt(question, rag_context, "Tidak ada info personal tambahan.", user_context)

	@staticmethod
	def product_recommendation_prompt(question: str, user_context: str = "") -> str:
		product_name = _extract_scanned_product_name(question)
		category = _extract_scanned_category(question)
		user_context_text = user_context.strip() or "[PROFIL PENGGUNA]\nNama: Pengguna\n(Data profil belum diisi)"
		scan_context = (
			"Produk hasil scan:\n"
			f"- Nama produk: {product_name or 'Tidak disebutkan eksplisit'}\n"
			f"- Kategori: {category or 'Tidak disebutkan eksplisit'}\n"
			f"- Pertanyaan lengkap user: {question}"
		)
		return (
			"Kamu adalah SKENNY, assistant kesehatan yang memberi rekomendasi produk rendah natrium.\n"
			"JANGAN gunakan konteks RAG untuk tugas ini. Gunakan hanya konteks scan, profil user, dan pengetahuan umum produk supermarket Indonesia.\n\n"
			f"{user_context_text}\n\n"
			f"{USER_PROFILE_CONTEXT_INSTRUCTION}\n\n"
			f"{scan_context}\n\n"
			"Instruksi wajib:\n"
			"- Rekomendasikan tepat 3 produk merek nyata yang dijual di supermarket Indonesia seperti Indomaret, Alfamart, Hypermart, atau supermarket besar lain.\n"
			"- Setiap rekomendasi harus berbentuk bullet point.\n"
			"- Setiap bullet wajib mencantumkan nama merek, varian produk, dan natrium per sajian dalam mg.\n"
			"- Kategori rekomendasi harus sama persis dengan kategori produk scan jika kategori tersedia; jika kategori tidak tersedia, pilih produk serupa dengan produk scan.\n"
			"- Terapkan aturan personalisasi usia, hipertensi, dan kehamilan saat memilih produk.\n"
			"- Untuk hipertensi, prioritaskan produk di bawah 100 mg natrium per sajian bila realistis untuk kategori tersebut.\n"
			"- Untuk kehamilan, hindari produk highly processed atau tinggi pengawet.\n"
			"- Jangan gunakan markdown table.\n"
			"- Jawaban utama harus ringkas, lalu akhiri dengan delimiter ||FOLLOWUP|| dan satu pertanyaan follow-up natural yang relevan.\n"
		)

	@staticmethod
	def product_comparison_prompt(db: Session, user_id: int, question: str, rag_context: str, user_context: str = "") -> str:
		scans = list(
			db.scalars(
				select(FoodLabelScan)
				.where(FoodLabelScan.user_id == user_id)
				.order_by(FoodLabelScan.scanned_at.desc())
				.limit(20)
			).all()
		)
		intake_items = list(
			db.scalars(
				select(IntakeHistory)
				.where(IntakeHistory.user_id == user_id)
				.order_by(IntakeHistory.consumed_at.desc())
				.limit(40)
			).all()
		)
		requested_names = _extract_product_names(question)
		candidates = _product_candidates(scans, intake_items)
		selected = _match_product_candidates(candidates, requested_names)
		if len(selected) < 2 and len(candidates) >= 2 and not requested_names:
			selected = candidates[:2]

		if len(selected) < 2:
			personal_data = (
				"User meminta perbandingan produk, tetapi riwayat scan yang cocok belum cukup.\n"
				f"Nama produk yang diminta: {', '.join(requested_names) if requested_names else '-'}\n"
				f"Jumlah kandidat produk tersedia: {len(candidates)}\n"
				"Minta user menyebutkan dua nama produk yang sudah pernah discan atau scan produknya dulu."
			)
		else:
			personal_data = (
				"Info dua produk dari riwayat scan user:\n"
				+ "\n".join(_format_candidate_for_prompt(candidate, index) for index, candidate in enumerate(selected[:2]))
				+ "\nBandingkan natrium, takaran saji bila tersedia, kategori natrium, alasan edukatif, "
				"dan beri rekomendasi produk yang lebih aman. Akhiri dengan opsi follow-up singkat."
			)
		return _base_personal_prompt(question, rag_context, personal_data, user_context)

	@staticmethod
	def daily_sodium_recap_prompt(db: Session, user_id: int, question: str, rag_context: str, user_context: str = "") -> str:
		start, end = _today_wib_range()
		items = list(
			db.scalars(
				select(IntakeHistory)
				.where(IntakeHistory.user_id == user_id)
				.where(IntakeHistory.consumed_at >= start)
				.where(IntakeHistory.consumed_at < end)
				.order_by(IntakeHistory.consumed_at.desc())
			).all()
		)
		consumed = [item for item in items if item.is_consumed]
		total = sum(float(item.sodium_mg or 0) * float(item.servings or 1) for item in consumed)
		highest = max(consumed, key=lambda item: float(item.sodium_mg or 0) * float(item.servings or 1), default=None)
		limit = ChatbotPersonalizationService._daily_limit(db, user_id)
		remaining = max(limit - total, 0)
		percentage = (total / limit * 100) if limit else 0
		try:
			user = UserRepository.get_or_create_by_id(db, user_id)
			user_name = re.sub(r"\s+", " ", str(user.full_name or "")).strip() or "teman"
		except Exception:
			user_name = "teman"
		product_lines = [
			f"- {item.food_name}: {float(item.sodium_mg or 0) * float(item.servings or 1):.0f} mg"
			for item in consumed[:8]
		]
		personal_data = (
			"Info rekap natrium user hari ini:\n"
			f"Total natrium: {total:.0f} mg\n"
			f"Jumlah produk dikonsumsi: {len(consumed)}\n"
			f"Batas harian user: {limit:.0f} mg\n"
			f"Sisa batas: {remaining:.0f} mg\n"
			f"Persentase batas terpakai: {percentage:.0f}%\n"
			f"Produk tertinggi: {highest.food_name if highest else '-'}\n"
			"Produk hari ini:\n"
			+ ("\n".join(product_lines) if product_lines else "- Belum ada produk dikonsumsi")
			+ "\n\nInstruksi format WAJIB:\n"
			f"- Selalu buka jawaban dengan persis: 'Halo, {user_name}!'\n"
			f"- {BOLD_FORMAT_INSTRUCTION}\n"
			"- Gunakan bold markdown untuk angka penting: total natrium, sisa batas, dan persentase batas terpakai.\n"
			"- Gunakan bullet points untuk breakdown produk hari ini dan saran praktis.\n"
			"- Tutup dengan 1 pertanyaan follow-up yang ramah dan relevan."
		)
		context_text = user_context or ChatbotPersonalizationService.build_user_context(db, user_id)
		return _base_personal_prompt(question, rag_context, personal_data, context_text)

	@staticmethod
	def education_prompt(question: str, rag_context: str, user_context: str = "") -> str:
		personal_data = (
			"Mode edukasi aktif. Jelaskan seperti tutor yang ramah, bertahap, dan akhiri dengan satu pertanyaan kecil "
			"untuk melanjutkan pembelajaran. Tutup dengan kalimat: "
			"'Mau aku jelaskan lebih lanjut tentang bagian mana? 😊'"
		)
		return _base_personal_prompt(question, rag_context, personal_data, user_context)

	@staticmethod
	def _daily_limit(db: Session, user_id: int) -> float:
		profile = UserRepository.get_profile(db, user_id)
		if profile is None:
			return 2000.0
		daily_limit_mg, _source = compute_daily_limit_mg(
			birth_date=profile.birth_date,
			gender=profile.gender,
			has_hypertension=profile.has_hypertension,
		)
		return float(daily_limit_mg)


def _base_personal_prompt(question: str, rag_context: str, personal_data: str, user_context: str = "") -> str:
	context_text = rag_context.strip()
	user_context_text = user_context.strip() or "[PROFIL PENGGUNA]\nNama: Pengguna\n(Data profil belum diisi)"
	reference_section = (
		f"Konteks RAG yang boleh dipakai:\n{context_text}\n\n"
		if context_text
		else (
			"Tidak ada konteks RAG yang lolos filter relevansi. Jika pertanyaan masih seputar natrium, "
			"hipertensi, tekanan darah, gizi, pola makan sehat, atau resep rendah natrium, boleh gunakan "
			"pengetahuan umum kesehatan yang aman bersama info personal user. Jangan mengatakan referensi tidak cukup.\n\n"
		)
	)
	return (
		"Kamu adalah SKENNY, assistant kesehatan yang hangat, natural, dan helpful.\n"
		"Gunakan bahasa Indonesia yang terasa seperti chat manusia.\n"
		"Jika konteks RAG tersedia, prioritaskan konteks RAG dan info personal user yang diberikan di prompt ini.\n"
		"Jika konteks RAG kosong, boleh gunakan pengetahuan umum kesehatan yang aman hanya untuk topik SKENNA.\n"
		"Jangan gunakan asumsi personal atau informasi di luar data user yang diberikan.\n"
		"Jika pertanyaan user menyebut baru scan produk, gunakan nama produk, kategori, dan natrium per sajian dari pertanyaan sebagai konteks scan. "
		"Berikan perhatian utama pada risiko natrium, saran konsumsi, dan alternatif lebih rendah natrium tanpa mengklaim konsumsi sudah dicatat.\n"
		"Jika pesan user berisi konteks produk yang baru discan, termasuk frasa seperti 'Saya baru saja scan produk', selalu berikan tepat 3 rekomendasi produk merek nyata dalam bullet points. "
		"Setiap bullet wajib memuat nama merek, varian produk, dan natrium per sajian dalam mg. Produk harus sama persis kategorinya dengan kategori produk yang discan. "
		"Terapkan aturan personalisasi usia, hipertensi, dan kehamilan saat memilih 3 produk tersebut. Jawaban utama harus ringkas, lalu akhiri dengan ||FOLLOWUP|| dan satu pertanyaan follow-up.\n"
		"Jika user meminta alternatif produk atau opsi lebih rendah natrium, rekomendasikan produk nyata dengan merek yang umum tersedia di supermarket Indonesia "
		"seperti Indomaret, Alfamart, Hypermart, atau supermarket besar lain. Rekomendasi wajib sesuai kategori produk yang discan, ditulis dalam bullet points, "
		"dan setiap bullet wajib memuat nama merek, varian produk, serta kandungan natrium per sajian. Jika angka natrium bervariasi antar kemasan, sebutkan "
		"perkiraan konservatif dan sarankan user tetap cek label.\n"
		"Selalu akhiri setiap respons dengan delimiter ||FOLLOWUP|| lalu satu pertanyaan follow-up interaktif yang singkat, natural, conversational, dan relevan dengan topik yang baru dibahas.\n"
		f"\n{user_context_text}\n\n"
		f"{USER_PROFILE_CONTEXT_INSTRUCTION}\n\n"
		"[[CONVERSATION_HISTORY]]\n\n"
		f"{BOLD_FORMAT_INSTRUCTION}\n"
		"Jangan diagnosis pasti. Kalau info masih kurang, tanya klarifikasi dengan ramah.\n\n"
		f"{reference_section}"
		f"Info personal user:\n{personal_data}\n\n"
		f"Pertanyaan user:\n{question}\n\n"
		"Jawab seperti ahli gizi manusia yang membantu. Untuk perbandingan, boleh pakai poin singkat. "
		"Kalau ini rekap, berikan saran dan opsi lanjutan. Kalau ini edukasi, akhiri dengan follow-up interaktif."
	)


def _today_wib_range() -> tuple[datetime, datetime]:
	now = datetime.now(timezone(timedelta(hours=7))).replace(tzinfo=None)
	start = now.replace(hour=0, minute=0, second=0, microsecond=0)
	return start, start + timedelta(days=1)


def _age_years(birth_date: date) -> int:
	today = date.today()
	years = today.year - birth_date.year
	if (today.month, today.day) < (birth_date.month, birth_date.day):
		years -= 1
	return years


def _extract_product_names(question: str) -> list[str]:
	parts = [
		part.strip(" ,.;:-")
		for part in re.split(r"\s+(?:dengan|dan|vs|versus)\s+|,", question, flags=re.IGNORECASE)
	]
	candidates = [
		re.sub(r"\b(bandingkan|produk|compare)\b", " ", part, flags=re.IGNORECASE).strip()
		for part in parts
	]
	candidates = [part for part in candidates if len(part) >= 3]
	if len(candidates) >= 2:
		return candidates[:2]
	words = [word for word in re.sub(r"\b(bandingkan|produk|dengan|dan|vs|versus)\b", " ", question, flags=re.IGNORECASE).split() if len(word) > 2]
	return [" ".join(words[:2]), " ".join(words[2:4])] if len(words) >= 4 else []


def _extract_scanned_product_name(question: str) -> str | None:
	for pattern in [
		r'produk\s+"([^"]+)"',
		r"produk\s+'([^']+)'",
		r"scan produk\s+(.+?)(?:\s+dengan|\s+yang|\s+dari kategori|,|\.|\?|$)",
	]:
		match = re.search(pattern, question, flags=re.IGNORECASE)
		if match:
			value = re.sub(r"\s+", " ", match.group(1)).strip(" ,.;:-")
			if value:
				return value
	return None


def _extract_scanned_category(question: str) -> str | None:
	match = re.search(r"kategori\s+(.+?)(?:,|\.|\?| dan | serta |$)", question, flags=re.IGNORECASE)
	if not match:
		return None
	value = re.sub(r"\s+", " ", match.group(1)).strip(" ,.;:-")
	return value or None


def _match_products(scans: list[FoodLabelScan], names: list[str]) -> list[FoodLabelScan]:
	if len(names) < 2:
		return []
	matches: list[FoodLabelScan] = []
	used_ids: set[int] = set()
	for name in names[:2]:
		name_tokens = _tokens(name)
		best_scan = None
		best_score = 0
		for scan in scans:
			if scan.id in used_ids:
				continue
			score = len(name_tokens & _tokens(scan.raw_text))
			if score > best_score:
				best_score = score
				best_scan = scan
		if best_scan is not None and best_score > 0:
			used_ids.add(best_scan.id)
			matches.append(best_scan)
	return matches


def _product_candidates(scans: list[FoodLabelScan], intake_items: list[IntakeHistory]) -> list[dict[str, object]]:
	candidates: list[dict[str, object]] = []
	seen_names: set[str] = set()

	def add_candidate(name: str, sodium_mg: float, serving_size: str = "tidak terbaca") -> None:
		clean_name = re.sub(r"\s+", " ", name).strip()
		if not clean_name:
			return
		key = clean_name.lower()
		if key in seen_names:
			return
		seen_names.add(key)
		level, recommendation = SodiumClassifierService.classify(sodium_mg)
		candidates.append(
			{
				"name": clean_name[:100],
				"sodium_mg": float(sodium_mg or 0),
				"serving_size": serving_size,
				"level": level,
				"recommendation": recommendation,
			}
		)

	for item in intake_items:
		add_candidate(item.food_name, float(item.sodium_mg or 0), f"{_format_package_number(item.portions_in_package)} porsi")
		if item.product_name2 and item.sodium_mg2:
			add_candidate(item.product_name2, float(item.sodium_mg2 or 0), f"{_format_package_number(item.portions_in_package2)} porsi")
	for scan in scans:
		add_candidate(_product_name(scan), float(scan.sodium_mg or 0), _serving_size(scan))

	return candidates


def _match_product_candidates(candidates: list[dict[str, object]], names: list[str]) -> list[dict[str, object]]:
	if len(names) < 2:
		return []
	matches: list[dict[str, object]] = []
	used_indexes: set[int] = set()
	for name in names[:2]:
		name_tokens = _tokens(name)
		best_index = None
		best_score = 0
		for index, candidate in enumerate(candidates):
			if index in used_indexes:
				continue
			score = len(name_tokens & _tokens(str(candidate.get("name") or "")))
			if score > best_score:
				best_score = score
				best_index = index
		if best_index is not None and best_score > 0:
			used_indexes.add(best_index)
			matches.append(candidates[best_index])
	return matches


def _tokens(text: str) -> set[str]:
	return {token for token in re.findall(r"[a-z0-9]+", text.lower()) if len(token) > 2}


def _product_name(scan: FoodLabelScan) -> str:
	for pattern in [
		r"(?:nama produk|product name|produk)\s*[:\-]\s*([^\n]+)",
		r"source:\s*([^\n]+)",
	]:
		match = re.search(pattern, scan.raw_text, flags=re.IGNORECASE)
		if match:
			return match.group(1).strip()[:80]
	return scan.raw_text.splitlines()[0][:80] if scan.raw_text else f"Produk #{scan.id}"


def _serving_size(scan: FoodLabelScan) -> str:
	match = re.search(r"(?:serving size|takaran saji)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?\s*(?:g|gram|ml))", scan.raw_text, flags=re.IGNORECASE)
	return match.group(1) if match else "tidak terbaca"


def _format_product_for_prompt(scan: FoodLabelScan, index: int) -> str:
	level, recommendation = SodiumClassifierService.classify(scan.sodium_mg)
	return (
		f"- Produk {index + 1}: {_product_name(scan)} | "
		f"natrium {scan.sodium_mg:.0f} mg | "
		f"takaran saji {_serving_size(scan)} | "
		f"kategori {level} | rekomendasi awal: {recommendation}"
	)


def _format_candidate_for_prompt(candidate: dict[str, object], index: int) -> str:
	return (
		f"- Produk {index + 1}: {candidate.get('name')} | "
		f"natrium {float(candidate.get('sodium_mg') or 0):.0f} mg | "
		f"takaran saji {candidate.get('serving_size') or 'tidak terbaca'} | "
		f"kategori {candidate.get('level')} | "
		f"rekomendasi awal: {candidate.get('recommendation')}"
	)
