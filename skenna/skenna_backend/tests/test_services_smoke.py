from app.services.cv_ocr_service import CVOcrService
from app.services.sodium_classifier_service import SodiumClassifierService


def test_sodium_classifier_low_level() -> None:
    level, _ = SodiumClassifierService.classify(100, daily_limit_mg=2000)
    assert level == "low"


def test_cv_ocr_service_returns_numeric_sodium() -> None:
    _, sodium_mg = CVOcrService.scan_label("https://example.com/label.jpg")
    assert sodium_mg >= 0
