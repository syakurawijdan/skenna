from datetime import datetime, timezone, timedelta
from typing import Optional

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class IntakeHistory(Base):
    __tablename__ = "intake_history"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    food_name: Mapped[str] = mapped_column(String(120))
    kategori: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    scan_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True) 
    image_path: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    image_path2: Mapped[Optional[str]] = mapped_column(String(255), nullable=True) 
    sodium_mg: Mapped[float] = mapped_column(Float)
    sodium_level: Mapped[str] = mapped_column(String(20))
    servings: Mapped[int] = mapped_column(Integer, default=1) 
    is_consumed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    consumed_at: Mapped[datetime] = mapped_column(
        DateTime, 
        default=lambda: datetime.now(timezone(timedelta(hours=7)))
    )
    intake_type: Mapped[str] = mapped_column("type", String(50), default="single")
    product_name2: Mapped[Optional[str]] = mapped_column(String(120), nullable=True)
    sodium_mg2: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    package_ml: Mapped[int] = mapped_column(Integer, default=0)
    portions_in_package: Mapped[int] = mapped_column(Integer, default=1)
    satuan_takaran: Mapped[str] = mapped_column(String(20), default="g")
    package_ml2: Mapped[int] = mapped_column(Integer, default=0)
    portions_in_package2: Mapped[int] = mapped_column(Integer, default=1)
    satuan_takaran2: Mapped[str] = mapped_column(String(20), default="g")
    rekomendasi_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  
