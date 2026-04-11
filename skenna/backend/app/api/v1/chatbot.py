from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.repositories.chat_repository import ChatRepository
from app.repositories.user_repository import UserRepository
from app.schemas.chatbot import ChatAskRequest, ChatAskResponse
from app.services.chatbot_service import ChatbotService

router = APIRouter()


@router.post("/ask", response_model=ChatAskResponse)
def ask_chatbot(payload: ChatAskRequest, db: Session = Depends(get_db)) -> ChatAskResponse:
	user = UserRepository.get_or_create_by_id(db, payload.user_id)
	answer, sources = ChatbotService.answer(payload.question)
	ChatRepository.create_chat(db, user.id, payload.question, answer, sources)
	return ChatAskResponse(answer=answer, sources=sources)

