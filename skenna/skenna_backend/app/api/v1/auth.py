from fastapi import APIRouter

router = APIRouter()


@router.post("/login")
def login_stub() -> dict[str, str]:
	return {"access_token": "demo-token", "token_type": "bearer"}

