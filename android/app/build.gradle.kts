// File: android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.appsbyanandakumar.billing"

    // ✅ Compile with latest Android 15 APIs
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // 🔐 Load keystore properties safely
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    defaultConfig {
        applicationId = "com.appsbyanandakumar.billing"

        // ✅ Minimum SDK that supports most modern Flutter plugins
        minSdk = 23

        // ✅ Target SDK should match or trail compileSdk slightly
        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Prevent resource merge issues
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("debug") {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    // ✅ Ensure build tools match compile SDK
    buildToolsVersion = "35.0.0"
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Use Firebase BoM to manage versions automatically
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))

    // Core Firebase SDKs
    implementation("com.google.firebase:firebase-analytics")

    // Optional additional Firebase dependencies
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
    // implementation("com.google.firebase:firebase-messaging")

    // ✅ MultiDex support for larger apps
    implementation("androidx.multidex:multidex:2.0.1")
    // ADD THIS LINE
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// ✅ Repository configuration (modern Gradle)
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Unified build directory setup
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    layout.buildDirectory.set(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}