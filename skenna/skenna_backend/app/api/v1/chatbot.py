import logging
from datetime import datetime

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError

from app.api.deps import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.repositories.chat_repository import ChatRepository
from app.schemas.chatbot import ChatAskRequest, ChatAskResponse
from app.services.chatbot_service import ChatbotService

router = APIRouter()
history_router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/ask", response_model=ChatAskResponse)
def ask_chatbot(
	payload: ChatAskRequest,
	db: Session = Depends(get_db),
	current_user: User = Depends(get_current_user),
) -> ChatAskResponse:
	try:
		answer, sources = ChatbotService.answer(
			payload.question,
			db=db,
			user_id=current_user.id,
			education_part=payload.education_part,
			kategori=payload.kategori,
			product_name=payload.product_name,
			sodium_mg=payload.sodium_mg,
			scan_id=payload.scan_id,
		)
	except Exception as exc:
		logger.exception("Chatbot answer generation failed for user_id=%s: %s", current_user.id, exc)
		return ChatAskResponse(
			answer=(
				"Maaf, Skenny lagi kesulitan menghubungi layanan AI. "
				"Coba kirim ulang sebentar lagi ya."
			),
			sources=[],
		)
	try:
		ChatRepository.create_chat(db, current_user.id, payload.question, answer, sources)
	except SQLAlchemyError:
		pass
	return ChatAskResponse(answer=answer, sources=sources)


@history_router.get("/history")
@router.get("/history")
def get_chatbot_history(
	db: Session = Depends(get_db),
	current_user: User = Depends(get_current_user),
) -> list[dict]:
	try:
		data = ChatRepository.list_recent_for_sidebar(db, current_user.id, days=7)
	except SQLAlchemyError:
		return []

	now = datetime.now()
	today = now.date()
	sessions: list[list] = []
	for item in reversed(data):
		if not sessions:
			sessions.append([item])
			continue
		previous = sessions[-1][-1].created_at
		current = item.created_at
		if previous and current and (current - previous).total_seconds() <= 30 * 60:
			sessions[-1].append(item)
		else:
			sessions.append([item])

	sessions = list(reversed(sessions))
	groups: dict[str, list[dict]] = {}
	for session in sessions:
		first = session[0]
		last = session[-1]
		created_at = first.created_at
		created_date = created_at.date() if created_at else today
		days_ago = (today - created_date).days
		if days_ago <= 0:
			label = "Hari ini"
		elif days_ago == 1:
			label = "Kemarin"
		else:
			label = f"{days_ago} hari lalu"
		answer_preview = next((item.answer for item in session if item.answer), last.answer or "")
		groups.setdefault(label, []).append(
			{
				"id": first.id,
				"session_id": f"chat-{first.id}-{last.id}",
				"user_id": first.user_id,
				"title": _truncate(first.question or "Percakapan", 50),
				"answer_preview": _truncate(answer_preview, 80),
				"created_at": created_at.isoformat() if created_at else None,
				"updated_at": last.created_at.isoformat() if last.created_at else None,
				"messages": [
					{
						"id": item.id,
						"question": item.question,
						"answer": item.answer,
						"sources": item.sources,
						"created_at": item.created_at.isoformat() if item.created_at else None,
					}
					for item in session
				],
			}
		)
	return [{"label": label, "items": items} for label, items in groups.items()]


def _truncate(value: str, max_length: int) -> str:
	normalized = " ".join(str(value or "").split())
	if len(normalized) <= max_length:
		return normalized
	return f"{normalized[: max_length - 3]}..."

