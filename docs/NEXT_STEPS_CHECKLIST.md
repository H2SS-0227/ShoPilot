# 下一步准备工作 Checklist

## 必做

- [ ] 安装 Python 依赖：`pip install -r server/requirements.txt`
- [ ] 确认 `server/.env` 存在且填入本地 `LLM_API_KEY`
- [ ] 执行 `python scripts/ingest_dataset.py`
- [ ] 启动后端：`uvicorn app.main:app --reload --app-dir server`
- [ ] 测试 `/health` 和 `/api/chat`
- [ ] 安装前端依赖：`cd client && npm install`
- [ ] 启动前端：`npm run start`

## 前端协作

- [ ] 将 `docs/FRONTEND_STITCH_PROMPTS.md` 发给 Stitch 生成 UI
- [ ] 获取 Figma 文件链接或 file key
- [ ] 配置 Figma MCP server 和 `FIGMA_ACCESS_TOKEN`
- [ ] 通过 Figma MCP 读取组件树和 design tokens
- [ ] 将 Figma 组件映射到 `client/src/components/*`

## Demo 准备

- [ ] 准备 5 条演示问题
- [ ] 验证“推荐 -> 再便宜 -> 排除 -> 对比 -> 加购物车”链路
- [ ] 录屏前确认不展示 `.env`、API Key、Token
- [ ] 补充提交材料：项目亮点、代码仓库、设计文档、Demo 视频链接
