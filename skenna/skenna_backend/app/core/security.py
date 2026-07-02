from datetime import datetime, timedelta, timezone
import hashlib
import hmac
import secrets

import bcrypt
from jose import jwt

from app.core.config import settings


def hash_password(password: str) -> str:
	pw_bytes = password.encode("utf-8")[:72]
	hashed = bcrypt.hashpw(pw_bytes, bcrypt.gensalt())
	return hashed.decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
	pw_bytes = plain_password.encode("utf-8")[:72]
	return bcrypt.checkpw(pw_bytes, hashed_password.encode("utf-8"))


def create_access_token(subject: str, expires_minutes: int | None = None) -> str:
	expire_delta = timedelta(minutes=expires_minutes or settings.access_token_expire_minutes)
	now = datetime.now(timezone.utc)
	payload = {"sub": subject, "iat": int(now.timestamp()), "exp": int((now + expire_delta).timestamp())}
	return jwt.encode(payload, settings.secret_key, algorithm="HS256")


def generate_refresh_token() -> str:
	return secrets.token_urlsafe(64)


def hash_refresh_token(raw_token: str) -> str:
	# Refresh tokens are high-entropy random secrets, so a fast SHA-256 hash is
	# appropriate here; unlike passwords, they do not need a slow KDF.
	return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()


def verify_refresh_token_hash(raw_token: str, token_hash: str) -> bool:
	return hmac.compare_digest(hash_refresh_token(raw_token), token_hash)
