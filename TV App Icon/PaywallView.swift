import SwiftUI
import StoreKit

// MARK: - Paywall Sheet

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    var store: StoreModel = .shared

    @State private var isAnimating = false
    @State private var showSuccess = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0d0d18"), Color(hex: "130d22")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if showSuccess {
                successView
            } else {
                mainContent
            }
        }
        .frame(minWidth: 580, minHeight: 620)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { isAnimating = true }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
                .padding(20)
            }

            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    comparisonSection
                    purchaseSection
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 36)
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            // Animated layered icon
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [.purple.opacity(0.5), .clear],
                        center: .center, startRadius: 0, endRadius: 60
                    ))
                    .frame(width: 120, height: 120)
                    .blur(radius: 22)
                    .scaleEffect(isAnimating ? 1.3 : 0.9)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: isAnimating)

                ForEach([(-10.0, 10.0, 0.35), (-5.0, 5.0, 0.6), (0.0, 0.0, 1.0)], id: \.0) { x, y, opacity in
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 64, height: 64)
                        .offset(x: x, y: y)
                        .opacity(opacity)
                }

                Image(systemName: "tv.and.hifispeaker.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(height: 100)
            .scaleEffect(isAnimating ? 1 : 0.85)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isAnimating)

            Text("Unlock TV AppIcon Pro")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text("One-time purchase · No subscription · Yours forever")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.45))
        }
        .opacity(isAnimating ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: isAnimating)
    }

    // MARK: - Comparison Cards

    private var comparisonSection: some View {
        HStack(alignment: .top, spacing: 14) {
            // FREE card
            VStack(alignment: .leading, spacing: 0) {
                // Card header
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.open.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("FREE")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .tracking(1.5)
                    }
                    Text("Get started")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 14)

                Divider().background(.white.opacity(0.08))

                VStack(alignment: .leading, spacing: 0) {
                    PlanRow(icon: "house.fill",       color: .blue,   text: "Home Screen icon",    included: true)
                    PlanRow(icon: "square.3.layers.3d", color: .cyan, text: "Front, Mid, Back layers", included: true)
                    PlanRow(icon: "star.fill",         color: .gray,  text: "App Store icon",      included: false)
                    PlanRow(icon: "trophy.fill",       color: .gray,  text: "Top Shelf Wide",      included: false)
                    PlanRow(icon: "tv.fill",           color: .gray,  text: "Top Shelf",           included: false)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.08), lineWidth: 1))
            .frame(maxWidth: .infinity)

            // PRO card
            VStack(alignment: .leading, spacing: 0) {
                // Card header with crown glow
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.yellow)
                        Text("PRO")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.yellow)
                            .tracking(1.5)
                    }
                    Text("Everything unlocked")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 14)

                Divider().background(.white.opacity(0.12))

                VStack(alignment: .leading, spacing: 0) {
                    PlanRow(icon: "house.fill",          color: .blue,   text: "Home Screen icon",    included: true)
                    PlanRow(icon: "square.3.layers.3d",  color: .cyan,   text: "Front, Mid, Back layers", included: true)
                    PlanRow(icon: "star.fill",           color: .yellow, text: "App Store icon",      included: true)
                    PlanRow(icon: "trophy.fill",         color: .orange, text: "Top Shelf Wide",      included: true)
                    PlanRow(icon: "tv.fill",             color: .purple, text: "Top Shelf",           included: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.18), .purple.opacity(0.18)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        LinearGradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.5
                    )
            )
            .frame(maxWidth: .infinity)
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 16)
        .animation(.easeOut(duration: 0.45).delay(0.2), value: isAnimating)
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if store.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.vertical, 16)
            } else if let product = store.proProduct {
                Button {
                    Task {
                        await store.purchasePro()
                        if store.isPro {
                            withAnimation(.spring(response: 0.5)) { showSuccess = true }
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text("Unlock Pro — \(product.displayPrice)")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(colors: [.blue, .purple],
                                       startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(isAnimating ? 1 : 0.95)
                .animation(.spring(response: 0.5).delay(0.45), value: isAnimating)

            } else {
                // Products not loaded — retry button instead of dead state
                VStack(spacing: 10) {
                    Text("Could not load pricing")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                    Button("Try Again") {
                        Task { await store.loadProducts() }
                    }
                    .buttonStyle(.glass)
                }
                .padding(.vertical, 8)
            }

            if let error = store.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.75))
                    .multilineTextAlignment(.center)
            }

            Button("Restore Purchase") {
                Task { await store.restorePurchases() }
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.35))
            .buttonStyle(.plain)
        }
        .opacity(isAnimating ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.35), value: isAnimating)
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 130, height: 130)
                    .scaleEffect(showSuccess ? 1.4 : 0.5)
                    .opacity(showSuccess ? 0 : 1)
                    .animation(.easeOut(duration: 0.9), value: showSuccess)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(.green)
                    .scaleEffect(showSuccess ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSuccess)
            }

            VStack(spacing: 10) {
                Text("You're Pro!")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                Text("All export slots are now unlocked.\nThank you for supporting TV AppIcon!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button("Start Exporting") { dismiss() }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(colors: [.blue, .purple],
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
        }
    }
}

// MARK: - Plan Row

struct PlanRow: View {
    let icon: String
    let color: Color
    let text: String
    let included: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: included ? icon : "lock.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(included ? color : Color.white.opacity(0.2))
                .frame(width: 22)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(included ? .white.opacity(0.85) : .white.opacity(0.25))
                .strikethrough(!included, color: .white.opacity(0.15))

            Spacer()

            Image(systemName: included ? "checkmark" : "xmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(included ? .green : .white.opacity(0.15))
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 4)
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
