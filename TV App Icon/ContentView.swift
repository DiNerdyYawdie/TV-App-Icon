import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Main App View

struct ContentView: View {
    @State private var selectedTab: AppTab = .export

    var body: some View {
        TabView(selection: $selectedTab) {
            ExportView()
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
                .tag(AppTab.export)

            GuidanceView()
                .tabItem { Label("Guide", systemImage: "info.circle") }
                .tag(AppTab.guide)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .frame(minWidth: 900, minHeight: 680)
    }
}

enum AppTab { case export, guide, settings }

// MARK: - Export View

struct ExportView: View {
    @State private var sourceImage: NSImage? = nil
    @State private var layerImages: [IconLayer: NSImage] = [:]
    @State private var isExporting = false
    @State private var exportResult: ExportResultState = .idle
    @State private var isDroppingSource = false
    @State private var showSizeList = false
    @State private var showSuccessAlert = false
    @State private var successCount = 0
    @State private var successFolderURL: URL? = nil
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showPaywall = false

    var store: StoreModel = .shared

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                if !store.isPro {
                    proBanner
                }
                sourceDropSection
                layerSection
                exportButtonSection
                resultSection
            }
            .padding(32)
        }
        .background(backgroundGradient)
        .alert("Export Complete", isPresented: $showSuccessAlert, actions: {
            Button("Open Folder") {
                if let url = successFolderURL { NSWorkspace.shared.open(url) }
            }
            Button("OK", role: .cancel) {}
        }, message: {
            if let url = successFolderURL {
                Text("\(successCount) files exported successfully.\n\nSaved to:\n\(url.path)")
            }
        })
        .alert("Export Failed", isPresented: $showErrorAlert, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(errorMessage)
        })
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "tv.and.hifispeaker.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("tvOS Icon Exporter")
                        .font(.system(size: 28, weight: .bold))
                    Text("Generate all required icon sizes for your tvOS app")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Pro Banner

    private var proBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Free plan — Home Screen only")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Unlock Pro to export App Store & Top Shelf icons")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Unlock")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(colors: [.blue, .purple],
                                       startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(colors: [.blue.opacity(0.4), .purple.opacity(0.4)],
                                       startPoint: .leading, endPoint: .trailing),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Source Image Drop

    private var sourceDropSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Source Image", systemImage: "photo")
                .font(.headline)
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(isDroppingSource ? Color.accentColor.opacity(0.12) : Color.clear)
                    .stroke(isDroppingSource ? Color.accentColor : Color.primary.opacity(0.15),
                            style: StrokeStyle(lineWidth: 2, dash: isDroppingSource ? [] : [8, 6]))
                    .animation(.easeInOut(duration: 0.2), value: isDroppingSource)

                if let img = sourceImage {
                    HStack(spacing: 20) {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(radius: 8)

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Image ready", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.headline)
                            Text("Drag a new image to replace, or use separate layer images below.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            sourceImage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("Drop your 1024×1024 app icon here")
                            .font(.headline)
                        Text("PNG or JPEG · Used for all layers unless overridden below")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Choose File...") { openSourceImagePicker() }
                            .buttonStyle(.glass)
                    }
                    .padding(40)
                }
            }
            .frame(maxWidth: .infinity)
            .onDrop(of: [.fileURL, .image, .png, .jpeg], isTargeted: $isDroppingSource) { providers in
                handleDrop(providers: providers, forLayer: nil)
            }
        }
    }

    // MARK: - Per-Layer Section

    private var layerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Layer Images (Optional)", systemImage: "square.3.layers.3d")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.35)) { showSizeList.toggle() }
                } label: {
                    Label(showSizeList ? "Hide Sizes" : "Show Sizes", systemImage: showSizeList ? "chevron.up" : "list.bullet")
                        .font(.subheadline)
                }
                .buttonStyle(.glass)
            }

            Text("For the parallax effect, provide separate images per layer. If omitted, the source image is used for that layer.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ForEach(IconLayer.allCases) { layer in
                    LayerDropCard(
                        layer: layer,
                        image: layerImages[layer],
                        onDrop: { providers in handleDrop(providers: providers, forLayer: layer) },
                        onClear: { layerImages.removeValue(forKey: layer) },
                        onChoose: { openLayerImagePicker(for: layer) }
                    )
                }
            }

            if showSizeList {
                SizeListView()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Export Button

    private var exportButtonSection: some View {
        VStack(spacing: 12) {
            // Pro upsell banner — only shown when not pro
            if !store.isPro {
                Button { showPaywall = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Free: Home Screen only")
                                .font(.subheadline.weight(.semibold))
                            Text("Unlock Pro for App Store, Top Shelf & all layers")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Unlock")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(colors: [.blue, .purple],
                                               startPoint: .leading, endPoint: .trailing),
                                in: Capsule()
                            )
                    }
                    .padding(14)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.yellow.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            HStack {
                Spacer()
                Button {
                    runExport()
                } label: {
                    if isExporting {
                        HStack(spacing: 10) {
                            ProgressView().controlSize(.small)
                            Text("Exporting...")
                        }
                        .padding(.horizontal, 8)
                    } else {
                        Label(store.isPro ? "Export All Sizes" : "Export (Home Screen)",
                              systemImage: "square.and.arrow.up.fill")
                            .font(.headline)
                            .padding(.horizontal, 8)
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(sourceImage == nil || isExporting)
                Spacer()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store)
        }
    }

    // MARK: - Result Banner

    @ViewBuilder
    private var resultSection: some View {
        switch exportResult {
        case .idle:
            EmptyView()
        case .success(let count, let url):
            ResultBanner(
                icon: "checkmark.circle.fill",
                color: .green,
                title: "Export Complete",
                message: "\(count) files saved to \"\(url.lastPathComponent)\"",
                action: { NSWorkspace.shared.open(url) },
                actionLabel: "Open Folder",
                onDismiss: { exportResult = .idle }
            )
        case .failure(let msg):
            ResultBanner(
                icon: "exclamationmark.triangle.fill",
                color: .orange,
                title: "Export Failed",
                message: msg,
                action: nil,
                actionLabel: nil,
                onDismiss: { exportResult = .idle }
            )
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(nsColor: .windowBackgroundColor), Color(nsColor: .controlBackgroundColor)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Actions

    private func openSourceImagePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff]
        panel.message = "Select your 1024×1024 app icon"
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            sourceImage = img
        }
    }

    private func openLayerImagePicker(for layer: IconLayer) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff]
        panel.message = "Select image for the \(layer.rawValue) layer"
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            layerImages[layer] = img
        }
    }

    private func handleDrop(providers: [NSItemProvider], forLayer layer: IconLayer?) -> Bool {
        guard let provider = providers.first else { return false }
        guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            // macOS Finder delivers the URL as NSURL, Data, or String — handle all three
            let url: URL?
            if let nsURL = item as? NSURL {
                url = nsURL as URL
            } else if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else if let str = item as? String {
                url = URL(string: str)
            } else {
                url = nil
            }

            guard let resolved = url, let img = NSImage(contentsOf: resolved) else { return }
            DispatchQueue.main.async {
                if let layer { self.layerImages[layer] = img } else { self.sourceImage = img }
            }
        }
        return true
    }

    private func runExport() {
        guard let src = sourceImage else { return }

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Export Here"
        panel.message = "Choose a folder to save all exported icon files"

        guard panel.runModal() == .OK, let outputURL = panel.url else { return }

        isExporting = true
        exportResult = .idle

        do {
            let count = try exportAllSizes(sourceImage: src, layers: layerImages,
                                           outputURL: outputURL, proOnly: store.isPro)
            isExporting = false
            exportResult = .success(count: count, folderURL: outputURL)
            // Also show a prominent alert
            successCount = count
            successFolderURL = outputURL
            showSuccessAlert = true
        } catch {
            isExporting = false
            exportResult = .failure(message: error.localizedDescription)
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

enum ExportResultState {
    case idle
    case success(count: Int, folderURL: URL)
    case failure(message: String)
}

// MARK: - Layer Drop Card

struct LayerDropCard: View {
    let layer: IconLayer
    let image: NSImage?
    let onDrop: ([NSItemProvider]) -> Bool
    let onClear: () -> Void
    let onChoose: () -> Void

    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 12) {
            // Layer header
            HStack(spacing: 8) {
                Image(systemName: layer.icon)
                    .foregroundStyle(layer.color)
                    .font(.system(size: 18, weight: .semibold))
                Text(layer.rawValue)
                    .font(.headline)
            }

            // Drop zone
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isTargeted ? layer.color.opacity(0.12) : Color.primary.opacity(0.05))
                    .stroke(isTargeted ? layer.color : Color.primary.opacity(0.12),
                            style: StrokeStyle(lineWidth: 1.5, dash: image == nil && !isTargeted ? [5, 4] : []))
                    .animation(.easeInOut(duration: 0.15), value: isTargeted)
                    .frame(height: 120)

                if let img = image {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(alignment: .topTrailing) {
                            Button { onClear() } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white, .black.opacity(0.6))
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                            .offset(x: 6, y: -6)
                        }
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(layer.color.opacity(0.7))
                        Text("Drop or choose")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDrop(of: [.fileURL, .image, .png, .jpeg], isTargeted: $isTargeted) { providers in
                onDrop(providers)
            }
            .onTapGesture { if image == nil { onChoose() } }

            // Description
            Text(layer.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(layer.color.opacity(isTargeted ? 0.5 : 0.15), lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Size List View

struct SizeListView: View {
    // Group by slotFolder (the numbered top-level subfolder = one Xcode slot)
    private let groups: [(String, [TVOSIconSize])] = {
        var seen: [String] = []
        var result: [(String, [TVOSIconSize])] = []
        for size in tvOSIconSizes {
            if !seen.contains(size.slotFolder) {
                seen.append(size.slotFolder)
                let group = tvOSIconSizes.filter { $0.slotFolder == size.slotFolder }
                result.append((size.slotFolder, group))
            }
        }
        return result
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exported Files — grouped by Xcode slot")
                .font(.subheadline.weight(.semibold))
                .padding(.bottom, 4)

            ForEach(groups, id: \.0) { folder, sizes in
                VStack(alignment: .leading, spacing: 4) {
                    Text(folder)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    // Show unique sizes for this slot
                    let uniqueSizes = sizes.reduce(into: [String]()) { acc, s in
                        if !acc.contains(s.displaySize) { acc.append(s.displaySize) }
                    }
                    HStack(spacing: 8) {
                        ForEach(uniqueSizes, id: \.self) { size in
                            Text(size)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                }
            }
            Text("\(tvOSIconSizes.count) total files across 4 subfolders.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Result Banner

struct ResultBanner: View {
    let icon: String
    let color: Color
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionLabel: String?
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(message).font(.subheadline).foregroundStyle(.secondary)
            }

            Spacer()

            if let action, let label = actionLabel {
                Button(label, action: action).buttonStyle(.glass)
            }

            Button { onDismiss() } label: {
                Image(systemName: "xmark").font(.subheadline)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(color.opacity(0.2), lineWidth: 1))
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.4), value: title)
    }
}

// MARK: - Guidance View

struct GuidanceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Title
                VStack(alignment: .leading, spacing: 6) {
                    Label("tvOS App Icon Guide", systemImage: "book.fill")
                        .font(.system(size: 26, weight: .bold))
                    Text("Everything you need to know about tvOS layered icons")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // What is a layered icon
                GuideSection(
                    icon: "square.3.layers.3d",
                    title: "What is a Layered Icon?",
                    color: .blue
                ) {
                    Text("tvOS app icons are not flat images — they are **parallax stacks** made of 2 to 5 separate image layers. When a user hovers over your icon with the Apple TV remote, each layer moves independently at different depths, creating a stunning 3D effect.")
                    Text("Apple requires all tvOS app icons to use this layered format. You must supply each layer as a separate image at each required size.")
                }

                // The three layers explained
                VStack(alignment: .leading, spacing: 12) {
                    Label("The Three Layers", systemImage: "square.3.layers.3d.slash")
                        .font(.headline)

                    ForEach(IconLayer.allCases) { layer in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: layer.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(layer.color)
                                .frame(width: 36, height: 36)
                                .background(layer.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(layer.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(layer.color)
                                Text(layer.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                }

                // Icon slots explained
                GuideSection(
                    icon: "square.grid.2x2",
                    title: "Icon Slots",
                    color: .purple
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        IconSlotRow(name: "App Icon Small", size: "240×240 / 480×480", description: "Shown in the App Switcher and focused states")
                        IconSlotRow(name: "App Icon Large", size: "400×240 / 800×480", description: "Default view on the Home Screen")
                        IconSlotRow(name: "Top Shelf", size: "1920×720 / 3840×1440", description: "Banner shown at the top of the screen when your app is selected in the top row")
                        IconSlotRow(name: "Top Shelf Wide", size: "2320×720 / 4640×1440", description: "Wider variant for featured placement")
                    }
                }

                // Design tips
                GuideSection(
                    icon: "paintbrush.pointed",
                    title: "Design Tips",
                    color: .orange
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        TipRow(icon: "checkmark.circle", text: "Keep important content centered — layers shift during parallax and edges may be clipped.")
                        TipRow(icon: "checkmark.circle", text: "Use transparency (PNG) in the Front and Middle layers so layers below show through.")
                        TipRow(icon: "checkmark.circle", text: "The Back layer can be a solid color or gradient — it never needs transparency.")
                        TipRow(icon: "checkmark.circle", text: "Subtle shadows on the Front layer add depth and make the icon feel tactile.")
                        TipRow(icon: "checkmark.circle", text: "Test in the Parallax Previewer app from Apple Design Resources before submitting.")
                        TipRow(icon: "xmark.circle", text: "Don't place text close to the edges — it may be obscured by the parallax motion.")
                        TipRow(icon: "xmark.circle", text: "Avoid putting critical details only in the Back layer — it's the most obscured.")
                    }
                }

                // Workflow
                GuideSection(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Workflow",
                    color: .green
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        WorkflowStep(number: "1", text: "Design your icon with layers in mind (e.g., Sketch, Figma, Photoshop). Export each layer as a separate 1024×1024 PNG with transparency.")
                        WorkflowStep(number: "2", text: "Drop your source image (or each layer separately) into this app.")
                        WorkflowStep(number: "3", text: "Click Export All Sizes and choose an output folder.")
                        WorkflowStep(number: "4", text: "The exported files are organized in Back / Middle / Front subfolders, ready to drag into your Xcode Asset Catalog.")
                        WorkflowStep(number: "5", text: "In Xcode, open your asset catalog and drag each file into the corresponding layer slot at the matching size.")
                    }
                }
            }
            .padding(32)
        }
        .background(
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), Color(nsColor: .controlBackgroundColor)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Guide Sub-Components

struct GuideSection<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
            content()
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.85))
        }
    }
}

struct IconSlotRow: View {
    let name: String
    let size: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.weight(.semibold))
                Text(size).font(.caption).foregroundStyle(.secondary).fontDesign(.monospaced)
            }
            .frame(width: 200, alignment: .leading)
            Text(description).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var isPositive: Bool { icon.contains("checkmark") }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(isPositive ? .green : .red)
                .font(.subheadline)
                .padding(.top, 1)
            Text(text).font(.subheadline).foregroundStyle(.primary.opacity(0.85))
        }
    }
}

struct WorkflowStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .frame(width: 22, height: 22)
                .background(.blue.opacity(0.15), in: Circle())
                .foregroundStyle(.blue)
            Text(text).font(.subheadline).foregroundStyle(.primary.opacity(0.85))
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
