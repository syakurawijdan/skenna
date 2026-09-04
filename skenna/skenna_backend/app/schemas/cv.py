from typing import Optional

from pydantic import BaseModel, Field


class CVScanRequest(BaseModel):
    image_url: str | None = None
    image_base64: str | None = None
    kategori: str | None = None
    user_id: int = Field(..., gt=0)


class CVScanResponse(BaseModel):
    raw_text: str
    sodium_mg: Optional[float] = None
    sodium_level: Optional[str] = None
    scan_id: Optional[int] = None
    takaran_saji: Optional[float] = None
    sajian_per_kemasan: Optional[float] = None
    satuan_takaran: str
    image_path: Optional[str] = None
