import logging
from pathlib import Path
import sys

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
	sys.path.insert(0, str(BACKEND_ROOT))

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.logging import setup_logging
from app.db.base import Base
from app.db.session import engine, ensure_mysql_database_exists
from app.models import chat_session, food_label_scan, intake_history, user  # noqa: F401


def create_app() -> FastAPI:
	setup_logging()
	app = FastAPI(title=settings.app_name)
	app.add_middleware(
		CORSMiddleware,
		allow_origins=["*"],
		allow_credentials=False,
		allow_methods=["*"],
		allow_headers=["*"],
	)

	@app.on_event("startup")
	def on_startup() -> None:
		try:
			ensure_mysql_database_exists()
			Base.metadata.create_all(bind=engine)
		except Exception as exc:
			logging.getLogger(__name__).warning("Database unavailable at startup: %s", exc)

	@app.get("/health", tags=["health"])
	def health() -> dict[str, str]:
		return {"status": "ok"}

	app.include_router(api_router, prefix=settings.api_v1_prefix)
	return app


app = create_app()

