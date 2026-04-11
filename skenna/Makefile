run-backend:
	cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

test-backend:
	cd backend && pytest -q

docker-up:
	docker compose up --build

docker-down:
	docker compose down

