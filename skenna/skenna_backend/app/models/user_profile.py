from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class UserProfile(Base):
	__tablename__ = "user_profiles"

	id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
	user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), unique=True, index=True)
	gender: Mapped[str] = mapped_column(String(20))
	birth_date: Mapped[date] = mapped_column(Date)
	has_hypertension: Mapped[bool] = mapped_column(Boolean, default=False)
	systolic_pressure: Mapped[int] = mapped_column(Integer)
	diastolic_pressure: Mapped[int] = mapped_column(Integer)
	is_pregnant: Mapped[bool] = mapped_column(Boolean, default=False)
	updated_at: Mapped[datetime] = mapped_column(
		DateTime,
		default=datetime.utcnow,
		onupdate=datetime.utcnow,
	)