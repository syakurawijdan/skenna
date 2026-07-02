"""ChromaDB persistent storage for SKENNA RAG chunks."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Iterable

import chromadb

from .vector_store import ChunkRecord


class ChromaStore:
	def __init__(self, persist_path: str | Path, collection_name: str, *, reset: bool = False) -> None:
		self.persist_path = Path(persist_path)
		self.collection_name = collection_name
		self.persist_path.mkdir(parents=True, exist_ok=True)
		self._client = chromadb.PersistentClient(path=str(self.persist_path))
		if reset:
			try:
				self._client.delete_collection(name=collection_name)
			except Exception:
				pass
		self._collection = self._client.get_or_create_collection(name=collection_name)

	@property
	def collection(self):
		return self._collection

	def count(self) -> int:
		return int(self._collection.count())

	def upsert(self, records: Iterable[ChunkRecord], embeddings: Iterable[list[float]]) -> int:
		record_list = list(records)
		embedding_list = list(embeddings)
		if not record_list:
			return 0
		if len(record_list) != len(embedding_list):
			raise ValueError("records and embeddings must have the same length")

		self._collection.upsert(
			ids=[record.chunk_id for record in record_list],
			documents=[record.text for record in record_list],
			embeddings=embedding_list,
			metadatas=[self._metadata(record) for record in record_list],
		)
		return len(record_list)

	def query(self, query_embedding: list[float], top_k: int = 4) -> list[dict[str, Any]]:
		result = self._collection.query(query_embeddings=[query_embedding], n_results=top_k)
		ids = result.get("ids", [[]])[0]
		documents = result.get("documents", [[]])[0]
		metadatas = result.get("metadatas", [[]])[0]
		distances = result.get("distances", [[]])[0]
		return [
			{
				"id": ids[index],
				"text": documents[index],
				"metadata": metadatas[index] or {},
				"distance": float(distances[index] if index < len(distances) else 0.0),
				"score": 1.0 / (1.0 + float(distances[index] if index < len(distances) else 0.0)),
			}
			for index in range(len(ids))
		]

	@staticmethod
	def _metadata(record: ChunkRecord) -> dict[str, Any]:
		metadata = record.metadata or {}
		return {
			"chunk_id": record.chunk_id,
			"document_id": str(metadata.get("id") or record.chunk_id.split(":", 1)[0]),
			"title": str(metadata.get("judul") or record.section_title or record.source_file),
			"topic": record.topic,
			"source": record.source_file,
			"category": str(metadata.get("kategori") or ""),
			"language": record.language or "id",
		}
