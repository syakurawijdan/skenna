from pydantic import BaseModel, Field


class CVScanRequest(BaseModel):
	image_url: str = Field(..., description="URL or local path for image")


class CVScanResponse(BaseModel):
	raw_text: str
	sodium_mg: float
	sodium_level: str

