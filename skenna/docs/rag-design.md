## RAG Design

Desain RAG untuk Skenna sekarang bisa memakai dua sumber:

1. **JSON knowledge base utama**
	- Sumber kurasi terstruktur yang sudah berisi ringkasan, poin kunci, dan relevansi pertanyaan.
	- Lebih cepat di-ingest dan lebih stabil untuk retrieval.
	- Cocok jika Anda ingin chatbot membaca pengetahuan yang sudah dirapikan.

2. **PDF jurnal mentah sebagai fallback**
	- Dipakai jika Anda masih perlu arsip sumber asli.
	- Tetap bisa di-OCR, dibersihkan, lalu dipecah jadi chunk.

### Alur JSON-first

1. JSON dimuat dari file kurasi.
2. Setiap dokumen digabung menjadi teks retrieval-friendly.
3. Teks dipecah menjadi chunk.
4. Chunk disimpan ke `chunks/<topic>/`.
5. `rebuild_index.py` membangun ulang `index/docstore.json`.
6. Retriever mengambil konteks dari docstore JSON itu.

### Catatan implementasi

- Field seperti `judul`, `kategori`, `ringkasan`, `temuan_utama`, `kesimpulan`, `poin_kunci`, dan `relevansi_rag` sebaiknya dipertahankan karena paling berguna untuk retrieval.
- Kalau JSON adalah sumber utama, PDF hanya disimpan sebagai arsip referensi, bukan sumber baca utama chatbot.
