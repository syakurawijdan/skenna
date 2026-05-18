from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserProfileUpsertRequest, UserProfileUpsertResponse

router = APIRouter()


@router.post("/demo")
def create_demo_user(db: Session = Depends(get_db)) -> dict[str, int | str]:
	user = UserRepository.get_or_create_demo_user(db)
	return {"id": user.id, "email": user.email, "full_name": user.full_name}


@router.put("/{user_id}/profile", response_model=UserProfileUpsertResponse)
def upsert_user_profile(
	user_id: int,
	payload: UserProfileUpsertRequest,
	db: Session = Depends(get_db),
) -> UserProfileUpsertResponse:
	user = UserRepository.get_or_create_by_id(db, user_id)
	user.full_name = payload.full_name.strip()

	UserRepository.upsert_profile(
		db,
		user_id=user.id,
		gender=payload.gender,
		birth_date=payload.birth_date,
		has_hypertension=payload.has_hypertension,
		hypertension_condition=payload.hypertension_condition,
		systolic_pressure=payload.systolic_pressure,
		diastolic_pressure=payload.diastolic_pressure,
		pregnancy_status=payload.pregnancy_status,
	)

	db.commit()
	db.refresh(user)
	return UserProfileUpsertResponse(
		user_id=user.id,
		full_name=user.full_name,
		message="Profile saved",
	)

