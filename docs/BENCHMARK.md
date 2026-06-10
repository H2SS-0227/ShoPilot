# Benchmark 报告

## 定位

本 benchmark 是演示级可重复评估，用于比较 ShopPilot RAG + Agent 在本地商品库上的可用性，不代表真实市场竞品绝对结论。

## 查询集

`/scripts/run_benchmark.py` 内置 25 条查询，覆盖：

- 类目推荐：咖啡、防晒、精华、跑鞋、耳机、手机、平板、笔记本、服饰、食品。
- 预算约束：如 `200 元以内`、`1 元以内的笔记本电脑`。
- 排除条件：如 `不要太甜`、`不要酒精`。
- 多轮约束：推荐后 `对比前两款`、`把第一个加入购物车`。
- 测评参考：要求返回 TikTok 等真实测评链接。
- 无结果：严格预算下不编造不存在商品。

## 指标

当前结果来自：`python3 scripts/run_benchmark.py`。

- Precision@3：`0.8267`
- capped Recall@3：`0.9600`
- 约束命中率：`0.9600`
- 商品事实 grounding 率：`1.0000`
- 幻觉率：`0.0000`
- API 平均延迟：`2.89 ms`
- API p95 延迟：`3.43 ms`

完整逐条结果见 `docs/assets/benchmark_results.json`。

## Baseline 说明

- 关键词搜索 baseline：只看关键词与商品文本匹配，缺少多轮状态、购物车引用和回答生成。
- 无 RAG 通用回答 baseline：可生成自然语言，但不能验证商品事实、价格、测评链接和库存边界。
- ShopPilot RAG + Agent：先做结构化约束解析和本地商品召回，再用 LLM 或模板生成回答，商品事实始终来自本地数据。

## 复现

```bash
cd /Users/bytedance/Desktop/ShoPilot
python3 scripts/run_benchmark.py
```

脚本默认设置 `ENABLE_LLM=false`，避免 benchmark 依赖外部密钥和网络。
