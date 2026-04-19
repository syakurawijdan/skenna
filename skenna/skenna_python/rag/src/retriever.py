"""Simple retrieval over the docstore JSON."""

from __future__ import annotations

from pathlib import Path

from .vector_store import ChunkRecord, load_docstore, search_chunks


def retrieve(question: str, docstore_path: str | Path, top_k: int = 5) -> list[tuple[ChunkRecord, float]]:
	"""Find the most relevant chunks for the question."""
	records = load_docstore(docstore_path)
	if not records:
		return []
	return search_chunks(question, records, top_k=top_k)
