# Nook 🎵

Nook is a small macOS utility I built to make the MacBook notch a little more useful.

It sits around the camera notch and turns it into a compact music controller. Hover over it to see what's playing, check the artwork, or control playback without switching away from whatever you're doing.

I wanted something that felt like it belonged on macOS rather than another floating window sitting on top of it.

## What it does

* Sits directly underneath the MacBook camera notch and adjusts to the display automatically.
* Expands when you hover over it.
* Shows the currently playing song, artist, and cover art.
* Lets you play/pause and skip tracks.
* Keeps the song information visible when playback is paused.
* Can stay open when you want the controls accessible.
* Clicking outside closes it again.
* Runs quietly from the menu bar.

The UI is intentionally simple — basically a black, rounded media bar that grows out of the notch when you need it.

## Media support

| Source                 | Play / Pause | Previous / Next | Cover Art |
| ---------------------- | :----------: | :-------------: | :-------: |
| YouTube Music          |       ✅      |        ✅        |     ✅     |
| YouTube                |       ✅      |        ✅        |     ✅     |
| Spotify                |       ✅      |        ✅        |     ✅     |
| Apple Music            |       ✅      |        ✅        |     ✅     |
| SoundCloud / Web Audio |       ✅      |        ✅        |     ✅     |

It can also work with media playing through browsers including Chrome, Safari, Brave, Arc, and Edge.

## How it works

Nook is built entirely as a native macOS app using:

* **Swift**
* **SwiftUI**
* **AppKit**
* **MediaRemote**
* **AppleScript / Apple Events** where needed

The main window is an `NSPanel`, which lets Nook behave more like a small system utility than a regular macOS window.

The notch positioning is calculated dynamically using `NSScreen`, so the UI isn't tied to a particular MacBook resolution.

For media controls, Nook communicates with the macOS media system and uses browser automation where necessary for web players.

Cover artwork is retrieved from the available media information, with fallbacks for browser-based players such as YouTube Music and Spotify Web Player.

## Project structure

```text
Nook/
├── Nook/
│   ├── NookApp.swift
│   ├── AppDelegate.swift
│   ├── NookWindow.swift
│   ├── NookContentView.swift
│   ├── ExpandedNookView.swift
│   ├── MusicPlayerController.swift
│   ├── MusicWidgetView.swift
│   ├── NookTrackingView.swift
│   ├── Info.plist
│   ├── Nook.entitlements
│   └── Resources/
│       ├── AppIcon.icns
│       └── app_photo.jpg
│
├── build/
│   └── Nook.app/
│
└── README.md
```

## Running Nook

Nook can be built from the terminal using Apple's Swift compiler.

From the project directory:

```bash
cd Nook
```

Create the app bundle:

```bash
mkdir -p build/Nook.app/Contents/MacOS
mkdir -p build/Nook.app/Contents/Resources
```

Copy the resources:

```bash
cp Nook/Info.plist build/Nook.app/Contents/
cp Nook/Resources/AppIcon.icns build/Nook.app/Contents/Resources/
cp Nook/Resources/app_photo.jpg build/Nook.app/Contents/Resources/
```

Compile:

```bash
swiftc -O -target arm64-apple-macos12.0 \
  -framework AppKit \
  -framework SwiftUI \
  -framework MediaPlayer \
  -o build/Nook.app/Contents/MacOS/Nook Nook/*.swift
```

Then launch:

```bash
open build/Nook.app
```

## Using it

Once Nook is running:

1. Look for the Nook icon in the menu bar.
2. Move your cursor towards the notch.
3. Hover over Nook to reveal the music controls.
4. Use the playback buttons without leaving your current app.
5. Click the music area if you want to keep it open.
6. Click outside to dismiss it.

On the first run, macOS may ask for permission to let Nook interact with applications such as Chrome, Safari, or Spotify. This is needed for browser-based media control.

## Requirements

* macOS 13 Ventura or later
* Apple Silicon or Intel Mac
* Designed primarily for MacBooks with a camera notch

On displays without a notch, Nook falls back to a suitable position near the top of the screen.

## Why I made it

I was experimenting with different Mac utilities and came across a similar app that used the notch as an interactive space. I really liked the idea and how naturally it fit into the MacBook.

The only catch was that it was paid.

So I thought, *why not try making my own version?*

Nook started as a small experiment to see if I could turn the notch into something useful, and it slowly became a proper little macOS app. Along the way, I ended up learning a lot about `NSPanel`, screen positioning, media controls, browser automation, and the quirks of building for macOS.

For now, Nook is mainly a music controller, but I might keep adding and changing things as I use it. I'd like to eventually personalize it around the things **I actually need on my Mac**, rather than trying to recreate the original app feature-for-feature.

It's a small personal project, but it's also something I genuinely wanted for myself.

---

© 2026. Built as a personal project.
