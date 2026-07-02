import logging
import re
import time
import asyncio
import threading
from typing import Any

from sqlalchemy import desc, func, or_, select

from app.models.food_label_scan import FoodLabelScan
from app.models.intake_history import IntakeHistory
from app.repositories.chat_repository import ChatRepository
from app.repositories.history_repository import HistoryRepository
from app.repositories.user_repository import UserRepository
from app.services.chatbot_personalization_service import ChatbotPersonalizationService
from app.services.gemini_service import GeminiService
from app.services.rag_service import RAGService
from app.schemas.product_category import ProductCategory
from app.services.rekomendasi_service import get_rekomendasi
from skenna_python.rag.src.prompt_builder import build_indonesian_rag_prompt


logger = logging.getLogger(__name__)


def _tokens(text: str) -> set[str]:
	return {token for token in re.findall(r"[a-z0-9]+", text.lower()) if len(token) >= 2}


class ChatIntent:
	GREETING = "greeting"
	SMALL_TALK = "small_talk"
	MEDICAL = "medical"
	EDUCATION = "education"
	EDUCATION_CONTINUE = "education_continue"
	COMPARISON = "comparison"
	PRODUCT_RECOMMENDATION = "product_recommendation"
	SYMPTOM_CHAT = "symptom_chat"
	OUT_OF_SCOPE = "out_of_scope"


