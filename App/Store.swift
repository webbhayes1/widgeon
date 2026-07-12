import Foundation
import StoreKit

/// Widgeon Plus: one-time unlock for the five non-duck characters.
/// Duck is free — everyone gets the full ritual; Plus buys variety.
@MainActor
final class Store: ObservableObject {
    static let shared = Store()
    static let plusID = "com.webbhayes.widgeon.plus"

    @Published private(set) var plusProduct: Product?
    @Published private(set) var hasPlus: Bool
    @Published var purchasing = false

    private var updatesTask: Task<Void, Never>?

    private init() {
        // Cached so the picker renders instantly; entitlements refresh it.
        hasPlus = SharedStore.defaults.bool(forKey: "store.plus")
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if let transaction = try? update.payloadValue {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    static func isLocked(_ character: PetCharacter) -> Bool {
        character != .duck && !shared.hasPlus
    }

    func loadProducts() async {
        plusProduct = try? await Product.products(for: [Self.plusID]).first
    }

    func refreshEntitlements() async {
        var owned = false
        for await entitlement in Transaction.currentEntitlements {
            if let t = try? entitlement.payloadValue, t.productID == Self.plusID {
                owned = true
            }
        }
        hasPlus = owned
        SharedStore.defaults.set(owned, forKey: "store.plus")
    }

    /// Returns true if the user ends up owning Plus.
    @discardableResult
    func buyPlus() async -> Bool {
        guard let product = plusProduct else { return hasPlus }
        purchasing = true
        defer { purchasing = false }
        guard let result = try? await product.purchase() else { return hasPlus }
        if case .success(let verification) = result,
           let transaction = try? verification.payloadValue {
            await transaction.finish()
            await refreshEntitlements()
        }
        return hasPlus
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }
}
