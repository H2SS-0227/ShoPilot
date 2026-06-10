from typing import Optional
from functools import lru_cache
from pathlib import Path
import json

from app.core.config import settings
from app.data.loader import iter_raw_product_files, load_json
from app.data.normalizer import normalize_product
from app.schemas.product import Product


def _project_root() -> Path:
    return Path(__file__).resolve().parents[3]


class ProductRepository:
    def __init__(self, products: list[Product]) -> None:
        self.products = products
        self._by_id = {product.id: product for product in products}

    def list(self) -> list[Product]:
        return self.products

    def get(self, product_id: str) -> Optional[Product]:
        return self._by_id.get(product_id)


def _load_normalized(path: Path) -> list[Product]:
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    return [Product(**item) for item in data]


def _load_from_raw_dataset(dataset_root: Path) -> list[Product]:
    return [
        normalize_product(load_json(path), dataset_root=str(dataset_root))
        for path in iter_raw_product_files(str(dataset_root))
    ]


@lru_cache
def get_product_repository() -> ProductRepository:
    root = _project_root()
    normalized_path = root / settings.normalized_products_path
    products = _load_normalized(normalized_path)
    if not products:
        products = _load_from_raw_dataset(root / settings.dataset_root)
    return ProductRepository(products)


def refresh_product_repository() -> ProductRepository:
    get_product_repository.cache_clear()
    return get_product_repository()
