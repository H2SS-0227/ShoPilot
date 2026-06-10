# ShopPilot AI 项目架构导览

## 1. 架构目标

ShopPilot AI 的工程结构围绕“今晚可演示、后续可扩展”的目标设计：先保证端到端闭环稳定，再保留 RAG、Agent、前端体验和文档交付的扩展位。

核心链路为：用户输入 -> 客户端聊天页 -> FastAPI Chat API -> 意图与约束解析 -> 商品数据检索 -> Grounded 生成 -> 结构化响应 -> 商品卡片 / 测评参考 / 对比 / 购物车渲染。

## 2. 顶层目录

```text
ShoPilot/
  client/                  # Expo / React Native 移动端客户端
  server/                  # Python FastAPI 后端服务
  ecommerce_agent_dataset/ # 原始商品数据集，保持只读
  docs/                    # 架构、API、数据规范、Demo 与提交材料
  scripts/                 # 本地开发、数据导入、演示辅助脚本
  ShopPilot_AI_Project_Brief.md
  README.md
  .gitignore
```

## 3. 后端分层

`server/app/api/routes/` 是 HTTP 边界层，只负责请求响应协议，不直接承载业务规则。

`server/app/schemas/` 定义跨模块共享的数据契约，包括 `Product`、`ChatRequest`、`ChatResponse`、`Cart`、`Constraints`。前端和 LLM 输出都应向这些结构收敛。

`server/app/data/` 负责读取和标准化原始 dataset。原始数据字段如 `product_id`、`title`、`base_price`、`image_path` 会被映射为标准 Product Schema 的 `id`、`name`、`price`、`image_url`。如果数据源后续补充真实外部测评链接，会映射到 `review_references`。

`server/app/rag/` 负责商品文本化、结构化过滤、语义召回和排序。MVP 阶段优先用 TF-IDF，后续可替换为 Chroma / FAISS，不影响 API 层。

`server/app/agent/` 负责编排对话状态、意图识别、购物车工具、Prompt 和响应构造。它依赖 RAG 返回的商品候选，但不直接读取原始数据。

`server/app/services/` 放置外部服务适配，例如 LLM API Client。所有 Key 只能从环境变量读取。

模型服务采用火山 Ark 兼容接口，默认模型为 Doubao-Seed-2.0-lite，对应模型 ID 为 `ep-20260514111645-lmgt2`。`LLM_API_BASE` 和 `LLM_MODEL` 可写入示例配置，真实 `LLM_API_KEY` 只能放在本地 `server/.env`。

`server/data/normalized/` 保存由导入脚本生成的标准化商品 JSON，不提交生成结果。

`server/data/indexes/` 保存向量索引或 TF-IDF 索引，不提交生成结果。

## 4. 前端分层

`client/src/screens/` 放页面级容器，例如 `ChatScreen`，负责组织消息流、输入框、商品卡片区域和购物车抽屉。

`client/src/components/chat/` 放聊天基础组件，例如用户气泡、AI 气泡、typing 状态和快捷问题。

`client/src/components/product/` 放商品展示组件，例如 `ProductCard` 和后续的商品详情弹层。

`client/src/components/cart/` 放购物车抽屉、购物车行项目和数量操作。

`client/src/components/compare/` 放多商品对比 UI，承接后端 `comparison` 结构化结果。

`client/src/services/` 封装 API 调用，使 UI 组件不关心后端地址、请求格式和错误处理细节。

`client/src/state/` 管理本地 UI 状态和兜底购物车状态。若后端购物车来不及完成，可在这里先完成 Demo 闭环。

`client/src/types/` 镜像后端核心响应类型，减少商品卡片和聊天消息字段漂移。

`client/src/theme/` 统一视觉 token，承接 Stitch / Figma 的颜色、圆角、阴影等设计规范。

## 5. 数据流与依赖关系

`ecommerce_agent_dataset/` 是唯一商品事实来源。后端通过 `scripts/ingest_dataset.py` 调用 `server/app/data/loader.py` 和 `normalizer.py` 生成 `server/data/normalized/products.json`。

RAG 层只消费标准化 Product，不消费原始 JSON，从而隔离字段差异。

Agent 层调用 RAG 层得到候选商品，再结合会话状态生成回答。Agent 的推荐、对比和购物车动作都必须引用候选商品或会话中的已推荐商品 ID。

API 层返回结构化 `ChatResponse`，前端根据 `answer` 渲染 AI 文本，根据 `products` 渲染商品卡片和测评参考入口，根据 `comparison` 渲染对比面板，根据 `cart_action` 更新购物车。

## 6. 设计约束

推荐结果必须来自本地 dataset，不允许编造商品、价格、图片、优惠、库存或功效。

外部测评参考链接也必须来自已入库数据或可信采集流程，不允许模型生成、猜测或拼接 TikTok / 小红书等平台链接。

`.env`、API Key 和内部 Token 不允许提交；仓库只保留 `.env.example`。

实际商品数据源为根目录下的 `ecommerce_agent_dataset/`，开发时默认通过 `DATASET_ROOT=ecommerce_agent_dataset` 读取。

MVP 优先级为：单轮推荐 -> 商品卡片 -> 多轮约束 -> 排除条件 -> 购物车 -> 对比 -> 真 SSE / 多模态模拟。

## 7. 后续实现顺序

1. 执行 `scripts/ingest_dataset.py`，生成标准化商品数据。
2. 实现 `ProductRetriever.search()` 的结构化过滤和 TF-IDF 召回。
3. 实现 `parse_constraints()` 的预算、类目、排除项和“第几个”引用解析。
4. 完成 `/api/chat` 编排，返回最多 3 个商品和推荐理由。
5. 完成 `ChatScreen`、`ProductCard`、`CartDrawer` 的前端联调。
6. 补充 Demo 脚本、README 启动说明和验收 Checklist。
