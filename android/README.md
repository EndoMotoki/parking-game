# 駐車練習 Android アプリ

ウェブ版のゲーム（リポジトリ直下の `index.html`）を Android アプリにしたものです。iOS 版（`../ios`）と同じ仕様です。

- ゲーム本体はビルドのたびに `../index.html` からコピーされます（`app/build.gradle.kts` の `copyGame`）。three.js は iOS 版と同じ同梱ファイル（`../ios/ParkingGame/three.min.js`）を使うので、オフラインでも遊べます
- 広告（Google AdMob）と、買い切りの「広告削除＋ハードモード解放」（Google Play Billing、¥360、製品 ID `com.endomotoki.parking.premium`）
- パッケージ名：`com.endomotoki.parking`

| 機能 | ファイル | iOS 版で同じ役目のファイル |
|---|---|---|
| 画面・ゲームとのやり取り・振動・戻るボタン | `MainActivity.kt` | `AppModel.swift`・`GameWebView.swift` |
| 課金 | `Store.kt` | `Store.swift` |
| 広告 | `Ads.kt` | `AdManager.swift` |
| Firebase | `Telemetry.kt` | `Telemetry.swift` |

ゲームとアプリのやり取りは iOS 版と同じメッセージ（`ready`・`screen`・`buy`・`restore`・`cloudSave` など）です。ゲーム側からは `window.AndroidApp.postMessage(JSON 文字列)`、アプリ側からは `appState(...)`・`cloudLoad(...)` を呼びます。

## 動かし方

1. Android Studio で `android/` フォルダを開く（JDK は Android Studio に入っているものでよい）
2. エミュレーターか実機を選んで ▶︎

コマンドで作るとき：

```
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

### 動作確認用（Debug ビルドのみ）
- 疑似ストア：`adb shell am start -n com.endomotoki.parking/.MainActivity --ez mockStore true`（Google Play なしで購入の流れを試せる）
- 場面を用意する：`--es js "<コード>"` を付けると、読み込みのあとにそのコードを実行
- ゲームの console のログは logcat のタグ `web` に出る
- 広告は Google のテスト用の広告ユニット（「Test Ad」と表示）

## 広告の出し方（iOS 版と同じ）
- バナー：メニューと結果画面の下だけ。運転中・初回の説明中は出さない
- 全画面広告：結果画面から次の練習に進むとき、3回に1回
- 購入すると、どちらも出なくなる

## 進み具合の保存
ステージの解放・過去最高得点・バッジ・設定は、ゲームの localStorage に加えて、アプリの SharedPreferences（`cloud.xml`）にも保存します。この `cloud.xml` だけを Android のバックアップ（Google ドライブ）と機種変更の引き継ぎに入れるので（`res/xml/backup_rules.xml`・`data_extraction_rules.xml`）、入れ直しや機種変更のあとも続きから遊べます。iPhone と Android の間では引き継げません。
購入状態は保存せず、起動のたびに Google Play から読み直します（同じ Google アカウントなら、入れ直しても「購入を復元」で戻る）。

## Firebase（Analytics・Crashlytics）
- Firebase コンソールで、iOS 版と同じプロジェクトに Android アプリ（`com.endomotoki.parking`）を追加し、`google-services.json` を `app/` に置く。**公開リポジトリには入れない**（`.gitignore` 済み）
- ないときは Firebase なしで動く。ただし Release ビルドは、ないと止まる
- Debug ビルドでは集計しない

## 公開までにやること
1. [x] **AdMob**：本番のアプリ ID・広告ユニット ID は `app/build.gradle.kts` の `admobAppId`・`admobBanner`・`admobInterstitial`。app-ads.txt は今のもの（`https://endomotoki.github.io/app-ads.txt`）をそのまま使える。公開後、AdMob でアプリを Google Play のアプリとつなぐ
2. **Firebase**：上のとおり `google-services.json` を置く
3. **アップロード鍵**：Android Studio の Build → Generate Signed Bundle で鍵（`.jks`）を作り、`android/keystore.properties` に書く（どちらもリポジトリに入れない。鍵とパスワードはなくさないように保管）
   ```
   storeFile=../upload-key.jks
   storePassword=…
   keyAlias=upload
   keyPassword=…
   ```
4. **Play Console**：アプリを作成（パッケージ名 `com.endomotoki.parking`）、Play App Signing を使う
5. **アプリ内アイテム**：「収益化」→「アプリ内アイテム」で `com.endomotoki.parking.premium`、¥360 を作る（アプリを一度アップロードしてから作れる）
6. `./gradlew bundleRelease` で作った `app/build/outputs/bundle/release/app-release.aab` を内部テストにアップロードし、実機で購入（ライセンステスターに自分のアカウントを入れるとお金はかからない）を確かめる
7. ストアの掲載情報・データセーフティ・コンテンツのレーティングを入力して、製品版として公開
