from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class RefreshToken(Base):
	__tablename__ = "refresh_token"

	id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
	user_id: Mapped[int] = mapped_column(
		Integer,
		ForeignKey("users.id", ondelete="CASCADE"),
		nullable=False,
		index=True,
	)
	token_hash: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
	created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
	expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
	revoked_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
