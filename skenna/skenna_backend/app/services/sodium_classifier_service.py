from app.services.sodium_limit_service import compute_daily_limit_mg


class SodiumClassifierService:
	"""Rule-based classifier using personalized daily sodium limits."""

	@staticmethod
	def classify(sodium_mg: float | None, daily_limit_mg: int) -> tuple[str, str]:
		if sodium_mg is None:
			return "unknown", "Kadar natrium tidak terdeteksi, silakan isi manual."
		pct = sodium_mg / daily_limit_mg
		if pct <= 0.50:
			return "low", "Kadar natrium rendah, aman untuk konsumsi rutin."
		if pct <= 0.75:
			return "medium", "Kadar natrium sedang, perhatikan porsi harian."
		return "high", "Kadar natrium tinggi, batasi konsumsi dan imbangi air putih."

	@staticmethod
	def classify_for_profile(sodium_mg: float | None, profile) -> tuple[str, str, int, str]:
		daily_limit_mg, limit_source = compute_daily_limit_mg(
			birth_date=profile.birth_date,
			gender=profile.gender,
			has_hypertension=profile.has_hypertension,
		)
		sodium_level, recommendation = SodiumClassifierService.classify(
			sodium_mg,
			daily_limit_mg,
		)
		return sodium_level, recommendation, daily_limit_mg, limit_source

