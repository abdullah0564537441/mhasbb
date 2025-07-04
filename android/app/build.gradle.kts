// التعديل هنا: استخدام بناء جملة 'plugins {}' بدلاً من 'Plugins {}'
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // يجب أن يكون هذا آخر واحد لـ Flutter
}

android {
    namespace = "com.example.mhasbb"
    compileSdk = flutter.compileSdkVersion
    
    // تم تعيين ndkVersion إلى الإصدار المطلوب
    ndkVersion = "27.0.12077973" 

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString() // يجب أن يكون "11" كسلسلة نصية
    }

    defaultConfig {
        applicationId = "com.example.mhasbb"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
