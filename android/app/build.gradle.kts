plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.kairo.workspace"

    // Pinned rather than tracking `flutter.compileSdkVersion`.
    // The current Flutter channel points at API 37, which is still a preview:
    // the SDK manager installs it as `platforms/android-37.0`, while Gradle
    // resolves the target by the hash string `android-37` and cannot find it.
    // API 36 is the newest stable platform and satisfies every plugin here.
    // Raise this once 37 ships as stable.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "app.kairo.workspace"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Release builds are signed with the debug keystore so that
            // `flutter build apk --release` works from a clean checkout.
            // A real deployment replaces this with a keystore supplied through
            // `key.properties` (never committed).
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
