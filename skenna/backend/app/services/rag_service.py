class RAGService:
	@staticmethod
	def retrieve_context(question: str) -> tuple[str, list[str]]:
		sources = [
			"WHO sodium intake guideline",
			"Kemenkes gizi seimbang",
		]
		context = (
			"Asupan natrium harian disarankan dibatasi, terutama pada hipertensi. "
			f"Pertanyaan pengguna: {question}"
		)
		return context, sources

