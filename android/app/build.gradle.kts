import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadKeystoreProperties(): Properties? {
    val keyPropsFile = rootProject.file("key.properties")
    if (!keyPropsFile.exists()) return null
    val props = Properties()
    keyPropsFile.inputStream().use { props.load(it) }
    return props
}

android {
    namespace = "com.codevnexus.appgastos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.codevnexus.appgastos"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            val props = loadKeystoreProperties()
            if (props != null) {
                storeFile = file(props.getProperty("storeFile"))
                storePassword = props.getProperty("storePassword")
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation("com.google.android.play:core:1.10.3")
}

flutter {
    source = "../.."
}
