import json
import re
from typing import Optional

from app.services.gemini_service import GeminiService


class CVOcrService:
    @staticmethod
    def _parse_optional_float(value) -> Optional[float]:
        if value is None:
            return None
        try:
            if isinstance(value, str):
                value = value.strip().replace(",", ".")
                if not value:
                    return None
            return float(value)
        except (TypeError, ValueError):
            return None

    @staticmethod
    def scan_label(image_input: str) -> tuple[str, float, Optional[float], Optional[float], str, str]:
        """
        Returns: (raw_text, sodium_mg, takaran_saji, sajian_per_kemasan, satuan_takaran, nama_produk)
        takaran_saji & sajian_per_kemasan akan None jika Gemini tidak berhasil membaca nilainya.
        """
        if len(image_input) > 200:
            raw_text = GeminiService.analyze_vision_base64(image_input)
        else:
            raw_text = GeminiService.analyze_vision(image_input)

        try:
            clean = re.sub(r"```json|```", "", raw_text).strip()
            data = json.loads(clean)

            sodium_mg = float(data.get("sodium_mg") or 0)

            raw_takaran = data.get("takaran_saji")
            takaran_saji = CVOcrService._parse_optional_float(raw_takaran)

            raw_sajian = data.get("sajian_per_kemasan")
            sajian_per_kemasan = CVOcrService._parse_optional_float(raw_sajian)

            satuan_takaran = str(data.get("satuan_takaran") or "g").lower()
            if satuan_takaran not in ("g", "ml"):
                satuan_takaran = "g"
            nama_produk = str(data.get("nama_produk") or "")
        except Exception:
            match = re.search(r"sodium\s*(\d+(?:\.\d+)?)\s*mg", raw_text, re.IGNORECASE)
            if not match:
                match = re.search(r"natrium\s*(\d+(?:\.\d+)?)\s*mg", raw_text, re.IGNORECASE)
            sodium_mg = float(match.group(1)) if match else 0.0
            takaran_saji = None
            sajian_per_kemasan = None
            satuan_takaran = "g"
            nama_produk = ""

        return raw_text, sodium_mg, takaran_saji, sajian_per_kemasan, satuan_takaran, nama_produk
