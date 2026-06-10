# 设计文档

## 项目背景

ShopPilot AI 将传统展示型商品浏览升级为对话式购买决策助手。系统通过本地商品库 RAG 约束模型回答边界，降低商品事实幻觉，并用商品卡、对比和购物车组成可演示的端到端购物决策闭环。

## 系统架构

核心链路：

1. 用户通过 Expo/Web 或 SwiftUI App 输入自然语言需求。
2. 后端 Agent 识别意图、预算、类目、偏好、排除项和引用位置。
3. RAG 检索器从 `ecommerce_agent_dataset` 标准化商品中召回候选商品。
4. LLM 仅生成导购话术和推荐理由，商品事实始终来自本地商品对象。
5. `/api/chat` 以 JSON 或 SSE 返回结果；前端消费同一套协议。

详见 `docs/ARCHITECTURE_GUIDE.md`。

## 数据处理与 RAG

原始商品数据集保持只读，导入脚本统一映射为 Product Schema。检索采用结构化过滤 + TF-IDF 召回 + 约束/价格加权排序的双阶段方案。

结构化过滤覆盖：

- 预算上限和下限。
- 类目和子类目强匹配。
- 排除条件，如 `不要太甜`、`不含酒精`。
- 多轮约束继承和引用位置。

## Agent 设计

Agent 支持：

- `recommend`：商品推荐。
- `compare`：基于最近推荐商品做对比。
- `add_to_cart` / `remove_from_cart` / `view_cart`：购物车操作。
- `clarify`：信息不足时追问。

会话状态保存最近约束与最近推荐商品 ID，使“再便宜一点”“对比前两款”“把第一个加入购物车”等多轮表达可解析。

## SSE 协议

`POST /api/chat` 当 `stream=true` 或 `Accept: text/event-stream` 时返回 SSE：

- `meta`：会话与意图元信息。
- `delta`：逐段文本。
- `final`：完整 `ChatResponse`。
- `done`：结束。
- `error`：错误。

`final` 是降级和回放的权威状态，Web 和 SwiftUI 都以它回填商品、对比和购物车动作。

## 前端体验

Expo/Web：

- Stitch 高保真风格：玻璃卡片、渐变背景、底部输入栏。
- 流式助手气泡、打字光标、Thinking 状态、停止生成、失败重试。
- 商品卡渐入展示、详情 Sheet、对比 Panel、购物车 Drawer。

SwiftUI：

- `ShopPilotCore` 复用 JSON/SSE 协议。
- URLSession 实现 JSON 请求和 SSE 字节流解析。
- ChatViewModel 管理 delta 累积、final 回填、取消和 JSON fallback。

## 风险与兜底

- LLM 接入失败：使用 TF-IDF + 模板化推荐兜底。
- SSE 不可用：Web 和 SwiftUI 均可回落到 JSON 请求。
- 无完全匹配商品：明确说明商品库没有匹配项，不编造商品。
- Vercel 平台限制：至少交付 GitHub 可运行仓库、GIF、poster/banner、文档和本地部署说明。
