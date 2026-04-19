"""Rebuild the RAG docstore from chunk JSONL files.

The script reads every `chunks/<topic>/*.jsonl` file and writes a consolidated
`index/docstore.json` that the retriever can query.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any
import sys


ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
	sys.path.insert(0, str(ROOT_DIR))

from src.vector_store import ChunkRecord, save_docstore


CHUNKS_DIR = ROOT_DIR / "chunks"
INDEX_DIR = ROOT_DIR / "index"


def load_chunk_records(topic: str) -> list[ChunkRecord]:
	"""Load chunk JSONL files for one topic."""
	topic_dir = CHUNKS_DIR / topic
	if not topic_dir.exists():
		return []

	records: list[ChunkRecord] = []
	for jsonl_path in sorted(topic_dir.glob("*.jsonl")):
		with jsonl_path.open("r", encoding="utf-8") as handle:
			for line_number, line in enumerate(handle, start=1):
				line = line.strip()
				if not line:
					continue
				payload: dict[str, Any] = json.loads(line)
				records.append(
					ChunkRecord(
						chunk_id=f"{jsonl_path.stem}:{payload.get('chunk_id', line_number)}",
						source_file=payload.get("source_file", jsonl_path.stem),
						source_path=payload.get("source_path", ""),
						topic=payload.get("topic", topic),
						text=payload.get("text", ""),
						start_char=int(payload.get("start_char", 0)),
						end_char=int(payload.get("end_char", 0)),
						page=payload.get("page"),
						section_title=payload.get("section_title"),
						language=payload.get("language", "en"),
						metadata=payload.get("metadata"),
					)
				)
	return records


def main() -> int:
	parser = argparse.ArgumentParser(description="Rebuild the JSON docstore from chunk files.")
	parser.add_argument("--topic", default="hipertensi", help="Topic folder under chunks/")
	args = parser.parse_args()

	records = load_chunk_records(args.topic)
	if not records:
		print(f"No chunk files found in {CHUNKS_DIR / args.topic}")
		return 0

	INDEX_DIR.mkdir(parents=True, exist_ok=True)
	docstore_path = INDEX_DIR / "docstore.json"
	save_docstore(records, docstore_path)
	print(f"Saved {len(records)} chunk record(s) to {docstore_path.relative_to(ROOT_DIR)}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
