#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import statistics
import sys
import time
from pathlib import Path
from typing import Any

os.environ.setdefault("ENABLE_LLM", "false")

ROOT = Path(__file__).resolve().parents[1]
SERVER = ROOT / "server"
sys.path.insert(0, str(SERVER))

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402


QUERY_SET: list[dict[str, Any]] = [
    {"query": "推荐一款 200 元以内的咖啡，并给我参考真实测评链接", "category": "咖啡", "max_price": 200, "requires_review": True},
    {"query": "推荐不要太甜的咖啡，预算 100 元以内", "category": "咖啡", "max_price": 100, "exclusions": ["白砂糖", "三合一", "甜味"]},
    {"query": "推荐适合油皮的防晒，200 元以内", "category": "防晒", "max_price": 200},
    {"query": "敏感肌能用的精华，预算 300 元以内", "category": "精华", "max_price": 300},
    {"query": "推荐一款通勤跑鞋，500 元以内", "category": "跑步鞋", "max_price": 500},
    {"query": "想买学生党能负担的蓝牙耳机", "category": "真无线耳机"},
    {"query": "推荐一台适合办公的笔记本电脑", "category": "笔记本电脑"},
    {"query": "推荐一款适合上课记笔记的平板电脑", "category": "平板电脑"},
    {"query": "推荐 1 元以内的笔记本电脑", "category": "笔记本电脑", "max_price": 1, "expect_empty": True},
    {"query": "推荐适合旅行的洁面，不要酒精", "category": "洁面", "exclusions": ["酒精"]},
    {"query": "推荐控油洗面奶", "category": "洁面"},
    {"query": "推荐性价比短袖 T恤", "category": "短袖"},
    {"query": "推荐一件运动卫衣", "category": "卫衣"},
    {"query": "推荐户外裤", "category": "户外裤"},
    {"query": "推荐低脂酸奶", "category": "酸奶"},
    {"query": "推荐一款功能饮料", "category": "功能饮料"},
    {"query": "推荐坚果零食", "category": "坚果"},
    {"query": "推荐一款智能手机", "category": "智能手机"},
    {"query": "推荐一款蜜粉", "category": "蜜粉"},
    {"query": "推荐一支唇釉", "category": "唇釉"},
    {"query": "推荐一款眼霜", "category": "眼霜"},
    {"query": "推荐一款化妆水", "category": "化妆水"},
    {"query": "推荐篮球鞋", "category": "篮球鞋"},
    {"query": "推荐咖啡", "category": "咖啡", "follow_up": "对比前两款"},
    {"query": "推荐防晒", "category": "防晒", "follow_up": "把第一个加入购物车"},
]


def main() -> None:
    client = TestClient(app)
    cases: list[dict[str, Any]] = []
    latencies: list[float] = []

    for index, case in enumerate(QUERY_SET, start=1):
        session_id = f"benchmark-{index}"
        started = time.perf_counter()
        response = client.post(
            "/api/chat",
            json={"session_id": session_id, "message": case["query"], "stream": False},
        )
        elapsed_ms = (time.perf_counter() - started) * 1000
        latencies.append(elapsed_ms)

        body = response.json()
        products = body.get("products", [])
        metrics = evaluate_case(case, body, products)

        follow_up_result = None
        if case.get("follow_up"):
            follow = client.post(
                "/api/chat",
                json={"session_id": session_id, "message": case["follow_up"], "stream": False},
            )
            follow_up_result = {"status_code": follow.status_code, "intent": follow.json().get("intent")}

        cases.append(
            {
                "query": case["query"],
                "status_code": response.status_code,
                "latency_ms": round(elapsed_ms, 2),
                "intent": body.get("intent"),
                "product_ids": [product.get("id") for product in products],
                "metrics": metrics,
                "follow_up": follow_up_result,
            }
        )

    summary = summarize(cases, latencies)
    output = {"summary": summary, "cases": cases}
    output_path = ROOT / "docs" / "assets" / "benchmark_results.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    print(f"Wrote {output_path}")


def evaluate_case(case: dict[str, Any], body: dict[str, Any], products: list[dict[str, Any]]) -> dict[str, float | bool]:
    expect_empty = bool(case.get("expect_empty"))
    top3 = products[:3]
    category_hits = [matches_category(product, case.get("category", "")) for product in top3]

    precision = 1.0 if expect_empty and not top3 else (sum(category_hits) / max(len(top3), 1))
    recall = 1.0 if any(category_hits) or (expect_empty and not top3) else 0.0
    constraint_hit = constraints_pass(case, top3)
    grounding = answer_is_grounded(body.get("answer", ""), top3)
    hallucination = 0.0 if grounding else 1.0
    review_hit = True
    if case.get("requires_review"):
        review_hit = any(product.get("review_references") for product in top3)

    return {
        "precision_at_3": round(precision, 4),
        "capped_recall_at_3": round(recall, 4),
        "constraint_hit": constraint_hit and review_hit,
        "grounding": grounding,
        "hallucination_rate": hallucination,
    }


def matches_category(product: dict[str, Any], expected: str) -> bool:
    if not expected:
        return True
    text = " ".join(
        str(value or "")
        for value in [
            product.get("name"),
            product.get("category"),
            product.get("sub_category"),
            product.get("description"),
            " ".join(product.get("tags", [])),
        ]
    )
    return expected.lower() in text.lower()


def constraints_pass(case: dict[str, Any], products: list[dict[str, Any]]) -> bool:
    if case.get("expect_empty"):
        return not products
    if case.get("max_price") is not None and any(product.get("price", 0) > case["max_price"] for product in products):
        return False
    exclusions = [item.lower() for item in case.get("exclusions", [])]
    for product in products:
        product_text = json.dumps(product, ensure_ascii=False).lower()
        if any(exclusion in product_text for exclusion in exclusions):
            return False
    return True


def answer_is_grounded(answer: str, products: list[dict[str, Any]]) -> bool:
    if not products:
        return "没有" in answer or "未找到" in answer or "不会编造" in answer
    names = [product.get("name", "") for product in products]
    return any(name and name in answer for name in names) or "本地商品库" in answer or "商品库" in answer


def summarize(cases: list[dict[str, Any]], latencies: list[float]) -> dict[str, float]:
    metric_rows = [case["metrics"] for case in cases]
    sorted_latencies = sorted(latencies)
    p95_index = min(len(sorted_latencies) - 1, int(len(sorted_latencies) * 0.95))
    return {
        "case_count": len(cases),
        "precision_at_3": round(statistics.mean(row["precision_at_3"] for row in metric_rows), 4),
        "capped_recall_at_3": round(statistics.mean(row["capped_recall_at_3"] for row in metric_rows), 4),
        "constraint_hit_rate": round(statistics.mean(1.0 if row["constraint_hit"] else 0.0 for row in metric_rows), 4),
        "grounding_rate": round(statistics.mean(1.0 if row["grounding"] else 0.0 for row in metric_rows), 4),
        "hallucination_rate": round(statistics.mean(row["hallucination_rate"] for row in metric_rows), 4),
        "avg_latency_ms": round(statistics.mean(latencies), 2),
        "p95_latency_ms": round(sorted_latencies[p95_index], 2),
    }


if __name__ == "__main__":
    main()
