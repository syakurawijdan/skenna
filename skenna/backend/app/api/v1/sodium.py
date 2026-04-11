from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.repositories.history_repository import HistoryRepository
from app.repositories.user_repository import UserRepository
from app.schemas.sodium import SodiumClassifyRequest, SodiumClassifyResponse
from app.services.sodium_classifier_service import SodiumClassifierService

router = APIRouter()


@router.post("/classify", response_model=SodiumClassifyResponse)
def classify_sodium(payload: SodiumClassifyRequest, db: Session = Depends(get_db)) -> SodiumClassifyResponse:
	user = UserRepository.get_or_create_by_id(db, 1)
	sodium_level, recommendation = SodiumClassifierService.classify(payload.sodium_mg)
	HistoryRepository.create_intake(
		db=db,
		user_id=user.id,
		food_name="manual_input",
		sodium_mg=payload.sodium_mg,
		sodium_level=sodium_level,
	)
	return SodiumClassifyResponse(
		sodium_mg=payload.sodium_mg,
		sodium_level=sodium_level,
		recommendation=recommendation,
	)

