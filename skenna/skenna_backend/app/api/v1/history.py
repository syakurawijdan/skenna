from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy import desc, select
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError

from app.api.deps import get_db
from app.models.food_label_scan import FoodLabelScan
from app.models.intake_history import IntakeHistory
from app.repositories.chat_repository import ChatRepository
from app.repositories.history_repository import HistoryRepository
from app.schemas.history import IntakeCreateRequest, IntakeFullUpdateRequest, IntakeUpdateRequest
from app.services.rekomendasi_service import get_rekomendasi  # ← tambah import
import json

router = APIRouter()


def _today_wib_range() -> tuple[datetime, datetime]:
    now = datetime.now(timezone(timedelta(hours=7))).replace(tzinfo=None)
    start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    end = start + timedelta(days=1)
    return start, end


def _intake_to_dict(item: IntakeHistory) -> dict:
    return {
        "id": item.id,
        "user_id": item.user_id,
        "food_name": item.food_name,
        "kategori": getattr(item, "kategori", None),
        "image_path": getattr(item, "image_path", None),
        "image_path2": getattr(item, "image_path2", None),
        "sodium_mg": item.sodium_mg,
        "sodium_level": item.sodium_level,
        "servings": float(getattr(item, "servings", 1) or 1),
        "is_consumed": item.is_consumed,
        "consumed_at": item.consumed_at.isoformat() if item.consumed_at else None,
        "type": item.intake_type if hasattr(item, "intake_type") else "single",
        "product_name2": getattr(item, "product_name2", None),
        "sodium_mg2": getattr(item, "sodium_mg2", None),
        "package_ml": float(getattr(item, "package_ml", 0) or 0),
        "portions_in_package": float(getattr(item, "portions_in_package", 1) or 1),
        "satuan_takaran": getattr(item, "satuan_takaran", "g"),
        "package_ml2": float(getattr(item, "package_ml2", 0) or 0),
        "portions_in_package2": float(getattr(item, "portions_in_package2", 1) or 1),
        "satuan_takaran2": getattr(item, "satuan_takaran2", "g"),
        "rekomendasi_json": getattr(item, "rekomendasi_json", None),
    }


@router.get("/intake")
def get_intake_history(user_id: int = Query(..., gt=0), db: Session = Depends(get_db)) -> list[dict]:
    try:
        data = HistoryRepository.list_intake(db, user_id)
    except SQLAlchemyError:
        return []
    return [
        _intake_to_dict(item)
        for item in data
    ]


@router.get("/consumed-today")
def get_consumed_today(user_id: int = Query(..., gt=0), db: Session = Depends(get_db)) -> list[dict]:
    start, end = _today_wib_range()
    try:
        items = list(
            db.scalars(
                select(IntakeHistory)
                .where(IntakeHistory.user_id == user_id)
                .where(IntakeHistory.is_consumed == True)
                .where(IntakeHistory.consumed_at >= start)
                .where(IntakeHistory.consumed_at < end)
                .order_by(desc(IntakeHistory.consumed_at))
            ).all()
        )
    except SQLAlchemyError:
        return []
    return [_intake_to_dict(item) for item in items]


@router.get("/scans")
def get_scan_history(user_id: int = Query(..., gt=0), db: Session = Depends(get_db)) -> list[dict]:
	try:
		scans = list(
			db.scalars(
                select(FoodLabelScan)
                .where(FoodLabelScan.user_id == user_id)
				.order_by(desc(FoodLabelScan.scanned_at))
			).all()
		)
		intake_items = list(
			db.scalars(
				select(IntakeHistory)
				.where(IntakeHistory.user_id == user_id)
				.where(IntakeHistory.food_name.is_not(None))
				.order_by(desc(IntakeHistory.consumed_at))
			).all()
		)
	except SQLAlchemyError:
		return []
	products_by_name: dict[str, dict] = {}

	def timestamp_value(timestamp: datetime | None) -> float:
		return timestamp.timestamp() if timestamp else 0

	def add_product(product: dict, timestamp: datetime | None) -> None:
		name = str(product.get("nama_produk") or "").strip()
		if not name:
			return
		key = name.lower()
		current = products_by_name.get(key)
		current_timestamp = current.get("_timestamp") if current else None
		if current is None or timestamp_value(timestamp) > timestamp_value(current_timestamp):
			product["_timestamp"] = timestamp
			products_by_name[key] = product

	for scan in scans:
		add_product(
			{
				"id": scan.id,
				"user_id": scan.user_id,
				"nama_produk": scan.nama_produk,
				"product_name": scan.nama_produk,
				"food_name": scan.nama_produk,
				"raw_text": scan.raw_text,
				"sodium_mg": scan.sodium_mg,
				"takaran_saji": float(scan.takaran_saji) if scan.takaran_saji is not None else None,
				"sajian_per_kemasan": float(scan.sajian_per_kemasan) if scan.sajian_per_kemasan is not None else None,
				"satuan_takaran": scan.satuan_takaran,
				"kategori": scan.kategori,
				"image_path": scan.image_path,
				"scanned_at": scan.scanned_at.isoformat() if scan.scanned_at else None,
				"source": "food_label_scan",
			},
			scan.scanned_at,
		)

	for item in intake_items:
		add_product(
			{
				"id": item.id,
				"user_id": item.user_id,
				"nama_produk": item.food_name,
				"product_name": item.food_name,
				"food_name": item.food_name,
				"raw_text": item.food_name,
				"sodium_mg": item.sodium_mg,
				"takaran_saji": float(item.package_ml) if item.package_ml is not None else None,
				"sajian_per_kemasan": float(item.portions_in_package) if item.portions_in_package is not None else None,
				"satuan_takaran": item.satuan_takaran,
				"kategori": item.kategori,
				"image_path": item.image_path,
				"scanned_at": item.consumed_at.isoformat() if item.consumed_at else None,
				"source": "intake_history",
			},
			item.consumed_at,
		)

	products = sorted(
		products_by_name.values(),
		key=lambda product: timestamp_value(product.get("_timestamp")),
		reverse=True,
	)
	for product in products:
		product.pop("_timestamp", None)
	return products


