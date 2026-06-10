from fastapi.testclient import TestClient

from app.main import app


def test_chat_recommend_then_add_first_to_cart() -> None:
    client = TestClient(app)

    recommend = client.post(
        "/api/chat",
        json={"session_id": "test-session", "message": "推荐一款 200 元以内的咖啡", "stream": False},
    )
    assert recommend.status_code == 200
    body = recommend.json()
    assert body["intent"] == "recommend"
    assert len(body["products"]) > 0

    add = client.post(
        "/api/chat",
        json={"session_id": "test-session", "message": "把第一个加入购物车", "stream": False},
    )
    assert add.status_code == 200
    add_body = add.json()
    assert add_body["intent"] == "add_to_cart"
    assert add_body["cart_action"]["product_id"] == body["products"][0]["id"]


def test_chat_sse_returns_expected_events() -> None:
    client = TestClient(app)

    with client.stream(
        "POST",
        "/api/chat",
        json={"session_id": "sse-test-session", "message": "推荐一款 200 元以内的咖啡", "stream": True},
        headers={"Accept": "text/event-stream"},
    ) as response:
        assert response.status_code == 200
        text = response.read().decode("utf-8")

    assert "event: meta" in text
    assert "event: delta" in text
    assert "event: final" in text
    assert "event: done" in text
    assert '"products"' in text


def test_chat_no_result_for_strict_budget() -> None:
    client = TestClient(app)
    response = client.post(
        "/api/chat",
        json={"session_id": "no-result-session", "message": "推荐 1 元以内的笔记本电脑", "stream": False},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["intent"] == "recommend"
    assert body["products"] == []


def test_chat_compare_after_recommendation() -> None:
    client = TestClient(app)
    session_id = "compare-session"
    recommend = client.post(
        "/api/chat",
        json={"session_id": session_id, "message": "推荐一款 200 元以内的咖啡", "stream": False},
    )
    assert recommend.status_code == 200

    compare = client.post(
        "/api/chat",
        json={"session_id": session_id, "message": "对比前两款", "stream": False},
    )
    assert compare.status_code == 200
    body = compare.json()
    assert body["intent"] == "compare"
    assert len(body["comparison"]) >= 2


def test_chat_excludes_too_sweet_coffee() -> None:
    client = TestClient(app)
    response = client.post(
        "/api/chat",
        json={"session_id": "exclude-session", "message": "推荐不要太甜的咖啡，预算 100 元以内", "stream": False},
    )

    assert response.status_code == 200
    body = response.json()
    product_text = str(body["products"])
    assert "白砂糖" not in product_text
    assert "三合一" not in product_text
    assert "甜味" not in product_text


def test_chat_lip_gloss_only_returns_lip_gloss() -> None:
    client = TestClient(app)
    response = client.post(
        "/api/chat",
        json={"session_id": "lip-gloss-session", "message": "帮我找唇釉", "stream": False},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["products"]
    assert all(product["sub_category"] == "唇釉" for product in body["products"])


def test_chat_common_subcategories_stay_relevant() -> None:
    client = TestClient(app)
    cases = [
        ("推荐一款酸奶", {"酸奶"}),
        ("推荐功能饮料", {"功能饮料"}),
        ("推荐户外裤", {"户外裤"}),
        ("推荐一款篮球鞋", {"篮球鞋"}),
        ("推荐一款平板电脑", {"平板电脑"}),
        ("推荐坚果零食", {"坚果/零食"}),
    ]

    for message, expected_sub_categories in cases:
        response = client.post(
            "/api/chat",
            json={"session_id": f"relevance-{message}", "message": message, "stream": False},
        )
        assert response.status_code == 200
        products = response.json()["products"]
        assert products, message
        assert all(product["sub_category"] in expected_sub_categories for product in products), message


def test_chat_add_then_view_cart() -> None:
    client = TestClient(app)
    session_id = "cart-view-session"
    recommend = client.post(
        "/api/chat",
        json={"session_id": session_id, "message": "推荐一款适合油皮的防晒", "stream": False},
    )
    assert recommend.status_code == 200
    first_product_id = recommend.json()["products"][0]["id"]

    add = client.post(
        "/api/chat",
        json={"session_id": session_id, "message": "把第一个加入购物车", "stream": False},
    )
    assert add.status_code == 200
    assert add.json()["cart_action"]["product_id"] == first_product_id

    cart = client.post(
        "/api/chat",
        json={"session_id": session_id, "message": "查看购物车", "stream": False},
    )
    assert cart.status_code == 200
    assert cart.json()["intent"] == "view_cart"
