## RAG Workspace

Folder ini dipakai untuk menyiapkan knowledge base hipertensi, baik dari PDF mentah maupun JSON terkurasi, lalu mengubahnya menjadi chunk dan ChromaDB index untuk chatbot.

### Struktur Folder

- `raw_papers/hipertensi/`: tempat PDF jurnal mentah tentang hipertensi diunggah.
- `knowledge_base/hipertensi/`: tempat JSON terkurasi sebagai sumber utama knowledge base.
- `processed_text/hipertensi/`: hasil OCR dan teks yang sudah dibersihkan.
- `chunks/hipertensi/`: hasil pemotongan teks per dokumen atau per section.
- `chroma/`: persistent ChromaDB collection yang dipakai saat retrieval.
- `knowledge_base/`: pengelompokan sumber per topik.

### Topik yang Disediakan

- `hipertensi/` sebagai topik utama.

### Aturan Penamaan PDF

Gunakan format:

`topik_tahun_firstauthor_judulpendek.pdf`

Contoh:

- `hipertensi_2023_smith_hypertension_guideline.pdf`
- `hipertensi_2022_kemenkes_diet_dash.pdf`

Aturan sederhana:

1. Pakai huruf kecil.
2. Jangan pakai spasi.
3. Gunakan underscore `_`.
4. Sertakan topik `hipertensi` dan tahun.
5. Jika hasil scan, boleh tambahkan suffix `_scan`.

### Alur Pakai

#### Opsi A - JSON knowledge base utama

1. Simpan file JSON terkurasi ke `knowledge_base/hipertensi/` atau siapkan path file JSON di luar repo.
2. Jalankan ingest JSON:

	`python scripts/ingest_json_kb.py --source-json C:\path\to\hipertensi_jurnal.json --topic hipertensi`

3. Script akan:
	- membuat salinan JSON yang dinormalisasi ke `knowledge_base/hipertensi/`
	- menulis teks gabungan ke `processed_text/hipertensi/`
	- menulis chunk JSONL ke `chunks/hipertensi/`
	- mengganti output topic lama kecuali Anda menambahkan `--preserve-existing`
4. Build ChromaDB index supaya chatbot membaca chunk terbaru:

	`python scripts/build_chroma_index.py --topic hipertensi --reset`

#### Opsi B - PDF jurnal mentah

1. Taruh PDF mentah ke `raw_papers/hipertensi/`.
2. Install dependency Python dari `requirements.txt`.
	Pastikan juga aplikasi Tesseract OCR sudah terpasang di Windows.
	Script ingest akan mencoba mendeteksi `C:\Program Files\Tesseract-OCR\tesseract.exe` otomatis, atau gunakan environment variable `SKENNA_TESSERACT_CMD` jika path Anda berbeda.
3. Jalankan script ingest OCR:

	`python scripts/ingest_docs.py --topic hipertensi`

	Jika Anda perlu bahasa OCR lain, tambahkan `--ocr-lang <kode>`.

4. Script membersihkan teks dan memecah chunk.
5. Hasil chunk disimpan ke `chunks/hipertensi/`.
6. Build ChromaDB index supaya chatbot membaca chunk terbaru:

	`python scripts/build_chroma_index.py --topic hipertensi --reset`

7. Data dimasukkan ke persistent ChromaDB collection untuk dipakai chatbot.
