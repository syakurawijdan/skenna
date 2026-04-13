# Skenna Sodium Monitoring

Struktur repository dipisah menjadi tiga area utama: frontend, backend, dan python.

## Struktur Folder

```text
skenna/
├── frontend/                                         # Flutter app
├── skenna_backend/                                   # FastAPI + database
├── skenna_python/                                    # Modul CV/ML/RAG
├── shared/                                           # Konfigurasi/scheme bersama
├── infra/                                            # Deployment/monitoring scripts
├── docs/                                             # Dokumen arsitektur
├── .env.example
├── docker-compose.yml
└── Makefile
```

## Penjelasan Per Folder dan File Kunci

### Frontend (`frontend/`)
- `frontend/lib/main.dart`: entry point aplikasi Flutter.
- `frontend/android/`, `frontend/ios/`, `frontend/web/`, `frontend/windows/`, `frontend/linux/`, `frontend/macos/`: target platform Flutter.
- `frontend/pubspec.yaml`: dependensi Flutter.

### Backend (`skenna_backend/`)
- `skenna_backend/app/main.py`: entrypoint FastAPI.
- `skenna_backend/app/api/v1/router.py`: registrasi router versi API.
- `skenna_backend/app/api/v1/sodium.py`: endpoint klasifikasi kadar natrium.
- `skenna_backend/app/api/v1/cv.py`: endpoint upload gambar + ekstraksi label makanan.
- `skenna_backend/app/api/v1/chatbot.py`: endpoint chatbot LLM + RAG.
- `skenna_backend/app/api/v1/history.py`: endpoint riwayat user.
- `skenna_backend/app/services/sodium_classifier_service.py`: orkestrasi inferensi model ML.
- `skenna_backend/app/services/cv_ocr_service.py`: orkestrasi pipeline OCR/CV.
- `skenna_backend/app/services/rag_service.py`: retrieval context dari vector store.
- `skenna_backend/app/services/chatbot_service.py`: generate jawaban final chatbot.
- `skenna_backend/app/models/*.py`: model ORM (users, intake_history, food_label_scan, chat_session).
- `skenna_backend/app/schemas/*.py`: request/response schema (Pydantic).
- `skenna_backend/app/repositories/*.py`: layer query database.
- `skenna_backend/app/db/session.py`: koneksi dan session database.
- `skenna_backend/migrations/`: migrasi skema database (Alembic).
- `skenna_backend/tests/`: test API/service.

### Python (`skenna_python/`)
- `skenna_python/ml/src/train.py`: training model klasifikasi batas kadar natrium.
- `skenna_python/ml/src/inference.py`: prediksi kategori natrium untuk dipakai backend.
- `skenna_python/ml/src/label_thresholds.py`: aturan label (mis. rendah/sedang/tinggi).
- `skenna_python/ml/models/`: artefak model dan metadata.
- `skenna_python/ml/pipelines/train_pipeline.py`: pipeline training terstandar.

### Computer Vision (`skenna_python/cv/`)
- `skenna_python/cv/src/preprocess.py`: preprocessing gambar label makanan.
- `skenna_python/cv/src/label_detector.py`: deteksi area nutrition facts.
- `skenna_python/cv/src/ocr_engine.py`: ekstraksi teks OCR.
- `skenna_python/cv/src/nutrition_parser.py`: parsing teks menjadi field nutrisi.
- `skenna_python/cv/src/postprocess.py`: normalisasi unit dan validasi hasil.

### RAG Chatbot (`skenna_python/rag/`)
- `skenna_python/rag/src/chunking.py`: pemotongan dokumen knowledge base.
- `skenna_python/rag/src/embedding.py`: pembuatan embedding dokumen.
- `skenna_python/rag/src/vector_store.py`: simpan/baca index vector.
- `skenna_python/rag/src/retriever.py`: ambil konteks dokumen relevan.
- `skenna_python/rag/src/prompt_builder.py`: rakit prompt berisi context + pertanyaan user.
- `skenna_python/rag/src/llm_client.py`: integrasi provider LLM.
- `skenna_python/rag/src/answer_generator.py`: post-process jawaban chatbot.
- `skenna_python/rag/knowledge_base/`: sumber pengetahuan medis/regulasi/FAQ.
- `skenna_python/rag/scripts/ingest_docs.py`: ingest dokumen ke index.

### Shared (`shared/`)
- `shared/schemas/sodium_levels.json`: standar level natrium.
- `shared/schemas/nutrition_fields.json`: daftar field nutrisi hasil parsing OCR.
- `shared/constants/app_constants.py`: konstanta lintas modul.
- `shared/prompts/system_prompt.txt`: prompt sistem chatbot.
- `shared/prompts/safety_prompt.txt`: guardrail prompt.

### Infra (`infra/`)
- `infra/nginx/default.conf`: reverse proxy config.
- `infra/monitoring/prometheus.yml`: monitoring metrics.
- `infra/scripts/init_db.sh`: inisialisasi database.
- `infra/scripts/run_dev.sh`: helper menjalankan service lokal.
- `infra/scripts/backup_db.sh`: backup database.

### Docs (`docs/`)
- `docs/architecture.md`: gambaran arsitektur end-to-end.
- `docs/api-spec.md`: kontrak endpoint API.
- `docs/ml-pipeline.md`: alur training dan evaluasi model.
- `docs/rag-design.md`: desain retrieval + prompting.

## Catatan Implementasi

- Frontend ke backend tersambung melalui env `API_BASE_URL` (dart-define).
- Backend membaca konfigurasi dari `.env` (misalnya `DATABASE_URL`, `VECTOR_DB_PATH`).
- Riwayat user disimpan melalui model `intake_history`, `food_label_scan`, dan `chat_session`.

## Quick Start (Tinggal Run)

### Opsi A - Local (Laragon MySQL)

1. Install dependency backend:

```bash
cd skenna_backend
pip install -r requirements.txt
```

2. Pastikan MySQL Laragon aktif. Database `skenna` akan dibuat otomatis saat startup API.

3. Jalankan API:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

4. Cek API docs:

- `http://127.0.0.1:8000/docs`

### Opsi B - Docker (MySQL)

```bash
docker compose up --build
```

### Menjalankan Mobile App

```bash
cd frontend
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Alternatif via `Makefile` (menggunakan env):

```bash
API_BASE_URL=http://127.0.0.1:8000 make run-frontend
```

Kalau mau sekali jalan untuk backend + frontend:

```bash
powershell -ExecutionPolicy Bypass -File run-all.ps1
```

Atau:

```bash
API_BASE_URL=http://127.0.0.1:8000 make run-all
```

Screen kerangka mobile yang sudah dibuat:

- `Dashboard` di `frontend/lib/presentation/screens/dashboard_screen.dart`
- `Klasifikasi Natrium` di `frontend/lib/presentation/screens/classify_screen.dart`
- `Scan Label` di `frontend/lib/presentation/screens/scan_screen.dart`
- `Chatbot` di `frontend/lib/presentation/screens/chatbot_screen.dart`
- `Riwayat` di `frontend/lib/presentation/screens/history_screen.dart`

Shell dan navigasi ada di `frontend/lib/presentation/app_shell.dart`, entry app tetap `frontend/lib/main.dart`.

## Endpoint Utama Siap Pakai

- `GET /health`
- `POST /api/v1/users/demo`
- `POST /api/v1/sodium/classify`
- `POST /api/v1/cv/scan`
- `POST /api/v1/chatbot/ask`
- `GET /api/v1/history/intake?user_id=1`
- `GET /api/v1/history/chat?user_id=1`
