from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class ChatSession(Base):
	__tablename__ = "chat_session"

	id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
	user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
	question: Mapped[str] = mapped_column(Text)
	answer: Mapped[str] = mapped_column(Text)
	sources: Mapped[str] = mapped_column(Text, default="[]")
	created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

