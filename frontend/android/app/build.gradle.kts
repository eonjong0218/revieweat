plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.revieweat"
    compileSdk = 35  // 최신 compileSdk 적용

    ndkVersion = "27.0.12077973"  // 필요시 유지

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  // 최신 Java 17로 업그레이드
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"  // Kotlin JVM 타겟도 17로 맞춤
    }

    defaultConfig {
        applicationId = "com.example.revieweat"
        minSdk = 23  // 최소 SDK 23 이상 권장
        targetSdk = 34  // 최신 Target SDK 적용
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")  // TODO: 릴리즈 키로 변경
        }
    }
}

flutter {
    source = "../.."
}
