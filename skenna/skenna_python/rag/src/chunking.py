"""Utilities for splitting cleaned OCR text into retrieval-friendly chunks."""

from __future__ import annotations

from dataclasses import dataclass
import re
from typing import Iterable


@dataclass(frozen=True)
class Chunk:
	chunk_id: int
	text: str
	start_char: int
	end_char: int


def normalize_text(text: str) -> str:
	"""Normalize whitespace while preserving paragraph boundaries."""
	text = text.replace("\r\n", "\n").replace("\r", "\n")
	lines = [line.strip() for line in text.split("\n")]
	cleaned_lines = []
	for line in lines:
		if line:
			cleaned_lines.append(re.sub(r"\s+", " ", line))
		elif cleaned_lines and cleaned_lines[-1] != "":
			cleaned_lines.append("")
	normalized = "\n".join(cleaned_lines)
	normalized = re.sub(r"\n{3,}", "\n\n", normalized)
	return normalized.strip()


def split_into_chunks(text: str, max_chars: int = 1800, overlap: int = 250) -> list[Chunk]:
	"""Split text into overlapping chunks with paragraph awareness.

	The function prefers to end chunks at paragraph boundaries, but falls back to
	character-based splitting when a paragraph is too large.
	"""
	if max_chars <= 0:
		raise ValueError("max_chars must be greater than zero")
	if overlap < 0:
		raise ValueError("overlap must be zero or greater")
	if overlap >= max_chars:
		raise ValueError("overlap must be smaller than max_chars")

	text = normalize_text(text)
	if not text:
		return []

	paragraphs = [paragraph.strip() for paragraph in text.split("\n\n") if paragraph.strip()]
	chunks: list[Chunk] = []
	current_parts: list[str] = []
	current_len = 0
	chunk_start = 0
	chunk_id = 1

	def flush_chunk(parts: list[str], start_char: int, end_char: int) -> None:
		nonlocal chunk_id
		chunk_text = "\n\n".join(parts).strip()
		if chunk_text:
			chunks.append(Chunk(chunk_id=chunk_id, text=chunk_text, start_char=start_char, end_char=end_char))
			chunk_id += 1

	for paragraph in paragraphs:
		paragraph_len = len(paragraph)
		separator_len = 2 if current_parts else 0
		prospective_len = current_len + separator_len + paragraph_len

		if current_parts and prospective_len > max_chars:
			flush_chunk(current_parts, chunk_start, chunk_start + current_len)

			if overlap > 0 and chunks:
				previous_text = chunks[-1].text
				overlap_text = previous_text[-overlap:].strip()
				current_parts = [overlap_text] if overlap_text else []
				current_len = len(overlap_text)
				chunk_start = max(0, chunks[-1].end_char - overlap)
			else:
				current_parts = []
				current_len = 0
				chunk_start = chunks[-1].end_char if chunks else 0

		if paragraph_len > max_chars:
			if current_parts:
				flush_chunk(current_parts, chunk_start, chunk_start + current_len)
				current_parts = []
				current_len = 0
				chunk_start = chunks[-1].end_char if chunks else 0

		start = 0
		while start < paragraph_len:
			end = min(start + max_chars, paragraph_len)
			piece = paragraph[start:end].strip()
			if piece:
				chunks.append(Chunk(chunk_id=chunk_id, text=piece, start_char=start, end_char=end))
				chunk_id += 1
			start = end - overlap if end < paragraph_len and overlap > 0 else end
			if start < 0:
				start = 0
			if start >= paragraph_len:
				break
			continue

		current_parts.append(paragraph)
		current_len = len("\n\n".join(current_parts))

	if current_parts:
		flush_chunk(current_parts, chunk_start, chunk_start + current_len)

	return chunks


def iter_chunk_texts(chunks: Iterable[Chunk]) -> Iterable[str]:
	"""Return the raw text for each chunk."""
	for chunk in chunks:
		yield chunk.text
