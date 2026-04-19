from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError

from app.api.deps import get_db
from app.repositories.chat_repository import ChatRepository
from app.repositories.history_repository import HistoryRepository

router = APIRouter()


@router.get("/intake")
def get_intake_history(user_id: int = Query(default=1), db: Session = Depends(get_db)) -> list[dict]:
	try:
		data = HistoryRepository.list_intake(db, user_id)
	except SQLAlchemyError:
		return []
	return [
		{
			"id": item.id,
			"user_id": item.user_id,
			"food_name": item.food_name,
			"sodium_mg": item.sodium_mg,
			"sodium_level": item.sodium_level,
			"consumed_at": item.consumed_at,
		}
		for item in data
	]


@router.get("/chat")
def get_chat_history(user_id: int = Query(default=1), db: Session = Depends(get_db)) -> list[dict]:
	try:
		data = ChatRepository.list_chat(db, user_id)
	except SQLAlchemyError:
		return []
	return [
		{
			"id": item.id,
			"user_id": item.user_id,
			"question": item.question,
			"answer": item.answer,
			"sources": item.sources,
			"created_at": item.created_at,
		}
		for item in data
	]

