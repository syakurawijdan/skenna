"""Memeriksa isi dan kemampuan retrieval ChromaDB yang dipakai SKENNA."""

from __future__ import annotations

# Bagian 1: import pustaka standar yang dipakai untuk path, output, dan error.
import json
import logging
import os
from pathlib import Path
import sys
from typing import Any


# Bagian 2: tentukan lokasi proyek agar script tetap benar dari working directory mana pun.
SCRIPT_DIR = Path(__file__).resolve().parent
APP_ROOT = SCRIPT_DIR / "skenna"
BACKEND_ROOT = APP_ROOT / "skenna_backend"

# Bagian 3: gunakan UTF-8 agar karakter ilmiah/Indonesia aman di terminal Windows.
if hasattr(sys.stdout, "reconfigure"):
	sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
	sys.stderr.reconfigure(encoding="utf-8", errors="replace")


def print_json(data: Any) -> None:
	"""Cetak data ChromaDB sebagai JSON yang rapi dan mudah dibaca."""
	print(json.dumps(data, indent=2, ensure_ascii=False, default=str))


def load_application_config():
	"""Muat .env dan Settings yang sama dengan backend SKENNA."""
	# Bagian 4: validasi struktur proyek sebelum mengimpor modul aplikasi.
	if not BACKEND_ROOT.is_dir():
		raise FileNotFoundError(
			f"Folder backend tidak ditemukan: {BACKEND_ROOT}\n"
			"Pastikan check_chroma.py berada di root repository SKENNA."
		)

	# Bagian 5: masukkan root aplikasi dan backend ke path seperti bootstrap RAGService.
	if str(APP_ROOT) not in sys.path:
		sys.path.insert(0, str(APP_ROOT))
	if str(BACKEND_ROOT) not in sys.path:
		sys.path.insert(0, str(BACKEND_ROOT))

	# Bagian 6: baca file environment aplikasi tanpa menimpa environment aktif.
	from dotenv import load_dotenv

	load_dotenv(APP_ROOT / ".env", override=False)

	# Bagian 7: gunakan objek settings asli agar path, collection, dan model identik.
	from app.core.config import settings

	return settings


def collection_name(collection: Any) -> str:
	"""Ambil nama collection pada berbagai versi API ChromaDB."""
	return collection if isinstance(collection, str) else str(collection.name)


def show_collection(client: Any, name: str) -> int:
	"""Tampilkan identitas, jumlah, lima dokumen pertama, dan metadata collection."""
	# Bagian 7: buka collection yang sudah ada; tidak membuat collection baru.
	collection = client.get_collection(name=name)
	count = int(collection.count())

	print("\n" + "=" * 72)
	print(f"Nama collection : {name}")
	print(f"Jumlah dokumen  : {count}")
	print("Metadata collection:")
	print_json(collection.metadata or {})

	# Bagian 8: collection kosong ditangani tanpa memanggil peek secara sia-sia.
	if count == 0:
		print("Lima dokumen pertama: collection kosong, tidak ada dokumen.")
		return count

	# Bagian 9: peek menampilkan maksimal lima dokumen beserta metadata dokumennya.
	print("Lima dokumen pertama (peek limit=5):")
	peek_result = collection.peek(limit=min(5, count))
	print_json(peek_result)
	return count


