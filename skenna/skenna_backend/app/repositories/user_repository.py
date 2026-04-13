from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User


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

