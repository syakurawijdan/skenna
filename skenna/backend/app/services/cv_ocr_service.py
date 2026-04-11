import re


class CVOcrService:
	"""Stub OCR parser.

	For development, this method accepts image URL/path and returns mocked OCR text.
	Replace with real OCR integration (EasyOCR/PaddleOCR/Tesseract) later.
	"""

	@staticmethod
	def scan_label(image_url: str) -> tuple[str, float]:
		mocked_text = f"Nutrition Facts\nServing size 30g\nSodium 220 mg\nSource: {image_url}"
		match = re.search(r"sodium\s*(\d+(?:\.\d+)?)\s*mg", mocked_text, flags=re.IGNORECASE)
		sodium_mg = float(match.group(1)) if match else 0.0
		return mocked_text, sodium_mg

