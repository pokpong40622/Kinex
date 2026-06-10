plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kinex.app"
    compileSdk = flutter.compileSdkVersion
    // SPIKE — flutter_embed_unity: use the highest NDK any plugin needs (jni wants 28.2.13676358;
    // others want 27.0.x). NDKs are backward compatible, so the highest satisfies all; AGP
    // auto-installs it. The unityLibrary builds with its own r27c via unity.androidNdkPath
    // (android/gradle.properties), so this app-level version is independent of it.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.kinex.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // SPIKE — flutter_embed_unity: this Unity export's unityLibrary declares minSdk 25.
        minSdk = maxOf(flutter.minSdkVersion, 25)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // SPIKE — flutter_embed_unity: links the unityLibrary module that Unity
    // will export later into android/unityLibrary. Until that export exists,
    // this reference is unresolved (expected — do not run a full build yet).
    implementation(project(":unityLibrary"))
}

flutter {
    source = "../.."
}
