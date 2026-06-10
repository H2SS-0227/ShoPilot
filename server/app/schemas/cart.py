from pydantic import BaseModel, Field


class CartItem(BaseModel):
    session_id: str = "demo-session"
    product_id: str
    quantity: int = 1


class Cart(BaseModel):
    session_id: str
    items: list[CartItem] = Field(default_factory=list)
