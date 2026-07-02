from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class OtpVerification(Base):
	__tablename__ = "otp_verification"

	id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
	email: Mapped[str] = mapped_column(String(120), nullable=False, index=True)
	otp_code: Mapped[str] = mapped_column(String(6), nullable=False)
	created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
	expired_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
	is_used: Mapped[bool] = mapped_column(Boolean, default=False)
