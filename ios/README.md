# 駐車練習 iOS アプリ

ウェブ版のゲーム（リポジトリ直下の `index.html`）を iPhone / iPad アプリにしたものです。
広告（Google AdMob）と、買い切りの「広告を削除」（アプリ内課金）が付いています。

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
- 「広告を削除」を購入すると、どちらも出なくなります。

## 公開までにやること

1. Apple Developer Program に登録する
2. Bundle ID（いまは `io.github.endomotoki.parkinggame`）を決めて、プロジェクトの設定と `Store.swift` の商品 ID、`Products.storekit` を合わせる
3. App Store Connect でアプリを作り、非消耗型の課金アイテムを2つ登録する。有料アプリの契約・口座・税の情報も登録する
   - 広告を削除：`<Bundle ID>.noads`
   - ハードステージ：`<Bundle ID>.hardstages`（`Store.swift` の `Store.Item` と `Products.storekit` も合わせる）
4. AdMob でアプリと広告ユニット（バナー・インタースティシャル）を作り、次の ID を差し替える
   - `Config/Info.plist` の `GADApplicationIdentifier`
   - `ParkingGame/AdManager.swift` の `AdUnit.banner` と `AdUnit.interstitial`
   - `Config/Info.plist` の `SKAdNetworkItems`（Google が公開している一覧を全部入れる）
5. EU・英国向けに出すなら、AdMob の同意メッセージ（UMP）を設定する
6. プライバシーポリシーのページを用意し、App Store Connect にプライバシー情報（広告・トラッキング）を記入する
7. Product → Archive でアップロードして審査に出す
