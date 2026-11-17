import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

// Firebase の設定（google-services.json）があるときだけ Firebase を有効にする。公開リポジトリには入れない
val hasFirebase = file("google-services.json").exists()
if (hasFirebase) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

// AdMob の本番 ID（Android アプリ）。Debug ビルドは Google のテスト用 ID を使う
val admobAppId = "ca-app-pub-3350766982337275~4315249481"
val admobBanner = "ca-app-pub-3350766982337275/7056303752"
val admobInterstitial = "ca-app-pub-3350766982337275/2294931660"

// アップロード鍵（Play Console に出すための署名）。keystore.properties と鍵ファイルはリポジトリに入れない
val keystoreProps = Properties().apply {
    val f = rootProject.file("keystore.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    namespace = "com.endomotoki.parking"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.endomotoki.parking"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    signingConfigs {
        if (keystoreProps.containsKey("storeFile")) {
            create("upload") {
                storeFile = rootProject.file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
            buildConfigField("String", "AD_BANNER", "\"ca-app-pub-3940256099942544/9214589741\"")
            buildConfigField("String", "AD_INTERSTITIAL", "\"ca-app-pub-3940256099942544/1033173712\"")
        }
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            manifestPlaceholders["admobAppId"] = admobAppId
            buildConfigField("String", "AD_BANNER", "\"$admobBanner\"")
            buildConfigField("String", "AD_INTERSTITIAL", "\"$admobInterstitial\"")
            signingConfigs.findByName("upload")?.let { signingConfig = it }
        }
    }

    buildFeatures { buildConfig = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    // ゲーム本体はリポジトリ直下の index.html をビルドのたびにコピーして入れる（下の copyGame）
    sourceSets["main"].assets.srcDir(layout.buildDirectory.dir("generated/game"))
}

// ウェブ版のゲームをアプリに入れる。three.js は CDN ではなく同梱のもの（iOS 版と同じファイル）を使う
val copyGame by tasks.registering(Copy::class) {
    val out = layout.buildDirectory.dir("generated/game")
    from(rootProject.file("../index.html")) {
        filter { it.replace("https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js", "three.min.js") }
    }
    from(rootProject.file("../ios/ParkingGame/three.min.js"))
    into(out)
}
tasks.named("preBuild") { dependsOn(copyGame) }

// 本番に出すビルド（Release）で、AdMob の本番 ID や Firebase の設定が抜けていたら止める
gradle.taskGraph.whenReady {
    if (allTasks.any { it.name.contains("Release") && (it.name.startsWith("assemble") || it.name.startsWith("bundle")) }) {
        check(!admobAppId.contains("TODO")) { "app/build.gradle.kts の AdMob の本番 ID（admobAppId など）を設定してください" }
        check(hasFirebase) { "app/google-services.json（Firebase の設定）を置いてください" }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.activity:activity-ktx:1.9.3")
    implementation("androidx.webkit:webkit:1.12.1")
    implementation("com.android.billingclient:billing:7.1.1")
    implementation("com.google.android.gms:play-services-ads:23.6.0")
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-crashlytics")
}