def run_example_query(client: Any, settings: Any, available_names: list[str]) -> None:
	"""Jalankan query contoh dengan embedding Gemini yang sama dengan aplikasi."""
	question = "berapa batas konsumsi natrium harian?"
	configured_name = settings.chroma_collection_name

	print("\n" + "=" * 72)
	print("CONTOH QUERY")
	print(f"Pertanyaan       : {question}")
	print(f"Target collection: {configured_name}")
	print(f"Model embedding  : {settings.gemini_embedding_model}")

	# Bagian 10: pastikan collection target tersedia dan memiliki data.
	if configured_name not in available_names:
		print(
			f"Query dilewati: collection konfigurasi '{configured_name}' "
			"tidak ditemukan di database."
		)
		return

	collection = client.get_collection(name=configured_name)
	count = int(collection.count())
	if count == 0:
		print("Query dilewati: collection target masih kosong.")
		return

	# Bagian 11: hasil indeks dibuat dengan Gemini, jadi query memakai helper Gemini asli.
	from skenna_python.rag.src.embedding import generate_embedding

	try:
		query_embedding = generate_embedding(question)
		result = collection.query(
			query_embeddings=[query_embedding],
			n_results=min(int(settings.rag_top_k), count),
			include=["documents", "metadatas", "distances"],
		)
	except Exception as exc:
		print("Query tidak dapat dijalankan, tetapi pemeriksaan database selesai.")
		print(f"Penyebab: {type(exc).__name__}: {exc}")
		print("Periksa GEMINI_API_KEY, koneksi internet, kuota API, dan model embedding.")
		return

	# Bagian 12: uraikan hasil agar dokumen, metadata, jarak, dan skor mudah dijelaskan.
	ids = (result.get("ids") or [[]])[0]
	documents = (result.get("documents") or [[]])[0]
	metadatas = (result.get("metadatas") or [[]])[0]
	distances = (result.get("distances") or [[]])[0]
	if not ids:
		print("Query berhasil, tetapi tidak ada dokumen yang berhasil diretrieval.")
		return

	print(f"Dokumen berhasil diretrieval: {len(ids)}")
	for index, document_id in enumerate(ids, start=1):
		distance = float(distances[index - 1])
		# Rumus skor ini sama dengan ChromaStore aplikasi: 1 / (1 + distance).
		score = 1.0 / (1.0 + distance)
		print(f"\nHasil #{index}")
		print(f"ID       : {document_id}")
		print(f"Jarak    : {distance:.6f}")
		print(f"Skor     : {score:.6f}")
		print("Metadata :")
		print_json(metadatas[index - 1] or {})
		print("Dokumen  :")
		print(documents[index - 1] or "(dokumen kosong)")


def main() -> int:
	"""Hubungkan ke ChromaDB, tampilkan isinya, lalu uji retrieval."""
	try:
		# Bagian 13: ambil konfigurasi runtime dan normalkan path database absolut.
		settings = load_application_config()
		database_path = Path(settings.chroma_db_path).expanduser().resolve()
		print("KONFIGURASI CHROMADB SKENNA")
		print(f"Path database    : {database_path}")
		print(f"Collection utama : {settings.chroma_collection_name}")
		print(f"Top-K aplikasi   : {settings.rag_top_k}")
		print(f"Batas jarak RAG  : {settings.rag_distance_threshold}")

		# Bagian 14: cegah PersistentClient membuat folder baru ketika path salah.
		if not database_path.is_dir():
			print(f"ERROR: path ChromaDB tidak ditemukan: {database_path}")
			return 1
		if not (database_path / "chroma.sqlite3").is_file():
			print(f"ERROR: file chroma.sqlite3 tidak ditemukan di: {database_path}")
			return 1

		# Bagian 15: matikan telemetry opsional agar output pemeriksaan tetap bersih.
		os.environ.setdefault("ANONYMIZED_TELEMETRY", "False")
		logging.getLogger("chromadb.telemetry.product.posthog").disabled = True

		# Bagian 16: koneksi persisten dibuat sama seperti ChromaStore aplikasi.
		import chromadb

		client = chromadb.PersistentClient(path=str(database_path))
		collections = client.list_collections()
		names = [collection_name(item) for item in collections]
		print(f"Daftar collection : {names if names else '(tidak ada collection)'}")

		# Bagian 17: periksa seluruh collection yang tersimpan dalam database.
		if not names:
			print("Database berhasil dibuka, tetapi belum memiliki collection.")
			return 0
		for name in names:
			try:
				show_collection(client, name)
			except Exception as exc:
				print(f"Gagal membaca collection '{name}': {type(exc).__name__}: {exc}")

		# Bagian 18: jalankan retrieval pada collection utama aplikasi.
		run_example_query(client, settings, names)
		return 0
	except ModuleNotFoundError as exc:
		print(f"ERROR: dependency Python belum tersedia: {exc.name}")
		print("Aktifkan virtual environment proyek dan instal requirements backend/RAG.")
		return 1
	except Exception as exc:
		print(f"ERROR: pemeriksaan ChromaDB gagal: {type(exc).__name__}: {exc}")
		return 1


# Bagian 19: entry point membuat file dapat dijalankan dengan `python check_chroma.py`.
if __name__ == "__main__":
	raise SystemExit(main())
