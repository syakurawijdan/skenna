from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL, make_url
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings


def ensure_mysql_database_exists() -> None:
	url = make_url(settings.database_url)
	if not url.drivername.startswith("mysql"):
		return
	if not settings.mysql_auto_create_db:
		return
	if not url.database:
		return

	target_db_name = url.database
	admin_url: URL = url.set(database=settings.mysql_admin_database)
	admin_engine = create_engine(admin_url, future=True)
	with admin_engine.connect() as conn:
		conn.execute(
			text(
				f"CREATE DATABASE IF NOT EXISTS `{target_db_name}` "
				"CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
			)
		)
		conn.commit()
	admin_engine.dispose()


database_url = settings.database_url
connect_args = {"check_same_thread": False} if database_url.startswith("sqlite") else {}
engine = create_engine(database_url, future=True, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, class_=Session)


def get_db():
	db = SessionLocal()
	try:
		yield db
	finally:
		db.close()

