from __future__ import annotations

import json
from typing import Any

from app.agent.prompt import SYSTEM_PROMPT
from app.schemas.product import Product
from app.services.llm_client import llm_client


def generate_recommendation_copy(query: str, products: list[Product]) -> tuple[str | None, dict[str, str]]:
    if not products or not llm_client.is_configured():
        return None, {}

    payload = {
        "user_query": query,
        "context_products": [_product_context(product) for product in products],
        "output_schema": {
            "answer": "面向用户的自然语言导购回答，必须只基于 context_products。",
            "reasons": {
                "product_id": "该商品匹配用户需求的简短理由，必须只基于该商品事实。",
            },
        },
    }
    user_prompt = (
        "请基于下面 JSON 中的候选商品生成导购回答。"
        "不要新增商品，不要修改价格，不要编造优惠/库存/测评结论。"
        "如果有 TikTok 测评参考，只能说有真实测评链接可参考。\n"
        f"{json.dumps(payload, ensure_ascii=False)}"
    )

    try:
        result = llm_client.complete_json(SYSTEM_PROMPT, user_prompt)
    except Exception:
        return None, {}

    answer = result.get("answer")
    raw_reasons = result.get("reasons", {})
    reasons = _normalize_reasons(raw_reasons)
    return (answer if isinstance(answer, str) and answer.strip() else None), reasons


def generate_comparison_copy(query: str, products: list[Product]) -> str | None:
    if len(products) < 2 or not llm_client.is_configured():
        return None

    payload = {
        "user_query": query,
        "context_products": [_product_context(product) for product in products[:2]],
        "output_schema": {
            "answer": "对前两款商品的自然语言对比结论，必须只基于 context_products。",
        },
    }
    user_prompt = (
        "请基于下面 JSON 对两款商品做对比，给出适合不同需求用户的选择建议。"
        "不要新增商品，不要编造数据。\n"
        f"{json.dumps(payload, ensure_ascii=False)}"
    )

    try:
        result = llm_client.complete_json(SYSTEM_PROMPT, user_prompt)
    except Exception:
        return None

    answer = result.get("answer")
    return answer if isinstance(answer, str) and answer.strip() else None


def apply_llm_reasons(products: list[Product], reasons: dict[str, str]) -> list[Product]:
    if not reasons:
        return products

    result: list[Product] = []
    for product in products:
        copied = product.model_copy(deep=True)
        reason = reasons.get(product.id)
        if reason:
            copied.reason = reason
        result.append(copied)
    return result


def _product_context(product: Product) -> dict[str, Any]:
    return {
        "id": product.id,
        "name": product.name,
        "category": product.category,
        "sub_category": product.sub_category,
        "brand": product.brand,
        "price": product.price,
        "currency": product.currency,
        "description": product.description[:500],
        "features": product.features[:4],
        "tags": product.tags[:8],
        "review_references": [
            {
                "platform": ref.platform,
                "title": ref.title,
                "author": ref.author,
                "url": ref.url,
            }
            for ref in product.review_references[:2]
        ],
    }


def _normalize_reasons(raw_reasons: Any) -> dict[str, str]:
    if not isinstance(raw_reasons, dict):
        return {}

    result: dict[str, str] = {}
    for product_id, reason in raw_reasons.items():
        if isinstance(product_id, str) and isinstance(reason, str) and reason.strip():
            result[product_id] = reason.strip()
    return result
