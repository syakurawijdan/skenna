
from alembic import op
import sqlalchemy as sa
from sqlalchemy import text


# revision identifiers, used by Alembic.
revision = '0005'
down_revision = '1782a7c6dcd8'
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Upgrade: Modify user_profiles table structure."""
    conn = op.get_bind()
    existing_columns = {
        row[0]
        for row in conn.execute(
            text(
                "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS "
                "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_profiles'"
            )
        )
    }

    if 'height_cm' in existing_columns:
        op.execute('ALTER TABLE user_profiles DROP COLUMN height_cm')
    if 'weight_kg' in existing_columns:
        op.execute('ALTER TABLE user_profiles DROP COLUMN weight_kg')
    if 'bmi' in existing_columns:
        op.execute('ALTER TABLE user_profiles DROP COLUMN bmi')
    if 'is_pregnant' in existing_columns:
        op.execute('ALTER TABLE user_profiles DROP COLUMN is_pregnant')

    if 'hypertension_condition' not in existing_columns:
        op.execute(
            "ALTER TABLE user_profiles ADD COLUMN hypertension_condition "
            "VARCHAR(50) NULL COMMENT 'Kondisi hipertensi: history_only, controlled, uncontrolled'"
        )
    if 'pregnancy_status' not in existing_columns:
        op.execute(
            "ALTER TABLE user_profiles ADD COLUMN pregnancy_status "
            "VARCHAR(50) NULL COMMENT 'Pregnancy status: pregnant, breastfeeding, none'"
        )


def downgrade() -> None:
    """Downgrade: Revert to previous schema."""
    conn = op.get_bind()
    existing_columns = {
        row[0]
        for row in conn.execute(
            text(
                "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS "
                "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_profiles'"
            )
        )
    }

    if 'height_cm' not in existing_columns:
        op.execute('ALTER TABLE user_profiles ADD COLUMN height_cm FLOAT NULL')
    if 'weight_kg' not in existing_columns:
        op.execute('ALTER TABLE user_profiles ADD COLUMN weight_kg FLOAT NULL')
    if 'bmi' not in existing_columns:
        op.execute('ALTER TABLE user_profiles ADD COLUMN bmi FLOAT NULL')
    if 'is_pregnant' not in existing_columns:
        op.execute('ALTER TABLE user_profiles ADD COLUMN is_pregnant TINYINT(1) DEFAULT 0')

    if 'hypertension_condition' in existing_columns:
        op.execute('ALTER TABLE user_profiles DROP COLUMN hypertension_condition')
    if 'pregnancy_status' in existing_columns:
        op.execute('ALTER TABLE user_profiles DROP COLUMN pregnancy_status')
