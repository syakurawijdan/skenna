from datetime import date
from typing import Literal

from pydantic import BaseModel, Field


class UserProfileUpsertRequest(BaseModel):
	full_name: str = Field(..., min_length=1, max_length=120)
	gender: Literal["perempuan", "laki-laki"]
	birth_date: date
	height_cm: float = Field(..., ge=50, le=300)
	weight_kg: float = Field(..., ge=20, le=500)
	has_hypertension: bool
	systolic_pressure: int = Field(..., ge=50, le=300)
	diastolic_pressure: int = Field(..., ge=30, le=200)
	is_pregnant: bool


class UserProfileUpsertResponse(BaseModel):
	user_id: int
	full_name: str
	bmi: float
	message: str
