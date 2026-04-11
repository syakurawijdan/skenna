from app.services.rag_service import RAGService


class ChatbotService:
	@staticmethod
	def answer(question: str) -> tuple[str, list[str]]:
		context, sources = RAGService.retrieve_context(question)
		answer = (
			"Berdasarkan referensi kesehatan, batasi natrium bila konsumsi harian Anda tinggi. "
			"Fokus pada makanan segar, kurangi makanan olahan, dan cek label sodium per porsi. "
			f"Konteks: {context}"
		)
		return answer, sources

