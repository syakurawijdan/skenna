"""Gemini embedding helpers for SKENNA RAG."""

from __future__ import annotations

from functools import lru_cache


def generate_embedding(text: str) -> list[float]:
	"""Generate a real Gemini embedding and fail loudly on any error."""
	return list(_cached_embedding(_cache_key(text)))


def _cache_key(text: str) -> str:
	return " ".join(text.strip().lower().split())


@lru_cache(maxsize=512)
def _cached_embedding(text: str) -> tuple[float, ...]:
	from app.services.gemini_service import GeminiService

	if not GeminiService.is_configured():
		raise RuntimeError("GEMINI_API_KEY is required for embedding generation")
	return tuple(GeminiService.generate_embedding(text))


def generate_embeddings(texts: list[str]) -> list[list[float]]:
	"""Generate real Gemini embeddings in batch and fail loudly on any error."""
	from app.services.gemini_service import GeminiService

	if not GeminiService.is_configured():
		raise RuntimeError("GEMINI_API_KEY is required for embedding generation")
	return GeminiService.generate_embeddings(texts)
