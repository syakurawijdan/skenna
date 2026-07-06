"""add_decimal_precision_to_package_serving_fields

Revision ID: 20260706_decimal_package_serving
Revises: 11a287c642eb
Create Date: 2026-07-06 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '20260706_decimal_package_serving'
down_revision: Union[str, None] = '11a287c642eb'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column(
        'food_label_scan',
        'takaran_saji',
        existing_type=sa.Integer(),
        type_=sa.DECIMAL(10, 2),
        existing_nullable=True,
    )
    op.alter_column(
        'food_label_scan',
        'sajian_per_kemasan',
        existing_type=sa.Integer(),
        type_=sa.DECIMAL(10, 2),
        existing_nullable=True,
    )
    op.alter_column(
        'intake_history',
        'package_ml',
        existing_type=sa.Integer(),
        type_=sa.DECIMAL(10, 2),
        existing_nullable=True,
    )
    op.alter_column(
        'intake_history',
        'portions_in_package',
        existing_type=sa.Integer(),
        type_=sa.DECIMAL(10, 2),
        existing_nullable=True,
    )
    op.alter_column(
        'intake_history',
        'package_ml2',
        existing_type=sa.Integer(),
        type_=sa.DECIMAL(10, 2),
        existing_nullable=True,
    )
    op.alter_column(
        'intake_history',
        'portions_in_package2',
        existing_type=sa.Integer(),
        type_=sa.DECIMAL(10, 2),
        existing_nullable=True,
    )


def downgrade() -> None:
    # Downgrading will truncate any decimal data entered after this upgrade.
    op.alter_column(
        'intake_history',
        'portions_in_package2',
        existing_type=sa.DECIMAL(10, 2),
        type_=sa.Integer(),
        existing_nullable=True,
    )
    op.alter_column(
        'intake_history',
        'package_ml2',
        existing_type=sa.DECIMAL(10, 2),
        type_=sa.Integer(),
        existing_nullable=True,
    )
    op.alter_column(
        'intake_history',
        'portions_in_package',
        existing_type=sa.DECIMAL(10, 2),
        type_=sa.Integer(),
        existing_nullable=True,
    )
    op.alter_column(
        'intake_history',
        'package_ml',
        existing_type=sa.DECIMAL(10, 2),
        type_=sa.Integer(),
        existing_nullable=True,
    )
    op.alter_column(
        'food_label_scan',
        'sajian_per_kemasan',
        existing_type=sa.DECIMAL(10, 2),
        type_=sa.Integer(),
        existing_nullable=True,
    )
    op.alter_column(
        'food_label_scan',
        'takaran_saji',
        existing_type=sa.DECIMAL(10, 2),
        type_=sa.Integer(),
        existing_nullable=True,
    )
