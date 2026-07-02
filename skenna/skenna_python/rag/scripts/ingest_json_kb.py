"""Ingest a curated JSON knowledge base into processed text and chunk JSONL outputs.

Usage example:

	python scripts/ingest_json_kb.py --source-json C:\\Users\\USER\\Downloads\\hipertensi_jurnal.json

The script reads a JSON file that contains a top-level ``dokumen`` array and
writes normalized outputs to:

- ``processed_text/<topic>/``: one JSON file per document with combined text
- ``chunks/<topic>/``: one JSONL file per document with retrieval-ready chunks

This lets the curated JSON become the primary knowledge base for ChromaDB indexing.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
import sys


ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
	sys.path.insert(0, str(ROOT_DIR))

from src.chunking import normalize_text, split_into_chunks


PROCESSED_DIR = ROOT_DIR / "processed_text"
CHUNKS_DIR = ROOT_DIR / "chunks"
KNOWLEDGE_BASE_DIR = ROOT_DIR / "knowledge_base"


def safe_slug(value: str, fallback: str = "document") -> str:
	"""Convert text into a filesystem-safe slug."""
	text = value.strip().lower()
	chars: list[str] = []
	previous_underscore = False
	for character in text:
		if character.isalnum():
			chars.append(character)
			previous_underscore = False
		elif not previous_underscore:
			chars.append("_")
			previous_underscore = True
	slug = "".join(chars).strip("_")
	return slug or fallback


def build_document_text(document: dict[str, Any]) -> str:
	"""Build a retrieval-friendly text block from one JSON document."""
	parts: list[str] = []

	def add_section(label: str, value: Any) -> None:
		if value is None:
			return
		if isinstance(value, str):
			cleaned = value.strip()
		elif isinstance(value, list):
			cleaned_items = [str(item).strip() for item in value if str(item).strip()]
			cleaned = "\n".join(f"- {item}" for item in cleaned_items)
		else:
			cleaned = str(value).strip()
		if cleaned:
			parts.append(f"{label}:\n{cleaned}")

	add_section("ID", document.get("id"))
	add_section("Judul", document.get("judul"))
	add_section("Kategori", document.get("kategori"))
	add_section("Tahun", document.get("tahun"))
	add_section("Tipe", document.get("tipe"))
	add_section("Penulis", document.get("penulis"))
	add_section("Ringkasan", document.get("ringkasan"))
	add_section("Abstrak ringkas", document.get("abstrak_ringkas"))
	add_section("Metodologi", document.get("metodologi"))
	add_section("Temuan utama", document.get("temuan_utama"))
	add_section("Kesimpulan", document.get("kesimpulan"))
	add_section("Keywords", document.get("keywords"))
	add_section("Poin kunci", document.get("poin_kunci"))
	add_section("Relevansi RAG", document.get("relevansi_rag"))

	return normalize_text("\n\n".join(parts))


def ensure_output_dirs(topic: str) -> tuple[Path, Path, Path]:
	"""Create knowledge base, processed text, and chunk folders for a topic."""
	knowledge_topic_dir = KNOWLEDGE_BASE_DIR / topic
	processed_topic_dir = PROCESSED_DIR / topic
	chunks_topic_dir = CHUNKS_DIR / topic
	knowledge_topic_dir.mkdir(parents=True, exist_ok=True)
	processed_topic_dir.mkdir(parents=True, exist_ok=True)
	chunks_topic_dir.mkdir(parents=True, exist_ok=True)
	return knowledge_topic_dir, processed_topic_dir, chunks_topic_dir


def clear_topic_outputs(processed_dir: Path, chunks_dir: Path) -> None:
	"""Remove previously generated outputs for a topic before writing fresh JSON data."""
	for file_path in processed_dir.glob("*.json"):
		file_path.unlink(missing_ok=True)
	for file_path in chunks_dir.glob("*.jsonl"):
		file_path.unlink(missing_ok=True)


def load_json_documents(source_json: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
	"""Load and validate the curated JSON knowledge base file."""
	with source_json.open("r", encoding="utf-8") as handle:
		payload = json.load(handle)

	if not isinstance(payload, dict):
		raise ValueError("Top-level JSON must be an object with metadata and dokumen fields")

	documents = payload.get("dokumen", [])
	if not isinstance(documents, list):
		raise ValueError("The dokumen field must be an array")

	return payload, [doc for doc in documents if isinstance(doc, dict)]


def write_processed_document(
	output_dir: Path,
	document: dict[str, Any],
	combined_text: str,
	source_json: Path,
	index: int,
) -> Path:
	"""Persist the normalized document as JSON for inspection or debug tracing."""
	document_id = str(document.get("id") or f"doc_{index:03d}")
	output_path = output_dir / f"{safe_slug(document_id)}.json"
	payload = {
		"metadata": {
			"source_json": str(source_json),
			"extracted_at": datetime.now(timezone.utc).isoformat(),
		},
		"document": document,
		"text": combined_text,
	}
	with output_path.open("w", encoding="utf-8") as handle:
		json.dump(payload, handle, ensure_ascii=False, indent=2)
	return output_path


def write_chunks_file(
	output_dir: Path,
	document: dict[str, Any],
	combined_text: str,
	source_json: Path,
	topic: str,
	max_chars: int,
	overlap: int,
	index: int,
) -> Path:
	"""Write retrieval chunks for one document as JSONL."""
	document_id = str(document.get("id") or f"doc_{index:03d}")
	document_slug = safe_slug(document_id)
	chunk_list = split_into_chunks(combined_text, max_chars=max_chars, overlap=overlap)
	output_path = output_dir / f"{document_slug}.jsonl"
	with output_path.open("w", encoding="utf-8") as handle:
		for chunk in chunk_list:
			payload = {
				"chunk_id": f"{document_slug}:{chunk.chunk_id}",
				"source_file": source_json.name,
				"source_path": str(source_json),
				"document_id": document_id,
				"document_title": document.get("judul", ""),
				"document_category": document.get("kategori", ""),
				"topic": topic,
				"text": chunk.text,
				"start_char": chunk.start_char,
				"end_char": chunk.end_char,
				"page": None,
				"section_title": None,
				"language": document.get("bahasa", "id"),
				"metadata": {
					"id": document.get("id"),
					"tipe": document.get("tipe"),
					"tahun": document.get("tahun"),
					"kategori": document.get("kategori"),
					"judul": document.get("judul"),
					"penulis": document.get("penulis"),
					"keywords": document.get("keywords", []),
					"poin_kunci": document.get("poin_kunci", []),
					"relevansi_rag": document.get("relevansi_rag", []),
				},
			}
			handle.write(json.dumps(payload, ensure_ascii=False) + "\n")
	return output_path


def main() -> int:
	parser = argparse.ArgumentParser(description="Ingest a curated JSON knowledge base for RAG.")
	parser.add_argument(
		"--source-json",
		required=True,
		help="Path to the curated JSON knowledge base file",
	)
	parser.add_argument("--topic", default="hipertensi", help="Topic folder under knowledge_base/, chunks/, and processed_text/")
	parser.add_argument("--max-chars", type=int, default=1800, help="Maximum characters per chunk")
	parser.add_argument("--overlap", type=int, default=250, help="Character overlap between chunks")
	parser.add_argument(
		"--preserve-existing",
		action="store_true",
		help="Keep existing processed_text and chunks files for the topic instead of clearing them first",
	)
	args = parser.parse_args()

	source_json = Path(args.source_json).expanduser().resolve()
	if not source_json.exists():
		raise SystemExit(f"Source JSON not found: {source_json}")

	_, processed_dir, chunks_dir = ensure_output_dirs(args.topic)
	knowledge_topic_dir = KNOWLEDGE_BASE_DIR / args.topic
	if not args.preserve_existing:
		clear_topic_outputs(processed_dir, chunks_dir)

	metadata, documents = load_json_documents(source_json)
	if not documents:
		print(f"No documents found in {source_json}")
		return 0

	# Keep a normalized copy of the source knowledge base alongside the raw file.
	normalized_copy = knowledge_topic_dir / source_json.name
	with normalized_copy.open("w", encoding="utf-8") as handle:
		json.dump(metadata, handle, ensure_ascii=False, indent=2)

	print(f"Processing {len(documents)} document(s) from {source_json}")
	print(f"Normalized copy -> {normalized_copy.relative_to(ROOT_DIR)}")

	for index, document in enumerate(documents, start=1):
		document_id = str(document.get("id") or f"doc_{index:03d}")
		combined_text = build_document_text(document)
		processed_path = write_processed_document(processed_dir, document, combined_text, source_json, index)
		chunk_path = write_chunks_file(
			chunks_dir,
			document,
			combined_text,
			source_json,
			args.topic,
			args.max_chars,
			args.overlap,
			index,
		)
		print(f"- {document_id}: processed -> {processed_path.relative_to(ROOT_DIR)}")
		print(f"  {document_id}: chunks    -> {chunk_path.relative_to(ROOT_DIR)}")

	return 0


if __name__ == "__main__":
	raise SystemExit(main())
