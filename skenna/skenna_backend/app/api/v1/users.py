from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserProfileUpsertRequest, UserProfileUpsertResponse
from app.schemas.user import UserCreateRequest
from app.schemas.user import UserCreateRequest, UserProfileUpsertRequest, UserProfileUpsertResponse
from fastapi import APIRouter, Depends, HTTPException

router = APIRouter()


@router.post("/demo")
def create_demo_user(db: Session = Depends(get_db)) -> dict[str, int | str]:
	user = UserRepository.get_or_create_demo_user(db)
	return {"id": user.id, "email": user.email, "full_name": user.full_name}

@router.post("/register")
def register_user(
    payload: UserCreateRequest,
    db: Session = Depends(get_db)
) -> dict:
    user = UserRepository.create_user(db, full_name=payload.full_name)
    return {"id": user.id, "full_name": user.full_name}

@router.put("/{user_id}/profile", response_model=UserProfileUpsertResponse)
def upsert_user_profile(
	user_id: int,
	payload: UserProfileUpsertRequest,
	db: Session = Depends(get_db),
) -> UserProfileUpsertResponse:
	print(f"[PROFILE] user_id={user_id}, gender={payload.gender}, full_name={payload.full_name}")
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

@router.get("/{user_id}/profile")
def get_user_profile(
    user_id: int,
    db: Session = Depends(get_db),
) -> dict:
    user = UserRepository.get_or_create_by_id(db, user_id)
    profile = UserRepository.get_profile(db, user_id)
    
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    return {
        "user_id": user.id,
        "full_name": user.full_name,
        "gender": profile.gender,
        "birth_date": str(profile.birth_date),
        "has_hypertension": profile.has_hypertension,
    }
