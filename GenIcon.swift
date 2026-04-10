import AppKit

let size = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()

let ctx = NSGraphicsContext.current!.cgContext
let s = CGFloat(size)

// Background rounded rect (macOS-style squircle)
let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
let bgPath = NSBezierPath(roundedRect: bgRect.insetBy(dx: 20, dy: 20), xRadius: 185, yRadius: 185)
NSColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1.0).setFill()
bgPath.fill()

// Display area
let displayRect = CGRect(x: 120, y: s - 340, width: s - 240, height: 180)
let displayPath = NSBezierPath(roundedRect: displayRect, xRadius: 24, yRadius: 24)
NSColor(red: 0.25, green: 0.25, blue: 0.27, alpha: 1.0).setFill()
displayPath.fill()

// Display text
let displayAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 100, weight: .light),
    .foregroundColor: NSColor.white
]
let displayText = NSAttributedString(string: "42", attributes: displayAttrs)
let textSize = displayText.size()
displayText.draw(at: NSPoint(x: displayRect.maxX - textSize.width - 30,
                              y: displayRect.midY - textSize.height / 2))

// Button grid
let buttonColors: [(String, NSColor)] = [
    ("C", NSColor(red: 0.65, green: 0.65, blue: 0.67, alpha: 1.0)),
    ("±", NSColor(red: 0.65, green: 0.65, blue: 0.67, alpha: 1.0)),
    ("%", NSColor(red: 0.65, green: 0.65, blue: 0.67, alpha: 1.0)),
    ("÷", NSColor.orange),
    ("7", NSColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.0)),
    ("8", NSColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.0)),
    ("9", NSColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.0)),
    ("×", NSColor.orange),
    ("4", NSColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.0)),
    ("5", NSColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.0)),
    ("6", NSColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.0)),
    ("−", NSColor.orange),
    ("1", NSColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.0)),
    ("2", NSColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.0)),
    ("3", NSColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.0)),
    ("+", NSColor.orange),
]

let gridX: CGFloat = 120
let gridY: CGFloat = 80
let btnSize: CGFloat = 155
let gap: CGFloat = 22

for (i, (label, color)) in buttonColors.enumerated() {
    let col = i % 4
    let row = i / 4
    let x = gridX + CGFloat(col) * (btnSize + gap)
    let y = gridY + CGFloat(3 - row) * (btnSize + gap)

    let btnRect = CGRect(x: x, y: y, width: btnSize, height: btnSize)
    let btnPath = NSBezierPath(roundedRect: btnRect, xRadius: btnSize / 2, yRadius: btnSize / 2)
    color.setFill()
    btnPath.fill()

    let isOp = ["÷", "×", "−", "+"].contains(label)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: isOp ? 60 : 50, weight: isOp ? .medium : .medium),
        .foregroundColor: NSColor.white
    ]
    let text = NSAttributedString(string: label, attributes: attrs)
    let ts = text.size()
    text.draw(at: NSPoint(x: btnRect.midX - ts.width / 2, y: btnRect.midY - ts.height / 2))
}

img.unlockFocus()

// Save as PNG
guard let tiff = img.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to generate PNG")
    exit(1)
}

let url = URL(fileURLWithPath: "icon_1024.png")
try! png.write(to: url)
print("Saved icon_1024.png")
