"""make_food_label_scan_sodium_nullable

Revision ID: 20260904_nullable_scan_sodium
Revises: 20260706_decimal_servings
Create Date: 2026-09-04 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "20260904_nullable_scan_sodium"
down_revision: Union[str, None] = "20260706_decimal_servings"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Allow an OCR scan with an undetected sodium value to persist as NULL."""
    op.alter_column(
        "food_label_scan",
        "sodium_mg",
        existing_type=sa.Float(),
        nullable=True,
    )


def downgrade() -> None:
    """Restore the previous non-null constraint."""
    op.alter_column(
        "food_label_scan",
        "sodium_mg",
        existing_type=sa.Float(),
        nullable=False,
    )
