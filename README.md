# Nook 🎵

Nook is a lightweight, native macOS utility built to turn the MacBook camera notch into a seamless, interactive music controller, live equalizer, and media hub.

Built with **Swift, SwiftUI, AppKit, and Apple's MediaRemote framework**, Nook sits flush beneath the camera notch, expanding on hover and click to display live song metadata, real-time cover art, precise playback scrubbers, hardware-accelerated media controls, and Bluetooth headphone battery monitoring.

---

## ✨ What it does

### 3 Adaptive Display States
* **🏝 Collapsed Notch Pill**: Rests flush beneath the MacBook camera space, showing mini album artwork and a live audio waveform indicator when music is playing.
* **⚡ Hover Tray (240 × 35 px)**: Expanding on cursor proximity, it displays album art, track details, and an animated audio equalizer graph.
* **🎛 Expanded Media Hub (360 × 180 px)**: Clicking the notch opens a full media card featuring 80 × 80 px high-res artwork, source badges (*Spotify, Apple Music, YouTube Music*), song title, artist name, interactive playback controls, and an accurate 60 FPS progress scrubber with live timestamps (`mm:ss`).
* **🎧 Connected Bluetooth Headphone Battery Indicator**: Shows a live headphone icon right next to the playback controls which smoothly expands on click to reveal exact remaining battery percentage for any connected Bluetooth headset (AirPods, OnePlus Buds, Sony, Bose, Beats, etc.).

---

### 🎨 Themes & Custom Color Accents
* **Light & Dark Mode Support**:
  * **Light Mode**: Crisp porcelain white surface with vibrant contrast elements.
  * **Dark Mode**: Deep OLED obsidian surface with luminous accents.
* **5 Curated Color Palettes**:
  * ⚪ **Classic** *(Neutral High-Contrast: Jet Black in Light / Pure White in Dark)*
  * 🔵 **Electric Blue** *(Vibrant Cyan-Blue)*
  * 🟢 **Emerald Green** *(Fresh Mint-Emerald)*
  * 🟠 **Sunset Amber** *(Warm Tangerine-Amber)*
  * 🟣 **Neon Purple** *(Rich Violet-Purple)*
* **High-Contrast Border**: Optional outline for maximum readability on bright or dynamic wallpapers.

---

### ⚙️ Native macOS Settings Window
Designed to perfectly match macOS 13+ / 14+ System Settings styling (`NavigationSplitView`, grouped forms, classic traffic light window controls):

#### 1. **General**
* **Behaviour**:
  * *Expand on hover* (ON/OFF)
  * *Keep open when clicked* (ON/OFF)
  * *Close when clicking outside* (ON/OFF)
* **Interaction**:
  * *Hover sensitivity* (Low / Medium / High detection threshold)
  * *Animation speed* (0.5x – 2.0x transition timing)

#### 2. **Notch**
* **Position & Alignment**:
  * `[ ⬅️ Move Left ]`, `[ Center ]`, `[ ➡️ Move Right ]` nudge buttons.
  * Real-time horizontal alignment slider (`-150px ... +150px`).
* **Dimensions**:
  * Real-time **Width Offset** (`-100px ... +100px`) and **Height Offset** (`-20px ... +40px`) sliders that dynamically adjust and center the notch live.

#### 3. **Appearance**
* Segmented **Light / Dark Mode** theme switcher.
* Dynamic **Color Accent** swatch selector.
* High-contrast border outline toggle.

#### 4. **Now Playing**
* **Display**:
  * *Show album artwork* (ON/OFF)
  * *Show song title* (ON/OFF)
  * *Show artist name* (ON/OFF)
  * *Show playback progress* (ON/OFF)
  * *Show media source* (ON/OFF)
  * *Show waveform visualizer* (ON/OFF)
* **Controls & Peripherals**:
  * *Show playback controls* (ON/OFF)
  * *Show Previous / Next* (ON/OFF)
  * *Show Play / Pause* (ON/OFF)
  * *Show headphone battery* (ON/OFF)

---

## 🎧 Media Support

