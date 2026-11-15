import Foundation
import StoreKit

/// 買い切りの課金アイテム（StoreKit 2）
/// - 広告を削除
/// - ハードステージ（動く車・歩行者・立体駐車場などの難しいステージ）
@MainActor
final class Store {
    enum Item: String, CaseIterable {
        case noAds = "io.github.endomotoki.parkinggame.noads"
        case hard = "io.github.endomotoki.parkinggame.hardstages"

        /// Web 側から届く名前（"noads" / "hard"）
        init?(webName: String?) {
            switch webName {
            case nil, "noads": self = .noAds
            case "hard": self = .hard
            default: return nil
            }
        }
        var savedKey: String { self == .noAds ? "adFree" : "hardOwned" }
        var thanks: String { self == .noAds ? "購入ありがとうございます。広告を削除しました" : "購入ありがとうございます。ハードステージを解放しました" }
    }

    private(set) var owned: Set<Item>
    private(set) var prices: [Item: String] = [:]
    private(set) var busy = false
    private(set) var message: String?
    var onChange: (() -> Void)?

    var adFree: Bool { owned.contains(.noAds) }
    var hardOwned: Bool { owned.contains(.hard) }

    private var products: [Item: Product] = [:]
    private var updates: Task<Void, Never>?

    #if DEBUG
    /// シミュレーターで App Store なしに流れを確かめるための疑似ストア（起動引数 -mockStore のときだけ）
    private let mock = ProcessInfo.processInfo.arguments.contains("-mockStore")
    #else
    private let mock = false
    #endif

    init() {
        owned = Set(Item.allCases.filter { UserDefaults.standard.bool(forKey: $0.savedKey) })
        if mock {
            prices = [.noAds: "¥360", .hard: "¥480"]
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
        for item in Item.allCases { UserDefaults.standard.set(owned.contains(item), forKey: item.savedKey) }
        onChange?()
    }

    func loadProducts() async {
        do {
            for p in try await Product.products(for: Item.allCases.map(\.rawValue)) {
                if let item = Item(rawValue: p.id) { products[item] = p; prices[item] = p.displayPrice }
            }
        } catch {
            print("product load failed:", error)
        }
        changed()
    }

    /// 購入済みかどうかを App Store の記録から確かめる
    func refreshEntitlements() async {
        var now = Set<Item>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.revocationDate == nil, let item = Item(rawValue: t.productID) { now.insert(item) }
        }
        owned = now
        changed()
    }

    func buy(_ item: Item) async {
        guard !busy, !owned.contains(item) else { return }
        message = nil
        if mock {
            busy = true; changed()
            try? await Task.sleep(nanoseconds: 600_000_000)
            busy = false; owned.insert(item); message = "購入しました（テスト）"; changed()
            return
        }
        if products[item] == nil { await loadProducts() }
        guard let product = products[item] else { message = "App Store に接続できませんでした"; changed(); return }
        busy = true; changed()
        defer { busy = false; changed() }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let t) = verification {
                    await t.finish()
                    owned.insert(item)
                    message = item.thanks
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
        message = owned.isEmpty ? "復元できる購入はありませんでした" : "購入を復元しました"
        changed()
    }
}
