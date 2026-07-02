"""add otp verification table

Revision ID: 20260624_otp
Revises: bdf12fe9ae2d
Create Date: 2026-06-24

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260624_otp"
down_revision: Union[str, None] = "bdf12fe9ae2d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
	op.create_table(
		"otp_verification",
		sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
		sa.Column("email", sa.String(length=120), nullable=False),
		sa.Column("otp_code", sa.String(length=6), nullable=False),
		sa.Column("created_at", sa.DateTime(), nullable=False),
		sa.Column("expired_at", sa.DateTime(), nullable=False),
		sa.Column("is_used", sa.Boolean(), nullable=True, server_default=sa.text("0")),
	)
	op.create_index("ix_otp_verification_email", "otp_verification", ["email"])


def downgrade() -> None:
	op.drop_index("ix_otp_verification_email", table_name="otp_verification")
	op.drop_table("otp_verification")
