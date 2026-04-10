# Dock Icon Escape

A native macOS SwiftUI calculator app demonstrating how to bypass the macOS squircle icon mask using `NSDockTilePlugin`.

Since macOS Big Sur, all app icons are forced into a rounded square ("squircle") shape. This project shows how to escape that using Apple's own APIs.

## How It Works

1. **Runtime icon** — `NSApplication.shared.applicationIconImage` sets a custom-shaped icon while the app is running
2. **Persistent icon** — A `NSDockTilePlugin` bundle loads in the Dock's process, keeping the custom icon even when the app is closed

The `NSDockTile` API has existed since Mac OS X 10.6 Snow Leopard, originally intended for things like CD burn progress overlays. It still works today and is how apps like Cyberduck maintain custom icon shapes.

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
