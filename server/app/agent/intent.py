from typing import Optional
import re

from app.schemas.intent import Constraints


CATEGORY_KEYWORDS = [
    "笔记本电脑", "真无线耳机", "平板电脑", "短袖T恤", "速干T恤", "运动长裤",
    "运动短裤", "智能手机", "功能饮料", "坚果/零食", "碳酸饮料", "方便食品",
    "蓝牙耳机", "洗面奶", "化妆水", "粉底液", "户外裤", "瑜伽裤", "徒步鞋",
    "篮球鞋", "跑步鞋", "调味品", "防晒", "精华", "面霜", "眼霜", "蜜粉",
    "卸妆", "洁面", "眉笔", "唇釉", "面膜", "咖啡", "酸奶", "牛奶", "茶饮",
    "卫衣", "背包", "帽子", "耳机", "手机", "平板", "电脑", "跑鞋", "运动鞋",
    "T恤", "短袖", "零食", "饮料", "护肤", "美妆",
]

PREFERENCE_KEYWORDS = [
    "轻量", "长续航", "通勤", "学生党", "敏感肌", "油皮", "混油皮", "干皮", "保湿",
    "控油", "抗初老", "便宜", "性价比", "旅行", "出差", "办公", "运动", "无糖", "低脂",
]


def detect_intent(message: str) -> str:
    text = message.lower()
    if any(word in message for word in ["购物车", "车里", "已加"]):
        if any(word in message for word in ["查看", "看看", "有什么"]):
            return "view_cart"
    if any(word in message for word in ["加入购物车", "加购物车", "加入", "加到车", "放进购物车"]):
        return "add_to_cart"
    if any(word in message for word in ["删除", "移除", "不要这个"]):
        return "remove_from_cart"
    if any(word in message for word in ["对比", "比较", "哪个更", "哪款更"]):
        return "compare"
    if any(word in message for word in ["详情", "介绍", "参数"]):
        return "detail"
    if any(word in message for word in ["推荐", "想买", "适合", "来一款", "便宜点", "再便宜"]):
        return "recommend"
    if text.strip() in {"hi", "hello", "你好"}:
        return "smalltalk"
    return "recommend"


def parse_constraints(message: str) -> Constraints:
    constraints = Constraints()
    constraints.category = _extract_category(message)
    constraints.budget_max = _extract_budget_max(message)
    constraints.budget_min = _extract_budget_min(message)
    constraints.preferences = _extract_preferences(message)
    constraints.exclusions = _extract_exclusions(message)
    constraints.referenced_product_position = _extract_position(message)
    constraints.scenario = _extract_scenario(message)
    constraints.target_user = _extract_target_user(message)
    return constraints


def _extract_category(message: str) -> Optional[str]:
    for keyword in sorted(CATEGORY_KEYWORDS, key=len, reverse=True):
        if keyword.lower() in message.lower():
            return keyword
    return None


def _extract_budget_max(message: str) -> Optional[float]:
    patterns = [r"(\d+(?:\.\d+)?)\s*(?:元|块)?\s*(?:以内|以下|内)", r"预算\s*(?:不超过|最多|在)?\s*(\d+(?:\.\d+)?)"]
    for pattern in patterns:
        match = re.search(pattern, message)
        if match:
            return float(match.group(1))
    if "再便宜" in message or "便宜点" in message:
        return None
    return None


def _extract_budget_min(message: str) -> Optional[float]:
    match = re.search(r"(\d+(?:\.\d+)?)\s*(?:元|块)?\s*(?:以上|起)", message)
    return float(match.group(1)) if match else None


def _extract_preferences(message: str) -> list[str]:
    return [keyword for keyword in PREFERENCE_KEYWORDS if keyword in message]


def _extract_exclusions(message: str) -> list[str]:
    exclusions: list[str] = []
    for pattern in [r"不要([^，。,.；;]+)", r"不含([^，。,.；;]+)", r"排除([^，。,.；;]+)", r"除了([^，。,.；;]+)"]:
        for match in re.finditer(pattern, message):
            value = match.group(1).strip()
            value = re.sub(r"^(含|有|是)", "", value).strip()
            if value:
                exclusions.append(value)
    if any(keyword in message for keyword in ["不要太甜", "不太甜", "别太甜", "不要甜", "无糖", "少糖"]):
        exclusions.extend(["白砂糖", "三合一", "奶香", "甜味"])
    return exclusions


def _extract_position(message: str) -> Optional[int]:
    mapping = {"第一个": 1, "第一款": 1, "前一个": 1, "第二个": 2, "第二款": 2, "第三个": 3, "第三款": 3}
    for keyword, position in mapping.items():
        if keyword in message:
            return position
    return None


def _extract_scenario(message: str) -> Optional[str]:
    for keyword in ["通勤", "旅行", "出差", "办公", "上课", "运动", "三亚", "日常"]:
        if keyword in message:
            return keyword
    return None


def _extract_target_user(message: str) -> Optional[str]:
    for keyword in ["学生党", "上班族", "敏感肌", "油皮", "混油皮", "干皮", "男生", "女生"]:
        if keyword in message:
            return keyword
    return None
