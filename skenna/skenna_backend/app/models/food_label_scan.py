from datetime import datetime, timezone, timedelta 
from typing import Optional

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class FoodLabelScan(Base):
    __tablename__ = "food_label_scan"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    image_path: Mapped[str] = mapped_column(Text)
    raw_text: Mapped[str] = mapped_column(Text)
    sodium_mg: Mapped[float] = mapped_column(Float)
    scanned_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=lambda: datetime.now(timezone(timedelta(hours=7))).replace(tzinfo=None)  
    )
    takaran_saji: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    sajian_per_kemasan: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    satuan_takaran: Mapped[Optional[str]] = mapped_column(String(10), nullable=True)
    nama_produk: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)  
    kategori: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    isi_kemasan: Mapped[Optional[float]] = mapped_column(Float, nullable=True)          
    isi_kemasan_satuan: Mapped[Optional[str]] = mapped_column(String(5), nullable=True, default='g')  
    
