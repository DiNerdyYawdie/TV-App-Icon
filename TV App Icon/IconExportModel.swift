import SwiftUI
import AppKit

// MARK: - tvOS Icon Size Definitions

struct TVOSIconSize: Identifiable {
    let id = UUID()
    /// Top-level folder — matches the Xcode asset catalog slot name
    let slotFolder: String
    /// Second-level folder — the layer (Front / Middle / Back)
    let layer: IconLayer
    /// Third-level folder — the scale (@1x or @2x)
    let scale: Int
    let width: Int
    let height: Int

    /// Simple filename: just the pixel dimensions so it's easy to read at a glance
    var filename: String { "\(width)x\(height).png" }

    /// Full nested path: SlotFolder / Layer / @Nx / filename
    /// For single-scale slots the @Nx folder is omitted for simplicity
    var relativePath: String {
        if slotFolder.hasPrefix("1 -") {
            // App Icon - App Store only has one size per layer — no scale subfolder needed
            return "\(slotFolder)/\(layer.rawValue)/\(filename)"
        }
        return "\(slotFolder)/\(layer.rawValue)/@\(scale)x/\(filename)"
    }

    var displaySize: String { "\(width)x\(height) @\(scale)x" }
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

// Exported files are nested: Slot > Layer > @Scale > filename.png
// This maps 1-to-1 with what you see in Xcode's asset catalog.
let tvOSIconSizes: [TVOSIconSize] = [

    // ── 1. App Icon - App Store ───────────────────────────────────────────────
    // Drag into: App Icon & Top Shelf Image > App Icon - App Store > Front / Middle / Back
    // Note: only the standard size works for this slot — use the file inside each layer folder
    TVOSIconSize(slotFolder: "1 - App Icon - App Store", layer: .front,  scale: 1, width: 1280, height: 768),
    TVOSIconSize(slotFolder: "1 - App Icon - App Store", layer: .middle, scale: 1, width: 1280, height: 768),
    TVOSIconSize(slotFolder: "1 - App Icon - App Store", layer: .back,   scale: 1, width: 1280, height: 768),

    // ── 2. App Icon - Large (Home Screen landscape slot) ──────────────────────
    // Drag into: App Icon & Top Shelf Image > App Icon > Front / Middle / Back (landscape well)
    TVOSIconSize(slotFolder: "2 - App Icon (Large 400x240)", layer: .front,  scale: 1, width: 400,  height: 240),
    TVOSIconSize(slotFolder: "2 - App Icon (Large 400x240)", layer: .front,  scale: 2, width: 800,  height: 480),
    TVOSIconSize(slotFolder: "2 - App Icon (Large 400x240)", layer: .middle, scale: 1, width: 400,  height: 240),
    TVOSIconSize(slotFolder: "2 - App Icon (Large 400x240)", layer: .middle, scale: 2, width: 800,  height: 480),
    TVOSIconSize(slotFolder: "2 - App Icon (Large 400x240)", layer: .back,   scale: 1, width: 400,  height: 240),
    TVOSIconSize(slotFolder: "2 - App Icon (Large 400x240)", layer: .back,   scale: 2, width: 800,  height: 480),

    // ── 3. App Icon - Small (Home Screen square/focus slot) ───────────────────
    // Drag into: App Icon & Top Shelf Image > App Icon > Front / Middle / Back (square well)
    TVOSIconSize(slotFolder: "3 - App Icon (Small 240x240)", layer: .front,  scale: 1, width: 240,  height: 240),
    TVOSIconSize(slotFolder: "3 - App Icon (Small 240x240)", layer: .front,  scale: 2, width: 480,  height: 480),
    TVOSIconSize(slotFolder: "3 - App Icon (Small 240x240)", layer: .middle, scale: 1, width: 240,  height: 240),
    TVOSIconSize(slotFolder: "3 - App Icon (Small 240x240)", layer: .middle, scale: 2, width: 480,  height: 480),
    TVOSIconSize(slotFolder: "3 - App Icon (Small 240x240)", layer: .back,   scale: 1, width: 240,  height: 240),
    TVOSIconSize(slotFolder: "3 - App Icon (Small 240x240)", layer: .back,   scale: 2, width: 480,  height: 480),

    // ── 4. Top Shelf Image Wide ───────────────────────────────────────────────
    // Drag into: App Icon & Top Shelf Image > Top Shelf Image Wide
    TVOSIconSize(slotFolder: "4 - Top Shelf Image Wide", layer: .front, scale: 1, width: 2320, height: 720),
    TVOSIconSize(slotFolder: "4 - Top Shelf Image Wide", layer: .front, scale: 2, width: 4640, height: 1440),

    // ── 5. Top Shelf Image ────────────────────────────────────────────────────
    // Drag into: App Icon & Top Shelf Image > Top Shelf Image
    TVOSIconSize(slotFolder: "5 - Top Shelf Image", layer: .front, scale: 1, width: 1920, height: 720),
    TVOSIconSize(slotFolder: "5 - Top Shelf Image", layer: .front, scale: 2, width: 3840, height: 1440),
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

// NSImage drawing (lockFocus/unlockFocus) must happen on the main thread.
@MainActor
func resizeImage(_ nsImage: NSImage, to size: CGSize) -> Data? {
    // Use CGContext for thread-safe, high-quality rendering
    guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        return nil
    }

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard let context = CGContext(
        data: nil,
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else { return nil }

    context.interpolationQuality = .high
    context.draw(cgImage, in: CGRect(origin: .zero, size: size))

    guard let rendered = context.makeImage() else { return nil }

    let rep = NSBitmapImageRep(cgImage: rendered)
    rep.size = size
    return rep.representation(using: .png, properties: [:])
}

@MainActor
func exportAllSizes(sourceImage: NSImage, layers: [IconLayer: NSImage], outputURL: URL) throws -> Int {
    var count = 0
    let fileManager = FileManager.default

    for iconSize in tvOSIconSizes {
        let layerImage = layers[iconSize.layer] ?? sourceImage
        guard let pngData = resizeImage(layerImage, to: CGSize(width: iconSize.width, height: iconSize.height)) else {
            continue
        }

        // Nest as: Slot > Layer > @Nx > filename.png
        let fileURL = outputURL.appendingPathComponent(iconSize.relativePath)
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try pngData.write(to: fileURL)
        count += 1
    }
    return count
}
