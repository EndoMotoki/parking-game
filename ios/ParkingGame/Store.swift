import Foundation
import StoreKit

/// 「広告を削除」（買い切り）の購入管理。StoreKit 2
@MainActor
final class Store {
    static let noAdsID = "io.github.endomotoki.parkinggame.noads"

    private(set) var adFree: Bool { didSet { UserDefaults.standard.set(adFree, forKey: "adFree") } }
    private(set) var price: String?
    private(set) var busy = false
    private(set) var message: String?
    var onChange: (() -> Void)?

    private var product: Product?
    private var updates: Task<Void, Never>?

    #if DEBUG
    /// シミュレーターで App Store なしに流れを確かめるための疑似ストア（起動引数 -mockStore のときだけ）
    private let mock = ProcessInfo.processInfo.arguments.contains("-mockStore")
    #else
    private let mock = false
    #endif

    init() {
        adFree = UserDefaults.standard.bool(forKey: "adFree")
        if mock {
            price = "¥360"
            return
        }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result { await t.finish() }
                await self?.refreshEntitlement()
            }
        }
        Task {
            await loadProduct()
            await refreshEntitlement()
        }
    }

    private func changed() { onChange?() }

    func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.noAdsID]).first
            price = product?.displayPrice
        } catch {
            print("product load failed:", error)
        }
        changed()
    }

    /// 購入済みかどうかを App Store の記録から確かめる
    func refreshEntitlement() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.noAdsID, t.revocationDate == nil { owned = true }
        }
        adFree = owned
        changed()
    }

    func buy() async {
        guard !busy, !adFree else { return }
        message = nil
        if mock {
            busy = true; changed()
            try? await Task.sleep(nanoseconds: 600_000_000)
            busy = false; adFree = true; message = "購入しました（テスト）"; changed()
            return
        }
        if product == nil { await loadProduct() }
        guard let product else { message = "App Store に接続できませんでした"; changed(); return }
        busy = true; changed()
        defer { busy = false; changed() }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let t) = verification {
                    await t.finish()
                    adFree = true
                    message = "購入ありがとうございます。広告を削除しました"
                } else {
                    message = "購入を確認できませんでした"
                }
            case .pending:
                message = "購入の承認待ちです"
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = "購入できませんでした"
        }
    }

    func restore() async {
        guard !busy else { return }
        message = nil
        busy = true; changed()
        if !mock {
            try? await AppStore.sync()
            await refreshEntitlement()
        }
        busy = false
        message = adFree ? "購入を復元しました" : "復元できる購入はありませんでした"
        changed()
    }
}
