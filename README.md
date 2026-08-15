# Nook 🎵

**Nook** is a lightweight, native macOS utility that transforms your MacBook notch into a seamless, interactive music controller and media hub.

Built with **Swift, SwiftUI, AppKit, and Apple's MediaRemote framework**, Nook sits flush beneath the camera notch, expanding on hover to display live song metadata, real-time cover art, and playback controls.

---

## ✨ Features

- **🎯 Seamless Notch Anchoring & Exact Centering**: Anchors directly to the bottom edge of the MacBook camera space (`visibleFrame.maxY`) and centers mathematically (`screenFrame.midX`), adapting dynamically to screen resolution and display changes.
- **🖤 Minimal OLED Black Design**: Clean, borderless dark surface (`#000000` with 96% opacity and subtle 8px continuous rounded corners), free of distracting gradient sheens or visual artifacts.
- **🔄 Unified Hover & Extended Experience**: Both the hover pill and the locked extended view share an identical **200 × 44 px** layout. Locking the view open reveals a subtle top-right close button (`✕`).
- **⏯ Direct Hardware Playback Controls**:
  - **Previous (`⏮`)** and **Next (`⏭`)** track skipping.
  - **Play / Pause (`▶ / ⏸`)** enclosed in a subtle rounded square.
  - Powered by Apple's native **`MediaRemote.framework`** (`MRMediaRemoteSendCommand`) and system HID event dispatch for instant response across all desktop and browser players.
- **🖼 Real-Time Cover Art Fetching**:
  - Automatically parses YouTube and YouTube Music video IDs to fetch original video thumbnails.
  - Uses Apple's iTunes Search API as an automatic fallback for web audio streams and Spotify tracks.
  - Renders album covers at a crisp `30 × 30 px` with smooth rounded corners.
- **⏸ Persistent Metadata on Pause**: Track title, artist name, and album artwork remain visible when playback is paused or when browser tabs run in the background.
- **🖱 Transparent Click-Outside Dismissal**: Custom floating backdrop panel (`NookBackdropWindow`) detects outside clicks anywhere on the screen to collapse locked cards without requiring macOS Accessibility permissions.
- **🪐 Custom App Icon & Menu Bar Companion**: Bundles custom app branding into `AppIcon.icns` and displays an active menu bar item in the top macOS status bar.

---

## 🎧 Supported Players & Browsers

| Source | Play / Pause | Track Skip | Cover Art |
| :--- | :---: | :---: | :---: |
| **YouTube Music** (`music.youtube.com`) | ✅ | ✅ | ✅ |
| **YouTube** (`youtube.com`) | ✅ | ✅ | ✅ |
| **Spotify** (Desktop & Web Player) | ✅ | ✅ | ✅ |
| **Apple Music** (Music.app) | ✅ | ✅ | ✅ |
| **SoundCloud & Web Audio** | ✅ | ✅ | ✅ |
| **Supported Browsers** | Brave, Google Chrome, Safari, Arc, Microsoft Edge |

---

## 📁 Project Structure

```
Nook/
├── Nook/
│   ├── NookApp.swift              # Main app entry point
│   ├── AppDelegate.swift          # Menu bar icon, lifecycle, and application icon
│   ├── NookWindow.swift           # Floating panel geometry, notch anchoring, and backdrop
│   ├── NookContentView.swift      # Unified 200x44 bar UI (hover & locked extended states)
│   ├── ExpandedNookView.swift     # Expanded card view implementation
│   ├── MusicPlayerController.swift# MediaRemote bridge, AppleScript automation, and artwork fetch
│   ├── MusicWidgetView.swift      # Detailed media widget view
│   ├── NookTrackingView.swift     # Custom NSTrackingArea mouse enter/exit handler
│   ├── Info.plist                 # App bundle configuration & icon definitions
│   ├── Nook.entitlements          # Security & AppleScript entitlements
│   └── Resources/
│       ├── AppIcon.icns           # High-resolution multi-size macOS app icon
│       └── app_photo.jpg          # Custom app branding image
├── build/
│   └── Nook.app/                  # Compiled macOS Application Bundle
└── README.md                      # Documentation
```

---

## 🛠 How to Build & Run

Nook can be built directly using Apple's `swiftc` compiler without full Xcode IDE dependencies:

```bash
# 1. Navigate to the project directory
cd Nook

# 2. Prepare app bundle directories and resources
mkdir -p build/Nook.app/Contents/MacOS build/Nook.app/Contents/Resources
cp Nook/Info.plist build/Nook.app/Contents/
cp Nook/Resources/AppIcon.icns build/Nook.app/Contents/Resources/
cp Nook/Resources/app_photo.jpg build/Nook.app/Contents/Resources/

# 3. Compile the Swift source files
swiftc -O -target arm64-apple-macos12.0 \
  -framework AppKit \
  -framework SwiftUI \
  -framework MediaPlayer \
  -o build/Nook.app/Contents/MacOS/Nook Nook/*.swift

# 4. Refresh icon cache & launch
touch build/Nook.app
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f build/Nook.app 2>/dev/null || true
pkill -f "build/Nook.app/Contents/MacOS/Nook" 2>/dev/null || pkill -x "Nook" 2>/dev/null || true
open build/Nook.app
```

---

## 💡 How to Use

1. **Launch Nook**: The app runs as a lightweight accessory in your macOS menu bar and positions its collapsed indicator beneath your MacBook camera notch.
2. **Hover**: Move your cursor under the notch to reveal the **200 × 44 px** media bar with live track details, cover art, and playback controls.
3. **Control Playback**: Click **Play / Pause**, **Next**, or **Previous** directly on the bar to control your audio stream.
4. **Lock Open**: Click anywhere on the track title or artwork to lock Nook into the extended view.
5. **Dismiss**: Click the top-right close button (`✕`) or click anywhere outside Nook to collapse back to the notch.

---

## ⚙️ System Requirements

- **macOS Version**: macOS 13.0 (Ventura) or later (Apple Silicon & Intel supported).
- **Display**: MacBook with notch or standard external display.
- **Permissions**: Standard Apple Events / Automation permission prompt on first launch to monitor media tab titles. No Accessibility permissions required.

---

## 📄 License

Created with © 2026. All rights reserved.
