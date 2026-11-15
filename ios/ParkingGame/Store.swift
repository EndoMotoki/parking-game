import Foundation
import StoreKit

/// 買い切りの課金アイテム（StoreKit 2）
/// 1回の購入で「広告を削除」と「ハードステージ（動く車・歩行者・立体駐車場などの難しいステージ）の解放」の両方
@MainActor
final class Store {
    static let productID = "com.endomotoki.parking.premium"
    private static let savedKey = "premiumOwned"

    private(set) var owned: Bool
    private(set) var price: String?
    private(set) var busy = false
    private(set) var message: String?
    var onChange: (() -> Void)?

    var adFree: Bool { owned }
    var hardOwned: Bool { owned }

    private var product: Product?
    private var updates: Task<Void, Never>?

    #if DEBUG
    /// シミュレーターで App Store なしに流れを確かめるための疑似ストア（起動引数 -mockStore のときだけ）
    private let mock = ProcessInfo.processInfo.arguments.contains("-mockStore")
    /// App Store 用のスクリーンショットを撮るとき（起動引数 -screenshots YES）：購入済みとして広告を出さない
    private let screenshots = UserDefaults.standard.bool(forKey: "screenshots")
    #else
    private let mock = false
    private let screenshots = false
    #endif

    init() {
        owned = UserDefaults.standard.bool(forKey: Self.savedKey)
        if screenshots { owned = true; return }
        if mock {
            price = "¥360"
            return
        }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result { await t.finish() }
                await self?.refreshEntitlements()
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    private func changed() {
        if !screenshots { UserDefaults.standard.set(owned, forKey: Self.savedKey) }
        onChange?()
    }

    func loadProducts() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
            price = product?.displayPrice
        } catch {
            print("product load failed:", error)
        }
        changed()
    }

    /// 購入済みかどうかを App Store の記録から確かめる
    func refreshEntitlements() async {
        var now = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.revocationDate == nil, t.productID == Self.productID { now = true }
        }
        owned = now
        changed()
    }

    func buy() async {
        guard !busy, !owned else { return }
        message = nil
        if mock {
            busy = true; changed()
            try? await Task.sleep(nanoseconds: 600_000_000)
            busy = false; owned = true; message = "購入しました（テスト）"; changed()
            return
        }
        if product == nil { await loadProducts() }
        guard let product else { message = "App Store に接続できませんでした"; changed(); return }
        busy = true; changed()
        defer { busy = false; changed() }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let t) = verification {
                    await t.finish()
                    owned = true
                    message = "購入ありがとうございます。広告を削除し、ハードステージを解放しました"
                    Telemetry.log("premium_purchased")
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
            await refreshEntitlements()
        }
        busy = false
        message = owned ? "購入を復元しました" : "復元できる購入はありませんでした"
        changed()
    }
}
