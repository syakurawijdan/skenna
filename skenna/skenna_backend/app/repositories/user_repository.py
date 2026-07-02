from datetime import datetime
from uuid import uuid4
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import hash_password
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
    def get_by_id(db: Session, user_id: int) -> User | None:
        return db.get(User, user_id)

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
    def create_user(db: Session, full_name: str, email: str, password: str) -> User:  # ← masuk ke dalam class
        user = User(
            full_name=full_name.strip(),
            email=email,
            hashed_password=hash_password(password),
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
        has_hypertension: bool,
        hypertension_condition: str = None,
        systolic_pressure: int = None,
        diastolic_pressure: int = None,
        pregnancy_status: str = None,
        full_name: str = None,
    ) -> UserProfile:
        user = db.get(User, user_id)
        if user is not None and full_name is not None:
            user.full_name = full_name.strip()

        profile = db.scalar(select(UserProfile).where(UserProfile.user_id == user_id))
        if profile is None:
            profile = UserProfile(user_id=user_id, gender=gender, birth_date=birth_date)
            db.add(profile)

        profile.gender = gender
        profile.birth_date = birth_date
        profile.has_hypertension = has_hypertension
        profile.hypertension_condition = hypertension_condition
        profile.systolic_pressure = systolic_pressure
        profile.diastolic_pressure = diastolic_pressure
        profile.pregnancy_status = pregnancy_status

        db.commit()
        db.refresh(profile)
        return profile

    @staticmethod
    def update_full_name(db: Session, user_id: int, full_name: str) -> User | None:
        user = db.get(User, user_id)
        if user is None:
            return None
        user.full_name = full_name.strip()
        db.commit()
        db.refresh(user)
        return user

    @staticmethod
    def update_password(db: Session, email: str, new_password: str) -> User | None:
        user = db.scalar(select(User).where(User.email == email))
        if user is None:
            return None
        user.hashed_password = hash_password(new_password)
        db.commit()
        db.refresh(user)
        return user
    
    @staticmethod
    def get_profile(db: Session, user_id: int) -> UserProfile | None:
        return db.scalar(select(UserProfile).where(UserProfile.user_id == user_id))
