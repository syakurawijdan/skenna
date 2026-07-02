import json
from datetime import datetime, timedelta
from typing import Any

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.models.chat_session import ChatSession


class ChatRepository:
	@staticmethod
	def create_chat(db: Session, user_id: int, question: str, answer: str, sources: list[Any]) -> ChatSession:
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

	@staticmethod
	def list_recent_pairs(db: Session, user_id: int, limit: int = 10) -> list[ChatSession]:
		stmt = (
			select(ChatSession)
			.where(ChatSession.user_id == user_id)
			.order_by(desc(ChatSession.created_at))
			.limit(limit)
		)
		return list(db.scalars(stmt).all())

	@staticmethod
	def list_recent_for_sidebar(db: Session, user_id: int, days: int = 7) -> list[ChatSession]:
		cutoff = datetime.utcnow() - timedelta(days=days)
		stmt = (
			select(ChatSession)
			.where(ChatSession.user_id == user_id)
			.where(ChatSession.created_at >= cutoff)
			.order_by(desc(ChatSession.created_at))
		)
		return list(db.scalars(stmt).all())

