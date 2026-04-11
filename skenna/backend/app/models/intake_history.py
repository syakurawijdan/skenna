from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class IntakeHistory(Base):
	__tablename__ = "intake_history"

	id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
	user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
	food_name: Mapped[str] = mapped_column(String(120))
	sodium_mg: Mapped[float] = mapped_column(Float)
	sodium_level: Mapped[str] = mapped_column(String(20))
	consumed_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

