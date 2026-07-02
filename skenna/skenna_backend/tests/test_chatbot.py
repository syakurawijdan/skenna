from app.services.chatbot_service import ChatbotService


class _HistoryTurn:
	def __init__(self, question: str, answer: str) -> None:
		self.question = question
		self.answer = answer


def test_chatbot_greeting_does_not_use_rag(monkeypatch) -> None:
	def fail_retrieve(_: str):
		raise AssertionError("Greeting should not use RAG")

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fail_retrieve)

	answer, sources = ChatbotService.answer("halo")

	assert answer == (
		"Halo, teman! Saya Skenny, asisten kesehatan kamu di SKENNA. "
		"Ada yang bisa saya bantu seputar natrium atau hipertensi?"
	)
	assert sources == []


def test_chatbot_small_talk_uses_gemini_without_rag(monkeypatch) -> None:
	captured: dict[str, str] = {}

	def fail_retrieve(_: str):
		raise AssertionError("Small talk should not use RAG")

	def fake_generate_chat(prompt: str, **_: object) -> str:
		captured["prompt"] = prompt
		return "Aku baik nih, kamu gimana?"

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fail_retrieve)
	monkeypatch.setattr("app.services.chatbot_service.GeminiService.generate_chat", fake_generate_chat)

	answer, sources = ChatbotService.answer("apa kabar?")

	assert "friendly ai assistant" in captured["prompt"].lower()
	assert "baik" in answer.lower()
	assert sources == []


def test_chatbot_small_talk_refuses_unrelated_general_question(monkeypatch) -> None:
	def fail_generate_chat(*_: object, **__: object) -> str:
		raise AssertionError("Off-topic small talk should not call Gemini")

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", lambda _: ("", []))
	monkeypatch.setattr("app.services.chatbot_service.GeminiService.generate_chat", fail_generate_chat)

	answer, sources = ChatbotService.answer("jelaskan geografi eropa")

	assert answer == (
		"Hei, aku Skenny! Aku asisten kesehatan yang fokus pada natrium dan hipertensi. "
		"Untuk pertanyaan di luar itu, aku belum bisa bantu ya."
	)
	assert sources == []


def test_chatbot_emotional_chat_uses_free_chat(monkeypatch) -> None:
	def fail_retrieve(_: str):
		raise AssertionError("Emotional chat should not use RAG")

	def fake_generate_chat(prompt: str, **_: object) -> str:
		return "Capek ya, hari ini ngapain aja sampai rasanya berat?"

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fail_retrieve)
	monkeypatch.setattr("app.services.chatbot_service.GeminiService.generate_chat", fake_generate_chat)

	answer, sources = ChatbotService.answer("capek banget hari ini")

	assert "capek" in answer.lower()
	assert sources == []


def test_chatbot_rag_to_gemini_flow_uses_context_when_available(monkeypatch) -> None:
	captured: dict[str, str] = {}

	def fake_retrieve_context(question: str):
		captured["question"] = question
		return (
			"[SKOR 0.91] Batasi natrium untuk membantu kontrol tekanan darah.",
			[
				{"title": "Paper A", "topic": "hipertensi", "document_id": "A"},
				{"title": "Paper A", "topic": "hipertensi", "document_id": "A"},
				{"title": "Paper B", "topic": "hipertensi", "document_id": "B"},
			],
		)

	def fake_generate_chat(prompt: str, **_: object) -> str:
		captured["prompt"] = prompt
		return "Oke, aku bantu jelasin ya. Mengurangi natrium bisa membantu tekanan darah lebih terkontrol."

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fake_retrieve_context)
	monkeypatch.setattr("app.services.chatbot_service.GeminiService.generate_chat", fake_generate_chat)

	answer, sources = ChatbotService.answer("brp batas ntrium")

	assert captured["question"] == "berapa batas natrium"
	assert "Konteks RAG yang boleh dipakai" in captured["prompt"]
	assert "Jawab HANYA dari konteks RAG" in captured["prompt"]
	assert "Mengurangi natrium" in answer
	assert len(sources) == 2


def test_chatbot_normalizes_more_typos_before_rag(monkeypatch) -> None:
	captured: dict[str, str] = {}

	def fake_retrieve_context(question: str):
		captured["question"] = question
		return "[SKOR 0.91] Natrium perlu dibatasi.", []

	def fake_generate_chat(prompt: str, **_: object) -> str:
		captured["prompt"] = prompt
		return "Oke, natrium memang perlu diperhatikan."

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fake_retrieve_context)
	monkeypatch.setattr("app.services.chatbot_service.GeminiService.generate_chat", fake_generate_chat)

	ChatbotService.answer("Knp natirum dan sodiumm bahaya?")

	assert captured["question"] == "kenapa natrium dan sodium bahaya?"


