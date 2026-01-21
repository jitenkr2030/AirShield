# ProGuard Configuration for AIRSHIELD
# Add to android/app/proguard-rules.pro

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep TensorFlow Lite classes
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.support.** { *; }

# Keep Bluetooth related classes
-keep class com.polidea.rxandroidble.** { *; }
-keep class no.nordicsemi.** { *; }

# Keep image processing classes
-keep class com.bumptech.glide.** { *; }
-keep class com.googlecode.mp4parser.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# Keep AQI calculation classes
-keep class com.airshield.models.** { *; }

# Keep notification related classes
-keep class androidx.core.app.** { *; }
-keep class android.app.Notification { *; }

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Optimize string usage
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom models and data classes
-keep class com.airshield.models.** { *; }
-keep class com.airshield.core.** { *; }
-keep class com.airshield.features.** { *; }

# Google Maps optimization
-keep class com.google.android.gms.maps.** { *; }

# Permission handling
-keep class android.permission.** { *; }

# JSON serialization
-keep class * implements java.io.Serializable { *; }
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Minimize and obfuscate
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable
-repackageclasses ''