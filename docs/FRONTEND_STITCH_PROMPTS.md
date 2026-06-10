# Stitch 前端设计提示词

## 目标

为 ShopPilot AI 生成移动端电商导购助手 UI，供 Expo / React Native 实现。设计必须突出“对话中出现商品卡片”的交互创新，而不是传统商品列表。

## 主提示词

```text
请为 ShopPilot AI 设计一套移动端 AI 电商导购助手 UI。

项目定位：ShopPilot AI 是一个基于 RAG 的对话式电商智能导购助手。用户用自然语言表达购买需求，AI 从本地商品库中推荐真实商品，并在对话流中展示商品卡片、支持多轮追问、对比、购物车操作和真实测评参考。

设计目标：
1. 移动端优先，适合 Expo / React Native 实现。
2. 风格年轻、可信、轻电商、AI 助手感。
3. 主色建议蓝紫渐变或清爽绿色，卡片圆角、柔和阴影、信息层级清晰。
4. 强调“聊天 + 商品决策”的一体化体验。
5. 不要做复杂登录、支付、订单系统，专注 Demo 闭环。

请输出以下页面：
1. 首页 / 启动页：品牌名 ShopPilot AI、副标题“会聊天、懂商品、能帮你做购买决策”、3 个快捷提问卡片。
2. 聊天页：顶部 Agent 名称与在线状态，中部消息流，底部输入框、图片上传按钮占位、发送按钮。
3. 商品推荐卡片：横向滑动，包含商品图、名称、价格、类目标签、推荐理由、真实测评参考入口、加入购物车按钮、对比按钮。
4. 商品详情弹层：商品大图、品牌、价格、SKU、详情描述、推荐理由、真实测评参考列表、返回对话与加入购物车按钮。
5. 购物车抽屉：已加入商品、数量加减、删除、模拟确认下单按钮。
6. 对比面板：对比前两款商品，展示价格、类目、核心卖点、适用场景和推荐结论。
7. 测评参考模块：当商品存在 `review_references` 时展示“真实测评参考”，以小卡片或平台 chips 形式展示 TikTok / 小红书 / YouTube / 其他平台来源、作者、标题、摘要和“查看测评”按钮；当没有测评链接时隐藏该区域，不展示空状态。

请补充以下状态：
- loading：AI 正在思考
- streaming：AI 分段输出
- empty：首次进入无消息
- error：接口失败
- added-to-cart：加入购物车成功 toast
- no-result：商品库无完全匹配项
- no-review-reference：商品没有外部测评链接时，商品卡不出现测评入口，详情页可用轻量提示“暂无外部测评链接”

组件命名请使用：
- ChatScreen
- ChatBubble
- ProductCard
- ProductCarousel
- ProductDetailSheet
- CartDrawer
- ComparePanel
- ReviewReferenceCard
- ReviewReferenceSheet
- QuickPromptCard
- TypingIndicator
```

## 给开发的交付要求

```text
请在 Figma 中标注组件层级、颜色 token、字体层级、间距、圆角、阴影、按钮状态和组件命名。输出时请确保 React Native 能按组件拆分实现，并避免依赖复杂 Web-only 效果。

请额外设计 `ReviewReferenceCard`：用于展示真实测评参考链接，字段包括平台 `platform`、标题 `title`、作者 `author`、摘要 `summary` 和外链按钮 `url`。视觉上要和商品推荐理由区分开，强调“来自他人测评，仅供参考”，避免让用户误认为是官方承诺。
```
