from pathlib import Path
import sys

BACKEND_ROOT = Path(__file__).resolve().parents[2]
if str(BACKEND_ROOT) not in sys.path:
	sys.path.insert(0, str(BACKEND_ROOT))

from app.core.config import settings

REPO_ROOT = Path(__file__).resolve().parents[3]
if str(REPO_ROOT) not in sys.path:
	sys.path.insert(0, str(REPO_ROOT))

from skenna_python.rag.src.retriever import retrieve


class RAGService:
	@staticmethod
	def retrieve_context(question: str) -> tuple[str, list[str]]:
		docstore_path = Path(settings.vector_db_path) / "docstore.json"
		ranked_chunks = retrieve(question, docstore_path, top_k=20)
		if not ranked_chunks:
			return (
				"Belum ada konteks yang cocok dari index hipertensi. Coba tambahkan jurnal atau ubah pertanyaan.",
				[],
			)

		selected_chunks = []
		seen_sources: set[str] = set()

		# First pass: pick one best chunk from as many distinct sources as possible.
		for record, score in ranked_chunks:
			if record.source_file in seen_sources:
				continue
			selected_chunks.append((record, score))
			seen_sources.add(record.source_file)
			if len(selected_chunks) >= 4:
				break

		# Second pass: fill remaining slots if not enough sources are available.
		if len(selected_chunks) < 4:
			for record, score in ranked_chunks:
				if (record, score) in selected_chunks:
					continue
				selected_chunks.append((record, score))
				if len(selected_chunks) >= 4:
					break

		context_parts = []
		sources: list[str] = []
		seen_sources.clear()
		for record, score in selected_chunks:
			context_parts.append(f"[SKOR {score:.3f}] {record.text[:800]}")
			if record.source_file not in seen_sources:
				seen_sources.add(record.source_file)
				sources.append(record.source_file)

		context = "\n\n".join(context_parts)
		return context, sources

