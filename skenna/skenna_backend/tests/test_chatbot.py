import pytest

from app.services.chatbot_service import ChatbotService


@pytest.fixture(autouse=True)
def force_stub_provider(monkeypatch: pytest.MonkeyPatch) -> None:
	monkeypatch.setattr("app.services.chatbot_service.settings.llm_provider", "stub", raising=False)


def test_chatbot_greeting_response() -> None:
	answer, sources = ChatbotService.answer("halo")
	assert "Aku Skenny" in answer
	assert "natrium" in answer.lower()
	assert sources == []


def test_chatbot_identity_question_response() -> None:
	answer, sources = ChatbotService.answer("kamu siapa?")
	assert "Aku Skenny" in answer
	assert sources == []


def test_chatbot_typo_handling_uses_normalized_question(monkeypatch) -> None:
	captured: dict[str, str] = {}

	def fake_retrieve_context(question: str) -> tuple[str, list[str]]:
		captured["question"] = question
		return "[SKOR 0.99] Natrium harian perlu dibatasi.", ["kb/natrium.md"]

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fake_retrieve_context)

	answer, _ = ChatbotService.answer("brp batas ntrium")

	assert captured["question"] == "berapa batas natrium"
	assert "Dari sumber yang aku punya" in answer


def test_chatbot_unclear_question_prompts_clarification() -> None:
	answer, sources = ChatbotService.answer("natrium")
	assert "Maksudnya" in answer
	assert sources == []


def test_chatbot_out_of_topic_redirects() -> None:
	answer, sources = ChatbotService.answer("siapa pemain bola terbaik")
	assert "lebih fokus ke kesehatan" in answer.lower()
	assert sources == []


def test_chatbot_out_of_topic_uses_gemini_when_enabled(monkeypatch) -> None:
	monkeypatch.setattr("app.services.chatbot_service.settings.llm_provider", "gemini", raising=False)

	def fake_generate(*_: object, **__: object) -> str:
		return "Bisa kok, ini jawaban santai dari mode umum 😊"

	monkeypatch.setattr("app.services.chatbot_service.generate_with_gemini", fake_generate)

	answer, sources = ChatbotService.answer("siapa pemain bola terbaik")
	assert "mode umum" in answer.lower()
	assert sources == []


def test_chatbot_serious_condition_adds_doctor_advice(monkeypatch) -> None:
	def fake_retrieve_context(_: str) -> tuple[str, list[str]]:
		return "[SKOR 0.82] Gejala berat pada hipertensi perlu perhatian.", ["kb/serius.md"]

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fake_retrieve_context)

	answer, _ = ChatbotService.answer("saya sesak dan nyeri dada")

	assert "sebaiknya cek ke dokter" in answer.lower()


def test_chatbot_fallback_is_context_grounded(monkeypatch) -> None:
	def fake_retrieve_context(_: str) -> tuple[str, list[str]]:
		return (
			"[SKOR 0.91] Batasi natrium untuk membantu kontrol tekanan darah dan kurangi makanan olahan tinggi garam.",
			["paper-a.pdf", "paper-a.pdf", "paper-b.pdf"],
		)

	monkeypatch.setattr("app.services.chatbot_service.RAGService.retrieve_context", fake_retrieve_context)

	answer, sources = ChatbotService.answer("bagaimana cara kontrol tekanan darah")

	assert "Dari sumber yang aku punya" in answer
	assert len(sources) == 2
