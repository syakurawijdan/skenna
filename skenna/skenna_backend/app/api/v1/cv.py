from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.food_label_scan import FoodLabelScan
from app.repositories.history_repository import HistoryRepository
from app.repositories.user_repository import UserRepository
from app.schemas.cv import CVScanRequest, CVScanResponse
from app.services.cv_ocr_service import CVOcrService
from app.services.sodium_classifier_service import SodiumClassifierService

router = APIRouter()


@router.post("/scan", response_model=CVScanResponse)
def scan_food_label(payload: CVScanRequest, db: Session = Depends(get_db)) -> CVScanResponse:
    user = UserRepository.get_or_create_by_id(db, 1)
    raw_text, sodium_mg = CVOcrService.scan_label(payload.image_url)
    sodium_level, _ = SodiumClassifierService.classify(sodium_mg)

    scan = FoodLabelScan(
        user_id=user.id,
        image_path=payload.image_url,
        raw_text=raw_text,
        sodium_mg=sodium_mg,
    )
    db.add(scan)
    db.commit()
    db.refresh(scan)

    HistoryRepository.create_intake(
        db=db,
        user_id=user.id,
        food_name=raw_text or "scan_result",
        sodium_mg=sodium_mg,
        sodium_level=sodium_level,
        scan_id=scan.id,
        kategori=payload.kategori,
    )
    
    return CVScanResponse(
        raw_text=raw_text,
        sodium_mg=sodium_mg,
        sodium_level=sodium_level,
        scan_id=scan.id, 
    )
