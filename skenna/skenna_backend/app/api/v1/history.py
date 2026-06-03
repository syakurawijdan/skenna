from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError

from app.api.deps import get_db
from app.repositories.chat_repository import ChatRepository
from app.repositories.history_repository import HistoryRepository
from app.schemas.history import IntakeCreateRequest, IntakeUpdateRequest


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
            "kategori": getattr(item, 'kategori', None),
            "sodium_mg": item.sodium_mg,
            "sodium_level": item.sodium_level,
            "servings": getattr(item, 'servings', 1),
            "is_consumed": item.is_consumed,
            "consumed_at": item.consumed_at.isoformat() if item.consumed_at else None,
            "type": item.intake_type if hasattr(item, 'intake_type') else 'single',
            "product_name2": getattr(item, 'product_name2', None),
            "sodium_mg2": getattr(item, 'sodium_mg2', None),
             "package_ml": getattr(item, "package_ml", 0),
            "portions_in_package": getattr(item, "portions_in_package", 1),
            "satuan_takaran": getattr(item, "satuan_takaran", "g"),
            "package_ml2": getattr(item, "package_ml2", 0),
            "portions_in_package2": getattr(item, "portions_in_package2", 1),
            "satuan_takaran2": getattr(item, "satuan_takaran2", "g"),
        }
        for item in data
    ]

@router.post("/intake", status_code=201)
def create_intake(payload: IntakeCreateRequest, db: Session = Depends(get_db)):
    item = HistoryRepository.create_intake(
        db=db,
        user_id=payload.user_id,
        food_name=payload.food_name,
        kategori=payload.kategori,
        sodium_mg=payload.sodium_mg,
        sodium_level=payload.sodium_level,
        scan_id=payload.scan_id,
		servings=payload.servings,
        intake_type=payload.type,
        product_name2=payload.product_name2,
        sodium_mg2=payload.sodium_mg2,
        is_consumed=payload.is_consumed,
        package_ml=payload.package_ml,
        portions_in_package=payload.portions_in_package,
        satuan_takaran=payload.satuan_takaran,
        package_ml2=payload.package_ml2,
        portions_in_package2=payload.portions_in_package2,
        satuan_takaran2=payload.satuan_takaran2,
    )
    return {"id": item.id, "message": "ok"}

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


@router.patch("/intake/{intake_id}", status_code=200)
def update_intake_consumed(
    intake_id: int,
    payload: IntakeUpdateRequest,
    db: Session = Depends(get_db),
):
    print(f">>> intake_id={intake_id}, user_id={payload.user_id}")
    item = HistoryRepository.update_is_consumed(
        db=db,
        intake_id=intake_id,
        user_id=payload.user_id,
        is_consumed=payload.is_consumed,
		servings=payload.servings,
    )
    print(f">>> item result: {item}")
    if item is None:
        raise HTTPException(status_code=404, detail="Item tidak ditemukan")
    return {"id": item.id, "is_consumed": item.is_consumed, "servings": item.servings, "consumed_at": item.consumed_at, "message": "ok"}

