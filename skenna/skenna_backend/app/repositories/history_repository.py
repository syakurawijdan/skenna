from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.models.intake_history import IntakeHistory
from datetime import datetime, timezone, timedelta

class HistoryRepository:
	@staticmethod
	def create_intake(
		db: Session,
		user_id: int,
		food_name: str,
		sodium_mg: float,
		sodium_level: str,
		scan_id: int | None = None,
		kategori: str | None = None,
		image_path: str | None = None,
		image_path2: str | None = None,
		servings: int = 1,
		intake_type: str = 'single',
		product_name2=None, 
		sodium_mg2=None,
		is_consumed: bool = False,
		package_ml: float = 0,
		portions_in_package: float = 1,
		satuan_takaran: str = "g",
		package_ml2: float = 0,
		portions_in_package2: float = 1,
		satuan_takaran2: str = "g",
	) -> IntakeHistory:
		item = IntakeHistory(
			user_id=user_id,
			food_name=food_name,
			kategori=kategori,
			sodium_mg=sodium_mg,
			sodium_level=sodium_level,
			scan_id=scan_id,
			image_path=image_path,
			image_path2=image_path2,
			servings=servings,
			intake_type=intake_type,
			product_name2=product_name2,
			sodium_mg2=sodium_mg2,
			is_consumed=is_consumed,
			package_ml=package_ml,
			portions_in_package=portions_in_package,
			satuan_takaran=satuan_takaran,
			package_ml2=package_ml2,
			portions_in_package2=portions_in_package2,
			satuan_takaran2=satuan_takaran2,
		)
		db.add(item)
		db.commit()
		db.refresh(item)
		return item
	
	@staticmethod
	def list_intake(db: Session, user_id: int) -> list[IntakeHistory]:
		stmt = select(IntakeHistory).where(IntakeHistory.user_id == user_id).order_by(desc(IntakeHistory.consumed_at))
		return list(db.scalars(stmt).all())
	@staticmethod
	def update_is_consumed(
		db: Session,
		intake_id: int,
		user_id: int,
		is_consumed: bool,
		servings: int | None = None,
		food_name: str | None = None,
		sodium_mg: float | None = None,
		product_name2: str | None = None,
		sodium_mg2: float | None = None,
		image_path: str | None = None,      # ← TAMBAHKAN
		image_path2: str | None = None,     # ← TAMBAHKAN
	) -> IntakeHistory | None:
		item = db.get(IntakeHistory, intake_id)
		if item is None or item.user_id != user_id:
			return None
		item.is_consumed = is_consumed
		if servings is not None:
			item.servings = servings
			item.consumed_at = datetime.now(timezone(timedelta(hours=7)))
		if food_name is not None:
			item.food_name = food_name
		if sodium_mg is not None:
			item.sodium_mg = sodium_mg
		if product_name2 is not None:
			item.product_name2 = product_name2
		if sodium_mg2 is not None:
			item.sodium_mg2 = sodium_mg2
		if image_path is not None:
			item.image_path = image_path       
		if image_path2 is not None:
			item.image_path2 = image_path2     
		db.commit()
		db.refresh(item)
		return item
