"""add_decimal_precision_to_consumed_servings

Revision ID: 20260706_decimal_consumed_servings
Revises: 20260706_decimal_package_serving
Create Date: 2026-07-06 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '20260706_decimal_servings'
down_revision: Union[str, None] = '20260706_decimal_package_serving'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column(
        'intake_history',
        'servings',
        existing_type=sa.Integer(),
        type_=sa.DECIMAL(10, 2),
        existing_nullable=False,
    )


def downgrade() -> None:
    # Downgrading will truncate any decimal servings entered after this upgrade.
    op.alter_column(
        'intake_history',
        'servings',
        existing_type=sa.DECIMAL(10, 2),
        type_=sa.Integer(),
        existing_nullable=False,
    )
