import StoreKit
import SwiftUI

enum ProTier: Int {
    case none = 0
    case devicePro = 1
    case sync = 2
}

@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    private(set) var tier: ProTier = .none
    private(set) var isLoading: Bool = false
    private(set) var error: String?

    var isPro: Bool { tier != .none }
    var isSync: Bool { tier == .sync }

    #if os(iOS)
    private let deviceProProductID = "com.george.river.pro"
    #elseif os(macOS)
    private let deviceProProductID = "com.george.river.mac.pro"
    #else
    private let deviceProProductID = "com.george.river.pro"
    #endif
    private let syncProductID = "com.george.river.sync"

    // DEBUG: Change to .none before App Store submission
    private let debugTier: ProTier = .devicePro

    private init() {
        Task { await checkPurchaseStatus() }
        observeTransactionUpdates()
    }

    // MARK: - Status Check

    func checkPurchaseStatus() async {
        if debugTier != .none {
            await MainActor.run { tier = debugTier }
            return
        }

        var highest: ProTier = .none
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                if transaction.productID == syncProductID {
                    highest = .sync
                    break
                } else if transaction.productID == deviceProProductID && highest == .none {
                    highest = .devicePro
                }
            }
        }
        await MainActor.run { tier = highest }
    }

    // MARK: - Purchase

    func purchaseDevicePro() async {
        await purchase(productID: deviceProProductID)
    }

    func purchaseSync() async {
        await purchase(productID: syncProductID)
    }

    private func purchase(productID: String) async {
        await MainActor.run { isLoading = true; error = nil }
        do {
            let products = try await Product.products(for: [productID])
            guard let product = products.first else {
                await MainActor.run { error = "Product not available."; isLoading = false }
                return
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await checkPurchaseStatus()
                }
            case .userCancelled:
                break
            case .pending:
                await MainActor.run { error = "Purchase is pending approval." }
            @unknown default:
                break
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription }
        }
        await MainActor.run { isLoading = false }
    }

    // MARK: - Restore

    func restorePurchases() async {
        await MainActor.run { isLoading = true; error = nil }
        do {
            try await AppStore.sync()
            await checkPurchaseStatus()
        } catch {
            await MainActor.run { self.error = "Restore failed: \(error.localizedDescription)" }
        }
        await MainActor.run { isLoading = false }
    }

    // MARK: - Transaction Updates

    private func observeTransactionUpdates() {
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await checkPurchaseStatus()
                }
            }
        }
    }
}

// MARK: - Pro Feature Lock View (iOS only)

#if os(iOS)
struct ProFeatureLock: View {
    let feature: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(AppColors.focusBlue)
                Text(feature)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text("Pro")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.focusBlue)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.focusBlueSoft)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
#endif
