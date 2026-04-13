from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class FoodLabelScan(Base):
	__tablename__ = "food_label_scan"

	id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
	user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
	image_path: Mapped[str] = mapped_column(Text)
	raw_text: Mapped[str] = mapped_column(Text)
	sodium_mg: Mapped[float] = mapped_column(Float)
	scanned_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

