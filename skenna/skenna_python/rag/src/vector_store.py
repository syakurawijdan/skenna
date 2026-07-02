"""Shared chunk record structure for SKENNA ChromaDB indexing."""

from __future__ import annotations

from dataclasses import dataclass


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
