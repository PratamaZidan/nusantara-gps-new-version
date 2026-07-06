# SharedPreferences - dipakai di background isolate
-keep class androidx.preference.** { *; }
-keep class android.content.SharedPreferences { *; }

# Dio / OkHttp - HTTP client di background isolate
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Gson / JSON parsing (_parseResponse)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.gson.**

# Dart VM entry points - KRITIS agar onStartBackground tidak di-strip
-keep @interface dart.annotation.DartName
-keep class * {
    @pragma <methods>;
}

# Hive - box operations di background isolate  
-keep class hive.** { *; }
-keep class * extends hive.HiveObject { *; }

# flutter_local_notifications tambahan
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }