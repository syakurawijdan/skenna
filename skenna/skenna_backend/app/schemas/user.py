from datetime import date
from typing import Literal, Optional

from pydantic import BaseModel, Field


class UserProfileUpsertRequest(BaseModel):
	full_name: str = Field(..., min_length=1, max_length=120)
	gender: Literal["perempuan", "laki-laki"]
	birth_date: date
	has_hypertension: bool
	hypertension_condition: Optional[Literal["history_only", "controlled", "uncontrolled"]] = None
	systolic_pressure: Optional[int] = Field(None, ge=50, le=300)
	diastolic_pressure: Optional[int] = Field(None, ge=30, le=200)
	pregnancy_status: Optional[Literal["pregnant", "breastfeeding", "none"]] = None


class UserProfileUpsertResponse(BaseModel):
	user_id: int
	full_name: str
	message: str
