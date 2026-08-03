plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.legestic"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.example.legestic"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Neshan MapLibre SDK (platform.neshan.org/docs/sdk/android/installation)
        // Prefer mobile.* key for map tiles (nsh://). Service key stays for REST.
        val mapKey = (project.findProperty("NESHAN_MAP_KEY") as String?)
            ?: System.getenv("NESHAN_MAP_KEY")
            ?: "mobile.a4c96d24a3f9468e9a17a7b48047149f"
        val serviceKey = (project.findProperty("NESHAN_API_KEY") as String?)
            ?: System.getenv("NESHAN_API_KEY")
            ?: "service.4af4be621653464b88ebc8b15f49e78f"

        buildConfigField("String", "NESHAN_MAP_KEY", "\"$mapKey\"")
        buildConfigField("String", "NESHAN_SERVICE_KEY", "\"$serviceKey\"")
        manifestPlaceholders["NESHAN_MAP_KEY"] = mapKey
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // New Neshan Android SDK (MapLibre-based) — Maven Central
    implementation("org.neshan.maplibre:android-sdk-opengl:13.4.1")

    // Legacy services SDK for direction/search MethodChannel (REST alternative exists in Dart)
    implementation(files("libs/services-sdk-1.0.0.aar"))
    implementation(files("libs/common-sdk-0.0.3.aar"))

    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.constraintlayout:constraintlayout:2.2.0")
}
