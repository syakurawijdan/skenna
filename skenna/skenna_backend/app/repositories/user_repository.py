from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.user_profile import UserProfile


class UserRepository:
	@staticmethod
	def get_or_create_demo_user(db: Session) -> User:
		user = db.scalar(select(User).where(User.email == "demo@skenna.app"))
		if user:
			return user
		user = User(full_name="Demo User", email="demo@skenna.app", hashed_password="demo")
		db.add(user)
		db.commit()
		db.refresh(user)
		return user

	@staticmethod
	def get_or_create_by_id(db: Session, user_id: int) -> User:
		user = db.get(User, user_id)
		if user:
			return user
		user = User(
			id=user_id,
			full_name=f"User {user_id}",
			email=f"user{user_id}@skenna.app",
			hashed_password="demo",
		)
		db.add(user)
		db.commit()
		db.refresh(user)
		return user

	@staticmethod
	def upsert_profile(
		db: Session,
		*,
		user_id: int,
		gender: str,
		birth_date,
		height_cm: float,
		weight_kg: float,
		bmi: float,
		has_hypertension: bool,
		systolic_pressure: int,
		diastolic_pressure: int,
		is_pregnant: bool,
	) -> UserProfile:
		profile = db.scalar(select(UserProfile).where(UserProfile.user_id == user_id))
		if profile is None:
			profile = UserProfile(user_id=user_id, gender=gender, birth_date=birth_date)
			db.add(profile)

		profile.gender = gender
		profile.birth_date = birth_date
		profile.height_cm = height_cm
		profile.weight_kg = weight_kg
		profile.bmi = bmi
		profile.has_hypertension = has_hypertension
		profile.systolic_pressure = systolic_pressure
		profile.diastolic_pressure = diastolic_pressure
		profile.is_pregnant = is_pregnant

		db.commit()
		db.refresh(profile)
		return profile

