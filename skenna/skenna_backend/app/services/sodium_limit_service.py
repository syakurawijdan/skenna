from datetime import date


# NOTE: This logic mirrors klasifikasiNatriumDariDraft() in the Flutter
# app's natrium_classifier.dart. The AKG age-bracket table here is
# manually duplicated from frontend/assets/rules/sodium_rules.json -
# if that file is updated, this must be updated too. Consider unifying
# these into a single shared source in a future refactor.
WHO_LIMIT_MG = 2000
AHA_LIMIT_MG = 1500

# TODO: confirm final AKG table with product owner before defense.
AKG_UNDER_16_RULES = (
	{"min_age": 0, "max_age": 0, "value_mg": 120},
	{"min_age": 1, "max_age": 3, "value_mg": 800},
	{"min_age": 4, "max_age": 6, "value_mg": 900},
	{"min_age": 7, "max_age": 9, "value_mg": 1000},
	{"min_age": 10, "max_age": 12, "male_mg": 1300, "female_mg": 1400},
	{"min_age": 13, "max_age": 15, "male_mg": 1500, "female_mg": 1500},
)


def compute_daily_limit_mg(
	birth_date: date,
	gender: str,
	has_hypertension: bool,
) -> tuple[int, str]:
	"""Returns (daily_limit_mg, source_label) where source_label is AKG, AHA, or WHO."""
	age = _age_years(birth_date)
	if age < 16:
		return _akg_limit_for_age_and_gender(age, gender), "AKG"
	if has_hypertension:
		return AHA_LIMIT_MG, "AHA"
	return WHO_LIMIT_MG, "WHO"


def _age_years(birth_date: date) -> int:
	today = date.today()
	years = today.year - birth_date.year
	if (today.month, today.day) < (birth_date.month, birth_date.day):
		years -= 1
	return years


def _akg_limit_for_age_and_gender(age: int, gender: str) -> int:
	normalized_gender = _normalize_gender(gender)
	for rule in AKG_UNDER_16_RULES:
		if rule["min_age"] <= age <= rule["max_age"]:
			if "value_mg" in rule:
				return int(rule["value_mg"])
			if normalized_gender == "perempuan":
				return int(rule["female_mg"])
			return int(rule["male_mg"])
	raise ValueError(f"No AKG sodium rule for age {age}")


def _normalize_gender(gender: str) -> str:
	normalized = (gender or "").strip().lower()
	if normalized in {"perempuan", "female", "wanita", "cewe", "cewek"}:
		return "perempuan"
	return "laki_laki"
