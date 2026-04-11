# Architecture Overview

## Runtime Components

- Flutter frontend: UI client only.
- FastAPI backend: API gateway + business logic.
- PostgreSQL/SQLite: persistence for user and history.
- ML module: sodium classifier training/inference code.
- CV module: OCR and nutrition label parsing pipeline.
- RAG module: retrieval + answer generation pipeline.

## Request Flow

1. Flutter calls FastAPI endpoint.
2. Backend validates payload via Pydantic schema.
3. Backend executes service logic (ML/CV/RAG stub or real engine).
4. Backend stores history to database.
5. Backend returns normalized response to frontend.

