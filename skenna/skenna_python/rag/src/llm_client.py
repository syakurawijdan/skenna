"""LLM client helpers for optional Gemini-based answer generation."""

from __future__ import annotations

import httpx


def generate_with_gemini(prompt: str, api_key: str, model: str = "gemini-flash-latest") -> str:
	"""Generate text using Gemini REST API.

	Raises RuntimeError when the API call fails or returns an empty response.
	"""
	if not api_key.strip():
		raise RuntimeError("Gemini API key is empty")

	url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
	params = {"key": api_key}
	payload = {
		"contents": [{"parts": [{"text": prompt}]}],
		"generationConfig": {
			"temperature": 0.2,
			"maxOutputTokens": 700,
		},
	}

	with httpx.Client(timeout=45.0) as client:
		response = client.post(url, params=params, json=payload)
		if response.status_code >= 400:
			raise RuntimeError(f"Gemini request failed: {response.status_code} {response.text}")
		data = response.json()

	try:
		candidates = data.get("candidates", [])
		if not candidates:
			raise RuntimeError("Gemini response has no candidates")
		parts = candidates[0].get("content", {}).get("parts", [])
		texts = [part.get("text", "") for part in parts if part.get("text")]
		answer = "\n".join(texts).strip()
		if not answer:
			raise RuntimeError("Gemini response text is empty")
		return answer
	except Exception as exc:  # pragma: no cover - defensive parsing
		raise RuntimeError(f"Failed to parse Gemini response: {exc}") from exc
