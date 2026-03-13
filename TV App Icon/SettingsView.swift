import SwiftUI
import WebKit

// MARK: - Settings View

struct SettingsView: View {
    // Update these URLs once the GitHub Pages site is live
    private let homeURL      = URL(string: "https://dinerdyyawdie.github.io/TV-App-Icon/")!
    private let privacyURL   = URL(string: "https://dinerdyyawdie.github.io/TV-App-Icon/privacy.html")!
    private let termsURL     = URL(string: "https://dinerdyyawdie.github.io/TV-App-Icon/terms.html")!

    @State private var selectedPage: SettingsPage = .general

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detailPanel
        }
        .frame(minWidth: 900, minHeight: 620)
        .background(
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), Color(nsColor: .controlBackgroundColor)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.title2.bold())
                .padding(.bottom, 8)

            sidebarSection("General") {
                SidebarRow(page: .general, selected: $selectedPage)
            }

            sidebarSection("Legal") {
                SidebarRow(page: .privacy, selected: $selectedPage)
                SidebarRow(page: .terms,   selected: $selectedPage)
            }

            Spacer()

            // App info at bottom of sidebar
            VStack(alignment: .leading, spacing: 4) {
                Divider().padding(.bottom, 6)
                Text("TV AppIcon")
                    .font(.caption.weight(.semibold))
                Text("Version \(appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("© 2025 Di Nerd Apps LLC")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(20)
        .frame(width: 210, alignment: .leading)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private func sidebarSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.leading, 8)
                .padding(.top, 10)
                .padding(.bottom, 2)
            content()
        }
    }

    // MARK: - Detail panel

    @ViewBuilder
    private var detailPanel: some View {
        switch selectedPage {
        case .general:
            GeneralSettingsPanel()
        case .privacy:
            WebPagePanel(title: "Privacy Policy", url: privacyURL)
        case .terms:
            WebPagePanel(title: "Terms of Use", url: termsURL)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - Sidebar Row

struct SidebarRow: View {
    let page: SettingsPage
    @Binding var selected: SettingsPage

    var body: some View {
        Button {
            selected = page
        } label: {
            HStack(spacing: 10) {
                Image(systemName: page.icon)
                    .frame(width: 20)
                    .foregroundStyle(selected == page ? .white : page.color)
                Text(page.title)
                    .font(.subheadline)
                    .foregroundStyle(selected == page ? .white : .primary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selected == page ? page.color : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Page enum

enum SettingsPage: String, CaseIterable {
    case general = "General"
    case privacy = "Privacy Policy"
    case terms   = "Terms of Use"

    var title: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .privacy: return "lock.shield"
        case .terms:   return "doc.text"
        }
    }

    var color: Color {
        switch self {
        case .general: return .blue
        case .privacy: return .green
        case .terms:   return .orange
        }
    }
}

// MARK: - General Settings Panel

struct GeneralSettingsPanel: View {
    @AppStorage("exportFolderRemembered") private var exportFolderRemembered = false
    @AppStorage("showSizesOnLaunch")      private var showSizesOnLaunch      = false
    @State private var showPaywall  = false
    @State private var showTipJar   = false

    var store: StoreModel = .shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                panelHeader(icon: "gearshape.fill", title: "General", color: .blue)

                // Pro / Tip Jar card
                VStack(alignment: .leading, spacing: 12) {
                    sectionLabel(store.isPro ? "You're Pro!" : "Upgrade")

                    VStack(spacing: 0) {
                        if store.isPro {
                            // Already pro — show status
                            HStack(spacing: 12) {
                                Image(systemName: "crown.fill")
                                    .frame(width: 28, height: 28)
                                    .background(Color.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 7))
                                    .foregroundStyle(.yellow)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("TV AppIcon Pro").font(.subheadline)
                                    Text("All slots unlocked — thank you!").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                            }
                            .padding(14)
                        } else {
                            LinkRow(icon: "crown.fill", color: .yellow,
                                    label: "Unlock Pro",
                                    subtitle: "App Store, Top Shelf & all layers") {
                                showPaywall = true
                            }
                            Divider().padding(.leading, 46)
                        }

                        LinkRow(icon: "heart.fill", color: .pink,
                                label: "Tip Jar",
                                subtitle: "Support indie development ❤️") {
                            showTipJar = true
                        }
                    }
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                .sheet(isPresented: $showPaywall) { PaywallView(store: store) }
                .sheet(isPresented: $showTipJar)  { TipJarView(store: store)  }

                // About card
                VStack(alignment: .leading, spacing: 16) {
                    sectionLabel("About TV AppIcon")

                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 64, height: 64)
                            .overlay {
                                Image(systemName: "tv.and.hifispeaker.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("TV AppIcon")
                                .font(.headline)
                            Text("by Di Nerd Apps LLC")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Generate all required tvOS app icon sizes and layers, ready for Xcode.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }

                // Preferences card
                VStack(alignment: .leading, spacing: 12) {
                    sectionLabel("Preferences")

                    VStack(spacing: 0) {
                        Toggle("Show size list on launch", isOn: $showSizesOnLaunch)
                            .padding(14)
                        Divider().padding(.leading, 14)
                        Toggle("Remember last export folder", isOn: $exportFolderRemembered)
                            .padding(14)
                    }
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }

            }
            .padding(28)
        }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Reusable row for links

struct LinkRow: View {
    let icon: String
    let color: Color
    let label: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 7))
                    .foregroundStyle(color)

                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(.subheadline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Panel header helper

@ViewBuilder
func panelHeader(icon: String, title: String, color: Color) -> some View {
    HStack(spacing: 12) {
        Image(systemName: icon)
            .font(.system(size: 22))
            .foregroundStyle(color)
        Text(title)
            .font(.title2.bold())
    }
}

// MARK: - Web Page Panel

struct WebPagePanel: View {
    let title: String
    let url: URL

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack(spacing: 12) {
                panelHeader(icon: iconFor(title: title), title: title, color: colorFor(title: title))
                Spacer()
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Label("Open in Browser", systemImage: "arrow.up.right.square")
                        .font(.subheadline)
                }
                .buttonStyle(.glass)
            }
            .padding(20)

            Divider()

            // WebView
            WebView(url: url)
        }
    }

    private func iconFor(title: String) -> String {
        title.contains("Privacy") ? "lock.shield.fill" : "doc.text.fill"
    }

    private func colorFor(title: String) -> Color {
        title.contains("Privacy") ? .green : .orange
    }
}

// MARK: - WebView (WKWebView wrapper)

struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
