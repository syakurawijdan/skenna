import sys
from logging.config import fileConfig
from pathlib import Path

from sqlalchemy import engine_from_config, pool
from alembic import context

sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.core.config import settings

config = context.config
fileConfig(config.config_file_name)
config.set_main_option("sqlalchemy.url", settings.database_url)

from app.db.base import Base
from app.models.user import User
from app.models.user_profile import UserProfile
from app.models.chat_session import ChatSession
from app.models.food_label_scan import FoodLabelScan
from app.models.intake_history import IntakeHistory
from app.models.otp_verification import OtpVerification
from app.models.refresh_token import RefreshToken

target_metadata = Base.metadata


def run_migrations_offline():
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)

        with connection.begin():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
