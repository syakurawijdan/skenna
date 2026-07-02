from pydantic import BaseModel, Field
from typing import Any
from app.schemas.product_category import ProductCategory


class ChatAskRequest(BaseModel):
	user_id: int = Field(..., gt=0)
	question: str
	education_part: int | None = Field(default=None, ge=1, le=3)
	kategori: ProductCategory | None = None
	product_name: str | None = None
	sodium_mg: int | None = Field(default=None, ge=0)
	scan_id: int | None = Field(default=None, gt=0)


class ChatAskResponse(BaseModel):
	answer: str
	sources: list[Any]

