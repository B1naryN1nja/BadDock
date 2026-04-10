import SwiftUI
import AVFoundation

@main
struct CalculatorApp: App {
    init() {
        let searchPaths = [
            Bundle.main.url(forResource: "badapple", withExtension: "mp4")?.path,
            Bundle.main.bundlePath.components(separatedBy: "Contents").first.map { $0 + "badapple.mp4" },
            FileManager.default.currentDirectoryPath + "/badapple.mp4"
        ].compactMap { $0 }

        for path in searchPaths {
            if FileManager.default.fileExists(atPath: path) {
                DockVideoPlayer.shared.start(videoPath: path)
                return
            }
        }
        print("Could not find badapple.mp4")
    }

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 8) {
                Text("Bad Apple")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                Text("Now playing in your Dock")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .frame(width: 300, height: 120)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .windowResizability(.contentSize)
    }
}

class DockVideoPlayer {
    static let shared = DockVideoPlayer()
    private var timer: Timer?
    private var videoPath: String = ""

    // Ring buffer — only keep a small window of frames in memory
    private var buffer: [Data] = []
    private let bufferCapacity = 60  // ~5 seconds of frames at 12fps
    private let lock = NSLock()
    private var producerDone = false

    func start(videoPath: String) {
        self.videoPath = videoPath
        print("Streaming video: \(videoPath)")
        startProducer()
        startPlayback()
    }

    private func startProducer() {
        producerDone = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.extractFrames()
            // When done, loop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.startProducer()
            }
        }
    }

    private func extractFrames() {
        let url = URL(fileURLWithPath: videoPath)
        let asset = AVAsset(url: url)
        guard let track = asset.tracks(withMediaType: .video).first else { return }

        guard let reader = try? AVAssetReader(asset: asset) else { return }
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        reader.add(output)
        reader.startReading()

        let dockSize = 128
        let ciCtx = CIContext()
        var count = 0

        while let sampleBuffer = output.copyNextSampleBuffer() {
            count += 1
            if count % 2 != 0 { continue }

            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }

            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let w = CVPixelBufferGetWidth(pixelBuffer)
            let h = CVPixelBufferGetHeight(pixelBuffer)
            guard let cgImage = ciCtx.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: w, height: h)) else { continue }

            let img = NSImage(size: NSSize(width: dockSize, height: dockSize))
            img.lockFocus()
            NSColor.black.setFill()
            NSBezierPath.fill(NSRect(x: 0, y: 0, width: dockSize, height: dockSize))

            // Crop to fill — scale up to cover the square, clip the overflow
            let aspect = CGFloat(w) / CGFloat(h)
            let drawW: CGFloat, drawH: CGFloat
            if aspect > 1 {
                drawH = CGFloat(dockSize)
                drawW = CGFloat(dockSize) * aspect
            } else {
                drawW = CGFloat(dockSize)
                drawH = CGFloat(dockSize) / aspect
            }
            let drawX = (CGFloat(dockSize) - drawW) / 2
            let drawY = (CGFloat(dockSize) - drawH) / 2

            let nsImg = NSImage(cgImage: cgImage, size: NSSize(width: w, height: h))
            nsImg.draw(in: NSRect(x: drawX, y: drawY, width: drawW, height: drawH))
            img.unlockFocus()

            if let tiff = img.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.5]) {

                // Wait if buffer is full
                while true {
                    lock.lock()
                    let count = buffer.count
                    lock.unlock()
                    if count < bufferCapacity { break }
                    Thread.sleep(forTimeInterval: 0.01)
                }

                lock.lock()
                buffer.append(jpeg)
                lock.unlock()
            }
        }
    }

    private func startPlayback() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 12.0, repeats: true) { [weak self] _ in
            self?.renderFrame()
        }
    }

    private func renderFrame() {
        lock.lock()
        guard !buffer.isEmpty else {
            lock.unlock()
            return
        }
        let data = buffer.removeFirst()
        lock.unlock()

        guard let image = NSImage(data: data) else { return }

        let dockTile = NSApplication.shared.dockTile
        let ts = dockTile.size
        let imageView = NSImageView(frame: NSRect(origin: .zero, size: ts))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        dockTile.contentView = imageView
        dockTile.display()
    }
}
