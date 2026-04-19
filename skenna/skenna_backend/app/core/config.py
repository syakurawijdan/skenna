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
	database_url: str = "mysql+pymysql://root:@127.0.0.1:3306/skenna"
	mysql_auto_create_db: bool = True
	mysql_admin_database: str = "mysql"
	llm_provider: str = "stub"
	llm_api_key: str = ""
	llm_model: str = "gemini-flash-latest"
	vector_db_path: str = str(ROOT_DIR / "skenna_python" / "rag" / "index")


settings = Settings()

