from app.schemas.intent import Constraints
from app.schemas.product import Product


def rank_products(products: list[Product], constraints: Constraints) -> list[Product]:
    # TODO: combine semantic score, constraint match score, price, and rating signals.
    return products
