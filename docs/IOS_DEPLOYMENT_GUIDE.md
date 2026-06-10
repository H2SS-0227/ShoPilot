# ShoPilot iOS Deployment Guide

This guide explains how to run the native SwiftUI iOS app for demo recording.

## 1. Prerequisites

- macOS with Xcode installed.
- The project repository cloned locally.
- Python dependencies installed for the FastAPI backend.
- A valid local `server/.env` with the Doubao / Ark LLM configuration.

If Xcode is installed outside `/Applications`, point command-line tools to it:

```bash
export DEVELOPER_DIR=/Users/bytedance/Downloads/Xcode.app/Contents/Developer
```

## 2. Start The Backend

From the project root:

```bash
cd /Users/bytedance/Desktop/ShoPilot
./scripts/dev_server.sh
```

Verify the backend:

```bash
curl http://127.0.0.1:8000/health
```

Expected response:

```json
{"status":"ok","app":"ShopPilot AI"}
```

For the iOS simulator, the native app defaults to:

```text
http://127.0.0.1:8000
```

## 3. Open The Native iOS Project

Open the Xcode project:

```bash
open /Users/bytedance/Desktop/ShoPilot/ios/ShopPilotNative/ShopPilotNative.xcodeproj
```

In Xcode:

- Select scheme `ShopPilotNative`.
- Select an iPhone simulator, for example `iPhone 17 Pro`.
- Click Run.

## 4. Command-Line Build And Launch

List available simulators:

```bash
xcrun simctl list devices available
```

Build for a simulator:

```bash
DEVELOPER_DIR=/Users/bytedance/Downloads/Xcode.app/Contents/Developer \
xcodebuild \
  -project ios/ShopPilotNative/ShopPilotNative.xcodeproj \
  -scheme ShopPilotNative \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath ios/ShopPilotNative/.derivedData \
  build
```

Install the app:

```bash
xcrun simctl install booted ios/ShopPilotNative/.derivedData/Build/Products/Debug-iphonesimulator/ShopPilotNative.app
```

Launch the app:

```bash
xcrun simctl launch booted com.h2ss.shoppilot.native
```

## 5. Demo Recording Checklist

Before recording:

- Keep the backend running at `http://127.0.0.1:8000`.
- Confirm `/health` returns `ok`.
- Launch `ShopPilotNative` from Xcode or Simulator.
- Use the default query: `推荐一款 200 元以内的咖啡，并给我参考真实测评链接`.
- Show streaming answer playback.
- Show product cards and product images.
- Open a product detail sheet.
- Ask a follow-up question, for example `有没有更便宜的？`.
- Test no-result grounding with `给我推荐一款香水`.
- Tap stop during generation to show cancel behavior.

## 6. Troubleshooting

If the app cannot load recommendations:

- Ensure the backend terminal is still running.
- Open `http://127.0.0.1:8000/health` in a browser.
- Rebuild and reinstall the app after code changes.
- For a physical iPhone, replace `127.0.0.1` in `ShopPilotAPIClient.APIEnvironment.lan` with your Mac LAN IP and run the backend on `0.0.0.0`.

If Xcode cannot find the developer directory:

```bash
sudo xcode-select -s /Users/bytedance/Downloads/Xcode.app/Contents/Developer
```

If a simulator shows an old build:

```bash
xcrun simctl terminate booted com.h2ss.shoppilot.native
xcrun simctl uninstall booted com.h2ss.shoppilot.native
xcrun simctl install booted ios/ShopPilotNative/.derivedData/Build/Products/Debug-iphonesimulator/ShopPilotNative.app
xcrun simctl launch booted com.h2ss.shoppilot.native
```
