import re

from app.schemas.product import Product, ReviewReference, Sku


def _clean_text(value: str) -> str:
    return re.sub(r"\s+", " ", value or "").strip()


def _extract_tags(raw: dict) -> list[str]:
    tags: set[str] = set()
    for key in ("category", "sub_category", "brand"):
        value = raw.get(key)
        if value:
            tags.add(str(value))

    text = raw.get("rag_knowledge", {}).get("marketing_description", "")
    tag_keywords = [
        "学生党", "通勤", "敏感肌", "油皮", "混油皮", "干皮", "抗初老", "保湿", "控油",
        "轻量", "运动", "旅行", "出差", "办公", "商务", "续航", "快充", "无糖", "咖啡",
    ]
    for keyword in tag_keywords:
        if keyword in text:
            tags.add(keyword)
    return sorted(tags)


def _extract_features(raw: dict) -> list[str]:
    knowledge = raw.get("rag_knowledge", {})
    description = knowledge.get("marketing_description", "")
    sentences = re.split(r"[。！？!?.]", description)
    return [_clean_text(sentence) for sentence in sentences[:4] if _clean_text(sentence)]


def _detect_platform(url: str) -> str:
    lowered = url.lower()
    if "tiktok.com" in lowered:
        return "TikTok"
    if "douyin.com" in lowered:
        return "Douyin"
    if "xiaohongshu.com" in lowered or "xhslink.com" in lowered:
        return "Xiaohongshu"
    if "youtube.com" in lowered or "youtu.be" in lowered:
        return "YouTube"
    return "unknown"


def _extract_review_references(raw: dict) -> list[ReviewReference]:
    references: list[ReviewReference] = []
    candidates = []
    knowledge = raw.get("rag_knowledge", {})
    for key in ("review_references", "review_links", "evaluation_links", "social_reviews", "content_references"):
        value = raw.get(key) or knowledge.get(key)
        if isinstance(value, list):
            candidates.extend(value)

    for item in candidates:
        if isinstance(item, str):
            url = item.strip()
            title = "外部测评参考"
            author = None
            summary = None
        elif isinstance(item, dict):
            url = str(item.get("url") or item.get("link") or "").strip()
            title = str(item.get("title") or item.get("name") or "外部测评参考").strip()
            author = item.get("author") or item.get("creator")
            summary = item.get("summary") or item.get("description")
        else:
            continue
        if not url.startswith(("http://", "https://")):
            continue
        references.append(
            ReviewReference(
                title=title,
                url=url,
                platform=_detect_platform(url),
                author=author,
                summary=summary,
            )
        )
    return references


def normalize_product(raw: dict, dataset_root: str = "") -> Product:
    knowledge = raw.get("rag_knowledge", {})
    image_path = raw.get("image_path")
    image_url = f"/assets/products/{image_path}" if image_path else None

    return Product(
        id=raw["product_id"],
        name=raw["title"],
        category=raw.get("category", ""),
        sub_category=raw.get("sub_category"),
        brand=raw.get("brand"),
        price=float(raw.get("base_price", 0)),
        description=_clean_text(knowledge.get("marketing_description", "")),
        image_url=image_url,
        features=_extract_features(raw),
        tags=_extract_tags(raw),
        skus=[Sku(**sku) for sku in raw.get("skus", [])],
        review_references=_extract_review_references(raw),
        source="local_dataset",
    )
