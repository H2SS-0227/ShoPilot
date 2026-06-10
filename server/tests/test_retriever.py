from app.agent.intent import parse_constraints
from app.rag.retriever import ProductRetriever


def test_retriever_returns_grounded_products_for_budget_query() -> None:
    query = "推荐一款 200 元以内的咖啡"
    products = ProductRetriever().search(query, parse_constraints(query), top_k=3)

    assert products
    assert all(product.price <= 200 for product in products)
    assert all(product.source == "local_dataset" for product in products)
