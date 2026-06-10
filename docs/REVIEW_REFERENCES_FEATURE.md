# 真实测评参考功能评估

## 需求说明

在推荐商品时，如果商品存在相关外部测评链接，例如 TikTok 图文 / 视频、小红书笔记、YouTube 测评或其他真实图文内容，将这些链接作为“他人真实测评参考”展示给用户，辅助购买决策。

## 可行性结论

该需求可行，但必须区分“展示已入库真实链接”和“实时抓取平台内容”。

MVP 阶段建议采用“数据集预留字段 + 前端条件展示”的方案：商品数据中有 `review_references` 时展示，没有时隐藏。这样实现成本低、合规风险低，并且符合项目的可信 RAG 原则。

## 推荐实现路径

1. 数据层新增 `review_references` 字段，保存真实测评链接。
2. 后端标准化商品数据时解析 `review_references`、`review_links`、`evaluation_links`、`social_reviews`、`content_references` 等候选字段。
3. Chat API 与商品详情 API 原样返回 `review_references`。
4. 前端商品卡展示“真实测评参考”入口，详情页展示完整测评参考列表。
5. 如果没有真实链接，前端隐藏入口，Agent 不主动声称存在外部测评。

## 不建议 MVP 阶段做的事情

- 不建议由 LLM 生成 TikTok / 小红书链接。
- 不建议未经授权实时爬取 TikTok、小红书等平台内容。
- 不建议展示无法验证的点赞数、收藏数、带货销量或作者身份。
- 不建议把外部测评结论当作官方承诺。

## 数据结构

```json
{
  "review_references": [
    {
      "title": "创作者对这款商品的真实测评",
      "url": "https://www.tiktok.com/@creator/video/xxxx",
      "platform": "TikTok",
      "author": "creator_name",
      "summary": "测评中提到适合通勤场景，佩戴舒适度较高。"
    }
  ]
}
```

## 展示原则

- 文案使用“真实测评参考”“来自他人测评，仅供参考”。
- 不要写“权威认证”“官方推荐”“全网好评”等无法验证表述。
- 链接打开前可提示用户将跳转第三方平台。
- 如果平台链接不可访问，应允许前端降级为不可点击或隐藏。

## 当前项目状态

当前 `ecommerce_agent_dataset` 中主要包含商品描述、FAQ 和用户评论文本，没有检测到外部测评 URL。因此代码已完成字段预留和解析逻辑，但默认返回空 `review_references`。

后续只要在商品 JSON 中补充真实链接，重新执行：

```bash
python3 scripts/ingest_dataset.py
```

API 就会返回该字段，前端即可展示。
