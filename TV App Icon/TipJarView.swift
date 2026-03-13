import SwiftUI
import StoreKit

struct TipJarView: View {
    var store: StoreModel = .shared
    @Environment(\.dismiss) private var dismiss

    @State private var isAnimating = false
    @State private var tappedProduct: String? = nil
    @State private var showThankYou = false
    @State private var thankYouMessage = ""

    private let tipEmojis: [String: (emoji: String, label: String, color: Color)] = [
        StoreModel.tipSmall:  (emoji: "☕", label: "Small Tip",  color: .brown),
        StoreModel.tipMedium: (emoji: "🍕", label: "Medium Tip", color: .orange),
        StoreModel.tipLarge:  (emoji: "🚀", label: "Large Tip",  color: .purple),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0f0f1a"), Color(hex: "0a1a10")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if showThankYou {
                thankYouView
            } else {
                mainContent
            }
        }
        .frame(minWidth: 460, minHeight: 500)
        .onAppear {
            withAnimation(.spring(response: 0.6)) { isAnimating = true }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Close
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(20)
            }

            VStack(spacing: 28) {
                // Header
                VStack(spacing: 12) {
                    Text("❤️")
                        .font(.system(size: 56))
                        .scaleEffect(isAnimating ? 1 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isAnimating)

                    Text("Tip Jar")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("TV AppIcon is made with love by one developer.\nIf it saved you time, a tip means the world!")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: isAnimating)

                // Tip buttons
                if store.isLoading && store.tipProducts.isEmpty {
                    ProgressView().padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(store.tipProducts.enumerated()), id: \.element.id) { index, product in
                            let meta = tipEmojis[product.id] ?? (emoji: "💝", label: "Tip", color: .pink)
                            TipButton(
                                emoji: meta.emoji,
                                label: meta.label,
                                price: product.displayPrice,
                                color: meta.color,
                                isLoading: tappedProduct == product.id && store.isLoading
                            ) {
                                tappedProduct = product.id
                                Task {
                                    let success = await store.purchaseTip(product)
                                    if success, let msg = store.lastTipThankYou {
                                        thankYouMessage = msg
                                        withAnimation(.spring(response: 0.5)) {
                                            showThankYou = true
                                        }
                                    }
                                    tappedProduct = nil
                                }
                            }
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 16)
                            .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1 + 0.25), value: isAnimating)
                        }

                        if store.tipProducts.isEmpty {
                            Text("Tips unavailable. Check your connection.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let error = store.purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                Text("Tips are optional and non-refundable.\nThank you for your support! 🙏")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.25))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Thank You

    private var thankYouView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: CGFloat(60 + i * 20), height: CGFloat(60 + i * 20))
                        .scaleEffect(showThankYou ? 1 + CGFloat(i) * 0.15 : 0.3)
                        .opacity(showThankYou ? 0 : 0.6)
                        .animation(.easeOut(duration: 1.0).delay(Double(i) * 0.1), value: showThankYou)
                }

                Text("🎉")
                    .font(.system(size: 72))
                    .scaleEffect(showThankYou ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showThankYou)
            }
            .frame(height: 160)

            VStack(spacing: 10) {
                Text(thankYouMessage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Your support keeps TV AppIcon alive and growing.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button("Done") { dismiss() }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [.green.opacity(0.8), .teal],
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .buttonStyle(.plain)
                .padding(.horizontal, 36)
                .padding(.bottom, 40)
        }
    }
}

// MARK: - Tip Button

struct TipButton: View {
    let emoji: String
    let label: String
    let price: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                Text(label)
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    Text(price)
                        .font(.headline)
                        .foregroundStyle(color)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(color.opacity(0.15), in: Capsule())
                }
            }
            .padding(16)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(color.opacity(0.2), lineWidth: 1))
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        ._onButtonGesture(pressing: { isPressed = $0 }, perform: {})
    }
}

#Preview {
    TipJarView()
}
