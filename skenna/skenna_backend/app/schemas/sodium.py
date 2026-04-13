from pydantic import BaseModel, Field


class SodiumClassifyRequest(BaseModel):
	sodium_mg: float = Field(..., ge=0)
	serving_size_g: float = Field(default=100, gt=0)


class SodiumClassifyResponse(BaseModel):
	sodium_mg: float
	sodium_level: str
	recommendation: str

