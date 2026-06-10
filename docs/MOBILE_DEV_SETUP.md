# 移动端开发与联调说明

## Expo / Web 客户端

后端需要监听 `0.0.0.0`，便于真机访问：

```bash
cd /Users/bytedance/Desktop/ShoPilot
./scripts/dev_server.sh
```

启动前端：

```bash
cd /Users/bytedance/Desktop/ShoPilot/client
npm install
npm run start
```

前端读取 `EXPO_PUBLIC_API_BASE_URL`。

- Web：本地默认 `http://127.0.0.1:8000`，部署后默认同源 `/api`。
- iOS Simulator：通常可用 `http://127.0.0.1:8000`。
- Android Emulator：使用 `http://10.0.2.2:8000`。
- Expo Go 真机：使用 Mac 的局域网 IP，例如 `http://192.168.1.23:8000`。

复制配置文件：

```bash
cd /Users/bytedance/Desktop/ShoPilot/client
cp .env.example .env
```

真机调试时查询 Mac 局域网 IP：

```bash
ipconfig getifaddr en0
```

然后设置：

```env
EXPO_PUBLIC_API_BASE_URL=http://你的Mac局域网IP:8000
```

修改 `.env` 后需要重启 Expo。

## SwiftUI 原生 App

新增原生工程位于 `ios/ShopPilotNative`，采用 Swift Package 形式组织：

- `ShopPilotCore`：模型、SSE parser、URLSession API client、ChatViewModel。
- `ShopPilotNativeApp`：SwiftUI 聊天页、商品卡片、详情 Sheet、对比 Sheet、购物车 Sheet、测评参考入口。
- `ShopPilotCoreTests`：SSE parser 和 ViewModel 状态转移测试。

当前机器验证命令：

```bash
cd /Users/bytedance/Desktop/ShoPilot/ios/ShopPilotNative
swift build --disable-sandbox --target ShopPilotCore
swift build --disable-sandbox --target ShopPilotNativeApp
```

说明：当前 Command Line Tools 环境缺少可用 `XCTest` 模块，`swift test --disable-sandbox` 会在测试编译阶段报 `no such module XCTest`。源码 target 已通过 build；完整 iOS target build 和单测建议在完整 Xcode + iPhone SDK 环境中执行。

## 联调检查

1. 浏览器打开 `http://127.0.0.1:8000/health`，确认后端返回 `status: ok`。
2. 真机浏览器打开 `http://你的Mac局域网IP:8000/health`，确认手机能访问后端。
3. 输入“推荐一款 200 元以内的咖啡，并给我参考真实测评链接”。
4. 聊天气泡应逐段流式输出，最终出现商品卡和 TikTok 测评参考。

## 常见问题

- 如果 Web 正常、真机失败，通常是 `EXPO_PUBLIC_API_BASE_URL` 仍指向 `127.0.0.1`。
- 如果真机打不开 `/health`，检查 Mac 和手机是否在同一 Wi-Fi，或防火墙是否拦截 `8000` 端口。
- 如果浏览器报 CORS，确认后端服务已重启。
