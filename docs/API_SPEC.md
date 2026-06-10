# API 设计

## Health

### GET /health

用于部署和联调探活。

```json
{ "status": "ok", "app": "ShopPilot AI" }
```

## Chat

### POST /api/chat

统一聊天接口，保留 JSON 非流式行为，并支持 SSE 流式行为。

请求字段：

- `session_id`：会话 ID，用于多轮上下文、对比和购物车引用。
- `message`：用户自然语言需求。
- `stream`：`false` 返回 JSON；`true` 返回 `text/event-stream`。

非流式请求示例：

```bash
curl -X POST http://127.0.0.1:8000/api/chat   -H 'Content-Type: application/json'   -d '{"session_id":"demo","message":"推荐一款 200 元以内的咖啡","stream":false}'
```

SSE 请求示例：

```bash
curl -N -X POST http://127.0.0.1:8000/api/chat   -H 'Content-Type: application/json'   -H 'Accept: text/event-stream'   -d '{"session_id":"demo","message":"推荐一款 200 元以内的咖啡","stream":true}'
```

SSE 事件固定为：

- `meta`：会话、意图和创建时间，例如 `{"session_id":"demo","intent":"recommend","created_at":1781090000}`。
- `delta`：增量文本片段，例如 `{"text":"我从商品库"}`。
- `final`：完整 `ChatResponse`，用于回放、降级和最终状态对齐。
- `done`：流结束，例如 `{"ok":true}`。
- `error`：流式过程错误，例如 `{"message":"..."}`。

`ChatResponse` 字段：

- `type`：固定为 `final`。
- `intent`：`recommend`、`compare`、`add_to_cart`、`remove_from_cart`、`view_cart`、`clarify`。
- `answer`：最终完整回答。
- `products`：推荐商品数组。
- `comparison`：对比表格行。
- `cart_action`：购物车动作。
- `clarifying_question`：需要追问时返回。
- `suggested_actions`：推荐下一步操作。

`products[].review_references` 可包含真实外部测评参考链接，字段包括 `title`、`url`、`platform`、`author`、`summary`。如果当前商品没有已入库测评链接，则返回空数组，前端应隐藏测评入口。

## Products

### GET /api/products/{product_id}

返回标准化商品详情。商品详情同样返回 `review_references`，用于详情页展示 TikTok / 小红书 / YouTube 等外部测评参考。

商品图片通过 `/assets/products/...` 暴露，例如：

```text
/assets/products/4_食品生活/images/p_food_001_live.jpg
```

## Cart

### GET /api/cart

按 `session_id` 返回购物车。

### POST /api/cart/items

添加商品到购物车。
