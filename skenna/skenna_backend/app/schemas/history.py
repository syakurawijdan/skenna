from datetime import datetime

from pydantic import BaseModel
from typing import Optional

class IntakeHistoryItem(BaseModel):
	id: int
	user_id: int
	food_name: str
	sodium_mg: float
	sodium_level: str
	consumed_at: datetime


class ChatHistoryItem(BaseModel):
	id: int
	user_id: int
	question: str
	answer: str
	sources: str
	created_at: datetime

class IntakeCreateRequest(BaseModel):
    user_id: int
    food_name: str
    kategori: str | None = None
    sodium_mg: float
    sodium_level: str
    scan_id: int | None = None
    servings: float = 1
    type: str = 'single'
    product_name2: Optional[str] = None
    sodium_mg2: Optional[float] = None
    is_consumed: bool = False
    package_ml: float = 0
    portions_in_package: float = 1
    satuan_takaran: str = "g"
    package_ml2: float = 0
    portions_in_package2: float = 1
    satuan_takaran2: str = "g"
    image_path: Optional[str] = None
    image_path2: Optional[str] = None
    rekomendasi_json: Optional[str] = None

class IntakeHistoryResponse(BaseModel):
    id: int
    user_id: int
    food_name: str
    kategori: str | None = None
    sodium_mg: float
    sodium_level: str
    is_consumed: bool
    servings: float = 1 
    consumed_at: datetime
    image_path: Optional[str] = None
    
    class Config:
        from_attributes = True 

class IntakeUpdateRequest(BaseModel):
    user_id: int
    is_consumed: bool
    servings: float | None = None
    consumed_at: datetime | None = None
    food_name: str | None = None
    sodium_mg: float | None = None
    product_name2: str | None = None
    sodium_mg2: float | None = None
    image_path: str | None = None     
    image_path2: str | None = None

class IntakeFullUpdateRequest(BaseModel):
    user_id: int
    food_name: str
    kategori: str | None = None
    sodium_mg: float
    sodium_level: str
    servings: float = 1
    package_ml: float = 0
    portions_in_package: float = 1
    satuan_takaran: str = "g"
