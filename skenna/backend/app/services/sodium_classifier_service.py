class SodiumClassifierService:
	"""Rule-based classifier as baseline before model deployment."""

	@staticmethod
	def classify(sodium_mg: float) -> tuple[str, str]:
		if sodium_mg < 140:
			return "low", "Kadar natrium rendah, aman untuk konsumsi rutin."
		if sodium_mg <= 400:
			return "medium", "Kadar natrium sedang, perhatikan porsi harian."
		return "high", "Kadar natrium tinggi, batasi konsumsi dan imbangi air putih."

