"""Semantic retrieval over ChromaDB for SKENNA chatbot RAG."""

from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
import logging
from pathlib import Path

from .chroma_store import ChromaStore
from .embedding import generate_embedding


logger = logging.getLogger(__name__)


@dataclass
class RetrievedChunk:
	text: str
	score: float
	metadata: dict


def retrieve_semantic(
	question: str,
	persist_path: str | Path,
	collection_name: str,
	top_k: int = 12,
	distance_threshold: float = 0.7,
) -> list[RetrievedChunk]:
	store = _get_store(str(Path(persist_path)), collection_name)
	try:
		query_embedding = generate_embedding(question)
		results = store.query(query_embedding, top_k=top_k)
	except Exception as exc:
		logger.warning("RAG retrieval failed, falling back to LLM only: %s", exc)
		return []
	filtered_results = [
		result
		for result in results
		if result.get("text") and float(result.get("distance", float("inf"))) <= distance_threshold
	]
	return [
		RetrievedChunk(
			text=result.get("text", ""),
			score=float(result.get("score", 0.0)),
			metadata=result.get("metadata") or {},
		)
		for result in filtered_results
	]


@lru_cache(maxsize=8)
def _get_store(persist_path: str, collection_name: str) -> ChromaStore:
	return ChromaStore(persist_path, collection_name)


def initialize_semantic_store(persist_path: str | Path, collection_name: str) -> int:
	"""Open and cache the Chroma collection once during app startup."""
	store = _get_store(str(Path(persist_path)), collection_name)
	return store.count()