def test_chatbot_medical_mode_uses_general_health_fallback_when_rag_empty(monkeypatch) -> None:
	captured: dict[str, str] = {}

	def fake_retrieve_context(question: str):
		captured["question"] = question
		return "", []

	def fake_generate_chat(prompt: str, **_: object) -> str:
		captured["prompt"] = prompt
		return "Natrium tetap perlu dibatasi karena bisa memengaruhi tekanan darah."

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fake_retrieve_context)
	monkeypatch.setattr("app.services.chatbot_service.GeminiService.generate_chat", fake_generate_chat)

	answer, sources = ChatbotService.answer("kenapa natrium tinggi bahaya?")

	assert "Tidak ada chunk RAG relevan" in captured["prompt"]
	assert "pengetahuan umum kesehatan yang aman" in captured["prompt"]
	assert "Jangan mengatakan bahwa referensi" in captured["prompt"]
	assert "Natrium" in answer
	assert sources == []


def test_chatbot_includes_conversation_history_in_gemini_prompt(monkeypatch) -> None:
	captured: dict[str, str] = {}

	def fail_retrieve_context(_: str) -> tuple[str, list[object]]:
		raise AssertionError("Contextual short replies should not require RAG")

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fail_retrieve_context)
	monkeypatch.setattr(
		"app.services.chatbot_service.ChatRepository.list_recent_pairs",
		lambda *_, **__: [_HistoryTurn("Apa batas natrium?", "Batas umum WHO adalah 2000 mg per hari.")],
	)

	def fake_generate_chat(prompt: str, **_: object) -> str:
		captured["prompt"] = prompt
		return "Kalau begitu, pilih makanan yang lebih rendah natrium dulu."

	monkeypatch.setattr("app.services.chatbot_service.GeminiService.generate_chat", fake_generate_chat)

	answer, sources = ChatbotService.answer("yang ini gimana?", db=object(), user_id=7)

	assert "Riwayat percakapan sejauh ini" in captured["prompt"]
	assert "Apa batas natrium?" in captured["prompt"]
	assert "Batas umum WHO" in captured["prompt"]
	assert "rendah natrium" in answer.lower()
	assert sources == []


def test_topic_guard_allows_short_reply_in_health_context(monkeypatch) -> None:
	captured: dict[str, str] = {}

	def fail_retrieve_context(_: str) -> tuple[str, list[object]]:
		raise AssertionError("Health-context short replies should not require RAG")

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fail_retrieve_context)
	monkeypatch.setattr(
		"app.services.chatbot_service.ChatRepository.list_recent_pairs",
		lambda *_, **__: [_HistoryTurn("Mau masak rendah natrium?", "Apa bahan yang ada di kulkas kamu?")],
	)

	def fake_generate_chat(prompt: str, **_: object) -> str:
		captured["prompt"] = prompt
		return "Kentang dan telur bisa dibuat menu sederhana yang lebih rendah garam."

	monkeypatch.setattr("app.services.chatbot_service.GeminiService.generate_chat", fake_generate_chat)

	answer, sources = ChatbotService.answer("kentang telur", db=object(), user_id=7)

	assert "kentang telur" in captured["prompt"]
	assert "rendah garam" in answer.lower()
	assert sources == []


def test_chatbot_medical_mode_answers_when_rag_fails(monkeypatch) -> None:
	def fail_retrieve(_: str):
		raise RuntimeError("temporary retrieval failure")

	def fake_generate_chat(prompt: str, **_: object) -> str:
		return "Oke, aku bantu jelasin singkat. Natrium berlebih bisa membuat tekanan darah lebih sulit terkontrol."

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fail_retrieve)
	monkeypatch.setattr("app.services.chatbot_service.GeminiService.generate_chat", fake_generate_chat)

	answer, sources = ChatbotService.answer("apa efek sodium berlebih?")

	assert "Natrium" in answer or "sodium" in answer.lower()
	assert sources == []


def test_chatbot_personalized_flow_uses_gemini_prompt(monkeypatch) -> None:
	captured: dict[str, str] = {}

	def fake_retrieve_context(question: str):
		captured["question"] = question
		return "[SKOR 0.88] Natrium perlu dipantau harian.", []

	def fake_build_prompt(db, user_id: int, question: str, context: str, user_context: str = "") -> str:
		captured["user_id"] = str(user_id)
		captured["context"] = context
		captured["user_context"] = user_context
		return f"PROMPT PERSONAL: {question}"

	def fake_generate_chat(prompt: str, **_: object) -> str:
		captured["prompt"] = prompt
		return "Hari ini natriummu masih bisa dipantau dengan tenang."

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fake_retrieve_context)
	monkeypatch.setattr("app.services.chatbot_service.ChatbotPersonalizationService.can_handle", lambda _: True)
	monkeypatch.setattr("app.services.chatbot_service.ChatbotPersonalizationService.build_prompt", fake_build_prompt)
	monkeypatch.setattr("app.services.chatbot_service.GeminiService.generate_chat", fake_generate_chat)

	answer, sources = ChatbotService.answer("rekap natrium hari ini", db=object(), user_id=7)

	assert captured["user_id"] == "7"
	assert "Natrium perlu dipantau" in captured["context"]
	assert "[PROFIL PENGGUNA]" in captured["user_context"]
	assert "PROMPT PERSONAL" in captured["prompt"]
	assert "natriummu" in answer.lower()
	assert sources == []


