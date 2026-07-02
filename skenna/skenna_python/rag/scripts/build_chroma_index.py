"""Build the ChromaDB semantic index from JSONL chunks."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
import time


ROOT_DIR = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT_DIR.parents[1]
BACKEND_ROOT = REPO_ROOT / "skenna_backend"
if str(ROOT_DIR) not in sys.path:
	sys.path.insert(0, str(ROOT_DIR))
if str(REPO_ROOT) not in sys.path:
	sys.path.insert(0, str(REPO_ROOT))
if str(BACKEND_ROOT) not in sys.path:
	sys.path.insert(0, str(BACKEND_ROOT))

from src.chroma_store import ChromaStore
from src.embedding import generate_embeddings
from src.vector_store import ChunkRecord


CHUNKS_DIR = ROOT_DIR / "chunks"


def load_chunk_records(topic: str) -> list[ChunkRecord]:
	topic_dir = CHUNKS_DIR / topic
	records: list[ChunkRecord] = []
	if not topic_dir.exists():
		return records
	for file_path in sorted(topic_dir.glob("*.jsonl")):
		with file_path.open("r", encoding="utf-8") as handle:
			for line in handle:
				if not line.strip():
					continue
				payload = json.loads(line)
				records.append(
					ChunkRecord(
						chunk_id=str(payload["chunk_id"]),
						source_file=str(payload["source_file"]),
						source_path=str(payload["source_path"]),
						topic=str(payload["topic"]),
						text=str(payload["text"]),
						start_char=int(payload.get("start_char") or 0),
						end_char=int(payload.get("end_char") or 0),
						page=payload.get("page"),
						section_title=payload.get("section_title"),
						language=str(payload.get("language") or "id"),
						metadata=payload.get("metadata") or {},
					)
				)
	return records


def retry_delay_seconds(error_message: str, default_seconds: float = 60.0) -> float:
	match = re.search(r'"retryDelay"\s*:\s*"(\d+(?:\.\d+)?)s"', error_message)
	if match:
		return float(match.group(1))
	match = re.search(r"\b(\d+(?:\.\d+)?)\s*s\b", error_message)
	if match:
		return float(match.group(1))
	return default_seconds


def main() -> int:
	parser = argparse.ArgumentParser(description="Build ChromaDB index from SKENNA RAG chunks.")
	parser.add_argument("--topic", default="hipertensi", help="Topic folder under chunks/")
	parser.add_argument("--persist-path", default=str(ROOT_DIR / "chroma"), help="ChromaDB persistent path")
	parser.add_argument("--collection", default="hypertension_knowledge", help="ChromaDB collection name")
	parser.add_argument("--reset", action="store_true", help="Delete and recreate the collection before indexing")
	parser.add_argument(
		"--resume",
		action="store_true",
		help="Deprecated: kept for compatibility. The script now upserts every chunk idempotently.",
	)
	parser.add_argument("--batch-size", type=int, default=50, help="Chunks to embed and upsert per batch")
	parser.add_argument("--sleep-seconds", type=float, default=35.0, help="Delay between batches to respect Gemini quotas")
	args = parser.parse_args()

	records = load_chunk_records(args.topic)
	if not records:
		print(f"No chunk files found for topic: {args.topic}")
		return 0

	store = ChromaStore(args.persist_path, args.collection, reset=args.reset)
	count = 0
	if args.resume and not args.reset:
		print("--resume is ignored because count-based resume can skip missing chunks after partial indexing.")
		print("Re-upserting every chunk idempotently to guarantee complete coverage.")
	for start in range(0, len(records), args.batch_size):
		batch = records[start : start + args.batch_size]
		print(f"Embedding chunks {start + 1}-{start + len(batch)} of {len(records)}")
		while True:
			try:
				embeddings = generate_embeddings([record.text for record in batch])
				break
			except RuntimeError as exc:
				message = str(exc)
				if "429" not in message:
					raise
				delay_seconds = retry_delay_seconds(message)
				print(f"Rate limit hit. Waiting {delay_seconds:g}s before retrying...")
				time.sleep(delay_seconds)
		count += store.upsert(batch, embeddings)
		if start + len(batch) < len(records):
			time.sleep(0.5)
			time.sleep(args.sleep_seconds)
	final_count = store.count()
	print(f"Processed {len(records)} chunk record(s).")
	print(f"Upserted {count} Gemini embedding(s) to ChromaDB: {args.persist_path}")
	print(f"Total items successfully indexed in collection '{args.collection}': {final_count}")
	if final_count < len(records):
		print(
			f"Warning: collection contains {final_count} item(s), "
			f"but {len(records)} chunk record(s) were loaded."
		)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
