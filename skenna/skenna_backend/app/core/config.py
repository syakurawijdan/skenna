from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


ROOT_DIR = Path(__file__).resolve().parents[3]


class Settings(BaseSettings):
	model_config = SettingsConfigDict(extra="ignore", env_file=(".env", "../.env"), env_file_encoding="utf-8")

	app_name: str = "Skenna Sodium API"
	env: str = "dev"
	api_v1_prefix: str = "/api/v1"
	secret_key: str = "change_this_secret"
	access_token_expire_minutes: int = 1440
	refresh_token_expire_days: int = 30
	database_url: str = "mysql+pymysql://root:@127.0.0.1:3306/skenna"
	mysql_auto_create_db: bool = True
	mysql_admin_database: str = "mysql"
	gemini_api_key: str = ""
	gemini_chat_model: str = "gemini-2.5-flash"
	gemini_reasoning_model: str = "gemini-2.5-flash"
	gemini_embedding_model: str = "gemini-embedding-2"
	gemini_vision_model: str = "gemini-2.5-flash"
	chroma_db_path: str = str(ROOT_DIR / "skenna_python" / "rag" / "chroma")
	chroma_collection_name: str = "hypertension_knowledge"
	rag_top_k: int = 12
	rag_distance_threshold: float = 0.7
	smtp_host: str = ""
	smtp_port: int = 587
	smtp_username: str = ""
	smtp_password: str = ""
	smtp_from_email: str = ""
	smtp_use_tls: bool = True


settings = Settings()

