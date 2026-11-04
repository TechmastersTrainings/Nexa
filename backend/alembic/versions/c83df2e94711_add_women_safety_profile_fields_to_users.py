"""add women safety profile fields to users

Revision ID: c83df2e94711
Revises: b76edf0d357f
Create Date: 2026-11-01 02:28:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c83df2e94711'
down_revision: Union[str, None] = 'b76edf0d357f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('emergency_contact_name', sa.String(length=100), nullable=True))
    op.add_column('users', sa.Column('emergency_contact_phone', sa.String(length=20), nullable=True))
    op.add_column('users', sa.Column('emergency_contact_relation', sa.String(length=50), nullable=True))
    op.add_column('users', sa.Column('home_address', sa.String(length=255), nullable=True))
    op.add_column('users', sa.Column('city_police_jurisdiction', sa.String(length=100), nullable=True))
    op.add_column('users', sa.Column('preferred_police_helpline', sa.String(length=20), server_default='112', nullable=False))
    op.add_column('users', sa.Column('blood_group', sa.String(length=10), nullable=True))
    op.add_column('users', sa.Column('medical_notes', sa.String(length=255), nullable=True))
    op.add_column('users', sa.Column('age', sa.Integer(), nullable=True))
    op.add_column('users', sa.Column('police_dispatch_consent', sa.Boolean(), server_default=sa.text('true'), nullable=False))


def downgrade() -> None:
    op.drop_column('users', 'police_dispatch_consent')
    op.drop_column('users', 'age')
    op.drop_column('users', 'medical_notes')
    op.drop_column('users', 'blood_group')
    op.drop_column('users', 'preferred_police_helpline')
    op.drop_column('users', 'city_police_jurisdiction')
    op.drop_column('users', 'home_address')
    op.drop_column('users', 'emergency_contact_relation')
    op.drop_column('users', 'emergency_contact_phone')
    op.drop_column('users', 'emergency_contact_name')