@router.get("/dashboard")
def get_dashboard_stats(user_id: int = Query(..., gt=0), db: Session = Depends(get_db)) -> dict:
    start, end = _today_wib_range()
    try:
        intake_items = HistoryRepository.list_intake(db, user_id)
    except SQLAlchemyError:
        return {
            "user_id": user_id,
            "date": start.date().isoformat(),
            "total_sodium_consumed_today": 0,
            "consumed_items_today": 0,
            "products_scanned_today": 0,
        }

    total_sodium = 0.0
    consumed_items = 0
    for item in intake_items:
        consumed_at = item.consumed_at
        if consumed_at is None or consumed_at < start or consumed_at >= end:
            continue
        if not item.is_consumed:
            continue
        servings = float(item.servings or 1)
        total_sodium += float(item.sodium_mg or 0) * servings
        consumed_items += 1

    scanned_today = sum(
        1
        for item in intake_items
        if item.consumed_at is not None
        and start <= item.consumed_at < end
        and item.is_consumed
    )

    return {
        "user_id": user_id,
        "date": start.date().isoformat(),
        "total_sodium_consumed_today": round(total_sodium),
        "consumed_items_today": consumed_items,
        "products_scanned_today": scanned_today,
    }


@router.post("/intake", status_code=201)
async def create_intake(payload: IntakeCreateRequest, db: Session = Depends(get_db)):
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
        image_path=payload.image_path,
        image_path2=payload.image_path2,
    )

    if payload.rekomendasi_json:
        item.rekomendasi_json = payload.rekomendasi_json
        db.commit()
    else:
        try:
            reko = await get_rekomendasi(
                payload.kategori or 'lainnya',
                int(payload.sodium_mg),
                user_id=payload.user_id,
                product_name=payload.food_name,
            )
            item.rekomendasi_json = json.dumps(reko)
            db.commit()
        except Exception as e:
            print(f"=== REKO ERROR (non-fatal): {e}")

    return {"id": item.id, "message": "ok"}


@router.get("/chat")
def get_chat_history(user_id: int = Query(..., gt=0), db: Session = Depends(get_db)) -> list[dict]:
	try:
		data = ChatRepository.list_recent_for_sidebar(db, user_id, days=7)
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
		created_date = created_at.date()
		days_ago = (today - created_date).days
		if days_ago <= 0:
			label = "Today"
		elif days_ago == 1:
			label = "Yesterday"
		else:
			label = f"{days_ago} hari lalu"
		groups.setdefault(label, []).append(
			{
				"id": first.id,
				"session_id": f"chat-{first.id}-{last.id}",
				"user_id": first.user_id,
				"title": first.question,
				"question": first.question,
				"answer": last.answer,
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
        food_name=payload.food_name,
        sodium_mg=payload.sodium_mg,
        intake_type=payload.type,
        product_name2=payload.product_name2,
        sodium_mg2=payload.sodium_mg2,
        image_path=payload.image_path,        
        image_path2=payload.image_path2,   
    )
    print(f">>> item result: {item}")
    if item is None:
        raise HTTPException(status_code=404, detail="Item tidak ditemukan")
    return {
        "id": item.id,
        "is_consumed": item.is_consumed,
        "servings": float(item.servings) if item.servings is not None else 1.0,
        "food_name": item.food_name,
        "consumed_at": item.consumed_at,
        "message": "ok",
    }


@router.put("/intake/{intake_id}", status_code=200)
def update_intake(
    intake_id: int,
    payload: IntakeFullUpdateRequest,
    db: Session = Depends(get_db),
):
    item = db.get(IntakeHistory, intake_id)
    if item is None or item.user_id != payload.user_id:
        raise HTTPException(status_code=404, detail="Item tidak ditemukan")
    item.food_name = payload.food_name
    item.kategori = payload.kategori
    item.sodium_mg = payload.sodium_mg
    item.sodium_level = payload.sodium_level
    item.servings = payload.servings
    item.package_ml = payload.package_ml
    item.portions_in_package = payload.portions_in_package
    item.satuan_takaran = payload.satuan_takaran
    db.commit()
    db.refresh(item)
    return {**_intake_to_dict(item), "message": "ok"}


@router.delete("/intake/{intake_id}", status_code=200)
def delete_intake(
    intake_id: int,
    user_id: int = Query(..., gt=0),
    db: Session = Depends(get_db),
):
    item = db.get(IntakeHistory, intake_id)
    if item is None or item.user_id != user_id:
        raise HTTPException(status_code=404, detail="Item tidak ditemukan")
    db.delete(item)
    db.commit()
    return {"id": intake_id, "message": "ok"}
