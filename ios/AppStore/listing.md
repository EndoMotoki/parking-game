# App Store 掲載情報（下書き）

App Store Connect に入力する内容の下書きです。文字数の上限は Apple の制限です。

## 基本情報

| 項目 | 内容 |
|---|---|
| 名前（30文字まで） | 駐車練習 |
| 名前が使われていたときの案 | 駐車練習 - バック・縦列駐車 |
| サブタイトル（30文字まで） | バック・縦列駐車をゲームで練習 |
| Bundle ID | com.endomotoki.parking |
| SKU | parking |
| プライマリ言語 | 日本語 |
| カテゴリ | ゲーム ＞ シミュレーション（サブ：教育） |
| 価格 | 無料（アプリ内課金あり） |
| 配信地域 | 日本（おすすめ。EU・英国に出す場合は広告の同意画面が必要） |
| プライバシーポリシー URL | https://endomotoki.github.io/parking-game/privacy.html |
| サポート URL | https://endomotoki.github.io/parking-game/support.html |
| マーケティング URL（任意） | https://endomotoki.github.io/parking-game/ |
| 著作権 | 2026 EndoMotoki |

## プロモーション用テキスト（170文字まで、審査なしでいつでも変更可）

バック駐車・縦列駐車・出庫を、ミラーとバックモニターを見ながら練習できるゲーム。全40ステージ。動く車や歩行者、夜の駐車場に挑むハードステージも。

## 説明文（4000文字まで）

駐車が苦手な人のための、駐車練習ゲームです。
駐車場や路肩で、バック駐車・前向き駐車・縦列駐車と出庫を、何度でも練習できます。

■ 本物に近い運転感覚
・左右のドアミラーとルームミラー、バックモニター、アラウンドビューモニター
・ハンドルを切ったときの進路を示す予測線、コーナーセンサーの音
・普通車・軽自動車・ミニバンで、曲がり方や大きさが変わります
・ガイドやセンサーはオフにもできるので、慣れてきたら実際と同じ条件で

■ ステージで少しずつ上達
・ノーマル20ステージ：空いた駐車場から、満車の一番奥、狭い路肩の縦列まで
・60点以上、接触なしでクリアすると次のステージへ
・ステージごとに過去最高得点を記録
・全ステージクリアでバッジがもらえます
・進み具合は iCloud に保存。アプリを入れ直しても、機種変更しても続きから

■ ハードステージ（アプリ内課金）
・通路を走る車や歩行者、柱のある立体駐車場、夜の駐車場など、実際に近い難しい20ステージ
・「広告を削除＋ハードステージ解放」を一度購入すると、広告も出なくなります

■ 採点とリプレイ
・角度のずれ、枠の中心からのずれ、切り返しの回数、時間で100点満点の採点
・走った跡をリプレイで確認できます
・迷ったら「お手本」で、その配置の動かし方を自動運転で見られます

■ 自由練習
・入庫・出庫、バック・前向き・縦列、混み具合、車の種類、枠の幅を選んで練習

■ いろいろな遊び方
・iPhone は横向きでも縦向きでも
・iPad、Mac（Apple シリコン）にも対応
・Switch Pro コントローラーなどのゲームパッドでも遊べます

※ 実際の運転では、周りの安全を確かめ、交通ルールを守ってください。

## キーワード（100文字まで、カンマ区切り）

駐車,バック駐車,縦列駐車,車庫入れ,運転,練習,シミュレーター,ペーパードライバー,教習所,免許,出庫,バックモニター,ドライブ

## スクリーンショット

**App Store に使うのは `promo/` の宣伝用画像**（見出しと説明つき）。元のゲーム画面は `screenshots/`。

| App Store Connect の欄 | サイズ | ファイル（`promo/`） |
|---|---|---|
| iPhone（Dynamic Island 搭載・大） | 2868×1320 | promo-iphone69-1〜5 |
| iPhone（Dynamic Island 搭載） | 2622×1206 | promo-iphone63-1〜5 |
| iPad 13インチ | 2752×2064 | promo-ipad-1〜5 |
| iPhone Duo（任意） | 2007×2853 | promo-duo-inner-1〜5 |

1. バック駐車を何度でも練習
2. 夜の立体駐車場にも挑戦しよう（ハードステージ）
3. 苦手な縦列駐車もミラーで確認
4. 100点満点で採点（採点・リプレイ）
5. クリアして次のステージへ（全40ステージ）

## ヘッダと検索結果（任意）

`creative/` に入っています。夜の立体駐車場をゲームで描いた背景に「駐車が、うまくなる。」。

| 欄 | サイズ | ファイル |
|---|---|---|
| プロダクトページのヘッダ | 3840×1646（21:9） | appstore-header-3840x1646.png |
| 検索結果 | 3840×2560（3:2） | appstore-search-3840x2560.png |

文字と車は Apple の指定する中央の安全な範囲（ヘッダ 1646×661、検索結果 2168×1030）に収めています。透明部分なし。作り方は `promo/template/hero.html`。

