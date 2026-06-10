# Stitch 资源获取与前端还原工作流

## 当前项目

- 项目标题：ShopPilot AI Shopping Assistant
- Project ID：`6699502356344548246`
- Screen 清单：见 `.stitch/screens.json`

## 当前阻塞

当前 Trae MCP 配置中未检测到 Stitch MCP server，仅有 `integrated_browser`。因此还不能调用 `get_screen` 获取 `htmlCode.downloadUrl`、`screenshot.downloadUrl` 和 `figmaExport.downloadUrl`。

如果 Stitch 下载链接需要鉴权，请在本地 `.stitch/.env` 中配置 `STITCH_API_KEY`。该文件已加入 `.gitignore`，不要提交。

## 启用 Stitch MCP 后的执行步骤

1. 对 `.stitch/screens.json` 中每个 screen 调用 Stitch MCP `get_screen`。
2. 将返回结果保存到 `.stitch/screen-metadata/{slug}.json`。
3. 使用 `curl -L` 下载：
   - `screenshot.downloadUrl` -> `client/assets/stitch/screenshots/{slug}.png`
   - `htmlCode.downloadUrl` -> `client/assets/stitch/html/{slug}.html`
   - `figmaExport.downloadUrl` -> `client/assets/stitch/figma/{slug}.figma`，如果存在
4. 从 HTML/CSS 中提取颜色、字体、间距、圆角和阴影 token。
5. 按页面拆分 Expo / React Native 组件并进行视觉验收。

下载脚本会自动读取 `.stitch/.env`，并在存在 `STITCH_API_KEY` 时为 `curl` 添加 `x-goog-api-key` 请求头。

## 需要的 Stitch MCP 调用参数

```json
{
  "projectId": "6699502356344548246",
  "screenId": "d2ffa7b2f9104f5985b4b62df86b8f90"
}
```

注意：`projectId` 和 `screenId` 都使用纯 ID，不带 `projects/` 或 `screens/` 前缀。
