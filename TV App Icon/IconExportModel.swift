import SwiftUI
import AppKit

// MARK: - tvOS Icon Size Definitions

struct TVOSIconSize: Identifiable {
    let id = UUID()
    let name: String
    let layer: IconLayer
    let width: Int
    let height: Int
    let scale: Int
    let usage: String

    var filename: String {
        "\(layer.rawValue)_\(name.replacingOccurrences(of: " ", with: "_"))_\(width)x\(height)@\(scale)x.png"
    }

    var displaySize: String { "\(width)×\(height) @\(scale)x" }
}

enum IconLayer: String, CaseIterable, Identifiable {
    case back = "Back"
    case middle = "Middle"
    case front = "Front"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .back:
            return "The rearmost layer — deepest in the parallax stack. Use for solid backgrounds, gradients, or environment context. This layer appears most subtle and doesn't move much on hover."
        case .middle:
            return "The middle layer sits between back and front. Ideal for secondary elements, logo bodies, or supporting graphics. It moves slightly on hover, adding depth."
        case .front:
            return "The topmost layer — closest to the viewer. Place your main logo, text, or focal element here. This layer moves the most during parallax, creating a pop-out 3D effect."
        }
    }

    var icon: String {
        switch self {
        case .back: return "square.3.layers.3d.bottom.filled"
        case .middle: return "square.3.layers.3d.middle.filled"
        case .front: return "square.3.layers.3d.top.filled"
        }
    }

    var color: Color {
        switch self {
        case .back: return .blue
        case .middle: return .purple
        case .front: return .orange
        }
    }
}

// tvOS requires specific sizes for each icon slot and layer
// Ref: Apple Human Interface Guidelines / Asset Catalog documentation
let tvOSIconSizes: [TVOSIconSize] = [
    // App Icon Small (focus state on Home Screen)
    TVOSIconSize(name: "App Icon Small", layer: .back,   width: 240,  height: 240,  scale: 1, usage: "Home Screen small"),
    TVOSIconSize(name: "App Icon Small", layer: .back,   width: 480,  height: 480,  scale: 2, usage: "Home Screen small"),
    TVOSIconSize(name: "App Icon Small", layer: .middle, width: 240,  height: 240,  scale: 1, usage: "Home Screen small"),
    TVOSIconSize(name: "App Icon Small", layer: .middle, width: 480,  height: 480,  scale: 2, usage: "Home Screen small"),
    TVOSIconSize(name: "App Icon Small", layer: .front,  width: 240,  height: 240,  scale: 1, usage: "Home Screen small"),
    TVOSIconSize(name: "App Icon Small", layer: .front,  width: 480,  height: 480,  scale: 2, usage: "Home Screen small"),

    // App Icon Large (default Home Screen display)
    TVOSIconSize(name: "App Icon Large", layer: .back,   width: 400,  height: 240,  scale: 1, usage: "Home Screen large"),
    TVOSIconSize(name: "App Icon Large", layer: .back,   width: 800,  height: 480,  scale: 2, usage: "Home Screen large"),
    TVOSIconSize(name: "App Icon Large", layer: .middle, width: 400,  height: 240,  scale: 1, usage: "Home Screen large"),
    TVOSIconSize(name: "App Icon Large", layer: .middle, width: 800,  height: 480,  scale: 2, usage: "Home Screen large"),
    TVOSIconSize(name: "App Icon Large", layer: .front,  width: 400,  height: 240,  scale: 1, usage: "Home Screen large"),
    TVOSIconSize(name: "App Icon Large", layer: .front,  width: 800,  height: 480,  scale: 2, usage: "Home Screen large"),

    // Top Shelf Image (wide banner shown at top when app is selected)
    TVOSIconSize(name: "Top Shelf",      layer: .back,   width: 1920, height: 720,  scale: 1, usage: "Top Shelf"),
    TVOSIconSize(name: "Top Shelf",      layer: .back,   width: 3840, height: 1440, scale: 2, usage: "Top Shelf"),
    TVOSIconSize(name: "Top Shelf",      layer: .middle, width: 1920, height: 720,  scale: 1, usage: "Top Shelf"),
    TVOSIconSize(name: "Top Shelf",      layer: .middle, width: 3840, height: 1440, scale: 2, usage: "Top Shelf"),
    TVOSIconSize(name: "Top Shelf",      layer: .front,  width: 1920, height: 720,  scale: 1, usage: "Top Shelf"),
    TVOSIconSize(name: "Top Shelf",      layer: .front,  width: 3840, height: 1440, scale: 2, usage: "Top Shelf"),

    // Top Shelf Wide (featured row)
    TVOSIconSize(name: "Top Shelf Wide", layer: .back,   width: 2320, height: 720,  scale: 1, usage: "Top Shelf Wide"),
    TVOSIconSize(name: "Top Shelf Wide", layer: .back,   width: 4640, height: 1440, scale: 2, usage: "Top Shelf Wide"),
    TVOSIconSize(name: "Top Shelf Wide", layer: .middle, width: 2320, height: 720,  scale: 1, usage: "Top Shelf Wide"),
    TVOSIconSize(name: "Top Shelf Wide", layer: .middle, width: 4640, height: 1440, scale: 2, usage: "Top Shelf Wide"),
    TVOSIconSize(name: "Top Shelf Wide", layer: .front,  width: 2320, height: 720,  scale: 1, usage: "Top Shelf Wide"),
    TVOSIconSize(name: "Top Shelf Wide", layer: .front,  width: 4640, height: 1440, scale: 2, usage: "Top Shelf Wide"),
]

// MARK: - Export Engine

enum ExportError: LocalizedError {
    case invalidImage
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "The image could not be processed. Ensure it's a valid PNG or JPEG."
        case .exportFailed(let msg): return "Export failed: \(msg)"
        }
    }
}

func resizeImage(_ nsImage: NSImage, to size: CGSize) -> NSImage? {
    let newImage = NSImage(size: size)
    newImage.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    nsImage.draw(in: NSRect(origin: .zero, size: size),
                 from: NSRect(origin: .zero, size: nsImage.size),
                 operation: .copy,
                 fraction: 1.0)
    newImage.unlockFocus()
    return newImage
}

func exportAllSizes(sourceImage: NSImage, layers: [IconLayer: NSImage], outputURL: URL) async throws -> Int {
    var count = 0
    let fileManager = FileManager.default

    for iconSize in tvOSIconSizes {
        let layerImage = layers[iconSize.layer] ?? sourceImage
        guard let resized = resizeImage(layerImage, to: CGSize(width: iconSize.width, height: iconSize.height)),
              let tiff = resized.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            continue
        }

        // Group by layer subfolder
        let layerFolder = outputURL.appendingPathComponent(iconSize.layer.rawValue)
        try fileManager.createDirectory(at: layerFolder, withIntermediateDirectories: true)

        let fileURL = layerFolder.appendingPathComponent(iconSize.filename)
        try pngData.write(to: fileURL)
        count += 1
    }
    return count
}
