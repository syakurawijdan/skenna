from datetime import date, datetime, timezone, timedelta
from typing import Optional

from sqlalchemy import Boolean, Date, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base

def wib_now() -> datetime:
    return (datetime.now(timezone.utc) + timedelta(hours=7)).replace(tzinfo=None)

class UserProfile(Base):
	__tablename__ = "user_profiles"

	id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
	user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), unique=True, index=True)
	gender: Mapped[str] = mapped_column(String(20))
	birth_date: Mapped[date] = mapped_column(Date)
	has_hypertension: Mapped[bool] = mapped_column(Boolean, default=False)
	# Kondisi hipertensi: "history_only", "controlled", "uncontrolled"
	hypertension_condition: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
	systolic_pressure: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
	diastolic_pressure: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
	# Pregnancy status: "pregnant", "breastfeeding", "none"
	pregnancy_status: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
	updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=wib_now,
        onupdate=wib_now,
	)