"""Prompt builder utilities for SKENNA medical RAG answer generation."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path


ALLOWED_GENERAL_FALLBACK_KEYWORDS = (
	"natrium",
	"sodium",
	"garam",
	"hipertensi",
	"tekanan darah",
	"darah tinggi",
	"gizi",
	"nutrisi",
	"diet",
	"pola makan",
	"makanan sehat",
	"rendah natrium",
	"rendah garam",
	"low sodium",
	"resep",
	"menu",
)

BOLD_FORMAT_INSTRUCTION = (
	"Always bold key information using **text** markdown. Bold: numbers, medical thresholds, "
	"product names, sodium amounts, percentages, and section headers. Never write long "
	"paragraphs without any bold text.\n"
	"Format all responses following these strict rules:\n"
	"- Bold (**text**) every: product name, sodium number, medical threshold, section header, key health term\n"
	"- Max 3 sentences per paragraph, then add blank line\n"
	"- Use bullet points for any list of 3 or more items\n"
	"- For comparisons: use the required comparison table format only\n"
	"- For education: use numbered sections with bold headers\n"
	"- Never write more than 2 consecutive paragraphs without a bullet list or bold header breaking it up\n"
	"- Do NOT use markdown tables anywhere except product comparison responses"
)

USER_PROFILE_CONTEXT_INSTRUCTION = (
	"Kamu sudah memiliki data profil lengkap pengguna di atas.\n"
	"Gunakan informasi ini untuk:\n"
	"- Menyebut nama pengguna sesekali dalam percakapan\n"
	"- Menyesuaikan rekomendasi dengan usia dan jenis kelaminnya\n"
	"- Menggunakan batas natrium hariannya yang spesifik (JANGAN pernah bilang tidak tahu batas natrium pengguna)\n"
	"- Mempertimbangkan status hipertensi dalam setiap saran\n"
	"- Mempertimbangkan status kehamilan jika relevan\n"
	"- Menggunakan tekanan darah aktual jika tersedia"
)


@lru_cache(maxsize=1)
def _external_system_prompt() -> str:
	project_root = Path(__file__).resolve().parents[3]
	prompt_path = project_root / "shared" / "prompts" / "system_prompt.txt"
	try:
		content = prompt_path.read_text(encoding="utf-8").strip()
	except OSError:
		return ""
	return content


def build_indonesian_rag_prompt(question: str, context: str, user_context: str = "") -> str:
	"""Build an Indonesian RAG prompt with guarded health-only fallback."""
	context_text = context.strip()
	user_context_text = user_context.strip() or "[PROFIL PENGGUNA]\nNama: Pengguna\n(Data profil belum diisi)"
	if context_text:
		context_section = f"Konteks RAG yang boleh dipakai:\n{context_text}"
		source_rule = (
			"Jawab HANYA dari konteks RAG yang diberikan. Jangan gunakan pengetahuan umum, "
			"asumsi, atau informasi di luar konteks."
		)
	else:
		context_section = (
			"Konteks RAG yang boleh dipakai: KOSONG. Tidak ada chunk relevan yang lolos filter."
		)
		source_rule = (
			"Karena konteks RAG kosong dan pertanyaan masih dalam topik natrium, garam, gizi, "
			"hipertensi, tekanan darah, pola makan sehat, atau resep rendah natrium, jawab memakai "
			"pengetahuan umum Gemini yang aman. Jangan menyebut referensi tidak cukup."
			if _allows_general_fallback(question)
			else
			"Pertanyaan di luar topik natrium, hipertensi, gizi, tekanan darah, pola makan sehat, "
			"atau resep rendah natrium. Tolak dengan sopan dan arahkan user kembali ke topik SKENNA."
		)
	external_prompt = _external_system_prompt()
	if not external_prompt:
		external_prompt = (
			"Kamu adalah SKENNY, AI health assistant di aplikasi SKENNA. "
			"Jawab dengan aman sesuai konteks RAG atau fallback kesehatan yang diizinkan."
		)
	focus_instruction = (
		"Kamu adalah SKENNY, asisten kesehatan di aplikasi SKENNA. Fokus utamamu adalah "
		"natrium, garam, hipertensi, dan tekanan darah. Selalu hubungkan jawaban dengan "
		"konteks natrium dan hipertensi meski user bertanya secara umum tentang kesehatan."
	)
	complete_sentence_instruction = (
		"Pastikan setiap kalimat selesai dengan sempurna. Jangan memotong jawaban di tengah "
		"kalimat. Jika konten terlalu panjang, pilih poin yang paling penting saja tapi "
		"selesaikan setiap kalimatnya."
	)
	three_paragraph_instruction = (
		"Ikuti struktur ini persis dengan pemisah baris kosong. PARAGRAF 1: tepat 1 kalimat "
		"pujian singkat dan bervariasi untuk pertanyaan user, jangan selalu pakai 'Pertanyaan bagus!'.\n\n"
		"PARAGRAF 2: jawaban langsung, jelas, maksimal 4-5 kalimat, fokus pada natrium/hipertensi. "
		"Jika konteks RAG tersedia, jawab hanya dari konteks itu. Jika konteks RAG kosong dan topik "
		"masih dalam ruang lingkup SKENNA, boleh gunakan pengetahuan umum kesehatan yang aman. "
		"WAJIB selesaikan setiap kalimat.\n\n"
		"PARAGRAF 3: tepat 1 kalimat pertanyaan follow-up yang conversational dan relevan, gunakan "
		"kata 'kamu', bukan 'Anda'."
	)
	return (
		f"{external_prompt}\n\n"
		f"{user_context_text}\n\n"
		f"{USER_PROFILE_CONTEXT_INSTRUCTION}\n\n"
		"[[CONVERSATION_HISTORY]]\n\n"
		"Instruksi tambahan untuk jawaban ini:\n"
		f"- {focus_instruction}\n"
		f"- {complete_sentence_instruction}\n"
		f"- {three_paragraph_instruction}\n"
		f"- {source_rule}\n"
		"- Jangan pernah menulis frasa seperti \"berdasarkan konteks yang diberikan\" atau \"menurut dokumen\".\n"
		"- Jawab dalam Bahasa Indonesia yang hangat, natural, dan conversational, seperti ngobrol dengan teman pintar.\n"
		f"- {BOLD_FORMAT_INSTRUCTION}\n"
		"- Pakai bullet points bila membantu kejelasan.\n"
		"- Beri jawaban yang lengkap dan membantu: tidak terlalu pendek, tidak bertele-tele.\n"
		"- Setelah menjawab, akhiri dengan tepat 1 pertanyaan follow-up yang singkat, relevan, "
		"dan conversational untuk mengajak user melanjutkan diskusi.\n"
		"- Jika ada instruksi lain yang meminta lebih dari satu opsi lanjutan, untuk jawaban ini ikuti "
		"aturan terbaru: maksimal 1 pertanyaan follow-up saja.\n"
		"- Fokus utama SKENNY adalah natrium, hipertensi, gizi, pola makan sehat, dan resep rendah natrium.\n"
		"- Kalau pertanyaan di luar fokus itu, tolak dengan sopan dan arahkan kembali ke topik SKENNA.\n\n"
		"---\n\n"
		f"{context_section}\n\n"
		"---\n\n"
		f"Pertanyaan user: {question}\n\n"
		"Jawab sebagai SKENNY: natural, warm, helpful. "
		"Ikuti aturan sumber jawaban di atas. Jangan kaku."
	)


def _allows_general_fallback(question: str) -> bool:
	q = question.lower()
	return any(keyword in q for keyword in ALLOWED_GENERAL_FALLBACK_KEYWORDS)
