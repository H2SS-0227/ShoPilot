# 数据规范

## 标准 Product Schema

- `id`：商品 ID，来自 `product_id`
- `name`：商品名称，来自 `title`
- `category`：一级类目
- `sub_category`：二级类目
- `brand`：品牌
- `price`：基础价格，来自 `base_price`
- `currency`：默认 `CNY`
- `description`：可检索描述，来自 `rag_knowledge.marketing_description`
- `image_url`：商品封面图 URL，来自 `image_path`，标准化后形如 `/assets/products/1_美妆护肤/images/p_beauty_001_live.jpg`
- `review_references`：外部真实测评参考链接列表，可来自 TikTok、小红书、YouTube、图文测评等已入库数据；没有真实链接时为空数组
- `skus`：SKU 规格和价格
- `source`：固定为 `local_dataset`

## ReviewReference Schema

- `title`：测评标题
- `url`：测评链接，必须是 `http://` 或 `https://` 开头的真实 URL
- `platform`：平台来源，例如 `TikTok`、`Douyin`、`Xiaohongshu`、`YouTube`、`unknown`
- `author`：作者或创作者，可选
- `summary`：测评摘要，可选，必须来自数据源或后续可信采集流程

## Chunk 策略

每个商品作为一个 chunk，避免拆散价格、主图、详情、FAQ 和评论上下文。

外部测评链接不作为商品事实本身，只作为“决策参考来源”展示。系统不得编造测评链接、作者、点赞数或评价结论。

## 图片资源

后端通过 `/assets/products` 静态挂载 `ecommerce_agent_dataset`，前端需要将相对 `image_url` 拼接为完整 API 地址后加载。Web 示例：`http://127.0.0.1:8000/assets/products/1_美妆护肤/images/p_beauty_001_live.jpg`。
