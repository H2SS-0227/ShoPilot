# API 接口配置与启动说明

## 1. 后端环境变量

复制示例配置：

```bash
cp server/.env.example server/.env
```

`server/.env` 中需要包含：

```env
APP_NAME=ShopPilot AI
APP_ENV=local
API_HOST=0.0.0.0
API_PORT=8000
LLM_PROVIDER=volcengine_ark
LLM_API_BASE=https://ark.cn-beijing.volces.com/api/v3/
LLM_API_KEY=填写你的本地密钥
LLM_MODEL=ep-20260514111645-lmgt2
LLM_MODEL_NAME=Doubao-Seed-2.0-lite
DATASET_ROOT=ecommerce_agent_dataset
NORMALIZED_PRODUCTS_PATH=server/data/normalized/products.json
RAG_INDEX_DIR=server/data/indexes
RETRIEVER_BACKEND=tfidf
ENABLE_SSE=true
```

注意：`LLM_API_KEY` 只能放在本地 `.env`，不要写入 README、文档、前端代码或录屏画面。

## 2. 安装后端依赖

```bash
pip install -r server/requirements.txt
```

## 3. 导入商品数据

```bash
python scripts/ingest_dataset.py
```

成功后会生成：

```text
server/data/normalized/products.json
```

## 4. 启动后端

```bash
uvicorn app.main:app --reload --app-dir server
```

健康检查：

```bash
curl http://127.0.0.1:8000/health
```

## 5. 测试 Chat API

```bash
curl -X POST http://127.0.0.1:8000/api/chat   -H 'Content-Type: application/json'   -d '{"session_id":"demo-session","message":"推荐一款 200 元以内的咖啡","stream":false}'
```

## 6. 前端接口配置

前端默认请求：

```text
http://localhost:8000
```

如需改地址，启动前设置：

```bash
export EXPO_PUBLIC_API_BASE_URL=http://127.0.0.1:8000
```

## 7. 当前 API 清单

- `GET /health`：健康检查
- `POST /api/chat`：对话推荐、对比、购物车自然语言操作
- `GET /api/products`：查看标准化商品列表
- `GET /api/products/{product_id}`：查看商品详情
- `GET /api/cart?session_id=demo-session`：查看购物车
- `POST /api/cart/items`：加入购物车
- `DELETE /api/cart/items/{product_id}`：移除购物车
