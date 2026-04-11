import json

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.models.chat_session import ChatSession


class ChatRepository:
	@staticmethod
	def create_chat(db: Session, user_id: int, question: str, answer: str, sources: list[str]) -> ChatSession:
		item = ChatSession(
			user_id=user_id,
			question=question,
			answer=answer,
			sources=json.dumps(sources),
		)
		db.add(item)
		db.commit()
		db.refresh(item)
		return item

	@staticmethod
	def list_chat(db: Session, user_id: int) -> list[ChatSession]:
		stmt = select(ChatSession).where(ChatSession.user_id == user_id).order_by(desc(ChatSession.created_at))
		return list(db.scalars(stmt).all())

