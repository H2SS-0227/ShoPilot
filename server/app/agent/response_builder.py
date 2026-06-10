from __future__ import annotations

from app.schemas.chat import ChatResponse, ComparisonRow
from app.schemas.product import Product


def attach_reasons(products: list[Product], query: str) -> list[Product]:
    result: list[Product] = []
    for product in products[:3]:
        copied = product.model_copy(deep=True)
        copied.reason = _build_reason(copied, query)
        result.append(copied)
    return result


def _build_reason(product: Product, query: str) -> str:
    facts = []
    if product.price:
        facts.append(f"价格为 {product.price:g} 元")
    if product.brand:
        facts.append(f"品牌是 {product.brand}")
    if product.sub_category:
        facts.append(f"属于{product.sub_category}")
    if product.features:
        facts.append(product.features[0][:60])
    fact_text = "，".join(facts[:3])
    return f"匹配你的需求“{query}”：{fact_text}。"


def build_recommendation_response(answer: str, products: list[Product]) -> ChatResponse:
    return ChatResponse(
        intent="recommend",
        answer=answer,
        products=products,
        suggested_actions=["加入第一个到购物车", "对比前两款", "再便宜一点"],
    )


def build_comparison_response(products: list[Product], answer: str | None = None) -> ChatResponse:
    rows = [
        ComparisonRow(dimension="价格", items=[{"product_id": item.id, "value": f"{item.price:g} 元"} for item in products]),
        ComparisonRow(dimension="类目", items=[{"product_id": item.id, "value": item.sub_category or item.category} for item in products]),
        ComparisonRow(dimension="核心卖点", items=[{"product_id": item.id, "value": (item.features[0] if item.features else item.description[:50])} for item in products]),
    ]
    fallback_answer = "我已按价格、类目和核心卖点对前两款商品做了对比，建议优先选择更符合预算和使用场景的那款。"
    return ChatResponse(intent="compare", answer=answer or fallback_answer, products=products, comparison=rows, suggested_actions=["加入第一个到购物车", "查看详情"])