def test_chatbot_education_uses_reasoning_model(monkeypatch) -> None:
	captured: dict[str, str] = {}

	def fake_retrieve_context(question: str):
		captured["question"] = question
		return "[SKOR 0.88] Hipertensi perlu dipahami bertahap.", []

	def fake_generate_reasoning(prompt: str, **_: object) -> str:
		captured["prompt"] = prompt
		return "Kita belajar pelan-pelan ya. Hipertensi itu tekanan darah yang sering terlalu tinggi."

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fake_retrieve_context)
	monkeypatch.setattr("app.services.chatbot_service.ChatbotPersonalizationService.can_handle", lambda _: True)
	monkeypatch.setattr("app.services.chatbot_service.GeminiService.generate_reasoning", fake_generate_reasoning)

	answer, sources = ChatbotService.answer("mulai edukasi hipertensi", db=object(), user_id=7)

	assert "Konteks RAG yang boleh dipakai" in captured["prompt"]
	assert "prioritaskan konteks" in captured["prompt"]
	assert "Edukasi 1/3: Apa itu Hipertensi?" in captured["prompt"]
	assert "**>130/80 mmHg**" in captured["prompt"]
	assert "Always bold key information" in captured["prompt"]
	assert "belajar" in answer.lower()
	assert sources == []


def test_education_continue_after_part_two_generates_part_three(monkeypatch) -> None:
	captured: dict[str, str] = {}

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", lambda _: ("", []))
	monkeypatch.setattr(
		"app.services.chatbot_service.ChatRepository.list_chat",
		lambda *_: [_HistoryTurn("lanjut", "**Edukasi 2/3: Bahaya & Komplikasi**\n\nLanjut →")],
	)

	def fake_generate_reasoning(prompt: str, **_: object) -> str:
		captured["prompt"] = prompt
		return "**Edukasi 3/3: Natrium & Batas Harian**\n\n**WHO**: **2.000 mg/hari**.\n\nLanjut →"

	monkeypatch.setattr("app.services.chatbot_service.GeminiService.generate_reasoning", fake_generate_reasoning)

	answer, sources = ChatbotService.answer("lanjut", db=object(), user_id=7, education_part=3)

	assert "Edukasi 3/3: Natrium & Batas Harian" in captured["prompt"]
	assert "**WHO**: **2.000 mg/hari**" in captured["prompt"]
	assert "**AKG Kemenkes RI**: **1.500 mg/hari**" in captured["prompt"]
	assert "**AHA**: **1.500 mg/hari**" in captured["prompt"]
	assert "AHA 1.500 mg is stricter and ONLY" in captured["prompt"]
	assert "Edukasi 3/3" in answer
	assert "Lanjut" not in answer
	assert sources == []


def test_compare_product_intent_runs_before_topic_guard(monkeypatch) -> None:
	captured: dict[str, str] = {}

	class Item:
		food_name = "Produk A"
		sodium_mg = 600
		sodium_level = "tinggi"
		package_ml = 100
		satuan_takaran = "g"
		portions_in_package = 1
		product_name2 = "Produk B"
		sodium_mg2 = 120
		package_ml2 = 100
		satuan_takaran2 = "g"
		portions_in_package2 = 1
		intake_type = "comparison"

	def fail_retrieve_context(_: str) -> tuple[str, list[object]]:
		raise AssertionError("Comparison intent should route before RAG retrieval")

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fail_retrieve_context)
	monkeypatch.setattr(
		"app.services.chatbot_service.ChatbotService._comparison_products_from_scans",
		lambda *_: (
			[
				{"name": "Produk B", "sodium_mg": 120, "servings": 1, "serving_size": "100 g"},
				{"name": "Produk A", "sodium_mg": 600, "servings": 1, "serving_size": "100 g"},
			],
			[],
		),
	)

	def fake_generate_reasoning(prompt: str, **_: object) -> str:
		captured["prompt"] = prompt
		return "🔵 **Produk A**\n• Natrium: **600 mg** per sajian\n• % Batas Harian: **30%**\n• Sajian per kemasan: 1\n\n✅ Rekomendasi: **Produk B** lebih rendah natrium."

	monkeypatch.setattr("app.services.chatbot_service.GeminiService.generate_reasoning", fake_generate_reasoning)

	answer, sources = ChatbotService.answer("bandingkan produk", db=object(), user_id=7)

	assert "Perbandingan Produk:" in captured["prompt"]
	assert "| Produk | Natrium | % Batas Harian | Sajian/Kemasan |" in captured["prompt"]
	assert "jangan gunakan bullet list" in captured["prompt"]
	assert "Produk B: 120 mg natrium" in captured["prompt"]
	assert "Produk A: 600 mg natrium" in captured["prompt"]
	assert "Produk A" in answer
	assert sources == []
