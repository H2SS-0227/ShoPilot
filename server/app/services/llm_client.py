import json
import re

import httpx

from app.core.config import settings


class LLMClient:
    def __init__(self) -> None:
        self.api_base = (settings.llm_api_base or "").rstrip("/")
        self.api_key = settings.llm_api_key
        self.model = settings.llm_model

    def is_configured(self) -> bool:
        return bool(settings.enable_llm and self.api_base and self.api_key and self.model)

    def complete_json(self, system_prompt: str, user_prompt: str) -> dict:
        if not self.is_configured():
            return {}
        response = httpx.post(
            f"{self.api_base}/chat/completions",
            headers={"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"},
            json={
                "model": self.model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                "temperature": 0.2,
            },
            timeout=30,
        )
        response.raise_for_status()
        content = response.json()["choices"][0]["message"]["content"]
        return _loads_json_object(content)


def _loads_json_object(content: str) -> dict:
    try:
        parsed = json.loads(content)
        return parsed if isinstance(parsed, dict) else {}
    except json.JSONDecodeError:
        pass

    fenced = re.search(r"```(?:json)?\s*(\{[\s\S]*?\})\s*```", content)
    if fenced:
        parsed = json.loads(fenced.group(1))
        return parsed if isinstance(parsed, dict) else {}

    start = content.find("{")
    end = content.rfind("}")
    if start >= 0 and end > start:
        parsed = json.loads(content[start : end + 1])
        return parsed if isinstance(parsed, dict) else {}

    return {}


llm_client = LLMClient()
