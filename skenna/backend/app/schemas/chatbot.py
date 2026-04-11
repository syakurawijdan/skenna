from pydantic import BaseModel


class ChatAskRequest(BaseModel):
	user_id: int
	question: str


class ChatAskResponse(BaseModel):
	answer: str
	sources: list[str]

