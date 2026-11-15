# 駐車練習 iOS アプリ

ウェブ版のゲーム（リポジトリ直下の `index.html`）を iPhone / iPad アプリにしたものです。
広告（Google AdMob）と、買い切りの「広告削除＋ハードモード解放」（アプリ内課金、1回の購入で広告削除とハードステージの両方）が付いています。

- ゲーム本体はビルドのたびに `../index.html` からコピーされます。ウェブ版を直せばアプリにも反映されます。
- three.js はアプリに同梱しているので（`ParkingGame/three.min.js`）、オフラインでも遊べます。

## 動かし方

1. `ParkingGame.xcodeproj` を Xcode で開く
2. TARGETS → ParkingGame → Signing & Capabilities で Team を選ぶ（実機で動かすとき）
3. ⌘R で実行

### 課金のテスト

- Xcode から実行すると `Products.storekit`（StoreKit のテスト設定）が使われ、App Store なしで購入・復元を試せます。
  Xcode の Debug → StoreKit → Manage Transactions で購入の取り消しもできます。
- シミュレーターを `xcrun simctl launch` で直接起動するときは、起動引数 `-mockStore` を付けると疑似ストアで購入の流れを試せます（Debug ビルドのみ）。

### 広告のテスト

- いまはすべて Google のテスト用 ID です（「Test mode」と表示されます）。
- 起動引数 `-adTestOnStart` を付けると、スタートのたびに全画面広告が出ます（Debug ビルドのみ）。

## 広告の出し方

- バナー：メニューと結果画面の下にだけ表示。運転中は出しません。
- 全画面広告：結果画面から次の練習に進むとき、3回に1回。
- 「広告削除＋ハードモード解放」を購入すると、どちらも出なくなります。

## 公開までにやること

掲載文・スクリーンショット・課金アイテム・プライバシーの答え方は [`AppStore/listing.md`](AppStore/listing.md) にまとめています。

### 準備済み（このリポジトリ）
- [x] アプリアイコン（1024×1024、透明なし）
- [x] プライバシーマニフェスト（`ParkingGame/PrivacyInfo.xcprivacy`）
- [x] 暗号化の申告（`ITSAppUsesNonExemptEncryption = NO`）
- [x] SKAdNetwork ID（Google 公開の一覧、2026-01-30 版）
- [x] プライバシーポリシー・サポートページ（GitHub Pages：`privacy.html`、`support.html`）。アプリのメニューからも開ける
- [x] App Store 用スクリーンショット（`AppStore/screenshots/`）
- [x] Release ビルドが通ること

### 自分でやること
1. **App Store Connect でアプリを作る**：名前・Bundle ID・SKU は `AppStore/listing.md` のとおり
2. **有料アプリの契約**（ビジネス → 契約）：口座・税の情報を登録（アプリ内課金に必要）
3. **アプリ内課金を作る**：非消耗型 `com.endomotoki.parking.premium`、¥360
4. **AdMob** でアプリと広告ユニット（バナー・インタースティシャル）を作り、次の ID を差し替える（このあと頼んでもらえれば差し替えます）
   - `Config/Info.plist` の `GADApplicationIdentifier`
   - `ParkingGame/AdManager.swift` の `AdUnit.banner` と `AdUnit.interstitial`
5. **配信地域**：日本のみがおすすめ。EU・英国にも出すなら、AdMob の同意メッセージ（UMP）を設定して、アプリに同意画面を入れる
6. **掲載情報を入力**：説明文・キーワード・スクリーンショット・プライバシー・年齢制限（`AppStore/listing.md`）
7. **アップロード**：Xcode で Product → Archive → Distribute App → App Store Connect（Team を選んで署名）
8. TestFlight で実機の購入（Sandbox）を確認してから、審査に提出

### スクリーンショットの撮り直し
Debug ビルドを起動引数 `-screenshots YES -js "<場面を用意するコード>"` で起動すると、広告なし・購入済みの状態で、指定した場面を自動で用意します（Debug ビルドのみ）。
