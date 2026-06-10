from fastapi import APIRouter, HTTPException

from app.data.repository import get_product_repository
from app.schemas.product import Product

router = APIRouter()


@router.get("/products", response_model=list[Product])
def list_products() -> list[Product]:
    return get_product_repository().list()


@router.get("/products/{product_id}", response_model=Product)
def get_product(product_id: str) -> Product:
    product = get_product_repository().get(product_id)
    if not product:
        raise HTTPException(status_code=404, detail=f"Product {product_id} not found")
    return product
