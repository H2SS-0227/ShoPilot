# 提交材料

## 项目亮点

- 可信 RAG 推荐：所有商品事实来自本地商品库，LLM 只负责导购话术和解释。
- 流式体验：后端 SSE 输出 `meta/delta/final/done/error`，Web 与 SwiftUI 共用协议。
- 多轮决策：支持预算、偏好、排除条件、对比、加入购物车和查看购物车。
- 测评参考：推荐商品可附带 TikTok 等真实测评链接，辅助用户决策。
- 双端交付：Expo/Web 用于公网 Demo 和 GIF 录制，SwiftUI iOS 用于正式移动端交付。

## 仓库与运行

- 目标仓库：`git@github.com:H2SS-0227/ShoPilot.git`
- 主分支：`main`
- 本地启动：见 `README.md`
- 部署说明：见 `docs/DEPLOYMENT.md`

## 交付资产

- Poster：`docs/assets/poster.png`
- Banner：`docs/assets/banner.png`
- 核心流程 GIF：`docs/assets/shoppilot-core-flow.gif`
- Benchmark：`docs/BENCHMARK.md` 与 `docs/assets/benchmark_results.json`

## 自测结果

- 后端：`python3 -m pytest server/tests`。
- 前端：`cd client && npm run typecheck`。
- Web 导出：`cd client && npm run build:web`。
- Swift 源码构建：`cd ios/ShopPilotNative && swift build --disable-sandbox --target ShopPilotCore && swift build --disable-sandbox --target ShopPilotNativeApp`。
- Benchmark：`python3 scripts/run_benchmark.py`，25 条演示级查询，Precision@3 `0.8267`，Grounding `1.0000`。

## 已知限制

- 当前机器 Command Line Tools 缺少可用 `XCTest` 模块，Swift 单测文件已提供，但完整 `swift test` 需完整 Xcode 环境。
- 公网完整服务优先走 Vercel；若账号或平台限制导致后端函数不可用，仓库、本地运行、GIF、图片和文档仍满足可复现交付。
- Benchmark 是演示级对比，不做未经验证的真实市场竞品绝对结论。

## 安全说明

- `server/.env`、`.stitch/.env`、`.mcp/stitch.json` 被 `.gitignore` 忽略。
- README 和文档不包含真实 API Key。
- 推送前需执行密钥扫描，确认 Ark/Stitch/API Key 不进入 GitHub。