| Source | Play / Pause | Track Skip | Live Progress | Cover Art |
| :--- | :---: | :---: | :---: | :---: |
| **Spotify** (Desktop App & Web) | ✅ | ✅ | ✅ | ✅ |
| **Apple Music** (Music.app) | ✅ | ✅ | ✅ | ✅ |
| **YouTube Music** (`music.youtube.com`) | ✅ | ✅ | ✅ | ✅ |
| **YouTube** (`youtube.com`) | ✅ | ✅ | ✅ | ✅ |
| **SoundCloud & Web Audio** | ✅ | ✅ | ✅ | ✅ |
| **Supported Browsers** | Google Chrome, Brave, Safari, Arc, Microsoft Edge |

---

## 📁 Project Structure

```text
Nook/
├── Nook/
│   ├── NookApp.swift                  # Main app entry point
│   ├── AppDelegate.swift              # Menu bar status item, lifecycle, notifications
│   ├── AppSettings.swift              # Central reactive store for preferences & theming
│   ├── BluetoothBatteryManager.swift  # Bluetooth audio peripheral battery tracker
│   ├── SettingsView.swift             # Native macOS 13+ Settings interface
│   ├── SettingsWindowController.swift # Settings NSWindow lifecycle & window controls
│   ├── NookWindow.swift               # Floating panel, notch anchoring, Combine observers
│   ├── NookContentView.swift          # Notch pill, hover tray, and expanded card UI
│   ├── MusicPlayerController.swift    # MediaRemote bridge, AppleScript, YouTube/Spotify JS
│   ├── NookTrackingView.swift         # NSTrackingArea mouse enter/exit tracker
│   ├── Info.plist                     # App bundle configuration
│   ├── Nook.entitlements              # Security & AppleScript entitlements
│   └── Resources/
│       ├── AppIcon.icns               # Multi-size macOS application icon
│       └── app_photo.jpg              # App branding asset
├── build/
│   └── Nook.app/                      # Compiled macOS Application Bundle
└── README.md                          # Documentation
```

---

## 🛠 How to Build & Run

Nook can be built directly with Apple's `swiftc` compiler:

```bash
# 1. Navigate to the project root
cd Nook

# 2. Prepare app bundle directories and assets
mkdir -p build/Nook.app/Contents/MacOS build/Nook.app/Contents/Resources
cp Nook/Info.plist build/Nook.app/Contents/
cp Nook/Resources/AppIcon.icns build/Nook.app/Contents/Resources/ 2>/dev/null || true
cp Nook/Resources/app_photo.jpg build/Nook.app/Contents/Resources/ 2>/dev/null || true

# 3. Compile the Swift source files targeting macOS 13.0+
swiftc -O -target arm64-apple-macos13.0 \
  -framework AppKit \
  -framework SwiftUI \
  -framework MediaPlayer \
  -framework IOBluetooth \
  -o build/Nook.app/Contents/MacOS/Nook Nook/*.swift

# 4. Refresh bundle & launch
touch build/Nook.app
pkill -x "Nook" 2>/dev/null || true
open build/Nook.app
```

---

## 💡 How to Use

1. **Launch Nook**: The app runs unobtrusively in your menu bar and anchors to the camera notch.
2. **Hover**: Move your cursor near the notch to expand into the compact hover tray.
3. **Expand**: Click the notch to lock open the full 360 × 180 px media card with scrubber, playback buttons, and headphone battery indicator.
4. **Settings**: Click the menu bar icon and select **Settings...** (or press `⌘,`) to customize theming, colors, notch dimensions, position, and media controls.
5. **Dismiss**: Click anywhere outside the tray or the top-right `✕` button.

---

## ⚙️ System Requirements

* **macOS Version**: macOS 13.0 (Ventura), macOS 14.0 (Sonoma), or later.
* **Architecture**: Apple Silicon (M1/M2/M3/M4) and Intel Macs supported.
* **Permissions**: Standard Automation permission prompt on first launch to detect music playback.

---

## 💭 Why I made it

I was experimenting with different Mac utilities and came across a similar app that used the notch as an interactive space. I really liked the idea and how naturally it fit into the MacBook.

The only catch was that it was paid.

So I thought, *why not try making my own version?*

Nook started as a small experiment to see if I could turn the notch into something useful, and it slowly became a proper little macOS app. Along the way, I ended up learning a lot about `NSPanel`, screen positioning, media controls, browser automation, and the quirks of building for macOS.

For now, Nook is mainly a music controller, but I might keep adding and changing things as I use it. I'd like to eventually personalize it around the things **I actually need on my Mac**, rather than trying to recreate the original app feature-for-feature.

It's a small personal project, but it's also something I genuinely wanted for myself.

---

© 2026. Built as a personal project.
