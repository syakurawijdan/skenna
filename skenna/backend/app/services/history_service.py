from sqlalchemy import Select, desc, select
from sqlalchemy.orm import Session

from app.models.chat_session import ChatSession
from app.models.intake_history import IntakeHistory


class HistoryService:
	@staticmethod
	def get_intake_history(db: Session, user_id: int) -> list[IntakeHistory]:
		stmt: Select[tuple[IntakeHistory]] = (
			select(IntakeHistory).where(IntakeHistory.user_id == user_id).order_by(desc(IntakeHistory.consumed_at))
		)
		return list(db.scalars(stmt).all())

	@staticmethod
	def get_chat_history(db: Session, user_id: int) -> list[ChatSession]:
		stmt: Select[tuple[ChatSession]] = (
			select(ChatSession).where(ChatSession.user_id == user_id).order_by(desc(ChatSession.created_at))
		)
		return list(db.scalars(stmt).all())

