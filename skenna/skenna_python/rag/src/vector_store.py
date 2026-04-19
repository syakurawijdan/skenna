"""Lightweight document store for chunk metadata and retrieval.

This module keeps the index format simple and portable:
- `index/docstore.json` stores chunk records as JSON
- retrieval works with token overlap so the chatbot can query the processed chunks
"""

from __future__ import annotations

from dataclasses import dataclass, asdict
import json
import math
import re
from collections import Counter
from pathlib import Path
from typing import Iterable


TOKEN_PATTERN = re.compile(r"[a-z0-9]+", re.IGNORECASE)


@dataclass
class ChunkRecord:
	chunk_id: str
	source_file: str
	source_path: str
	topic: str
	text: str
	start_char: int = 0
	end_char: int = 0
	page: int | None = None
	section_title: str | None = None
	language: str = "en"
	metadata: dict[str, object] | None = None


def tokenize(text: str) -> list[str]:
	"""Tokenize text into lowercase alphanumeric terms."""
	return [token.lower() for token in TOKEN_PATTERN.findall(text)]


def build_term_frequency(tokens: Iterable[str]) -> Counter[str]:
	return Counter(tokens)


def cosine_similarity(left: Counter[str], right: Counter[str]) -> float:
	if not left or not right:
		return 0.0

	common = set(left).intersection(right)
	if not common:
		return 0.0

	dot_product = sum(left[token] * right[token] for token in common)
	left_norm = math.sqrt(sum(value * value for value in left.values()))
	right_norm = math.sqrt(sum(value * value for value in right.values()))
	if left_norm == 0 or right_norm == 0:
		return 0.0
	return dot_product / (left_norm * right_norm)


def load_docstore(docstore_path: str | Path) -> list[ChunkRecord]:
	"""Load chunk records from the JSON docstore."""
	path = Path(docstore_path)
	if not path.exists():
		return []
	with path.open("r", encoding="utf-8") as handle:
		payload = json.load(handle)
	return [ChunkRecord(**item) for item in payload]


def save_docstore(records: Iterable[ChunkRecord], docstore_path: str | Path) -> None:
	"""Persist chunk records to JSON."""
	path = Path(docstore_path)
	path.parent.mkdir(parents=True, exist_ok=True)
	with path.open("w", encoding="utf-8") as handle:
		json.dump([asdict(record) for record in records], handle, ensure_ascii=False, indent=2)


def search_chunks(query: str, records: list[ChunkRecord], top_k: int = 5) -> list[tuple[ChunkRecord, float]]:
	"""Return the top matching chunks using cosine similarity on token frequencies."""
	query_vector = build_term_frequency(tokenize(query))
	scored_records: list[tuple[ChunkRecord, float]] = []

	for record in records:
		searchable_parts = [
			record.text,
			record.topic,
			record.section_title or "",
		]
		record_vector = build_term_frequency(tokenize(" ".join(searchable_parts)))
		score = cosine_similarity(query_vector, record_vector)
		if score > 0:
			scored_records.append((record, score))

	scored_records.sort(key=lambda item: item[1], reverse=True)
	return scored_records[:top_k]
