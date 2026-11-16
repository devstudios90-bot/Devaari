# Devaari Browser for iPad 🌐✨

**Devaari** is a high-performance, desktop-class web browser built specifically for iPadOS with native support for multi-tab browsing, split-screen workflows, and full built-in integration with the **TryAIToday Flow Automator**.

---

## 🌟 Key Features

### 1. iPad Desktop-Class Browsing (Chrome & Firefox Reference)
- **Multi-Tab Interface:** Horizontal scrolling tab bar with favicons, loading spinners, close buttons, and instant tab creation.
- **Unified Omnibox / Address Bar:** Fast URL navigation, integrated search, SSL security lock indicator, and real-time load progress tracking.
- **Navigation Controls:** Fast back, forward, reload, and stop controls.
- **Bookmarks & History:** Instant quick access to saved links and full browsing history.
- **Direct Downloads Manager:** Downloads save directly to iPad local storage (`Files` app under `On My iPad / DevaariDownloads`) and automatically export images/videos to your **Photos Library**.

### 2. Built-in TryAIToday Flow Automator Engine
- **Dedicated iPad Side Panel:** Slide-over / split-screen panel running the full `sidepanel.html` UI alongside the main Google Flow window.
- **Automatic Script Injection:**
  - `recap-capture.js`: Injected at `documentStart` in the MAIN world to intercept and preserve Google Flow's native reCAPTCHA enterprise execute token.
  - `inject.js`: Injected into the page for session token extraction (`globalThis.__inj.getToken()`, etc.).
  - `vendor/wm-detect.js`, `wm.js`, and `flow-inject.js`: Injected at `documentEnd` for image clean pills and watermark processing.
  - `flow-inject.css`: Injected dynamically into Google Flow.
- **Devaari Native Chrome Polyfill Bridge (`devaari-chrome-polyfill.js`):**
  - `chrome.runtime.sendMessage` & `onMessage`: Bridged to native iOS via `WKScriptMessageHandler`.
  - `chrome.storage.local` & `sync`: Persistent storage backed by `UserDefaults` and local database.
  - `chrome.tabs.query` & `sendMessage`: Inspects and communicates directly with the active iPad browser tab.
  - `chrome.scripting.executeScript`: Dynamically executes automation code inside Google Flow in the main world.
  - `chrome.downloads.download`: Downloads video/image assets via native iOS `URLSession` tasks.
  - **Lifetime Pro License Pre-Activated:** Embedded promo code `9023` for unlimited generation access.

---

## 📦 Project Structure

```
d:\Antigravity Projects\D Browser\
├── .github/workflows/
│   └── build-ipa.yml                # Automated GitHub Actions workflow to build ARM64 IPA on macOS
├── Devaari/
│   ├── Devaari.xcodeproj/           # Xcode project file
│   └── Devaari/
│       ├── App/
│       │   └── DevaariApp.swift      # Main entry point
│       ├── BrowserEngine/
│       │   ├── BrowserModel.swift    # Tab, bookmark, history, download models
│       │   └── BrowserManager.swift  # Central browser state controller
│       ├── ExtensionEngine/
│       │   ├── ScriptInjector.swift  # Injects scripts into WKWebView (main & isolated worlds)
│       │   └── ExtensionBridge.swift # WKScriptMessageHandler bridging Chrome APIs to iOS
│       ├── ExtensionAssets/          # Full TryAIToday Flow Automator source assets
│       │   ├── devaari-chrome-polyfill.js
│       │   ├── sidepanel.html
│       │   ├── sidepanel.css
│       │   ├── sidepanel.js
│       │   ├── flow-inject.js
│       │   ├── flow-inject.css
│       │   ├── recap-capture.js
│       │   ├── inject.js
│       │   ├── wm.js
│       │   ├── icons/
│       │   └── vendor/
│       ├── Views/
│       │   ├── MainBrowserView.swift
│       │   ├── TabBarView.swift
│       │   ├── AddressBarView.swift
│       │   ├── SidePanelView.swift
│       │   ├── WebViewContainer.swift
│       │   └── BookmarksAndDownloadsViews.swift
│       └── Resources/
│           └── Info.plist
└── README.md
```

---

## 🚀 How to Install on iPad

### Option A: Direct Sideloading (Sideloadly / AltStore / TrollStore)
1. You can find `Devaari.ipa` directly on your Desktop (`C:\Users\Jaidev\Desktop\Devaari.ipa`).
2. Connect your iPad to your PC using a USB cable.
3. Open **Sideloadly** (or **AltStore** / **TrollStore**).
4. Drag and drop `Devaari.ipa` into Sideloadly, enter your Apple ID, and click **Start**.
5. On your iPad: Go to `Settings > General > VPN & Device Management`, trust your developer profile, and launch **Devaari**!

### Option B: Cloud Compilation via GitHub Actions (Free 1-Click)
Because iOS Mach-O binaries require an Apple compiler:
1. Create a repository on GitHub (e.g. `devaari-browser`).
2. Push this directory to your repository:
   ```bash
   git remote add origin https://github.com/<your-username>/devaari-browser.git
   git branch -M main
   git push -u origin main
   ```
3. Go to the **Actions** tab on GitHub. The `Build Devaari iPad Browser IPA` workflow runs automatically on Apple Silicon macOS runners and compiles the official signed/unsigned `.ipa` release for direct download in ~2 minutes!