class ChatbotService:
	"""Hybrid SKENNA chatbot router: free chat, RAG, education, comparison."""

	EDUCATION_TOTAL_STEPS = 3
	SHOW_CONTINUE_MARKER = "[SHOW_CONTINUE]"
	EDUCATION_COMPLETE_MARKER = "[EDUCATION_COMPLETE]"
	SUGGESTED_QUESTIONS_MARKER = (
		"[SUGGEST_Q]Berapa batas natrium harian yang aman?|"
		"Makanan apa yang tinggi natrium?|"
		"Bagaimana cara membaca label natrium di kemasan?[/SUGGEST_Q]"
	)
	EDUCATION_STEP_TOPICS = {
		1: (
			'Edukasi 1/3: Apa itu Hipertensi?\n'
			'- Definition of hypertension. Bold the threshold **>130/80 mmHg**.\n'
			'- Explain why hypertension is called **silent killer**.\n'
			'- Explain how common it is in Indonesia and bold the statistic.\n'
			'- Risk factors: **age**, **diet**, **genetics**, **obesity**.\n'
			'- Format: short intro paragraph + bullet points with bold key terms.'
		),
		2: (
			'Edukasi 2/3: Bahaya & Komplikasi\n'
			'- Dangers of uncontrolled hypertension.\n'
			'- Complications: **heart attack**, **stroke**, **kidney failure**.\n'
			'- Connection between sodium and blood pressure.\n'
			'- Format: bullet points, bold each complication name.'
		),
		3: (
			'Edukasi 3/3: Natrium & Batas Harian\n'
			'- What sodium is and why it raises blood pressure.\n'
			'- Daily limits from Skenna rule-based system. Never contradict these exact values:\n'
			'  * **WHO**: **2.000 mg/hari** -> Batas untuk populasi umum yang sehat.\n'
			'  * **AKG Kemenkes RI**: **1.500 mg/hari** -> Standar nasional Indonesia, acuan utama Skenna.\n'
			'  * **AHA**: **1.500 mg/hari** -> Batas LEBIH KETAT, hanya untuk pengguna hipertensi atau berisiko tinggi.\n'
			'- Clearly state WHO is general population standard.\n'
			'- Clearly state AKG Kemenkes RI is Indonesia national standard and Skenna main reference.\n'
			'- Clearly state AHA 1.500 mg is stricter and ONLY for hypertensive/high-risk users, not healthy users.\n'
			'- Never present all three as equal alternatives; they serve different user conditions in Skenna personalization.\n'
			'- Practical prevention tips: 5 bullet points, each with a bold action word.\n'
			'- Closing: encourage user to start scanning with Skenna.\n'
			'- Format: structured sections with bold headers and bullet points.'
		),
	}
	SKENNA_FOCUS_INSTRUCTION = (
		"Kamu adalah SKENNY, asisten kesehatan di aplikasi SKENNA. Fokus utamamu adalah "
		"natrium, garam, hipertensi, dan tekanan darah. Selalu hubungkan jawaban dengan "
		"konteks natrium dan hipertensi meski user bertanya secara umum tentang kesehatan."
	)
	FOLLOW_UP_INSTRUCTION = (
		"Akhiri jawabanmu dengan 1 pertanyaan follow-up yang singkat, relevan, dan "
		"conversational untuk mengajak user melanjutkan diskusi. Gunakan bahasa yang hangat."
	)
	GEMINI_FALLBACK_MESSAGE = (
		"Maaf, Skenny lagi kesulitan menghubungi layanan AI. "
		"Coba kirim ulang sebentar lagi ya."
	)
	COMPLETE_SENTENCE_INSTRUCTION = (
		"Pastikan setiap kalimat selesai dengan sempurna. Jangan memotong jawaban di tengah "
		"kalimat. Jika konten terlalu panjang, pilih poin yang paling penting saja tapi "
		"selesaikan setiap kalimatnya."
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
	THREE_PARAGRAPH_INSTRUCTION = (
		"Ikuti struktur ini persis dengan pemisah baris kosong. PARAGRAF 1: tepat 1 kalimat "
		"pujian singkat dan bervariasi untuk pertanyaan user, jangan selalu pakai 'Pertanyaan bagus!'.\n\n"
		"PARAGRAF 2: jawaban langsung, jelas, maksimal 4-5 kalimat, fokus pada natrium/hipertensi. "
		"Untuk mode RAG, jawab dari konteks yang diberikan jika tersedia. Jika konteks kosong dan "
		"pertanyaan masih dalam topik SKENNA, boleh gunakan pengetahuan umum kesehatan yang aman. "
		"WAJIB selesaikan setiap kalimat.\n\n"
		"PARAGRAF 3: tepat 1 kalimat pertanyaan follow-up yang conversational dan relevan, gunakan "
		"kata 'kamu', bukan 'Anda'."
	)

	TYPO_PATTERNS: list[tuple[re.Pattern[str], str]] = [
		(re.compile(r"\bnatirum\b", re.IGNORECASE), "natrium"),
		(re.compile(r"\bntrium\b", re.IGNORECASE), "natrium"),
		(re.compile(r"\bnatriun\b", re.IGNORECASE), "natrium"),
		(re.compile(r"\bnatruim\b", re.IGNORECASE), "natrium"),
		(re.compile(r"\bsodiumm\b", re.IGNORECASE), "sodium"),
		(re.compile(r"\bsodim\b", re.IGNORECASE), "sodium"),
		(re.compile(r"\bhipertnsi\b", re.IGNORECASE), "hipertensi"),
		(re.compile(r"\bhipertesi\b", re.IGNORECASE), "hipertensi"),
		(re.compile(r"\bgrm\b", re.IGNORECASE), "garam"),
		(re.compile(r"\bgarem\b", re.IGNORECASE), "garam"),
		(re.compile(r"\btd\b", re.IGNORECASE), "tekanan darah"),
		(re.compile(r"\bbrp\b", re.IGNORECASE), "berapa"),
		(re.compile(r"\bgmn\b", re.IGNORECASE), "gimana"),
		(re.compile(r"\bgimana\b", re.IGNORECASE), "bagaimana"),
		(re.compile(r"\bknp\b", re.IGNORECASE), "kenapa"),
		(re.compile(r"\bmksh?\b", re.IGNORECASE), "makasih"),
	]

	GREETING_PATTERN = re.compile(
		r"^((halo|hai|hi|hello|helo|p|hey)(\s+(skenny|skenna))?|selamat\s+(pagi|siang|sore|malam)|kenalkan dirimu|kenalin diri|perkenalkan diri|siapa kamu|kamu siapa)[!?.\s]*$",
		re.IGNORECASE,
	)
	OFF_TOPIC_RESPONSE = (
		"Hei, aku Skenny! Aku asisten kesehatan yang fokus pada natrium dan hipertensi. "
		"Untuk pertanyaan di luar itu, aku belum bisa bantu ya."
	)
	SMALL_TALK_KEYWORDS = [
		"apa kabar",
		"lagi apa",
		"bagaimana harimu",
		"terima kasih",
		"makasih",
		"thanks",
		"thank you",
		"oke",
		"ok",
		"siapa kamu",
		"kamu siapa",
	]
	MEDICAL_KEYWORDS = [
		"natrium",
		"sodium",
		"garam",
		"hipertensi",
		"tekanan darah",
		"darah tinggi",
		"diet",
		"dash",
		"makanan",
		"gizi",
		"nutrisi",
		"label",
		"produk",
		"scan",
		"jantung",
		"ginjal",
		"stroke",
		"obat",
		"resep",
		"menu",
		"kolesterol",
		"kalori",
	]
	EDUCATION_KEYWORDS = ["edukasi", "belajar", "ajarin", "materi", "kelas"]
	EDUCATION_CONTINUE_KEYWORDS = ["lanjut", "ya", "iya", "boleh", "next", "lanjutkan"]
	COMPARISON_KEYWORDS = ["bandingkan", "lebih baik mana", "mana yang lebih", "compare", "vs", "versus"]
	PRODUCT_RECOMMENDATION_KEYWORDS = [
		"saya baru saja scan produk",
		"rekomendasi produk",
		"produk lain",
		"alternatif",
		"cari produk",
		"produk rendah natrium",
		"merk lain",
		"merek lain",
		"produk serupa",
		"ganti produk",
		"pilihan lain",
	]
	SYMPTOM_KEYWORDS = [
		"pusing",
		"sakit kepala",
		"lemas",
		"lelah",
		"capek",
		"mual",
		"jantung berdebar",
		"sesak",
		"penglihatan kabur",
		"telinga berdenging",
		"mimisan",
		"stress",
		"stres",
		"tekanan",
		"kelelahan",
		"kurang tidur",
		"begadang",
		"banyak makan",
		"makan asin",
		"tidak enak badan",
		"meriang",
		"panas",
		"demam",
	]
	OUT_OF_SCOPE_KEYWORDS = [
		"website",
		"coding",
		"python",
		"javascript",
		"programming",
		"film",
		"movie",
		"drama",
		"anime",
		"game",
		"presiden",
		"politik",
		"saham",
		"crypto",
		"kripto",
		"investasi",
		"matematika",
		"fisika",
		"sejarah",
		"geografi",
		"musik",
		"lagu",
		"puisi",
		"pantun",
		"cerpen",
		"novel",
		"buat aplikasi",
		"cara buat",
		"masak",
		"rendang",
	]
	ALLOWED_HEALTH_FALLBACK_KEYWORDS = [
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
	]

	@staticmethod
	def _normalize_question(question: str) -> str:
		normalized = question.strip().lower()
		for pattern, replacement in ChatbotService.TYPO_PATTERNS:
			normalized = pattern.sub(replacement, normalized)
		return re.sub(r"\s+", " ", normalized).strip()

	@staticmethod
	def _classify_intent(question: str) -> str:
		q = question.lower().strip()
		if ChatbotService.GREETING_PATTERN.fullmatch(q):
			return ChatIntent.GREETING
		if any(keyword in q for keyword in ChatbotService.PRODUCT_RECOMMENDATION_KEYWORDS):
			return ChatIntent.PRODUCT_RECOMMENDATION
		if any(keyword in q for keyword in ChatbotService.COMPARISON_KEYWORDS):
			return ChatIntent.COMPARISON
		if q in ChatbotService.EDUCATION_CONTINUE_KEYWORDS:
			return ChatIntent.EDUCATION_CONTINUE
		if any(keyword in q for keyword in ChatbotService.EDUCATION_KEYWORDS):
			return ChatIntent.EDUCATION
		if any(keyword in q for keyword in ChatbotService.SYMPTOM_KEYWORDS):
			return ChatIntent.SYMPTOM_CHAT
		if any(keyword in q for keyword in ChatbotService.MEDICAL_KEYWORDS):
			return ChatIntent.MEDICAL
		if any(keyword in q for keyword in ChatbotService.SMALL_TALK_KEYWORDS):
			return ChatIntent.SMALL_TALK
		if ChatbotService._is_clearly_out_of_scope(q):
			return ChatIntent.OUT_OF_SCOPE
		return ChatIntent.SMALL_TALK

	@staticmethod
	def _is_clearly_out_of_scope(question: str) -> bool:
		allowed_keywords = (
			ChatbotService.SMALL_TALK_KEYWORDS
			+ ChatbotService.MEDICAL_KEYWORDS
			+ ChatbotService.EDUCATION_KEYWORDS
			+ ChatbotService.COMPARISON_KEYWORDS
			+ ChatbotService.SYMPTOM_KEYWORDS
			+ ["skenna", "skenny", "aplikasi"]
		)
		if any(keyword in question for keyword in allowed_keywords):
			return False
		return any(keyword in question for keyword in ChatbotService.OUT_OF_SCOPE_KEYWORDS)

	@staticmethod
	def _is_allowed_health_fallback_topic(question: str) -> bool:
		q = question.lower()
		return any(keyword in q for keyword in ChatbotService.ALLOWED_HEALTH_FALLBACK_KEYWORDS)

	@staticmethod
	def _is_small_talk_message(question: str) -> bool:
		q = question.lower()
		return any(keyword in q for keyword in ChatbotService.SMALL_TALK_KEYWORDS)

	@staticmethod
	def _conversation_history(db: Any, user_id: int | None, max_turns: int = 10) -> list[dict[str, str]]:
		if db is None or user_id is None:
			return []
		try:
			items = ChatRepository.list_recent_pairs(db, user_id, limit=max_turns)
		except Exception:
			return []
		turns: list[dict[str, str]] = []
		for item in reversed(items):
			question = re.sub(r"\s+", " ", str(getattr(item, "question", "") or "")).strip()
			answer = re.sub(r"\s+", " ", str(getattr(item, "answer", "") or "")).strip()
			if question:
				turns.append({"role": "user", "content": question})
			if answer:
				turns.append({"role": "assistant", "content": answer})
		return turns

	@staticmethod
	def _format_history(history: list[dict[str, str]]) -> str:
		if not history:
			return "Tidak ada riwayat percakapan sebelumnya."
		lines: list[str] = []
		for turn in history:
			role = "User" if turn.get("role") == "user" else "Skenny"
			content = re.sub(r"\s+", " ", turn.get("content", "")).strip()
			if content:
				lines.append(f"{role}: {content[:1200]}")
		return "\n".join(lines) if lines else "Tidak ada riwayat percakapan sebelumnya."

	@staticmethod
	def _with_conversation_history(prompt: str, history: list[dict[str, str]]) -> str:
		history_block = (
			"Riwayat percakapan sejauh ini. Gunakan ini untuk memahami follow-up, jawaban pendek, "
			"dan konteks pesan user terbaru:\n"
			f"{ChatbotService._format_history(history)}"
		)
		if "[[CONVERSATION_HISTORY]]" in prompt:
			return prompt.replace("[[CONVERSATION_HISTORY]]", history_block)
		return f"{history_block}\n\n---\n\n{prompt}"

	@staticmethod
	def _call_gemini(
		callable_fn: Any,
		prompt: str,
		*,
		max_tokens: int = 2048,
		fallback_fn: Any = None,
	) -> str:
		for fn in [callable_fn, fallback_fn]:
			if fn is None:
				continue
			for attempt in range(2):
				try:
					return fn(prompt, max_tokens=max_tokens, timeout_seconds=30.0)
				except Exception as e:
					print(f"[GEMINI ERROR] {type(e).__name__}: {e}")
					logger.exception("Gemini call failed on attempt %s/2", attempt + 1)
					if attempt == 0:
						time.sleep(2.0)
		return ChatbotService.GEMINI_FALLBACK_MESSAGE

	@staticmethod
	def _has_health_context(history: list[dict[str, str]]) -> bool:
		text = " ".join(turn.get("content", "") for turn in history).lower()
		return any(keyword in text for keyword in ChatbotService.ALLOWED_HEALTH_FALLBACK_KEYWORDS)

	@staticmethod
	def _is_direct_reply_in_context(question: str, history: list[dict[str, str]]) -> bool:
		if not history:
			return False
		q = question.strip()
		if len(q.split()) <= 8:
			return True
		last_assistant = next((turn.get("content", "") for turn in reversed(history) if turn.get("role") == "assistant"), "")
		return "?" in last_assistant and len(q.split()) <= 20

	@staticmethod
	def _user_display_name(db: Any, user_id: int | None) -> str:
		if db is None or user_id is None:
			return "teman"
		try:
			user = UserRepository.get_or_create_by_id(db, user_id)
			name = re.sub(r"\s+", " ", str(getattr(user, "full_name", "") or "")).strip()
			return name or "teman"
		except Exception:
			return "teman"

	@staticmethod
	def _friendly_greeting(user_name: str) -> str:
		return (
			f"Halo, {user_name}! Saya Skenny, asisten kesehatan kamu di SKENNA. "
			"Ada yang bisa saya bantu seputar natrium atau hipertensi?"
		)

	@staticmethod
	def _out_of_scope_response(user_context: str = "") -> str:
		return ChatbotService.OFF_TOPIC_RESPONSE or (
			"Hei, aku Skenny! 😊 Aku adalah asisten kesehatan di aplikasi SKENNA yang khusus "
			"membantu kamu soal natrium dan hipertensi. Untuk pertanyaan di luar itu, "
			"aku belum bisa bantu ya. Tapi kalau kamu mau tahu soal kandungan natrium makanan, "
			"tips diet rendah garam, atau informasi seputar tekanan darah, aku siap bantu!"
		)

	@staticmethod
	def _general_health_fallback_prompt(question: str, user_context: str = "") -> str:
		user_context_text = user_context.strip() or "[PROFIL PENGGUNA]\nNama: Pengguna\n(Data profil belum diisi)"
		return (
			f"{ChatbotService.SKENNA_FOCUS_INSTRUCTION}\n"
			f"{ChatbotService.COMPLETE_SENTENCE_INSTRUCTION}\n"
			f"{ChatbotService.FOLLOW_UP_INSTRUCTION}\n"
			f"{ChatbotService.BOLD_FORMAT_INSTRUCTION}\n"
			f"\n{user_context_text}\n\n"
			f"{ChatbotService.USER_PROFILE_CONTEXT_INSTRUCTION}\n\n"
			"[[CONVERSATION_HISTORY]]\n\n"
			"Tidak ada chunk RAG relevan untuk pertanyaan ini, tetapi pertanyaan masih dalam ruang lingkup "
			"SKENNA: natrium, garam, gizi, hipertensi, tekanan darah, pola makan sehat, atau resep rendah natrium. "
			"Jawab dengan pengetahuan umum kesehatan yang aman dari Gemini. Jangan mengatakan bahwa referensi "
			"tidak cukup. Jangan diagnosis pasti atau memberi instruksi obat personal.\n\n"
			f"Pertanyaan user: {question}"
		)

	@staticmethod
	def _symptom_chat_prompt(question: str, user_context: str = "") -> str:
		user_context_text = user_context.strip() or "[PROFIL PENGGUNA]\nNama: Pengguna\n(Data profil belum diisi)"
		return (
			f"{ChatbotService.SKENNA_FOCUS_INSTRUCTION}\n"
			"Kamu adalah SKENNY, asisten kesehatan yang hangat dan empatik di aplikasi SKENNA. "
			"Respons dengan empati terlebih dahulu, lalu hubungkan secara natural dengan konteks "
			"natrium atau hipertensi jika relevan. Jangan self-diagnose. Gunakan frasa seperti "
			"'bisa jadi', 'salah satu penyebabnya bisa dari', atau 'perlu diwaspadai' bila sesuai. "
			f"{ChatbotService.COMPLETE_SENTENCE_INSTRUCTION} "
			f"{ChatbotService.BOLD_FORMAT_INSTRUCTION} "
			f"{ChatbotService.THREE_PARAGRAPH_INSTRUCTION}\n\n"
			f"{user_context_text}\n\n"
			f"{ChatbotService.USER_PROFILE_CONTEXT_INSTRUCTION}\n\n"
			"[[CONVERSATION_HISTORY]]\n\n"
			f"User menyampaikan keluhan: '{question}'."
		)

	@staticmethod
	def _small_talk_prompt(question: str, user_context: str = "") -> str:
		user_context_text = user_context.strip() or "[PROFIL PENGGUNA]\nNama: Pengguna\n(Data profil belum diisi)"
		return (
			"Kamu adalah SKENNY, friendly AI assistant di aplikasi kesehatan SKENNA.\n"
			"Mode: free chat.\n"
			"Personality: natural, warm, sedikit casual, cepat nyambung, dan tidak robotic.\n"
			"Jawab seperti teman yang pintar dan enak diajak ngobrol.\n"
			"Jangan membahas cara kerja internal aplikasi.\n"
			"Jangan menolak obrolan normal.\n"
			"Kalau user tanya 'kamu siapa?', jawab bahwa kamu SKENNY, teman untuk bantu soal makanan dan kesehatan.\n"
			"Kalau user cerita emosi atau keseharian, respons empatik dan boleh tanya follow-up singkat.\n"
			f"{ChatbotService.BOLD_FORMAT_INSTRUCTION}\n"
			f"{user_context_text}\n\n"
			f"{ChatbotService.USER_PROFILE_CONTEXT_INSTRUCTION}\n\n"
			"[[CONVERSATION_HISTORY]]\n\n"
			"Gunakan bahasa Indonesia natural. Jangan mulai dengan 'Berikut adalah'.\n\n"
			f"Pesan user: {question}"
		)

	@staticmethod
	def _with_substantive_instructions(prompt: str, user_context: str = "") -> str:
		user_context_text = user_context.strip()
		return (
			f"{ChatbotService.SKENNA_FOCUS_INSTRUCTION}\n"
			f"{ChatbotService.COMPLETE_SENTENCE_INSTRUCTION}\n"
			f"{ChatbotService.FOLLOW_UP_INSTRUCTION}\n"
			f"{ChatbotService.BOLD_FORMAT_INSTRUCTION}\n"
			f"{ChatbotService.THREE_PARAGRAPH_INSTRUCTION}\n\n"
			+ (
				f"{user_context_text}\n\n"
				f"{ChatbotService.USER_PROFILE_CONTEXT_INSTRUCTION}\n\n"
				"[[CONVERSATION_HISTORY]]\n\n"
				if user_context_text
				else ""
			)
			+ f"{prompt}"
		)

	@staticmethod
	def _education_state(db: Any, user_id: int, current_question: str) -> tuple[str, int]:
		topic = re.sub(
			r"\b(mulai|mode|edukasi|belajar|ajarin|materi|kelas)\b",
			" ",
			current_question,
			flags=re.IGNORECASE,
		).strip(" ,.;:-")
		if topic and current_question.lower().strip() not in ChatbotService.EDUCATION_CONTINUE_KEYWORDS:
			return topic, 1

		try:
			history = ChatRepository.list_chat(db, user_id)[:3]
		except Exception:
			return "natrium dan hipertensi", 1

		next_step = 1
		last_topic = "natrium dan hipertensi"
		for item in history:
			answer = item.answer or ""
			match = re.search(r"(?:poin\s+ke[-\s]*|edukasi\s+)(\d+)", answer, flags=re.IGNORECASE)
			if match:
				next_step = int(match.group(1)) + 1

			previous_question = ChatbotService._normalize_question(item.question or "")
			previous_intent = ChatbotService._classify_intent(previous_question)
			if previous_intent == ChatIntent.EDUCATION:
				previous_topic = re.sub(
					r"\b(mulai|mode|edukasi|belajar|ajarin|materi|kelas)\b",
					" ",
					previous_question,
					flags=re.IGNORECASE,
				).strip(" ,.;:-")
				last_topic = previous_topic or last_topic
				break
		return last_topic, min(max(next_step, 1), ChatbotService.EDUCATION_TOTAL_STEPS)

	@staticmethod
	def _education_step_prompt(question: str, context: str, topic: str, step: int, user_context: str = "") -> str:
		step = min(max(step, 1), ChatbotService.EDUCATION_TOTAL_STEPS)
		step_topic = ChatbotService.EDUCATION_STEP_TOPICS[step]
		user_context_text = user_context.strip() or "[PROFIL PENGGUNA]\nNama: Pengguna\n(Data profil belum diisi)"
		context_text = context.strip() or (
			"Tidak ada konteks RAG yang lolos filter relevansi. Jika topik masih seputar natrium, "
			"hipertensi, tekanan darah, gizi, pola makan sehat, atau resep rendah natrium, gunakan "
			"pengetahuan umum kesehatan yang aman. Jangan mengatakan referensi tidak cukup."
		)
		continuation_instruction = (
			"Akhiri dengan kalimat persis: 'Mau lanjut ke poin berikutnya? 😊'."
			if step < ChatbotService.EDUCATION_TOTAL_STEPS
			else "Ini poin terakhir. Jangan tulis 'Mau lanjut ke poin berikutnya?'. Akhiri dengan transisi singkat sebelum saran pertanyaan lanjutan."
		)
		continuation_instruction = "Akhiri dengan baris tombol persis: 'Lanjut →'."
		continuation_instruction = "Akhiri dengan baris tombol persis: 'Lanjut →'."
		if step >= ChatbotService.EDUCATION_TOTAL_STEPS:
			continuation_instruction = (
				"Jangan tulis 'Lanjut →'. Akhiri dengan satu pertanyaan interaktif untuk user, "
				"misalnya apakah user ingin mulai scan makanan dengan SKENNA."
			)
		continuation_instruction = (
			"Akhiri dengan baris tombol persis: 'Lanjut ->'."
			if step < ChatbotService.EDUCATION_TOTAL_STEPS
			else (
				"Jangan tulis 'Lanjut ->'. Akhiri dengan satu pertanyaan interaktif untuk user, "
				"misalnya apakah user ingin mulai scan makanan dengan SKENNA."
			)
		)
		return (
			f"Kamu adalah SKENNY. Buat HANYA bagian {step} dari 3 bagian edukasi. "
			f"Respons harus memakai judul persis sesuai spesifikasi bagian {step}. Jangan membahas bagian lain.\n\n"
			f"{ChatbotService.SKENNA_FOCUS_INSTRUCTION}\n"
			f"{ChatbotService.COMPLETE_SENTENCE_INSTRUCTION}\n"
			f"{ChatbotService.BOLD_FORMAT_INSTRUCTION}\n\n"
			f"{user_context_text}\n\n"
			f"{ChatbotService.USER_PROFILE_CONTEXT_INSTRUCTION}\n\n"
			"[[CONVERSATION_HISTORY]]\n\n"
			"Format respons WAJIB:\n"
			f"{step_topic}\n\n"
			"Gunakan struktur persis dari spesifikasi bagian di atas. Jangan gabungkan beberapa bagian dalam satu jawaban.\n\n"
			f"Pertanyaan user: {question}\n"
			f"Konteks RAG yang boleh dipakai:\n{context_text}\n\n"
			"Jika konteks RAG tersedia, prioritaskan konteks itu. Jika kosong, gunakan fallback kesehatan "
			"umum hanya untuk topik SKENNA. Untuk batas natrium, angka WHO/AKG/AHA dari spesifikasi bagian 3 "
			"adalah sumber kebenaran dan tidak boleh diubah.\n\n"
			f"Jangan jelaskan lebih dari 1 bagian per respons. {continuation_instruction}"
		)

	@staticmethod
	def _comparison_items_from_history(db: Any, user_id: int) -> list[Any]:
		try:
			items = HistoryRepository.list_intake(db, user_id)
		except Exception as exc:
			logger.warning("Failed to load comparison history for chatbot: %s", exc)
			return []
		comparison_items = [
			item
			for item in items
			if getattr(item, "intake_type", "") == "comparison"
			and getattr(item, "food_name", None)
			and getattr(item, "sodium_mg", None) is not None
		]
		return comparison_items[:5]

	@staticmethod
	def _requested_product_names(question: str) -> list[str]:
		cleaned = re.sub(
			r"\b(bandingkan|produk|compare|perbandingan|lebih baik mana|mana yang lebih)\b",
			" ",
			question,
			flags=re.IGNORECASE,
		)
		parts = re.split(r"\s+(?:dengan|dan|vs|versus)\s+|,", cleaned, flags=re.IGNORECASE)
		names = [re.sub(r"\s+", " ", part).strip(" .,:;-") for part in parts]
		return [name for name in names if len(name) >= 2]

	@staticmethod
	def _scan_product_name(scan: FoodLabelScan) -> str:
		if scan.nama_produk and scan.nama_produk.strip():
			return scan.nama_produk.strip()
		for pattern in [
			r"(?:nama produk|product name|produk)\s*[:\-]\s*([^\n]+)",
			r"source:\s*([^\n]+)",
		]:
			match = re.search(pattern, scan.raw_text or "", flags=re.IGNORECASE)
			if match:
				return match.group(1).strip()[:120]
		return f"Produk scan #{scan.id}"

	@staticmethod
	def _comparison_products_from_scans(db: Any, user_id: int, question: str) -> tuple[list[dict[str, Any]], list[str]]:
		requested_names = ChatbotService._requested_product_names(question)

		products: list[dict[str, Any]] = []
		missing: list[str] = []
		used_product_names: set[str] = set()

		if requested_names:
			for requested in requested_names:
				needle = requested.strip().lower()
				if not needle:
					missing.append(requested)
					continue
				try:
					print(f"[DEBUG] user_id={user_id}, needle={needle}")
					stmt = (
						select(FoodLabelScan)
						.where(FoodLabelScan.user_id == user_id)
						.where(
							or_(
								func.lower(FoodLabelScan.nama_produk).like(f"%{needle}%"),
								func.lower(FoodLabelScan.raw_text).like(f"%{needle}%"),
							)
						)
						.order_by(desc(FoodLabelScan.scanned_at))
					)
					scan_matches = list(db.scalars(stmt).all())
					intake_stmt = (
						select(IntakeHistory)
						.where(IntakeHistory.user_id == user_id)
						.where(func.lower(IntakeHistory.food_name).like(f"%{needle}%"))
						.order_by(desc(IntakeHistory.consumed_at))
					)
					intake_matches = list(db.scalars(intake_stmt).all())
				except Exception as exc:
					logger.warning("Failed to search products for comparison: %s", exc)
					scan_matches = []
					intake_matches = []
				candidates = [
					(
						scan.scanned_at,
						ChatbotService._scan_product_name(scan).lower(),
						ChatbotService._scan_to_comparison_product(scan),
					)
					for scan in scan_matches
				] + [
					(
						item.consumed_at,
						(item.food_name or "").strip().lower(),
						ChatbotService._intake_to_comparison_product(item),
					)
					for item in intake_matches
					if (item.food_name or "").strip()
				]
				candidates.sort(key=lambda item: item[0].timestamp() if item[0] else 0, reverse=True)
				best_product = next(
					(product for _, key, product in candidates if key and key not in used_product_names),
					None,
				)
				if best_product is None:
					missing.append(requested)
					continue
				used_product_names.add(str(best_product.get("name", "")).lower())
				products.append(best_product)
		else:
			try:
				scans = list(
					db.scalars(
						select(FoodLabelScan)
						.where(FoodLabelScan.user_id == user_id)
						.order_by(desc(FoodLabelScan.scanned_at))
						.limit(10)
					).all()
				)
				intake_items = list(
					db.scalars(
						select(IntakeHistory)
						.where(IntakeHistory.user_id == user_id)
						.where(IntakeHistory.food_name.is_not(None))
						.order_by(desc(IntakeHistory.consumed_at))
						.limit(10)
					).all()
				)
			except Exception as exc:
				logger.warning("Failed to load products for comparison: %s", exc)
				return [], requested_names
			candidates = [
				(scan.scanned_at, ChatbotService._scan_to_comparison_product(scan))
				for scan in scans
			] + [
				(item.consumed_at, ChatbotService._intake_to_comparison_product(item))
				for item in intake_items
				if (item.food_name or "").strip()
			]
			candidates.sort(key=lambda item: item[0].timestamp() if item[0] else 0, reverse=True)
			for _, product in candidates:
				key = str(product.get("name", "")).lower()
				if not key or key in used_product_names:
					continue
				used_product_names.add(key)
				products.append(product)
				if len(products) >= 10:
					break

		products.sort(key=lambda item: float(item.get("sodium_mg") or 0))
		return products, missing

	@staticmethod
	def _scan_to_comparison_product(scan: FoodLabelScan) -> dict[str, Any]:
		return {
			"name": ChatbotService._scan_product_name(scan),
			"sodium_mg": float(scan.sodium_mg or 0),
			"servings": int(scan.sajian_per_kemasan or 1),
			"serving_size": (
				f"{scan.takaran_saji or '-'} {scan.satuan_takaran or 'g'}"
			),
		}

	@staticmethod
	def _intake_to_comparison_product(item: IntakeHistory) -> dict[str, Any]:
		return {
			"name": (item.food_name or "").strip(),
			"sodium_mg": float(item.sodium_mg or 0),
			"servings": int(item.portions_in_package or item.servings or 1),
			"serving_size": (
				f"{item.package_ml or '-'} {item.satuan_takaran or 'g'}"
			),
		}

	@staticmethod
	def _comparison_prompt(question: str, context: str, items: list[Any], user_context: str = "") -> str:
		product_lines: list[str] = []
		for index, item in enumerate(items, start=1):
			if isinstance(item, dict):
				product_lines.append(
					f"{index}. {item.get('name')}: {float(item.get('sodium_mg') or 0):.0f} mg natrium, "
					f"sajian per kemasan {item.get('servings') or 1}, takaran saji {item.get('serving_size') or '-'}"
				)
				continue
			first_serving = (
				f"{getattr(item, 'package_ml', 0) or '-'} {getattr(item, 'satuan_takaran', 'g') or 'g'}, "
				f"{getattr(item, 'portions_in_package', 1) or 1} porsi"
			)
			product_lines.append(
				f"{index}. {item.food_name}: {float(item.sodium_mg or 0):.0f} mg natrium, "
				f"kategori {getattr(item, 'sodium_level', '-')}, info saji {first_serving}"
			)
			second_name = getattr(item, "product_name2", None)
			second_sodium = getattr(item, "sodium_mg2", None)
			if second_name and second_sodium is not None:
				second_serving = (
					f"{getattr(item, 'package_ml2', 0) or '-'} {getattr(item, 'satuan_takaran2', 'g') or 'g'}, "
					f"{getattr(item, 'portions_in_package2', 1) or 1} porsi"
				)
				product_lines.append(
					f"{index}. {second_name}: {float(second_sodium or 0):.0f} mg natrium, info saji {second_serving}"
				)
		context_text = context.strip() or (
			"Tidak ada konteks RAG yang lolos filter relevansi. Gunakan data produk user dan pengetahuan "
			"umum kesehatan yang aman seputar natrium/hipertensi bila diperlukan. Jangan mengatakan referensi tidak cukup."
		)
		return ChatbotService._with_substantive_instructions(
			"Bandingkan produk-produk berikut berdasarkan kandungan natriumnya:\n"
			+ "\n".join(product_lines)
			+ "\n\nFormat respons WAJIB persis seperti ini:\n\n"
			"Perbandingan Produk:\n\n"
			"| Produk | Natrium | % Batas Harian | Sajian/Kemasan |\n"
			"|--------|---------|----------------|----------------|\n"
			"| [A] | X mg | X% | X |\n"
			"| [B] | X mg | X% | X |\n"
			"| [C] | X mg | X% | X |\n\n"
			"✅ Rekomendasi: **[Produk]** paling rendah natrium dengan **X mg** per sajian.\n\n"
			"[1-2 kalimat penjelasan dengan bold angka penting]\n\n"
			"Aturan perbandingan: selalu sertakan kolom Sajian/Kemasan, urutkan baris dari natrium paling rendah ke paling tinggi, "
			"bold nama produk pemenang di rekomendasi, maksimal 2 kalimat untuk penjelasan, jangan gunakan bullet list. "
			"Gunakan batas harian **2.000 mg** untuk menghitung persentase jika batas personal user tidak tersedia. "
			f"{ChatbotService.BOLD_FORMAT_INSTRUCTION}\n\n"
			f"Pertanyaan user: {question}\n"
			f"Konteks RAG yang boleh dipakai:\n{context_text}\n\n"
			"Jika konteks RAG tersedia, prioritaskan konteks itu. Jika kosong, gunakan fallback kesehatan "
			"umum hanya untuk topik natrium/hipertensi dan data produk user.",
			user_context,
		)

	@staticmethod
	def _append_education_marker(answer: str, step: int) -> str:
		clean_answer = re.sub(
			r"\s*(?:\[SHOW_CONTINUE\]|\[EDUCATION_COMPLETE\]|\[SUGGEST_Q\].*?\[/SUGGEST_Q\])\s*$",
			"",
			answer.strip(),
			flags=re.DOTALL,
		)
		if step >= ChatbotService.EDUCATION_TOTAL_STEPS:
			clean_answer = re.sub(
				r"\n?\s*Lanjut\s*(?:->|[^\n]*)?\s*$",
				"",
				clean_answer,
				flags=re.IGNORECASE,
			).strip()
			return clean_answer
		return f"{clean_answer}\n\n{ChatbotService.SHOW_CONTINUE_MARKER}"

	@staticmethod
	def _clean_sources(sources: list[Any], max_items: int = 5) -> list[Any]:
		seen: set[str] = set()
		cleaned: list[Any] = []
		for source in sources:
			if isinstance(source, dict):
				title = re.sub(r"\s+", " ", str(source.get("title") or "")).strip()
				document_id = re.sub(r"\s+", " ", str(source.get("document_id") or "")).strip()
				key = f"{title}|{document_id}"
				if title and key not in seen:
					seen.add(key)
					cleaned.append(
						{
							"title": title,
							"topic": str(source.get("topic") or "hipertensi"),
							"document_id": document_id,
						}
					)
			else:
				normalized = re.sub(r"\s+", " ", str(source)).strip()
				if normalized and normalized not in seen:
					seen.add(normalized)
					cleaned.append(normalized)
			if len(cleaned) >= max_items:
				break
		return cleaned

	@staticmethod
	def _retrieve_context_safely(question: str) -> tuple[str, list[Any]]:
		try:
			return RAGService.retrieve_context(question)
		except Exception:
			return "", []

	@staticmethod
	def _finalize_answer(answer: str) -> str:
		marker = ""
		marker_match = re.search(
			r"\s*(\[SHOW_CONTINUE\]|\[EDUCATION_COMPLETE\]|\[SUGGEST_Q\].*?\[/SUGGEST_Q\])\s*$",
			answer.strip(),
			flags=re.DOTALL,
		)
		if marker_match:
			marker = marker_match.group(1)
			answer = answer[: marker_match.start()].strip()
		normalized_lines: list[str] = []
		for line in answer.splitlines():
			clean_line = re.sub(r"[ \t]+", " ", line).strip()
			if not clean_line:
				if normalized_lines and normalized_lines[-1] != "":
					normalized_lines.append("")
				continue
			normalized_lines.append(clean_line)
		while normalized_lines and normalized_lines[-1] == "":
			normalized_lines.pop()
		text = "\n".join(normalized_lines).strip()
		if not text:
			raise RuntimeError("Gemini returned an empty chatbot answer")
		if not re.search(r"[.!?]$", text):
			text = f"{text}."
		if marker:
			text = f"{text}\n\n{marker}"
		return text

	@staticmethod
	def _run_async(coro: Any) -> Any:
		try:
			asyncio.get_running_loop()
		except RuntimeError:
			return asyncio.run(coro)

		result: dict[str, Any] = {}

		def runner() -> None:
			try:
				result["value"] = asyncio.run(coro)
			except Exception as exc:
				result["error"] = exc

		thread = threading.Thread(target=runner)
		thread.start()
		thread.join()
		if "error" in result:
			raise result["error"]
		return result.get("value")

	@staticmethod
	def _format_rekomendasi_chat_response(result: dict[str, Any], kategori: ProductCategory) -> str:
		items = result.get("rekomendasi") or []
		if not items:
			tips = result.get("tips") or (
				"Belum ada rekomendasi produk yang cukup cocok untuk kategori ini. "
				"Tetap cek label dan pilih natrium yang lebih rendah per sajian."
			)
			return (
				f"Aku belum menemukan alternatif produk yang valid untuk kategori **{kategori.value}**.\n\n"
				f"{tips}\n\n"
				"||FOLLOWUP||Mau aku bantu jelaskan cara memilih produk sejenis yang lebih rendah natrium?"
			)

		lines = [
			"Aku carikan opsi yang lebih rendah natrium dengan filter kategori yang sama dulu."
		]
		disclaimer = result.get("disclaimer")
		if result.get("is_fallback") and disclaimer:
			lines.append(str(disclaimer))
		lines.append("")

		for item in items:
			name = str(item.get("nama_produk") or "Produk alternatif").strip()
			sodium = item.get("sodium_per_sajian_mg")
			reason = str(item.get("alasan") or "Pilihan ini relatif lebih rendah natrium.").strip()
			category = str(item.get("kategori") or kategori.value)
			lines.append(
				f"- **{name}** ({category}) - **{sodium} mg natrium/sajian**. {reason}"
			)

		lines.append("")
		lines.append("Tetap cek label kemasan ya, karena angka natrium bisa berbeda antar varian dan ukuran.")
		lines.append("")
		lines.append("||FOLLOWUP||Mau aku bantu bandingkan salah satu opsi ini dengan produk yang kamu scan?")
		return "\n".join(lines)

	@staticmethod
	def answer(
		question: str,
		db: Any = None,
		user_id: int | None = None,
		education_part: int | None = None,
		kategori: ProductCategory | None = None,
		product_name: str | None = None,
		sodium_mg: int | None = None,
		scan_id: int | None = None,
	) -> tuple[str, list[Any]]:
		normalized_question = ChatbotService._normalize_question(question)
		if not normalized_question:
			normalized_question = "halo"

		user_name = ChatbotService._user_display_name(db, user_id)
		history = ChatbotService._conversation_history(db, user_id)
		user_context = ChatbotPersonalizationService.build_user_context(db, user_id)
		has_health_context = ChatbotService._has_health_context(history)
		is_context_reply = ChatbotService._is_direct_reply_in_context(normalized_question, history)
		intent = ChatbotService._classify_intent(normalized_question)
		if intent == ChatIntent.GREETING:
			return ChatbotService._friendly_greeting(user_name), []
		if intent == ChatIntent.PRODUCT_RECOMMENDATION:
			if kategori is not None and sodium_mg is not None:
				logger.info(
					"Using structured recommendation path for chatbot: user_id=%s scan_id=%s kategori=%s sodium_mg=%s",
					user_id,
					scan_id,
					kategori.value,
					sodium_mg,
				)
				rekomendasi_result = ChatbotService._run_async(
					get_rekomendasi(
						kategori,
						int(sodium_mg),
						user_id=user_id,
						db=db,
						product_name=product_name,
						jumlah=3,
					)
				)
				answer = ChatbotService._format_rekomendasi_chat_response(
					rekomendasi_result,
					kategori,
				)
				return ChatbotService._finalize_answer(answer), []

			logger.info(
				"Using legacy prompt-based product recommendation path for chatbot: user_id=%s has_kategori=%s has_sodium=%s",
				user_id,
				kategori is not None,
				sodium_mg is not None,
			)
			prompt = ChatbotPersonalizationService.product_recommendation_prompt(
				question,
				user_context,
			)
			prompt = ChatbotService._with_conversation_history(prompt, history)
			answer = ChatbotService._call_gemini(GeminiService.generate_chat, prompt, max_tokens=2048)
			return ChatbotService._finalize_answer(answer), []
		if intent == ChatIntent.COMPARISON:
			if db is None or user_id is None:
				return (
					"Aku butuh data user yang sedang login untuk membandingkan produk dari riwayat scan kamu."
				), []
			comparison_items, missing_products = ChatbotService._comparison_products_from_scans(
				db,
				user_id,
				normalized_question,
			)
			if not comparison_items:
				if missing_products:
					missing_text = ", ".join(missing_products)
					return (
						f"Aku belum menemukan produk **{missing_text}** di riwayat scan kamu. "
						"Coba scan produknya dulu atau tulis nama produk yang sudah pernah kamu scan."
					), []
				return (
					"Coba scan dulu ya lewat fitur kamera di SKENNA! ðŸ“·"
				), []
			prompt = ChatbotService._comparison_prompt(normalized_question, "", comparison_items, user_context)
			if missing_products:
				prompt += (
					"\n\nProduk yang diminta tapi tidak ditemukan di food_label_scan user ini: "
					+ ", ".join(missing_products)
					+ ". Sebutkan daftar ini dengan jelas, lalu bandingkan hanya produk yang ditemukan."
				)
			prompt = ChatbotService._with_conversation_history(prompt, history)
			answer = ChatbotService._call_gemini(
				GeminiService.generate_reasoning,
				prompt,
				max_tokens=2048,
				fallback_fn=GeminiService.generate_chat,
			)
			return ChatbotService._finalize_answer(answer), []
		if intent in {ChatIntent.EDUCATION, ChatIntent.EDUCATION_CONTINUE}:
			context, sources = ChatbotService._retrieve_context_safely(normalized_question)
			clean_sources = ChatbotService._clean_sources(sources)
			topic, step = (
				ChatbotService._education_state(db, user_id, normalized_question)
				if db is not None and user_id is not None
				else (normalized_question, 1)
			)
			if education_part is not None:
				step = min(max(int(education_part), 1), ChatbotService.EDUCATION_TOTAL_STEPS)
			prompt = ChatbotService._education_step_prompt(normalized_question, context, topic, step, user_context)
			prompt = ChatbotService._with_conversation_history(prompt, history)
			answer = ChatbotService._call_gemini(
				GeminiService.generate_reasoning,
				prompt,
				max_tokens=2048,
				fallback_fn=GeminiService.generate_chat,
			)
			answer = ChatbotService._append_education_marker(answer, step)
			return ChatbotService._finalize_answer(answer), clean_sources
		if intent == ChatIntent.OUT_OF_SCOPE and not has_health_context and not is_context_reply:
			return ChatbotService._out_of_scope_response(user_context), []
		if intent == ChatIntent.SYMPTOM_CHAT:
			prompt = ChatbotService._with_conversation_history(
				ChatbotService._symptom_chat_prompt(normalized_question, user_context),
				history,
			)
			answer = ChatbotService._call_gemini(GeminiService.generate_chat, prompt, max_tokens=2048)
			return ChatbotService._finalize_answer(answer), []
		if intent == ChatIntent.SMALL_TALK:
			if (
				ChatbotService._is_clearly_out_of_scope(normalized_question)
				and not has_health_context
				and not is_context_reply
				or (
					not ChatbotService._is_small_talk_message(normalized_question)
					and not ChatbotService._is_allowed_health_fallback_topic(normalized_question)
					and not has_health_context
					and not is_context_reply
				)
			):
				return ChatbotService._out_of_scope_response(user_context), []
			prompt = ChatbotService._with_conversation_history(
				ChatbotService._small_talk_prompt(normalized_question, user_context),
				history,
			)
			answer = ChatbotService._call_gemini(GeminiService.generate_chat, prompt, max_tokens=2048)
			return ChatbotService._finalize_answer(answer), []

		context, sources = ChatbotService._retrieve_context_safely(normalized_question)
		clean_sources = ChatbotService._clean_sources(sources)
		if (
			not context
			and not ChatbotService._is_allowed_health_fallback_topic(normalized_question)
			and not has_health_context
			and not is_context_reply
			and intent not in {ChatIntent.COMPARISON, ChatIntent.EDUCATION, ChatIntent.EDUCATION_CONTINUE}
		):
			return ChatbotService._out_of_scope_response(user_context), []

		if db is not None and user_id is not None and ChatbotPersonalizationService.can_handle(normalized_question):
			personal_prompt = ChatbotPersonalizationService.build_prompt(
				db,
				user_id,
				normalized_question,
				context,
				user_context,
			)
			if "rekap" not in normalized_question and "natrium hari ini" not in normalized_question:
				personal_prompt = ChatbotService._with_substantive_instructions(personal_prompt, user_context)
			personal_prompt = ChatbotService._with_conversation_history(personal_prompt, history)
			if intent in {ChatIntent.EDUCATION, ChatIntent.COMPARISON}:
				answer = ChatbotService._call_gemini(
					GeminiService.generate_reasoning,
					personal_prompt,
					max_tokens=2048,
					fallback_fn=GeminiService.generate_chat,
				)
			else:
				answer = ChatbotService._call_gemini(GeminiService.generate_chat, personal_prompt, max_tokens=2048)
			return ChatbotService._finalize_answer(answer), clean_sources

		prompt = (
			ChatbotService._general_health_fallback_prompt(normalized_question, user_context)
			if not context
			else build_indonesian_rag_prompt(normalized_question, context, user_context)
		)
		prompt = ChatbotService._with_conversation_history(prompt, history)
		answer = ChatbotService._call_gemini(GeminiService.generate_chat, prompt, max_tokens=2048)
		return ChatbotService._finalize_answer(answer), clean_sources
