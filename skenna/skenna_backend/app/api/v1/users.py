from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.core.security import hash_password, verify_password
from app.core.deps import get_current_user
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.user import (
    ChangePasswordRequest,
    UserFullNameUpdateRequest,
    UserProfileUpsertRequest,
    UserProfileUpsertResponse,
)

router = APIRouter()


@router.put("/profile", response_model=UserProfileUpsertResponse)
def upsert_user_profile(
	payload: UserProfileUpsertRequest,
	db: Session = Depends(get_db),
	current_user: User = Depends(get_current_user),
) -> UserProfileUpsertResponse:
	return _upsert_profile_for_user(db, current_user.id, payload)


@router.put("/{user_id}/profile", response_model=UserProfileUpsertResponse)
def upsert_user_profile_by_id(
	user_id: int,
	payload: UserProfileUpsertRequest,
	db: Session = Depends(get_db),
) -> UserProfileUpsertResponse:
	return _upsert_profile_for_user(db, user_id, payload)


@router.put("/{user_id}/full-name", response_model=UserProfileUpsertResponse)
def update_user_full_name(
	user_id: int,
	payload: UserFullNameUpdateRequest,
	db: Session = Depends(get_db),
) -> UserProfileUpsertResponse:
	user = UserRepository.update_full_name(db, user_id, payload.full_name)
	if user is None:
		raise HTTPException(status_code=404, detail="User not found")
	return UserProfileUpsertResponse(
		user_id=user.id,
		full_name=user.full_name,
		message="Full name saved",
	)


@router.post("/{user_id}/change-password")
def change_password(
	user_id: int,
	payload: ChangePasswordRequest,
	db: Session = Depends(get_db),
	current_user: User = Depends(get_current_user),
) -> dict:
	if current_user.id != user_id:
		raise HTTPException(status_code=403, detail="Tidak boleh mengganti password user lain")
	if not verify_password(payload.old_password, current_user.hashed_password):
		raise HTTPException(status_code=400, detail="Password lama salah")
	if verify_password(payload.new_password, current_user.hashed_password):
		raise HTTPException(status_code=400, detail="Password baru tidak boleh sama dengan password lama")
	current_user.hashed_password = hash_password(payload.new_password)
	db.commit()
	return {"message": "Password changed"}

@router.get("/profile")
def get_user_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict:
    return _get_profile_for_user(db, current_user.id)


@router.get("/{user_id}/profile")
def get_user_profile_by_id(
    user_id: int,
    db: Session = Depends(get_db),
) -> dict:
    return _get_profile_for_user(db, user_id)


@router.get("/{user_id}")
def get_user_account(
	user_id: int,
	db: Session = Depends(get_db),
) -> dict:
	user = UserRepository.get_by_id(db, user_id)
	if user is None:
		raise HTTPException(status_code=404, detail="User not found")
	return {
		"user_id": user.id,
		"full_name": user.full_name,
		"email": user.email,
	}


def _upsert_profile_for_user(
	db: Session,
	user_id: int,
	payload: UserProfileUpsertRequest,
) -> UserProfileUpsertResponse:
	print(f"[PROFILE] user_id={user_id}, gender={payload.gender}, full_name={payload.full_name}")
	user = UserRepository.get_by_id(db, user_id)
	if user is None:
		raise HTTPException(status_code=404, detail="User not found")

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
		full_name=payload.full_name,
	)

	db.refresh(user)
	return UserProfileUpsertResponse(
		user_id=user.id,
		full_name=user.full_name,
		message="Profile saved",
	)


def _get_profile_for_user(db: Session, user_id: int) -> dict:
    user = UserRepository.get_by_id(db, user_id)
    profile = UserRepository.get_profile(db, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    return {
        "user_id": user.id,
        "full_name": user.full_name,
        "gender": profile.gender,
        "birth_date": str(profile.birth_date),
        "has_hypertension": profile.has_hypertension,
        "hypertension_condition": profile.hypertension_condition,
        "systolic_pressure": profile.systolic_pressure,
        "diastolic_pressure": profile.diastolic_pressure,
        "pregnancy_status": profile.pregnancy_status,
        "updated_at": profile.updated_at.isoformat() if profile.updated_at else None,
    }
