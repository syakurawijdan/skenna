from datetime import datetime

from sqlalchemy import DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class User(Base):
	__tablename__ = "users"

	id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
	full_name: Mapped[str] = mapped_column(String(120))
	email: Mapped[str] = mapped_column(String(120), unique=True, index=True)
	hashed_password: Mapped[str] = mapped_column(String(255))
	created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

