from fastapi import APIRouter

from app.agent.cart_tools import cart_service
from app.schemas.cart import Cart, CartItem

router = APIRouter()


@router.get("/cart", response_model=Cart)
def get_cart(session_id: str) -> Cart:
    return cart_service.get(session_id)


@router.post("/cart/items", response_model=Cart)
def add_cart_item(item: CartItem) -> Cart:
    return cart_service.add(item)


@router.delete("/cart/items/{product_id}", response_model=Cart)
def remove_cart_item(product_id: str, session_id: str = "demo-session") -> Cart:
    return cart_service.remove(session_id, product_id)
