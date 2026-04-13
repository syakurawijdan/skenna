from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.models.intake_history import IntakeHistory


class HistoryRepository:
	@staticmethod
	def create_intake(
		db: Session,
		user_id: int,
		food_name: str,
		sodium_mg: float,
		sodium_level: str,
	) -> IntakeHistory:
		item = IntakeHistory(
			user_id=user_id,
			food_name=food_name,
			sodium_mg=sodium_mg,
			sodium_level=sodium_level,
		)
		db.add(item)
		db.commit()
		db.refresh(item)
		return item

	@staticmethod
	def list_intake(db: Session, user_id: int) -> list[IntakeHistory]:
		stmt = select(IntakeHistory).where(IntakeHistory.user_id == user_id).order_by(desc(IntakeHistory.consumed_at))
		return list(db.scalars(stmt).all())

