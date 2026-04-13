from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.repositories.user_repository import UserRepository

router = APIRouter()


@router.post("/demo")
def create_demo_user(db: Session = Depends(get_db)) -> dict[str, int | str]:
	user = UserRepository.get_or_create_demo_user(db)
	return {"id": user.id, "email": user.email, "full_name": user.full_name}

