"""Ingest raw PDF papers into OCR text files and chunked JSONL outputs.

Usage example:

    python scripts/ingest_docs.py --topic hipertensi

The script scans `raw_papers/<topic>/`, extracts text from each PDF page,
falls back to OCR for image-based pages, then writes:

- cleaned OCR text to `processed_text/<topic>/`
- chunk files to `chunks/<topic>/`
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from datetime import datetime, timezone
import io
import re
import sys
from typing import Any


ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
	sys.path.insert(0, str(ROOT_DIR))

try:
	import fitz  # PyMuPDF
except ImportError as exc:  # pragma: no cover - dependency check happens at runtime
	raise SystemExit(
		"PyMuPDF is required. Install dependencies with: pip install -r requirements.txt"
	) from exc

try:
	import pytesseract
except ImportError as exc:  # pragma: no cover - dependency check happens at runtime
	raise SystemExit(
		"pytesseract is required. Install dependencies with: pip install -r requirements.txt"
	) from exc

try:
	from PIL import Image
except ImportError as exc:  # pragma: no cover - dependency check happens at runtime
	raise SystemExit(
		"Pillow is required. Install dependencies with: pip install -r requirements.txt"
	) from exc

from src.chunking import normalize_text, split_into_chunks


RAW_DIR = ROOT_DIR / "raw_papers"
PROCESSED_DIR = ROOT_DIR / "processed_text"
CHUNKS_DIR = ROOT_DIR / "chunks"
DEFAULT_OCR_LANG = os.environ.get("SKENNA_OCR_LANG", "eng")


def configure_tesseract() -> Path | None:
	"""Point pytesseract at a local Windows install when PATH is unavailable."""
	candidates = []
	env_cmd = os.environ.get("SKENNA_TESSERACT_CMD")
	if env_cmd:
		candidates.append(Path(env_cmd))
	candidates.extend(
		[
			Path(r"C:\Program Files\Tesseract-OCR\tesseract.exe"),
			Path(r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe"),
		]
	)

	for candidate in candidates:
		if candidate.exists():
			pytesseract.pytesseract.tesseract_cmd = str(candidate)
			return candidate

	return None


def slugify_filename(path: Path) -> str:
	"""Convert a file stem into a filesystem-safe slug."""
	name = path.stem.lower()
	name = re.sub(r"[^a-z0-9]+", "_", name)
	return re.sub(r"_+", "_", name).strip("_") or "document"


def extract_text_from_page(page: fitz.Page, ocr_lang: str = DEFAULT_OCR_LANG) -> str:
	"""Extract embedded text first, then OCR the rendered page if needed."""
	text = page.get_text("text").strip()
	if text:
		return text

	zoom = 2.0
	matrix = fitz.Matrix(zoom, zoom)
	pix = page.get_pixmap(matrix=matrix, alpha=False)
	image = Image.open(io.BytesIO(pix.tobytes("png")))
	return pytesseract.image_to_string(image, lang=ocr_lang)


def extract_document(pdf_path: Path, use_ocr: bool = True, ocr_lang: str = DEFAULT_OCR_LANG) -> dict[str, Any]:
	"""Read a PDF file and return its cleaned OCR text plus page metadata."""
	document = fitz.open(pdf_path)
	page_entries: list[dict[str, Any]] = []
	all_text_parts: list[str] = []

	for page_index in range(document.page_count):
		page = document.load_page(page_index)
		text = page.get_text("text").strip()
		ocr_used = False

		if not text and use_ocr:
			text = extract_text_from_page(page, ocr_lang=ocr_lang)
			ocr_used = True
		elif not text:
			text = ""

		cleaned = normalize_text(text)
		page_entries.append(
			{
				"page": page_index + 1,
				"ocr_used": ocr_used,
				"text": cleaned,
			}
		)
		if cleaned:
			all_text_parts.append(f"[PAGE {page_index + 1}]\n{cleaned}")

	metadata = {
		"source_file": pdf_path.name,
		"source_path": str(pdf_path),
		"page_count": document.page_count,
		"extracted_at": datetime.now(timezone.utc).isoformat(),
	}
	return {
		"metadata": metadata,
		"pages": page_entries,
		"text": normalize_text("\n\n".join(all_text_parts)),
	}


def ensure_output_dirs(topic: str) -> tuple[Path, Path]:
	"""Create the processed text and chunk folders for a topic."""
	processed_topic_dir = PROCESSED_DIR / topic
	chunks_topic_dir = CHUNKS_DIR / topic
	processed_topic_dir.mkdir(parents=True, exist_ok=True)
	chunks_topic_dir.mkdir(parents=True, exist_ok=True)
	return processed_topic_dir, chunks_topic_dir


def write_processed_file(output_dir: Path, pdf_path: Path, document_data: dict[str, Any]) -> Path:
	"""Write cleaned OCR output as JSON."""
	output_path = output_dir / f"{slugify_filename(pdf_path)}.json"
	with output_path.open("w", encoding="utf-8") as handle:
		json.dump(document_data, handle, ensure_ascii=False, indent=2)
	return output_path


def write_chunks_file(output_dir: Path, pdf_path: Path, document_data: dict[str, Any], topic: str, max_chars: int, overlap: int) -> Path:
	"""Write chunk output as JSONL for downstream indexing."""
	chunk_list = split_into_chunks(document_data["text"], max_chars=max_chars, overlap=overlap)
	output_path = output_dir / f"{slugify_filename(pdf_path)}.jsonl"
	with output_path.open("w", encoding="utf-8") as handle:
		for chunk in chunk_list:
			payload = {
				"chunk_id": chunk.chunk_id,
				"source_file": pdf_path.name,
				"source_path": str(pdf_path),
				"text": chunk.text,
				"start_char": chunk.start_char,
				"end_char": chunk.end_char,
				"topic": topic,
			}
			handle.write(json.dumps(payload, ensure_ascii=False) + "\n")
	return output_path


def iter_pdf_files(topic: str) -> list[Path]:
	"""Return PDF files from the topic-specific raw folder."""
	raw_topic_dir = RAW_DIR / topic
	if not raw_topic_dir.exists():
		raise SystemExit(f"Input folder does not exist: {raw_topic_dir}")
	return sorted(raw_topic_dir.glob("*.pdf"))


def main() -> int:
	parser = argparse.ArgumentParser(description="OCR and chunk raw PDF papers for RAG ingestion.")
	parser.add_argument("--topic", default="hipertensi", help="Topic folder to process under raw_papers/")
	parser.add_argument("--max-chars", type=int, default=1800, help="Maximum characters per chunk")
	parser.add_argument("--overlap", type=int, default=250, help="Character overlap between chunks")
	parser.add_argument("--no-ocr", action="store_true", help="Disable OCR fallback for image-only pages")
	parser.add_argument("--ocr-lang", default=DEFAULT_OCR_LANG, help="Tesseract language code for OCR pages")
	args = parser.parse_args()

	tesseract_path = configure_tesseract()
	if not args.no_ocr and tesseract_path is None:
		print("Warning: Tesseract executable not found. OCR pages will fail unless you install it or set SKENNA_TESSERACT_CMD.")
	elif tesseract_path is not None:
		print(f"Using Tesseract at {tesseract_path}")

	processed_dir, chunks_dir = ensure_output_dirs(args.topic)
	pdf_files = iter_pdf_files(args.topic)
	if not pdf_files:
		print(f"No PDF files found in {RAW_DIR / args.topic}")
		return 0

	print(f"Processing {len(pdf_files)} PDF file(s) from {RAW_DIR / args.topic}")
	for pdf_path in pdf_files:
		print(f"- {pdf_path.name}")
		document_data = extract_document(pdf_path, use_ocr=not args.no_ocr, ocr_lang=args.ocr_lang)
		processed_path = write_processed_file(processed_dir, pdf_path, document_data)
		chunk_path = write_chunks_file(chunks_dir, pdf_path, document_data, args.topic, args.max_chars, args.overlap)
		print(f"  processed -> {processed_path.relative_to(ROOT_DIR)}")
		print(f"  chunks    -> {chunk_path.relative_to(ROOT_DIR)}")

	return 0


if __name__ == "__main__":
	raise SystemExit(main())
