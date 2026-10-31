#!/usr/bin/env bash
set -e

echo "==> Running Alembic Database Migrations..."
alembic upgrade head

echo "==> Starting Nexa FastAPI Production Server..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
