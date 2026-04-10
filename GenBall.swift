import AppKit

let size = 1024
let s = CGFloat(size)
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()

let ctx = NSGraphicsContext.current!.cgContext

// Red rubber ball with highlight
let ballRect = NSRect(x: 80, y: 80, width: s - 160, height: s - 160)

// Ball gradient - red to dark red
let gradient = NSGradient(colors: [
    NSColor(red: 1.0, green: 0.25, blue: 0.2, alpha: 1.0),
    NSColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1.0)
])!
let ballPath = NSBezierPath(ovalIn: ballRect)
gradient.draw(in: ballPath, angle: -45)

// Shiny highlight
let highlightRect = NSRect(x: 250, y: 480, width: 320, height: 280)
let highlightGrad = NSGradient(colors: [
    NSColor(white: 1.0, alpha: 0.6),
    NSColor(white: 1.0, alpha: 0.0)
])!
let highlightPath = NSBezierPath(ovalIn: highlightRect)
highlightGrad.draw(in: highlightPath, angle: 90)

// Small specular dot
let specRect = NSRect(x: 340, y: 600, width: 100, height: 80)
let specGrad = NSGradient(colors: [
    NSColor(white: 1.0, alpha: 0.9),
    NSColor(white: 1.0, alpha: 0.0)
])!
let specPath = NSBezierPath(ovalIn: specRect)
specGrad.draw(in: specPath, angle: 90)

img.unlockFocus()

guard let tiff = img.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed")
    exit(1)
}

try! png.write(to: URL(fileURLWithPath: "ball_1024.png"))
print("Saved ball_1024.png")
