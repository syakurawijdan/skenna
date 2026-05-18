
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '0005'
down_revision = '0004'
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Upgrade: Modify user_profiles table structure."""
    # Drop old columns if they exist
    op.execute('ALTER TABLE user_profiles DROP COLUMN IF EXISTS height_cm')
    op.execute('ALTER TABLE user_profiles DROP COLUMN IF EXISTS weight_kg')
    op.execute('ALTER TABLE user_profiles DROP COLUMN IF EXISTS bmi')
    op.execute('ALTER TABLE user_profiles DROP COLUMN IF EXISTS is_pregnant')
    
    # Add new columns if they don't exist
    op.execute('''
        ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS hypertension_condition 
        VARCHAR(50) NULL COMMENT 'Kondisi hipertensi: history_only, controlled, uncontrolled'
    ''')
    op.execute('''
        ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS pregnancy_status 
        VARCHAR(50) NULL COMMENT 'Pregnancy status: pregnant, breastfeeding, none'
    ''')


def downgrade() -> None:
    """Downgrade: Revert to previous schema."""
    # Re-add old columns
    op.execute('ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS height_cm FLOAT NULL')
    op.execute('ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS weight_kg FLOAT NULL')
    op.execute('ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS bmi FLOAT NULL')
    op.execute('ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS is_pregnant TINYINT(1) DEFAULT 0')
    
    # Drop new columns
    op.execute('ALTER TABLE user_profiles DROP COLUMN IF EXISTS hypertension_condition')
    op.execute('ALTER TABLE user_profiles DROP COLUMN IF EXISTS pregnancy_status')
