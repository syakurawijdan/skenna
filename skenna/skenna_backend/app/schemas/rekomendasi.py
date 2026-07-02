from pydantic import BaseModel
from typing import Optional
from app.schemas.product_category import ProductCategory


class RekomendasiRequest(BaseModel):
    kategori: ProductCategory
    sodium_mg: int
    user_id: Optional[int] = None
    product_name: Optional[str] = None


class RekomendasiItem(BaseModel):
    nama_produk: str
    kategori: ProductCategory
    sodium_per_sajian_mg: int
    alasan: str


class RekomendasiResponse(BaseModel):
    rekomendasi: list[RekomendasiItem]
    tips: Optional[str] = None
    is_fallback: bool = False
    disclaimer: Optional[str] = None
