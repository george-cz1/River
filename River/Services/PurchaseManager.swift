import StoreKit
import SwiftUI

/// Manages StoreKit 2 in-app purchases for the Pro upgrade
@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    private(set) var isPro: Bool = false
    private(set) var isLoading: Bool = false
    private(set) var error: String?

    private let proProductID = "com.george.river.pro"

    // DEBUG: Set to true to unlock Pro features for testing
    private let debugUnlockPro = false

    private init() {
        Task {
            await checkPurchaseStatus()
        }
        observeTransactionUpdates()
    }

    // MARK: - Status Check

    func checkPurchaseStatus() async {
        // DEBUG: Override for testing
        if debugUnlockPro {
            await MainActor.run { isPro = true }
            return
        }

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == proProductID,
               transaction.revocationDate == nil {
                await MainActor.run { isPro = true }
                return
            }
        }
        await MainActor.run { isPro = false }
    }

    // MARK: - Purchase

    func purchasePro() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            let products = try await Product.products(for: [proProductID])
            guard let product = products.first else {
                await MainActor.run {
                    error = "Product not available."
                    isLoading = false
                }
                return
            }

            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await MainActor.run { isPro = true }
                }
            case .userCancelled:
                break
            case .pending:
                await MainActor.run {
                    error = "Purchase is pending approval."
                }
            @unknown default:
                break
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }

        await MainActor.run { isLoading = false }
    }

    // MARK: - Restore

    func restorePurchases() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            try await AppStore.sync()
            await checkPurchaseStatus()
        } catch {
            await MainActor.run {
                self.error = "Restore failed: \(error.localizedDescription)"
            }
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

// MARK: - Pro Feature Gate View

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
