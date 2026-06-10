# Figma MCP 接入说明

## 当前状态

当前运行环境只检测到浏览器 MCP，没有检测到可直接调用的 Figma MCP server。因此本项目已提供 Figma MCP 配置模板和提示词，但真正连通 Figma 还需要你提供或安装 Figma MCP server，并配置 Figma access token。

## 需要准备

- Figma Personal Access Token
- Figma 文件链接或 file key
- 可用的 Figma MCP server，例如支持 `get_file`、`get_node`、`export_assets`、`inspect_components` 的 server
- 本地 MCP 配置位置，取决于你使用的 IDE / Agent 宿主

## MCP 配置模板

请将以下内容按你的 MCP 宿主要求填入配置文件。不同工具字段可能略有差异，核心是 `command`、`args` 和 `env.FIGMA_ACCESS_TOKEN`。

```json
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "figma-developer-mcp"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "${FIGMA_ACCESS_TOKEN}"
      }
    }
  }
}
```

## Figma MCP 使用提示词

```text
请通过 Figma MCP 读取 ShopPilot AI 的 Figma 文件，提取以下内容并生成 React Native 实现规格：

1. 页面结构：启动页、聊天页、商品详情弹层、购物车抽屉、对比面板。
2. 组件树：ChatScreen、ChatBubble、ProductCard、ProductCarousel、ProductDetailSheet、CartDrawer、ComparePanel、QuickPromptCard、TypingIndicator。
3. Design Tokens：颜色、字体、字号、行高、圆角、阴影、间距。
4. 图片与图标资产：列出需要导出的 asset 名称、尺寸、格式和用途。
5. 交互状态：loading、streaming、empty、error、added-to-cart、no-result。
6. 输出前端实现建议：哪些组件为容器组件，哪些组件为纯展示组件，哪些状态由 API 驱动。

请严格输出结构化 Markdown，并给出可直接转成 Expo / React Native 组件的实现清单。
```

## 接入验证步骤

1. 在 MCP 宿主中添加 Figma server 配置。
2. 设置环境变量 `FIGMA_ACCESS_TOKEN`，不要把 token 写入仓库。
3. 重启 IDE / Agent。
4. 让 Agent 执行“列出 Figma 文件页面”或“读取指定 file key”。
5. 如果能返回页面树和节点信息，说明 MCP 已连通。

## 本项目内的限制

本仓库不会提交 Figma token，也不会提交真实 MCP 密钥。若需要我继续完成真实 Figma MCP 调用，请提供已安装 MCP server 的名称、工具 schema 或可用 file key。
