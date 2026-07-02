from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.repositories.history_repository import HistoryRepository
from app.repositories.user_repository import UserRepository
from app.schemas.sodium import SodiumClassifyRequest, SodiumClassifyResponse
from app.services.sodium_classifier_service import SodiumClassifierService

router = APIRouter()


@router.post("/classify", response_model=SodiumClassifyResponse)
def classify_sodium(
	payload: SodiumClassifyRequest,
	db: Session = Depends(get_db),
	current_user: User = Depends(get_current_user),
) -> SodiumClassifyResponse:
	profile = UserRepository.get_profile(db, current_user.id)
	if profile is None or profile.birth_date is None or not profile.gender:
		raise HTTPException(
			status_code=400,
			detail="Complete profile birth_date and gender before sodium classification.",
		)
	sodium_level, recommendation, daily_limit_mg, limit_source = SodiumClassifierService.classify_for_profile(
		payload.sodium_mg,
		profile,
	)
	HistoryRepository.create_intake(
		db=db,
		user_id=current_user.id,
		food_name="manual_input",
		sodium_mg=payload.sodium_mg,
		sodium_level=sodium_level,
	)
	return SodiumClassifyResponse(
		sodium_mg=payload.sodium_mg,
		sodium_level=sodium_level,
		recommendation=recommendation,
		daily_limit_mg=daily_limit_mg,
		limit_source=limit_source,
	)

