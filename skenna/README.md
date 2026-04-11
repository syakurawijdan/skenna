# Skenna Sodium Monitoring

Struktur ini mempertahankan folder bawaan Flutter dan menambahkan modul backend + AI sebagai sibling di root project.

## Struktur Folder

```text
skenna/
├── android/ ios/ web/ windows/ linux/ macos/ lib/   # Flutter app (tetap)
├── backend/                                          # FastAPI + database
├── ml/                                               # Model klasifikasi natrium
├── cv/                                               # Computer Vision + OCR label
├── rag/                                              # LLM + RAG chatbot
├── shared/                                           # Konfigurasi/scheme bersama
├── infra/                                            # Deployment/monitoring scripts
├── docs/                                             # Dokumen arsitektur
├── .env.example
├── docker-compose.yml
└── Makefile
```

## Penjelasan Per Folder dan File Kunci

### Flutter App (existing)
- `lib/main.dart`: entry point aplikasi Flutter.
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`: target platform Flutter.
- `pubspec.yaml`: dependensi Flutter.

### Backend (`backend/`)
- `backend/app/main.py`: entrypoint FastAPI.
- `backend/app/api/v1/router.py`: registrasi router versi API.
- `backend/app/api/v1/sodium.py`: endpoint klasifikasi kadar natrium.
- `backend/app/api/v1/cv.py`: endpoint upload gambar + ekstraksi label makanan.
- `backend/app/api/v1/chatbot.py`: endpoint chatbot LLM + RAG.
- `backend/app/api/v1/history.py`: endpoint riwayat user.
- `backend/app/services/sodium_classifier_service.py`: orkestrasi inferensi model ML.
- `backend/app/services/cv_ocr_service.py`: orkestrasi pipeline OCR/CV.
- `backend/app/services/rag_service.py`: retrieval context dari vector store.
- `backend/app/services/chatbot_service.py`: generate jawaban final chatbot.
- `backend/app/models/*.py`: model ORM (users, intake_history, food_label_scan, chat_session).
- `backend/app/schemas/*.py`: request/response schema (Pydantic).
- `backend/app/repositories/*.py`: layer query database.
- `backend/app/db/session.py`: koneksi dan session database.
- `backend/migrations/`: migrasi skema database (Alembic).
- `backend/tests/`: test API/service.

### ML (`ml/`)
- `ml/src/train.py`: training model klasifikasi batas kadar natrium.
- `ml/src/inference.py`: prediksi kategori natrium untuk dipakai backend.
- `ml/src/label_thresholds.py`: aturan label (mis. rendah/sedang/tinggi).
- `ml/models/`: artefak model dan metadata.
- `ml/pipelines/train_pipeline.py`: pipeline training terstandar.

### Computer Vision (`cv/`)
- `cv/src/preprocess.py`: preprocessing gambar label makanan.
- `cv/src/label_detector.py`: deteksi area nutrition facts.
- `cv/src/ocr_engine.py`: ekstraksi teks OCR.
- `cv/src/nutrition_parser.py`: parsing teks menjadi field nutrisi.
- `cv/src/postprocess.py`: normalisasi unit dan validasi hasil.

### RAG Chatbot (`rag/`)
- `rag/src/chunking.py`: pemotongan dokumen knowledge base.
- `rag/src/embedding.py`: pembuatan embedding dokumen.
- `rag/src/vector_store.py`: simpan/baca index vector.
- `rag/src/retriever.py`: ambil konteks dokumen relevan.
- `rag/src/prompt_builder.py`: rakit prompt berisi context + pertanyaan user.
- `rag/src/llm_client.py`: integrasi provider LLM.
- `rag/src/answer_generator.py`: post-process jawaban chatbot.
- `rag/knowledge_base/`: sumber pengetahuan medis/regulasi/FAQ.
- `rag/scripts/ingest_docs.py`: ingest dokumen ke index.

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

- Struktur Flutter tidak perlu dipindah.
- Integrasi dilakukan lewat HTTP dari Flutter ke FastAPI.
- Riwayat user disimpan melalui model `intake_history`, `food_label_scan`, dan `chat_session`.

## Quick Start (Tinggal Run)

### Opsi A - Local (Laragon MySQL)

1. Install dependency backend:

```bash
cd backend
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
flutter run
```

Screen kerangka mobile yang sudah dibuat:

- `Dashboard` di `lib/presentation/screens/dashboard_screen.dart`
- `Klasifikasi Natrium` di `lib/presentation/screens/classify_screen.dart`
- `Scan Label` di `lib/presentation/screens/scan_screen.dart`
- `Chatbot` di `lib/presentation/screens/chatbot_screen.dart`
- `Riwayat` di `lib/presentation/screens/history_screen.dart`

Shell dan navigasi ada di `lib/presentation/app_shell.dart`, entry app tetap `lib/main.dart`.

## Endpoint Utama Siap Pakai

- `GET /health`
- `POST /api/v1/users/demo`
- `POST /api/v1/sodium/classify`
- `POST /api/v1/cv/scan`
- `POST /api/v1/chatbot/ask`
- `GET /api/v1/history/intake?user_id=1`
- `GET /api/v1/history/chat?user_id=1`
