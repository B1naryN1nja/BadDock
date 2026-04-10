# Dock Icon Escape

A native macOS SwiftUI calculator app demonstrating how to bypass the macOS squircle icon mask using `NSDockTilePlugin` — and how far you can push it.

Since macOS Big Sur, all app icons are forced into a rounded square ("squircle") shape. This project shows how to escape that using Apple's own APIs, and explores what else is possible once you're out.

## How It Works

1. **Runtime icon** — `NSApplication.shared.applicationIconImage` sets a custom-shaped icon while the app is running
2. **Persistent icon** — A `NSDockTilePlugin` bundle loads in the Dock's process, keeping the custom icon even when the app is closed
3. **Animated icon** — `NSDockTile.contentView` + `dockTile.display()` on a timer enables real-time dock icon animation

The `NSDockTile` API has existed since Mac OS X 10.6 Snow Leopard, originally intended for things like CD burn progress overlays. It still works today and is how apps like Cyberduck maintain custom icon shapes.

## Findings

### Escaping the squircle
Setting `NSApplication.shared.applicationIconImage` at runtime bypasses the squircle mask entirely. The Dock renders whatever image you give it — no rounded square clipping. However, this only works while the app is running. For persistence when the app is closed, you need a `NSDockTilePlugin`.

### Oversized icons — max bounds
By setting `dockTile.contentView` to a view with subviews larger than the tile size, the icon can overflow its bounds. macOS clips at the **full square tile boundary** (not the squircle). Testing with a red border and manual scale controls:

| Scale | Result |
|-------|--------|
| 1.0x  | Fills the squircle shape |
| 1.1x  | Mostly fills the square, squircle corners still slightly visible |
| 1.2x  | Completely fills the square tile bounds |
| >1.2x | Clipped — no visual change |

The squircle is inscribed within the tile's square bounds, and the ~20% extra is what it takes to cover the rounded corners. **1.2x is the effective max.**

### Animated dock icons
The Dock happily redraws the tile on every `dockTile.display()` call. By running a `Timer` at 30fps and updating the `contentView` each frame, you get a smoothly animated dock icon. The current implementation pulses the icon between 0.5x and 3.0x scale using a sine wave:

```swift
let scale = 1.75 + 1.25 * sin(phase) // oscillates 0.5x to 3.0x
```

This works because `NSDockTile` is essentially a free canvas — Apple never locked down what you can render into it. The API was designed for progress bars, but nothing stops you from running arbitrary animations.

### What this means
The Dock is more flexible than it appears. With a 17-year-old API and no private frameworks, you can:
- Render any shape (escape the squircle)
- Overflow the tile bounds (oversized icons)
- Animate at 30fps (pulsing, spinning, bouncing, etc.)
- Persist custom icons when the app is closed (`NSDockTilePlugin`)

None of this is allowed on the Mac App Store — `NSDockTilePlugin` is restricted to direct distribution only.

## Building

No Xcode required — just `swiftc` and the command line.

```bash
# Generate the app icon
swift GenIcon.swift

# Create the .app bundle
mkdir -p Calculator.app/Contents/MacOS
mkdir -p Calculator.app/Contents/Resources
mkdir -p Calculator.app/Contents/PlugIns/DockPlugin.docktileplugin/Contents/MacOS

# Compile the app
swiftc -parse-as-library -o Calculator.app/Contents/MacOS/Calculator Calculator.swift \
    -framework SwiftUI -framework AppKit

# Compile the dock tile plugin
swiftc -parse-as-library -module-name DockPlugin DockPlugin.swift \
    -o Calculator.app/Contents/PlugIns/DockPlugin.docktileplugin/Contents/MacOS/DockPlugin \
    -Xlinker -dylib -Xlinker -undefined -Xlinker suppress -Xlinker -flat_namespace \
    -framework AppKit

# Convert icon to icns
mkdir -p AppIcon.iconset
for sz in 16 32 64 128 256 512 1024; do
    sips -z $sz $sz icon_1024.png --out AppIcon.iconset/icon_${sz}x${sz}.png
done
for sz in 16 32 128 256 512; do
    dbl=$((sz*2))
    cp AppIcon.iconset/icon_${dbl}x${dbl}.png AppIcon.iconset/icon_${sz}x${sz}@2x.png
done
iconutil -c icns AppIcon.iconset -o Calculator.app/Contents/Resources/AppIcon.icns

# Code sign
codesign --force --sign - Calculator.app/Contents/PlugIns/DockPlugin.docktileplugin
codesign --force --deep --sign - Calculator.app

# Register and launch
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f Calculator.app
open Calculator.app
```

## Files

- `Calculator.swift` — SwiftUI calculator app with runtime icon override
- `DockPlugin.swift` — `NSDockTilePlugin` implementation for persistent dock icon
- `GenIcon.swift` — CoreGraphics script that generates the calculator icon

## Credit

Inspired by [this r/MacOS post](https://www.reddit.com/r/MacOS/comments/1sgpjx4/cyberduck_has_escaped_squircle_jail_how/) explaining how Cyberduck escapes the squircle jail. See also the [original gist](https://gist.github.com/B1naryN1nja/a4db8eafc64caa4bc3e1849e6dd0b575) by u/B1naryN1nja.
