import SwiftUI

@main
struct CalculatorApp: App {
    init() {
        if let iconURL = Bundle.main.url(forResource: "BallIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            DockAnimator.shared.start(icon: icon)
        }
    }

    var body: some Scene {
        WindowGroup {
            CalculatorView()
                .frame(width: 260, height: 380)
                .background(Color(nsColor: .windowBackgroundColor))
        }
        .windowResizability(.contentSize)
    }
}

struct CalculatorView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Bouncing Ball")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
            Text("Watch the dock icon")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(24)
    }
}

class DockAnimator {
    static let shared = DockAnimator()
    private var timer: Timer?

    // Physics
    private var y: CGFloat = 0.8       // position (0 = bottom, 1 = top)
    private var vy: CGFloat = 0         // velocity
    private let gravity: CGFloat = -2.5
    private let bounceDamping: CGFloat = 0.75
    private let dt: CGFloat = 1.0 / 30.0

    // Squish
    private var squishAmount: CGFloat = 0  // 0 = normal, 1 = max squish
    private var squishDecay: CGFloat = 0.8

    func start(icon: NSImage) {
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(dt), repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.step()
            self.render(icon: icon)
        }
    }

    private func step() {
        vy += gravity * dt
        y += vy * dt

        // Hit the floor
        if y <= 0 {
            y = 0
            let impactSpeed = abs(vy)
            vy = -vy * bounceDamping
            // Squish proportional to impact speed
            squishAmount = min(0.5, impactSpeed * 0.3)
        }

        // Decay squish
        squishAmount *= squishDecay
        if squishAmount < 0.01 { squishAmount = 0 }

        // Reset when ball has nearly stopped
        if y <= 0.01 && abs(vy) < 0.1 {
            y = 1.0
            vy = 0
        }
    }

    private func render(icon: NSImage) {
        let dockTile = NSApplication.shared.dockTile
        let ts = dockTile.size
        let ballSize: CGFloat = ts.width * 0.55

        // Squish: stretch width, compress height
        let sx: CGFloat = 1.0 + squishAmount       // wider
        let sy: CGFloat = 1.0 - squishAmount * 0.8 // shorter

        let drawW = ballSize * sx
        let drawH = ballSize * sy

        // Y position: 0 = bottom of tile, map to pixel coords
        let floor: CGFloat = 4
        let ceiling: CGFloat = ts.height - drawH - 4
        let drawY = floor + y * (ceiling - floor)

        // Center horizontally
        let drawX = (ts.width - drawW) / 2

        // Render
        let frame = NSImage(size: ts)
        frame.lockFocus()

        // Dark background
        NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: ts.width, height: ts.height),
                     xRadius: ts.width * 0.22, yRadius: ts.height * 0.22).fill()

        // Shadow under ball
        let shadowAlpha = 0.4 * (1.0 - y * 0.7)
        let shadowW = drawW * (1.0 - y * 0.3)
        let shadowH: CGFloat = 6
        NSColor(white: 0, alpha: shadowAlpha).setFill()
        let shadowRect = NSRect(
            x: (ts.width - shadowW) / 2,
            y: floor - 2,
            width: shadowW,
            height: shadowH
        )
        NSBezierPath(ovalIn: shadowRect).fill()

        // Draw the icon as the ball
        icon.draw(in: NSRect(x: drawX, y: drawY, width: drawW, height: drawH),
                  from: .zero, operation: .sourceOver, fraction: 1.0)

        frame.unlockFocus()

        let imageView = NSImageView(frame: NSRect(origin: .zero, size: ts))
        imageView.image = frame
        imageView.imageScaling = .scaleNone
        dockTile.contentView = imageView
        dockTile.display()
    }
}
