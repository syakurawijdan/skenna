## RAG Workspace

Folder ini dipakai untuk menyiapkan jurnal mentah, hasil OCR, chunk, dan index untuk chatbot.

### Struktur Folder

- `raw_papers/hipertensi/`: tempat PDF jurnal mentah tentang hipertensi diunggah.
- `processed_text/hipertensi/`: hasil OCR dan teks yang sudah dibersihkan.
- `chunks/hipertensi/`: hasil pemotongan teks per dokumen atau per section.
- `index/`: vector index yang dipakai saat retrieval.
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

1. Taruh PDF mentah ke `raw_papers/hipertensi/`.
2. Install dependency Python dari `requirements.txt`.
	Pastikan juga aplikasi Tesseract OCR sudah terpasang di Windows.
	Script ingest akan mencoba mendeteksi `C:\Program Files\Tesseract-OCR\tesseract.exe` otomatis, atau gunakan environment variable `SKENNA_TESSERACT_CMD` jika path Anda berbeda.
3. Jalankan script ingest OCR:

	`python scripts/ingest_docs.py --topic hipertensi`

	Jika Anda perlu bahasa OCR lain, tambahkan `--ocr-lang <kode>`.

4. Script membersihkan teks dan memecah chunk.
4. Hasil chunk disimpan ke `chunks/hipertensi/`.
5. Rebuild index supaya chatbot membaca chunk terbaru:

	`python scripts/rebuild_index.py --topic hipertensi`

6. Data dimasukkan ke `index/` untuk dipakai chatbot.
