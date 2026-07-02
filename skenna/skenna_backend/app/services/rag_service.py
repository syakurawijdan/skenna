from pathlib import Path
import sys

BACKEND_ROOT = Path(__file__).resolve().parents[2]
if str(BACKEND_ROOT) not in sys.path:
	sys.path.insert(0, str(BACKEND_ROOT))

from app.core.config import settings

REPO_ROOT = Path(__file__).resolve().parents[3]
if str(REPO_ROOT) not in sys.path:
	sys.path.insert(0, str(REPO_ROOT))

from skenna_python.rag.src.semantic_retriever import initialize_semantic_store, retrieve_semantic


class RAGService:
	@staticmethod
	def initialize() -> int:
		return initialize_semantic_store(
			settings.chroma_db_path,
			settings.chroma_collection_name,
		)

	@staticmethod
	def retrieve_context(question: str) -> tuple[str, list[dict[str, str]]]:
		semantic_chunks = retrieve_semantic(
			question,
			settings.chroma_db_path,
			settings.chroma_collection_name,
			top_k=settings.rag_top_k,
			distance_threshold=settings.rag_distance_threshold,
		)
		if not semantic_chunks:
			return "", []

		context_parts = []
		sources: list[dict[str, str]] = []
		seen_source_keys: set[tuple[str, str]] = set()
		for chunk in semantic_chunks:
			metadata = chunk.metadata
			context_parts.append(f"[SKOR {chunk.score:.3f}] {chunk.text[:900]}")
			source = {
				"title": str(metadata.get("title") or metadata.get("source") or "Sumber RAG"),
				"topic": str(metadata.get("topic") or "hipertensi"),
				"document_id": str(metadata.get("document_id") or metadata.get("chunk_id") or ""),
			}
			source_key = (source["title"], source["document_id"])
			if source_key not in seen_source_keys:
				seen_source_keys.add(source_key)
				sources.append(source)
		return "\n\n".join(context_parts), sources
