# RAG 算法实现说明

## 已实现能力

- 原始商品数据读取：`ecommerce_agent_dataset/*/data/*.json`
- 标准 Product Schema 映射：`id`、`name`、`category`、`brand`、`price`、`description`、`image_url`、`features`、`tags`、`skus`
- 商品文本化：每个商品作为一个 chunk，拼接名称、品牌、类目、价格、描述、卖点、标签和 SKU
- TF-IDF 召回：使用 `char_wb` 2-4 gram，适配中文短查询
- 结构化过滤：预算、类目别名、排除词
- 综合排序：语义相似度 65%，约束匹配 30%，价格偏好 5%
- 多轮上下文：保留上一轮约束和推荐商品 ID
- 购物车指代解析：支持“第一个”“第二款”等表达

## 关键文件

- `server/app/data/repository.py`
- `server/app/data/normalizer.py`
- `server/app/rag/document.py`
- `server/app/rag/retriever.py`
- `server/app/agent/intent.py`
- `server/app/api/routes/chat.py`

## 当前策略

MVP 阶段优先稳定、可解释、无需外部 embedding 服务。后续可把 `ProductRetriever` 的向量化部分替换为 FAISS / Chroma / Ark embedding，不影响 API 层和前端结构。