## アプリ内課金

| 項目 | 内容 |
|---|---|
| 種類 | 非消耗型 |
| 参照名 | 広告削除＋ハードモード解放 |
| 製品 ID | com.endomotoki.parking.premium |
| 価格 | ¥360（近い価格帯を選ぶ） |
| 表示名 | 広告削除＋ハードモード解放 |
| 説明 | 広告をすべて消し、動く車や夜の駐車場など難しい20ステージを遊べるようにします |
| 審査用スクリーンショット | `screenshots/iphone-1-menu.png` など、購入ボタンのある画面 |

## 年齢制限

暴力・性的表現・ギャンブルなど、すべて「なし」。→ 4+ の想定。
広告を出すので、AdMob 側で広告の内容を「一般向け」に設定する。

## App のプライバシー（広告 SDK・Firebase の分）

アプリ自身は情報を集めませんが、Google AdMob と Firebase（Analytics・Crashlytics）が集めるため、次のように答えます（Google の案内に合わせた想定。提出前に AdMob・Firebase のヘルプで最新を確認）。

| データの種類 | 用途 | ユーザーに紐づく | トラッキング |
|---|---|---|---|
| ID（デバイス ID） | サードパーティ広告、分析 | いいえ | はい |
| 使用状況データ（製品の操作） | サードパーティ広告、分析 | いいえ | はい |
| 使用状況データ（広告データ） | サードパーティ広告 | いいえ | はい |
| 診断（クラッシュデータ） | 分析、App の機能 | いいえ | いいえ |
| 診断（パフォーマンスデータ） | 分析 | いいえ | いいえ |
| 位置情報（おおよその場所） | サードパーティ広告、分析 | いいえ | はい |

Firebase Analytics で記録している出来事：`stage_start`・`stage_result`（ステージ・得点・クリアしたか・接触回数）、`free_start`・`free_result`、`demo_start`、`purchase_tap`、`premium_purchased`、`badge_earned`、`tutorial_complete`

## 審査メモ（App Review への連絡事項）

2026-11 の初回審査で「Guideline 2.1 - Information Needed」となり、次の6点を求められた。下の英文を App Store Connect の「App Review に関する情報」→「メモ」にそのまま貼り、実機の画面収録を「添付ファイル」に付ける。

```
1. Screen recording
A screen recording captured on a physical iPhone running the latest iOS is attached. It starts with launching the app and shows: the first-launch tutorial, the tracking permission prompt, starting Normal stage 1, driving and parking, the result screen with the score, the stage list with the locked Hard stages, the in-app purchase ("Remove ads + unlock Hard stages", non-consumable), and playing a Hard stage after the purchase. The app has no account registration, no login and no user-generated content.

2. Purpose and target audience
"駐車練習" (Parking Practice) is a 3D parking simulator for people in Japan who are learning to drive or who are not confident about parking: driving-school students, new drivers and people who rarely drive. Users practice reverse parking, parallel parking, pulling out of tight spaces, multi-story car parks, night parking and avoiding moving cars and pedestrians, using an on-screen steering wheel, mirrors and parking sensors. Each attempt is scored (how straight the car is in the space, the number of turns; hitting a car or wall gives 0 points), and a replay shows the car's path, so users can repeat difficult situations safely before trying them in a real car.

3. How to use the app
No login, account or sample file is needed. Launch the app, read the short tutorial (it can be reopened from "遊び方" at the bottom of the menu), choose a stage from "ステージ" and tap "スタート". Turn the steering wheel with a finger and hold "前進" (forward) or "後退" (reverse) to move. Stop inside the blue space and tap "完了" (done) to get a score. The 20 Normal stages are free and unlock one by one when the previous stage is cleared. The 20 Hard stages and ad removal are unlocked by the non-consumable in-app purchase "com.endomotoki.parking.premium", available from the gold button under "スタート" or from the Hard tab of the stage list. "購入を復元" (Restore Purchases) is in the menu. The purchase can be tested in the sandbox environment.

4. External services
- Apple StoreKit: the in-app purchase
- Apple iCloud key-value storage: syncs stage progress, best scores and settings between the user's devices (no account in the app)
- Google AdMob (Google Mobile Ads SDK): banner ads on the menu and result screens, and an interstitial ad after every third practice. No ads are shown while driving, and none after the purchase.
- Google Firebase Analytics and Crashlytics: anonymous usage statistics and crash reports
The game itself (3D graphics via the bundled three.js library) runs entirely on the device and works offline. No AI services, data providers or authentication services are used.

5. Regional differences
The app is distributed in Japan only and the interface is in Japanese. Its features and content are the same for all users; there are no regional differences.

6. Regulated industry / third-party material
The app is not in a regulated industry. It is a practice game and not an official driving-school or licensing tool. All stages, 3D models and graphics are original and made for this app; the only third-party code is open-source libraries (three.js, MIT license) and the Google and Firebase SDKs.
```
