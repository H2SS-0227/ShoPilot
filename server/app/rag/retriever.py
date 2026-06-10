from dataclasses import dataclass
import re

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from app.data.repository import get_product_repository
from app.rag.document import product_to_document
from app.schemas.intent import Constraints
from app.schemas.product import Product


@dataclass
class RetrievedProduct:
    product: Product
    score: float


class ProductRetriever:
    def __init__(self) -> None:
        self.repository = get_product_repository()
        self.products = self.repository.list()
        self.documents = [product_to_document(product) for product in self.products]
        self.vectorizer = TfidfVectorizer(analyzer="char_wb", ngram_range=(2, 4), lowercase=True)
        self.matrix = self.vectorizer.fit_transform(self.documents) if self.documents else None

    def search(self, query: str, constraints: Constraints, top_k: int = 5) -> list[Product]:
        return [item.product for item in self.search_with_scores(query, constraints, top_k)]

    def search_with_scores(self, query: str, constraints: Constraints, top_k: int = 5) -> list[RetrievedProduct]:
        if not self.products or self.matrix is None:
            return []

        query_text = self._build_query_text(query, constraints)
        query_vector = self.vectorizer.transform([query_text])
        semantic_scores = cosine_similarity(query_vector, self.matrix).flatten()

        results: list[RetrievedProduct] = []
        for index, product in enumerate(self.products):
            if not self._passes_hard_filters(product, constraints):
                continue
            score = float(semantic_scores[index]) * 0.65
            score += self._constraint_score(product, constraints) * 0.3
            score += self._price_score(product, constraints) * 0.05
            results.append(RetrievedProduct(product=product, score=score))

        results.sort(key=lambda item: item.score, reverse=True)
        return results[:top_k]

    def _build_query_text(self, query: str, constraints: Constraints) -> str:
        parts = [query, constraints.category or "", constraints.scenario or "", constraints.target_user or ""]
        parts.extend(constraints.preferences)
        parts.extend(constraints.brand_preferences)
        return " ".join(part for part in parts if part)

    def _product_text(self, product: Product) -> str:
        return product_to_document(product).lower()

    def _passes_hard_filters(self, product: Product, constraints: Constraints) -> bool:
        if constraints.budget_min is not None and product.price < constraints.budget_min:
            return False
        if constraints.budget_max is not None and product.price > constraints.budget_max:
            return False

        product_text = self._product_text(product)
        category = (constraints.category or "").lower()
        if category and not self._matches_category(product, category, product_text):
            return False

        for exclusion in constraints.exclusions:
            normalized = exclusion.lower().strip()
            if not normalized:
                continue
            if normalized in product_text:
                return False
            cleaned = re.sub(r"^(不要|不含|排除|除了|别|不想要)", "", normalized).strip()
            if cleaned and cleaned in product_text:
                return False
        return True

    def _matches_category(self, product: Product, category: str, product_text: str) -> bool:
        strict_mapping = {
            "咖啡": {"咖啡"},
            "防晒": {"防晒"},
            "精华": {"精华"},
            "跑鞋": {"跑步鞋"},
            "运动鞋": {"跑步鞋", "篮球鞋", "徒步鞋"},
            "耳机": {"真无线耳机"},
            "手机": {"智能手机"},
            "平板": {"平板电脑"},
            "电脑": {"笔记本电脑"},
        }
        sub_category = (product.sub_category or "").lower()
        if category in strict_mapping:
            return any(alias.lower() in sub_category for alias in strict_mapping[category])

        if category in product_text:
            return True
        category_aliases = self._category_aliases(category)
        return any(alias in product_text for alias in category_aliases)

    def _category_aliases(self, category: str) -> set[str]:
        aliases = {category}
        mapping = {
            "耳机": {"蓝牙耳机", "无线耳机", "真无线耳机"},
            "手机": {"智能手机"},
            "洗面奶": {"洁面"},
            "防晒": {"防晒霜"},
            "跑鞋": {"跑步鞋", "运动鞋"},
            "咖啡": {"黑咖啡", "速溶咖啡", "冻干咖啡", "冷萃咖啡"},
            "t恤": {"短袖", "短袖t恤", "速干t恤"},
        }
        for key, values in mapping.items():
            if key in category:
                aliases.update(values)
        return {alias.lower() for alias in aliases}

    def _constraint_score(self, product: Product, constraints: Constraints) -> float:
        product_text = self._product_text(product)
        checks: list[bool] = []
        for value in [constraints.category, constraints.scenario, constraints.target_user, *constraints.preferences, *constraints.brand_preferences]:
            if value:
                checks.append(value.lower() in product_text or any(alias in product_text for alias in self._category_aliases(value.lower())))
        if not checks:
            return 0.5
        return sum(checks) / len(checks)

    def _price_score(self, product: Product, constraints: Constraints) -> float:
        if constraints.budget_max is None:
            return 0.5
        if product.price <= constraints.budget_max:
            return max(0.0, 1 - product.price / max(constraints.budget_max, 1))
        return 0.0
