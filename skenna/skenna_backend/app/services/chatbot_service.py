import re

from app.core.config import settings
from .rag_service import RAGService
from skenna_python.rag.src.llm_client import generate_with_gemini
from skenna_python.rag.src.prompt_builder import build_indonesian_rag_prompt


class ChatbotService:
	TYPO_PATTERNS: list[tuple[re.Pattern[str], str]] = [
		(re.compile(r"\bntrium\b", re.IGNORECASE), "natrium"),
		(re.compile(r"\bnatriun\b", re.IGNORECASE), "natrium"),
		(re.compile(r"\bhipertnsi\b", re.IGNORECASE), "hipertensi"),
		(re.compile(r"\bhipertensi\b", re.IGNORECASE), "hipertensi"),
		(re.compile(r"\bgrm\b", re.IGNORECASE), "garam"),
		(re.compile(r"\btd\b", re.IGNORECASE), "tekanan darah"),
		(re.compile(r"\bbrp\b", re.IGNORECASE), "berapa"),
	]

	QUESTION_WORDS = {
		"apa",
		"berapa",
		"bagaimana",
		"kenapa",
		"kapan",
		"dimana",
		"siapa",
		"gimana",
		"bisa",
		"cek",
		"ceknya",
		"boleh",
		"bahaya",
		"batas",
		"contoh",
		"cara",
	}

	HEALTH_KEYWORDS = [
		"natrium",
		"sodium",
		"garam",
		"hipertensi",
		"tekanan darah",
		"cek",
		"ceknya",
		"diet",
		"resep",
		"menu",
		"masak",
		"makanan",
		"jantung",
		"ginjal",
		"obat",
		"stroke",
	]

	TRUNCATED_ENDINGS = {
		"dan",
		"atau",
		"kalau",
		"jika",
		"untuk",
		"dengan",
		"karena",
		"agar",
		"supaya",
	}

	SERIOUS_KEYWORDS = [
		"nyeri dada",
		"sesak",
		"pingsan",
		"kejang",
		"lemah sebelah",
		"bicara pelo",
		"mati rasa",
		"penurunan kesadaran",
		"ig d",
		"igd",
	]

	IDENTITY_KEYWORDS = [
		"kamu siapa",
		"siapa kamu",
		"kenalkan dirimu",
		"kenalin diri",
		"perkenalkan diri",
	]

	@staticmethod
	def _normalize_question(question: str) -> str:
		normalized = question.strip()
		for pattern, replacement in ChatbotService.TYPO_PATTERNS:
			normalized = pattern.sub(replacement, normalized)
		return re.sub(r"\s+", " ", normalized).strip()

	@staticmethod
	def _is_greeting(question: str) -> bool:
		q = question.lower().strip()
		return bool(re.fullmatch(r"(halo|hai|hi|hey|helo|p|woy|woi)[!. ]*", q))

	@staticmethod
	def _is_unclear(question: str) -> bool:
		tokens = re.findall(r"[a-zA-Z]+", question.lower())
		if not tokens:
			return True
		if len(tokens) == 1 and tokens[0] in {"natrium", "garam", "hipertensi", "sodium", "tekanan", "darah"}:
			return True
		has_question_mark = "?" in question
		if len(tokens) <= 2 and not has_question_mark and not any(
			token in ChatbotService.QUESTION_WORDS for token in tokens
		):
			return True
		return False

	@staticmethod
	def _is_identity_question(question: str) -> bool:
		q = question.lower().strip()
		return any(keyword in q for keyword in ChatbotService.IDENTITY_KEYWORDS)

	@staticmethod
	def _identity_response() -> str:
		return (
			"Aku Skenny 😊\n"
			"Teman virtual kamu di Skenna. Aku siap bantu soal natrium, makanan sehat, tekanan darah, "
			"dan kalau mau ngobrol santai juga boleh 👍"
		)

	@staticmethod
	def _can_use_gemini() -> bool:
		return settings.llm_provider.lower() == "gemini" and bool(settings.llm_api_key.strip())

	@staticmethod
	def _general_gemini_answer(question: str) -> str | None:
		if not ChatbotService._can_use_gemini():
			return None
		prompt = (
			"Kamu adalah Skenny, teman virtual yang ramah. "
			"Jawab pertanyaan user dengan natural, singkat, jelas, bahasa Indonesia sederhana, dan boleh emoji secukupnya.\n"
			"Kalau pertanyaan berkaitan kesehatan, arahkan ke saran aman dan jangan diagnosis pasti.\n"
			f"Pertanyaan user: {question}"
		)
		try:
			return generate_with_gemini(prompt, settings.llm_api_key, settings.llm_model)
		except Exception:
			return None

	@staticmethod
	def _is_health_related(question: str) -> bool:
		q = question.lower()
		return any(keyword in q for keyword in ChatbotService.HEALTH_KEYWORDS)

	@staticmethod
	def _is_serious_medical(question: str) -> bool:
		q = question.lower()
		return any(keyword in q for keyword in ChatbotService.SERIOUS_KEYWORDS)

	@staticmethod
	def _intent(question: str) -> str:
		q = question.lower()
		if any(keyword in q for keyword in ["resep", "menu", "masak", "sarapan", "makan siang", "makan malam"]):
			return "recipe"
		if any(keyword in q for keyword in ["dash", "diet", "makanan", "garam", "natrium", "sodium"]):
			return "diet"
		if any(keyword in q for keyword in ["diagnosis", "pemeriksaan", "cek", "tekanan darah"]):
			return "diagnosis"
		if any(keyword in q for keyword in ["obat", "pengobatan", "terapi"]):
			return "treatment"
		if any(keyword in q for keyword in ["gejala", "tanda", "keluhan"]):
			return "symptom"
		if any(keyword in q for keyword in ["komplikasi", "risiko", "bahaya"]):
			return "complication"
		if any(keyword in q for keyword in ["pencegahan", "mencegah", "prevent"]):
			return "prevention"
		if any(keyword in q for keyword in ["darurat", "emergency", "igd"]):
			return "emergency"
		return "general"

	@staticmethod
	def _answer_by_intent(intent: str) -> str:
		answers = {
			"recipe": (
				"Ini contoh resep rendah garam untuk hipertensi yang bisa langsung dicoba:\n"
				"Nama menu: Tumis Tahu Brokoli Rendah Garam\n"
				"Bahan: tahu putih 150 g, brokoli 100 g, wortel 1/2 buah, bawang putih 2 siung,\n"
				"1 sdt minyak zaitun, lada/jeruk nipis secukupnya (tanpa garam tambahan).\n"
				"Langkah: tumis bawang dengan minyak, masukkan tahu, brokoli, wortel, tambah sedikit air,\n"
				"masak 4-5 menit sampai matang, lalu bumbui lada dan jeruk nipis."
			),
			"diet": (
				"Sejauh yang aku tahu, pola makan sehat untuk tekanan darah itu fokus ke makanan segar, sayur, buah, "
				"dan kurangi makanan olahan yang tinggi garam."
			),
			"diagnosis": (
				"Sejauh yang aku tahu, hipertensi biasanya dinilai dari pengukuran tekanan darah berulang, bukan sekali cek saja."
			),
			"treatment": (
				"Sejauh yang aku tahu, penanganan hipertensi biasanya kombinasi perubahan gaya hidup dan obat sesuai anjuran dokter."
			),
			"symptom": (
				"Sejauh yang aku tahu, hipertensi sering tidak terasa gejalanya, jadi cek tekanan darah rutin itu penting."
			),
			"complication": (
				"Sejauh yang aku tahu, hipertensi yang tidak terkontrol bisa meningkatkan risiko stroke, gangguan jantung, dan ginjal."
			),
			"prevention": (
				"Sejauh yang aku tahu, pencegahan terbaik itu batasi natrium, aktif gerak, jaga berat badan, dan rutin cek tekanan darah."
			),
			"emergency": (
				"Kalau tekanannya sangat tinggi dan ada gejala berat seperti nyeri dada, sesak, atau lemah sebelah, "
				"itu kondisi darurat dan perlu segera ke IGD."
			),
			"general": (
				"Sejauh yang aku tahu, kunci menjaga tekanan darah itu ada di pola makan, aktivitas fisik, dan konsistensi kontrol."
			),
		}
		return answers[intent]

	@staticmethod
	def _practical_points(intent: str) -> list[str]:
		points = {
			"recipe": [
				"Gunakan bumbu alami seperti bawang, lada, jahe, kunyit, dan perasan lemon sebagai pengganti garam.",
				"Jika mau, aku bisa buatkan 7 menu resep hipertensi untuk 1 minggu (sarapan-siang-malam).",
			],
			"diet": [
				"Utamakan makanan segar dan minim olahan.",
				"Batasi garam dapur, bumbu tinggi natrium, dan makanan kemasan.",
			],
			"diagnosis": [
				"Lakukan pengukuran tekanan darah berulang dengan teknik yang benar.",
				"Catat hasil pengukuran untuk evaluasi klinis lanjutan.",
			],
			"treatment": [
				"Kombinasikan perubahan gaya hidup dan terapi obat sesuai evaluasi dokter.",
				"Lakukan pemantauan rutin untuk menilai kontrol tekanan darah.",
			],
			"symptom": [
				"Jangan menunggu gejala untuk mulai skrining hipertensi.",
				"Segera evaluasi bila muncul gejala berat yang mendadak.",
			],
			"complication": [
				"Kontrol tekanan darah menurunkan risiko stroke dan penyakit jantung.",
				"Pantau faktor risiko lain seperti diabetes dan gangguan ginjal.",
			],
			"prevention": [
				"Pertahankan aktivitas fisik rutin dan berat badan sehat.",
				"Kurangi natrium, hindari rokok, dan batasi alkohol.",
			],
			"emergency": [
				"Jika ada gejala neurologis atau nyeri dada akut, segera ke IGD.",
				"Hindari menunda penanganan dengan pengobatan mandiri.",
			],
			"general": [
				"Fokus pada deteksi dini, kontrol faktor risiko, dan terapi teratur.",
				"Ajukan pertanyaan yang lebih spesifik agar rekomendasi lebih tepat.",
			],
		}
		return points[intent]

	@staticmethod
	def _format_natural_answer(summary: str, points: list[str]) -> str:
		return "\n".join([summary, f"- {points[0]}", f"- {points[1]}"])

	@staticmethod
	def _is_recipe_formatted(answer: str) -> bool:
		lowered = answer.lower()
		return "bahan" in lowered and "langkah" in lowered

	@staticmethod
	def _finalize_answer(answer: str) -> str:
		"""Normalize LLM output so user does not receive hanging/incomplete sentences."""
		lines = [re.sub(r"[ \t]+", " ", line).strip() for line in answer.splitlines()]
		text = "\n".join(line for line in lines if line).strip()
		if not text:
			return ""

		last_word_match = re.search(r"([A-Za-zÀ-ÿ]+)$", text)
		last_word = last_word_match.group(1).lower() if last_word_match else ""

		if last_word in ChatbotService.TRUNCATED_ENDINGS:
			text = f"{text}. Kamu mau aku lanjutkan dengan versi lengkapnya?"
		elif not re.search(r"[.!?…]$", text):
			text = f"{text}."

		return text

	@staticmethod
	def _context_hint(context: str, limit: int = 220) -> str:
		plain = re.sub(r"\[SKOR\s+[0-9.]+\]\s*", "", context)
		plain = re.sub(r"\s+", " ", plain).strip()
		if not plain:
			return ""
		if len(plain) <= limit:
			return plain
		trimmed = plain[:limit]
		if " " in trimmed:
			trimmed = trimmed.rsplit(" ", 1)[0]
		return f"{trimmed}..."

	@staticmethod
	def _clarification_prompt(question: str) -> str:
		q = question.lower()
		if "natrium" in q or "garam" in q or "sodium" in q:
			return "Maksudnya konsumsi harian atau dari makanan tertentu ya?"
		if "tekanan darah" in q or "hipertensi" in q:
			return "Maksudnya kamu mau bahas gejala, batas normal, atau cara ngontrolnya ya?"
		return "Boleh diperjelas sedikit pertanyaannya biar aku bisa jawab lebih pas?"

	@staticmethod
	def _clean_sources(sources: list[str], max_items: int = 5) -> list[str]:
		seen: set[str] = set()
		cleaned: list[str] = []
		for source in sources:
			normalized = re.sub(r"\s+", " ", source).strip()
			if normalized and normalized not in seen:
				seen.add(normalized)
				cleaned.append(normalized)
			if len(cleaned) >= max_items:
				break
		return cleaned

	@staticmethod
	def answer(question: str) -> tuple[str, list[str]]:
		normalized_question = ChatbotService._normalize_question(question)
		is_serious = ChatbotService._is_serious_medical(normalized_question)

		if ChatbotService._is_greeting(normalized_question):
			return (
				"Halo! Aku Skenny 😊\n"
				"Aku bisa bantu kamu soal natrium, makanan, atau tekanan darah.\n"
				"Mau tanya apa hari ini?",
				[],
			)

		if ChatbotService._is_identity_question(normalized_question):
			return ChatbotService._identity_response(), []

		if ChatbotService._is_unclear(normalized_question):
			return ChatbotService._clarification_prompt(normalized_question), []

		if not ChatbotService._is_health_related(normalized_question) and not is_serious:
			general_answer = ChatbotService._general_gemini_answer(normalized_question)
			if general_answer:
				return general_answer, []
			return (
				"Aku lebih fokus ke kesehatan dan natrium sih 😊\n"
				"Mau tanya soal makanan atau tekanan darah mungkin?",
				[],
			)

		context, sources = RAGService.retrieve_context(normalized_question)
		clean_sources = ChatbotService._clean_sources(sources)

		intent = ChatbotService._intent(normalized_question)
		answer: str | None = None
		if clean_sources and ChatbotService._can_use_gemini():
			prompt = build_indonesian_rag_prompt(normalized_question, context)
			try:
				answer = generate_with_gemini(prompt, settings.llm_api_key, settings.llm_model)
			except Exception:
				# Fall back to deterministic template if Gemini call fails.
				answer = None

		if not answer:
			context_hint = ChatbotService._context_hint(context) if clean_sources else ""
			if intent == "recipe":
				answer = ChatbotService._answer_by_intent(intent)
				if clean_sources:
					answer = (
						f"{answer}\n\n"
						f"Referensi terkait: {', '.join(clean_sources[:2])}."
					)
			else:
				summary = (
					f"Dari sumber yang aku punya, intinya {context_hint}"
					if context_hint
					else ChatbotService._answer_by_intent(intent)
				)
				points = ChatbotService._practical_points(intent)
				answer = ChatbotService._format_natural_answer(summary, points)

		if intent == "recipe" and not ChatbotService._is_recipe_formatted(answer):
			answer = ChatbotService._answer_by_intent("recipe")
			if clean_sources:
				answer = (
					f"{answer}\n\n"
					f"Referensi terkait: {', '.join(clean_sources[:2])}."
				)

		answer = ChatbotService._finalize_answer(answer)

		if is_serious and "sebaiknya cek ke dokter" not in answer.lower():
			answer = f"{answer}\n\nKalau sudah mengarah ke kondisi serius, sebaiknya cek ke dokter ya 🙏"

		return answer, clean_sources

