"""Centralized Gemini integration for all backend AI features."""

from __future__ import annotations

import base64
import logging
import re
import time
from pathlib import Path
from typing import Any

import httpx

from app.core.config import settings


logger = logging.getLogger(__name__)


class GeminiUnavailableError(RuntimeError):
	"""Raised when Gemini generateContent remains unavailable after retries."""

_http_client: httpx.Client | None = None


def _get_client(timeout_seconds: float) -> httpx.Client:
	global _http_client
	if _http_client is None or _http_client.is_closed:
		_http_client = httpx.Client(
			timeout=timeout_seconds,
			limits=httpx.Limits(max_keepalive_connections=10, max_connections=20),
		)
	return _http_client

class GeminiService:
	"""Single Gemini gateway for chat, reasoning, embeddings, and vision."""

	@staticmethod
	def _api_key() -> str:
		return settings.gemini_api_key.strip()

	@staticmethod
	def is_configured() -> bool:
		return bool(GeminiService._api_key())

	@staticmethod
	def _generate_content(
		prompt_or_parts: str | list[dict[str, Any]],
		*,
		model: str,
		temperature: float,
		max_tokens: int,
		timeout_seconds: float = 30.0,
	) -> str:
		api_key = GeminiService._api_key()
		if not api_key:
			raise RuntimeError("GEMINI_API_KEY is empty")
		print(f"[DEBUG] GEMINI_API_KEY loaded={bool(api_key)}, length={len(api_key)}")

		model_name = model.strip()
		if not model_name:
			raise RuntimeError("Gemini model is empty")
		url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent"
		parts = [{"text": prompt_or_parts}] if isinstance(prompt_or_parts, str) else prompt_or_parts
		generation_config: dict[str, Any] = {
			"temperature": temperature,
			"maxOutputTokens": max_tokens,
		}
		model_name_lower = model_name.lower()
		if "2.5" in model_name_lower or "flash" in model_name_lower:
			generation_config["thinkingConfig"] = {"thinkingBudget": 0}
		payload: dict[str, Any] = {
			"contents": [{"role": "user", "parts": parts}],
			"generationConfig": generation_config,
		}

		data: dict[str, Any] | None = None
		last_response_status: int | None = None
		last_response_text = ""
		backoff_seconds = (2.0, 4.0, 8.0)
		max_attempts = 3
		for attempt in range(max_attempts):
			try:
				t_start = time.perf_counter()
				client = _get_client(timeout_seconds)
				response = client.post(
					url,
					params={"key": api_key},
					json=payload,
				)
				t_elapsed = time.perf_counter() - t_start
				logger.info(
					"⏱️ Gemini HTTP call (model=%s, attempt=%d): %.2fs",
					model_name, attempt + 1, t_elapsed,
				)
				if response.status_code in {429, 503}:
					last_response_status = response.status_code
					last_response_text = response.text
					if attempt < max_attempts - 1:
						time.sleep(backoff_seconds[attempt])
						continue
					if response.status_code == 503:
						raise GeminiUnavailableError(
							f"Gemini request failed after retries: {response.status_code} {response.text}"
						)
					raise RuntimeError(f"Gemini request failed after retries: {response.status_code} {response.text}")
				if response.status_code >= 400:
					raise RuntimeError(f"Gemini request failed: {response.status_code} {response.text}")
				data = response.json()
				break
			except GeminiUnavailableError:
				raise
			except httpx.RequestError as exc:
				print(f"[GEMINI ERROR] {type(exc).__name__}: {exc}")
				raise
		if data is None:
			if last_response_status == 503:
				raise GeminiUnavailableError(
					f"Gemini request failed after retries: {last_response_status} {last_response_text}"
				)
			raise RuntimeError(f"Gemini request failed after retries: {last_response_status} {last_response_text}")

		try:
			candidates = data.get("candidates") or []
			if not candidates:
				raise RuntimeError("Gemini response has no candidates")
			parts = candidates[0].get("content", {}).get("parts", [])
			text = "".join(part.get("text", "") for part in parts).strip()
			if not text:
				raise RuntimeError("Gemini response text is empty")
			return text
		except Exception as exc:  # pragma: no cover - defensive parsing
			raise RuntimeError(f"Failed to parse Gemini response: {exc}") from exc

	@staticmethod
	def generate_chat(
		prompt: str,
		*,
		temperature: float = 0.35,
		max_tokens: int = 4096,
		timeout_seconds: float = 30.0,
	) -> str:
		return GeminiService._generate_content(
			prompt,
			model=settings.gemini_chat_model,
			temperature=temperature,
			max_tokens=max_tokens,
			timeout_seconds=timeout_seconds,
		)

	@staticmethod
	def generate_reasoning(
		prompt: str,
		*,
		temperature: float = 0.2,
		max_tokens: int = 4096,
		timeout_seconds: float = 30.0,
	) -> str:
		try:
			return GeminiService._generate_content(
				prompt,
				model=settings.gemini_reasoning_model,
				temperature=temperature,
				max_tokens=max_tokens,
				timeout_seconds=timeout_seconds,
			)
		except GeminiUnavailableError:
			logger.warning(
				"Gemini reasoning model unavailable; falling back to chat model %s",
				settings.gemini_chat_model,
			)
			return GeminiService._generate_content(
				prompt,
				model=settings.gemini_chat_model,
				temperature=temperature,
				max_tokens=max_tokens,
				timeout_seconds=timeout_seconds,
			)

	@staticmethod
	def generate_embedding(text: str, *, model: str | None = None, max_attempts: int = 1) -> list[float]:
		api_key = GeminiService._api_key()
		if not api_key:
			raise RuntimeError("GEMINI_API_KEY is empty")

		model_name = model or settings.gemini_embedding_model
		url = f"https://generativelanguage.googleapis.com/v1/models/{model_name}:embedContent"
		payload = {
			"model": f"models/{model_name}",
			"content": {"parts": [{"text": text}]},
		}

		with httpx.Client(timeout=30.0) as client:
			total_attempts = max(max_attempts, 2)
			for attempt in range(total_attempts):
				try:
					response = client.post(
						url,
						params={"key": api_key},
						json=payload,
					)
				except httpx.RequestError as exc:
					print(f"[GEMINI ERROR] embedding attempt={attempt + 1}/{total_attempts}: {repr(exc)}")
					if attempt < total_attempts - 1:
						time.sleep(1.0)
						continue
					raise
				if response.status_code in {429, 500, 502, 503, 504} and attempt < total_attempts - 1:
					time.sleep(min(_retry_delay_seconds(response.text), 1.0))
					continue
				if response.status_code >= 400:
					error = RuntimeError(f"Gemini embedding failed: {response.status_code} {response.text}")
					print(f"[GEMINI ERROR] embedding status: {repr(error)}")
					raise error
				data = response.json()
				break

		values = data.get("embedding", {}).get("values")
		if not isinstance(values, list) or not values:
			raise RuntimeError("Gemini embedding response is empty")
		return [float(value) for value in values]

	@staticmethod
	def generate_embeddings(texts: list[str], *, model: str | None = None) -> list[list[float]]:
		api_key = GeminiService._api_key()
		if not api_key:
			raise RuntimeError("GEMINI_API_KEY is empty")
		if not texts:
			return []

		model_name = model or settings.gemini_embedding_model
		url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:batchEmbedContents"
		payload = {
			"requests": [
				{
					"model": f"models/{model_name}",
					"content": {"parts": [{"text": text}]},
				}
				for text in texts
			]
		}

		with httpx.Client(timeout=30.0) as client:
			for attempt in range(2):
				try:
					response = client.post(
						url,
						params={"key": api_key},
						json=payload,
					)
				except httpx.RequestError as exc:
					print(f"[GEMINI ERROR] batch embedding attempt={attempt + 1}/2: {repr(exc)}")
					if attempt < 1:
						time.sleep(1.0)
						continue
					raise
				if response.status_code in {429, 500, 502, 503, 504} and attempt < 1:
					time.sleep(min(_retry_delay_seconds(response.text), 1.0))
					continue
				if response.status_code >= 400:
					error = RuntimeError(f"Gemini batch embedding failed: {response.status_code} {response.text}")
					print(f"[GEMINI ERROR] batch embedding status: {repr(error)}")
					raise error
				data = response.json()
				break

		embeddings = data.get("embeddings")
		if not isinstance(embeddings, list) or len(embeddings) != len(texts):
			raise RuntimeError("Gemini batch embedding response count does not match request count")
		values = [item.get("values") for item in embeddings]
		if any(not isinstance(item, list) or not item for item in values):
			raise RuntimeError("Gemini batch embedding response contains empty embeddings")
		return [[float(value) for value in item] for item in values]

	@staticmethod
	def analyze_vision_base64(base64_image: str) -> str:
		"""Analyze a food label image from base64 string."""
		logger.info(f"⏱️ Image base64 size: {len(base64_image)} chars ({len(base64_image) * 3 // 4 / 1024:.1f} KB)")
		prompt = (
			"Ekstrak informasi nilai gizi dari gambar label makanan kemasan ini.\n"
			"Kembalikan HANYA raw JSON tanpa markdown, tanpa penjelasan apapun.\n\n"
			"{\n"
			'  "takaran_saji": <angka takaran per sajian, tanpa satuan, atau null>,\n'
			'  "satuan_takaran": <"g" atau "ml">,\n'
			'  "sajian_per_kemasan": <angka jumlah sajian per kemasan, BOLEH DESIMAL seperti 1.5 atau 2.5, atau null>,\n'
			'  "sodium_mg": <kandungan NATRIUM per sajian dalam mg, atau null jika tidak ditemukan>\n'
			"}\n\n"
			"ATURAN WAJIB:\n"
			"1. sodium_mg adalah nilai NATRIUM/SODIUM dalam mg per sajian\n"
			"2. Gunakan nilai NATRIUM/SODIUM dalam satuan mg yang tercantum langsung pada label Jangan mengonversi nilai %AKG menjadi mg.\n"
			"3. takaran_saji adalah angka saja tanpa satuan (contoh: 100, tidak '100g')\n"
			"4. satuan_takaran hanya boleh 'g' atau 'ml'\n"
			"5. EVALUASI SETIAP FIELD SECARA TERPISAH. Jika SATU bagian teks pada label "
			"tertutup jari, buram, terpotong, atau benar-benar tidak terbaca, kembalikan "
			"null HANYA untuk field tersebut. JANGAN mengembalikan 0 sebagai pengganti "
			"null untuk takaran_saji atau sajian_per_kemasan — 0 berarti kamu YAKIN "
			"nilainya nol, sedangkan null berarti tidak terbaca.\n"
			"6. JANGAN PERNAH menebak atau mengarang angka. JANGAN mengambil/menyalin "
			"nilai dari field lain untuk mengisi field yang tidak terbaca (contoh: jangan "
			"memakai angka 'sajian_per_kemasan' untuk mengisi 'takaran_saji' atau "
			"sebaliknya, meskipun angkanya kebetulan sama).\n"
			"7. Jika nilai natrium/sodium benar-benar tidak ditemukan atau tidak terbaca, "
			"isi sodium_mg dengan null.\n"
			"8. Jangan tambahkan teks, komentar, atau markdown apapun selain JSON"
			"9. sajian_per_kemasan SERING berupa angka desimal (misal 1.5, 2.5, 3.33) karena takaran saji tidak selalu membagi rata isi kemasan. JANGAN membulatkan nilai ini ke integer — salin angka desimal persis seperti tercetak di label (misal '1,5 Sajian per Kemasan' → 1.5)"
		)
		parts: list[dict[str, Any]] = [
			{"text": prompt},
			{
				"inline_data": {
					"mime_type": "image/jpeg",
					"data": base64_image,
				}
			}
		]
		try:
			return GeminiService._generate_content(
				parts,
				model=settings.gemini_vision_model,
				temperature=0.1,
				max_tokens=256,
				timeout_seconds=30.0,
			)
		except GeminiUnavailableError:
			fallback_model = settings.gemini_chat_model.strip()
			if not fallback_model or fallback_model == settings.gemini_vision_model.strip():
				fallback_model = "gemini-1.5-flash"
			logger.warning(
				"Gemini vision model unavailable; falling back to vision-capable model %s",
				fallback_model,
			)
			return GeminiService._generate_content(
				parts,
				model=fallback_model,
				temperature=0.1,
				max_tokens=256,
				timeout_seconds=30.0,
			)

	@staticmethod
	def analyze_vision(image_path_or_url: str) -> str:
		"""Analyze a food label image from a local path or URL-like string."""
		prompt = (
			"Ekstrak informasi nilai gizi dari gambar label makanan kemasan ini.\n"
			"Kembalikan HANYA raw JSON tanpa markdown, tanpa penjelasan apapun.\n\n"
			"{\n"
			'  "takaran_saji": <angka takaran per sajian, tanpa satuan>,\n'
			'  "satuan_takaran": <"g" atau "ml">,\n'
			'  "sajian_per_kemasan": <angka jumlah sajian per kemasan>,\n'
			'  "sodium_mg": <kandungan NATRIUM per sajian dalam mg, atau null jika tidak ditemukan>\n'
			"}\n\n"
			"ATURAN WAJIB:\n"
			"1. sodium_mg adalah nilai NATRIUM/SODIUM dalam mg per sajian\n"
			"2. Jika natrium ditulis dalam %AKG atau %DV, konversi: nilai% x 2000 / 100\n"
			"3. takaran_saji adalah angka saja tanpa satuan (contoh: 100, tidak '100g')\n"
			"4. satuan_takaran hanya boleh 'g' atau 'ml'\n"
			"5. Jika nilai natrium/sodium tidak terbaca atau tidak ditemukan, kembalikan sodium_mg sebagai null; jangan gunakan 0 sebagai pengganti nilai yang tidak terbaca.\n"
			"6. Jangan tambahkan teks, komentar, atau markdown apapun selain JSON"
		)
		parts: list[dict[str, Any]] = [{"text": prompt}]

		path = Path(image_path_or_url)
		if path.exists() and path.is_file():
			image_bytes = path.read_bytes()
			parts.append(
				{
					"inline_data": {
						"mime_type": "image/jpeg",
						"data": base64.b64encode(image_bytes).decode("ascii"),
					}
				}
			)
		else:
			parts.append({"text": f"Lokasi gambar atau URL: {image_path_or_url}"})

		return GeminiService._generate_content(
			parts,
			model=settings.gemini_vision_model,
			temperature=0.1,
			max_tokens=256,
			timeout_seconds=30.0,
		)

def _retry_delay_seconds(response_text: str) -> float:
	match = re.search(r'"retryDelay"\s*:\s*"(\d+)s"', response_text)
	if match:
		return float(match.group(1)) + 2.0
	return 35.0
