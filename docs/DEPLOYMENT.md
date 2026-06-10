# 部署说明

## 本地运行

```bash
cd /Users/bytedance/Desktop/ShoPilot
python3 -m pip install -r server/requirements.txt
python3 scripts/ingest_dataset.py
./scripts/dev_server.sh
```

另开终端：

```bash
cd /Users/bytedance/Desktop/ShoPilot/client
npm install
npm run web
```

## Vercel 部署

项目已加入：

- `vercel.json`：构建 Expo Web，并把 `/api/*`、`/health`、`/assets/products/*` 转发到 FastAPI。
- `api/index.py`：Vercel Python Function 入口，复用 `server/app/main.py` 的 FastAPI app。
- `requirements.txt`：指向 `server/requirements.txt`。

推荐环境变量：

```env
LLM_PROVIDER=volcengine_ark
LLM_API_BASE=https://ark.cn-beijing.volces.com/api/v3/
LLM_API_KEY=在 Vercel 控制台配置，不写入仓库
LLM_MODEL=ep-20260514111645-lmgt2
ENABLE_LLM=true
```

如果没有配置 `LLM_API_KEY` 或平台阻止外部调用，后端会使用本地 RAG + 模板回答兜底，Demo 仍可运行。

## Web 同源 API

`client/src/config/env.ts` 已做部署适配：

- 本地 Web：默认请求 `http://127.0.0.1:8000/api/...`。
- Vercel 域名：请求同源 `/api/...`。
- Expo 真机：通过 `EXPO_PUBLIC_API_BASE_URL` 指向局域网后端。

## 验证清单

```bash
curl https://你的域名/health
curl -X POST https://你的域名/api/chat -H 'Content-Type: application/json' -d '{"session_id":"deploy","message":"推荐一款咖啡","stream":false}'
curl -N -X POST https://你的域名/api/chat -H 'Content-Type: application/json' -H 'Accept: text/event-stream' -d '{"session_id":"deploy-sse","message":"推荐一款咖啡","stream":true}'
```

同时检查：

- Web 首页可打开。
- 商品图 `/assets/products/...` 可加载。
- SSE 返回 `meta`、`delta`、`final`、`done`。
- 无密钥时不会暴露错误堆栈，仍返回兜底回答。
