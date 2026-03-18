import StoreKit
import SwiftUI

// MARK: - Store Model

@MainActor
@Observable
class StoreModel {
    static let shared = StoreModel()

    // Product IDs
    static let proProductID  = "unlimitedaccess.tvicon"
    static let tipSmall      = "smalltime.tvicon"
    static let tipMedium     = "mediumtip.tvicon"
    static let tipLarge      = "largetip.tvicon"

    var proProduct: Product?
    var tipProducts: [Product] = []
    var isPro: Bool = true // TEMP: remove before release

    var isLoading = false
    var purchaseError: String? = nil
    var lastTipThankYou: String? = nil

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await refreshPurchaseStatus() }
    }

    nonisolated func cancelListener() {
        // listener is cancelled when the task is deallocated
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        do {
            let allIDs: Set<String> = [
                Self.proProductID,
                Self.tipSmall, Self.tipMedium, Self.tipLarge
            ]
            let products = try await Product.products(for: allIDs)
            proProduct = products.first { $0.id == Self.proProductID }
            tipProducts = products
                .filter { $0.id != Self.proProductID }
                .sorted { $0.price < $1.price }
        } catch {
            purchaseError = "Could not load products: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Purchase Pro

    func purchasePro() async {
        guard let product = proProduct else { return }
        isLoading = true
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    isPro = true
                }
            case .pending:
                break
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Purchase Tip

    func purchaseTip(_ product: Product) async -> Bool {
        isLoading = true
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    lastTipThankYou = thankYouMessage(for: product.id)
                    isLoading = false
                    return true
                }
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
        isLoading = false
        return false
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
        } catch {
            purchaseError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Refresh Status

    func refreshPurchaseStatus() async {
        isPro = true // TEMP: remove before release
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    if transaction.productID == Self.proProductID {
                        await MainActor.run { self.isPro = true }
                    }
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Helpers

    private func thankYouMessage(for productID: String) -> String {
        switch productID {
        case Self.tipSmall:  return "Thanks for the coffee! ☕"
        case Self.tipMedium: return "You're awesome, thank you! 🙌"
        case Self.tipLarge:  return "Wow, you're amazing! Thank you so much! 🎉"
        default: return "Thank you for your support!"
        }
    }
}
