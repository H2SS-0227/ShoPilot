from typing import Optional
import json
import time

from fastapi import APIRouter, Request
from fastapi.responses import StreamingResponse

from app.agent.cart_tools import cart_service
from app.agent.dialogue_state import get_dialogue_state, merge_constraints, update_dialogue_state
from app.agent.intent import detect_intent, parse_constraints
from app.agent.llm_response import apply_llm_reasons, generate_comparison_copy, generate_recommendation_copy
from app.agent.response_builder import attach_reasons, build_comparison_response, build_recommendation_response
from app.data.repository import get_product_repository
from app.rag.retriever import ProductRetriever
from app.schemas.cart import CartItem
from app.schemas.chat import CartAction, ChatRequest, ChatResponse

router = APIRouter()
retriever = ProductRetriever()


@router.post("/chat")
def chat(payload: ChatRequest, request: Request):
    if payload.stream or "text/event-stream" in request.headers.get("accept", ""):
        return StreamingResponse(
            _sse_events(payload),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no",
            },
        )
    response = _build_chat_response(payload)
    return response


def _build_chat_response(request: ChatRequest, use_llm: bool = True) -> ChatResponse:
    state = get_dialogue_state(request.session_id)
    intent = detect_intent(request.message)
    current_constraints = parse_constraints(request.message)
    constraints = merge_constraints(state.last_constraints, current_constraints, request.message)

    if intent == "view_cart":
        cart = cart_service.get(request.session_id)
        return ChatResponse(intent="view_cart", answer=f"当前购物车有 {len(cart.items)} 件商品。", suggested_actions=["继续推荐", "删除第一个商品"])

    if intent in {"add_to_cart", "remove_from_cart"}:
        product_id = _resolve_referenced_product(request.session_id, current_constraints.referenced_product_position)
        if not product_id:
            return ChatResponse(intent="clarify", answer="你想操作哪一款商品？可以说“把第一个加入购物车”。", clarifying_question="请告诉我要操作第几个商品。")
        if intent == "add_to_cart":
            cart_service.add(CartItem(session_id=request.session_id, product_id=product_id, quantity=1))
            return ChatResponse(intent="add_to_cart", answer="已把这款商品加入购物车。", cart_action=CartAction(type="add", product_id=product_id), suggested_actions=["查看购物车", "继续推荐"])
        cart_service.remove(request.session_id, product_id)
        return ChatResponse(intent="remove_from_cart", answer="已从购物车移除这款商品。", cart_action=CartAction(type="remove", product_id=product_id), suggested_actions=["查看购物车", "继续推荐"])

    if intent == "compare":
        products = _resolve_compare_products(request.session_id)
        if len(products) < 2:
            return ChatResponse(intent="clarify", answer="我需要至少两款已推荐商品才能对比。", clarifying_question="请先让我推荐几款商品。")
        products_with_reasons = attach_reasons(products[:2], request.message)
        answer = generate_comparison_copy(request.message, products_with_reasons) if use_llm else None
        return build_comparison_response(products_with_reasons, answer=answer)

    products = retriever.search(request.message, constraints, top_k=3)
    products_with_reasons = attach_reasons(products, request.message)
    product_ids = [product.id for product in products_with_reasons]
    update_dialogue_state(request.session_id, "recommend", constraints, product_ids)

    if not products_with_reasons:
        return ChatResponse(
            intent="recommend",
            answer="当前商品库中没有找到完全匹配的商品，我不会编造不存在的商品。你可以放宽预算、类目或排除条件后再试。",
            products=[],
            suggested_actions=["放宽预算", "换个类目", "查看热门商品"],
        )

    llm_answer, llm_reasons = generate_recommendation_copy(request.message, products_with_reasons) if use_llm else (None, {})
    products_with_reasons = apply_llm_reasons(products_with_reasons, llm_reasons)
    answer = llm_answer or f"我从本地商品库中筛选出 {len(products_with_reasons)} 款更匹配的商品，推荐理由均基于商品数据。"
    return build_recommendation_response(answer, products_with_reasons)


def _sse_events(request: ChatRequest):
    try:
        intent = detect_intent(request.message)
        yield _format_sse(
            "meta",
            {
                "session_id": request.session_id,
                "intent": intent,
                "created_at": int(time.time()),
            },
        )

        yield _format_sse("delta", {"text": "正在理解你的需求，并检索本地商品库...\n"})
        response = _build_chat_response(request, use_llm=True)
        for chunk in _chunk_text(response.answer, size=4):
            yield _format_sse("delta", {"text": chunk})
            time.sleep(0.02)
        yield _format_sse("final", response.model_dump(mode="json"))
        yield _format_sse("done", {"ok": True})
    except Exception as exc:
        yield _format_sse("error", {"message": str(exc)})


def _format_sse(event: str, data: dict) -> str:
    return f"event: {event}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"


def _chunk_text(text: str, size: int = 8) -> list[str]:
    if not text:
        return []
    return [text[index : index + size] for index in range(0, len(text), size)]


def _resolve_referenced_product(session_id: str, position: Optional[int]) -> Optional[str]:
    state = get_dialogue_state(session_id)
    if not state.last_recommended_products:
        return None
    index = (position or 1) - 1
    if 0 <= index < len(state.last_recommended_products):
        return state.last_recommended_products[index]
    return None


def _resolve_compare_products(session_id: str):
    repository = get_product_repository()
    state = get_dialogue_state(session_id)
    products = [repository.get(product_id) for product_id in state.last_recommended_products[:2]]
    return [product for product in products if product is not None]
