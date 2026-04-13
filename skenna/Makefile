API_BASE_URL ?= http://127.0.0.1:8000

run-frontend:
	cd frontend && flutter run --dart-define=API_BASE_URL=$(API_BASE_URL)

run-backend:
	cd skenna_backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

run-all:
	powershell -ExecutionPolicy Bypass -File run-all.ps1 -ApiBaseUrl $(API_BASE_URL)

test-frontend:
	cd frontend && flutter test

test-backend:
	cd skenna_backend && pytest -q

docker-up:
	docker compose up --build

docker-down:
	docker compose down

