from typing import Optional
from pydantic import BaseModel, Field

from app.schemas.product import Product


class ChatRequest(BaseModel):
    session_id: str = "demo-session"
    message: str
    stream: bool = True


class CartAction(BaseModel):
    type: str = "none"
    product_id: Optional[str] = None
    quantity: int = 1


class ComparisonRow(BaseModel):
    dimension: str
    items: list[dict[str, str]] = Field(default_factory=list)


class ChatResponse(BaseModel):
    type: str = "final"
    intent: str
    answer: str
    products: list[Product] = Field(default_factory=list)
    comparison: list[ComparisonRow] = Field(default_factory=list)
    cart_action: CartAction = Field(default_factory=CartAction)
    clarifying_question: str = ""
    suggested_actions: list[str] = Field(default_factory=list)
