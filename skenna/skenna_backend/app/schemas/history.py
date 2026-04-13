from datetime import datetime

from pydantic import BaseModel


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

