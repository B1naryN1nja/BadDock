import AppKit

@objc class DockPlugin: NSObject, NSDockTilePlugIn {
    @objc func setDockTile(_ dockTile: NSDockTile?) {
        guard let dockTile = dockTile else { return }

        // Load the icon from the main app's Resources
        let bundle = Bundle(for: DockPlugin.self)
        if let appBundlePath = bundle.bundlePath
            .components(separatedBy: "Contents/PlugIns")
            .first,
           let icon = NSImage(contentsOfFile: appBundlePath + "Contents/Resources/AppIcon.icns") {

            let view = NSImageView(frame: NSRect(x: 0, y: 0,
                                                  width: dockTile.size.width,
                                                  height: dockTile.size.height))
            view.image = icon
            view.imageScaling = .scaleProportionallyUpOrDown
            dockTile.contentView = view
            dockTile.display()
        }
    }
}
