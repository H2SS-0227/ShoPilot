from app.schemas.cart import Cart, CartItem


class CartService:
    def __init__(self) -> None:
        self._carts: dict[str, Cart] = {}

    def get(self, session_id: str) -> Cart:
        return self._carts.setdefault(session_id, Cart(session_id=session_id, items=[]))

    def add(self, item: CartItem) -> Cart:
        cart = self.get(item.session_id)
        for existing in cart.items:
            if existing.product_id == item.product_id:
                existing.quantity += item.quantity
                return cart
        cart.items.append(item)
        return cart

    def remove(self, session_id: str, product_id: str) -> Cart:
        cart = self.get(session_id)
        cart.items = [item for item in cart.items if item.product_id != product_id]
        return cart


cart_service = CartService()
