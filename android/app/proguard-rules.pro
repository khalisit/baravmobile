# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# AndroidX WorkManager & Room (Crucial: prevents "Failed to create an instance of androidx.work.impl.WorkDatabase" crash)
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.work.impl.**
-dontwarn androidx.work.**

-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.room.** { *; }
-dontwarn androidx.room.**

# AndroidX Startup (InitializationProvider)
-keep class androidx.startup.** { *; }
-dontwarn androidx.startup.**

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Sign In (Legacy & Credential Manager for google_sign_in 7.x)
-keep class com.google.android.gms.auth.api.signin.** { *; }
-dontwarn com.google.android.gms.auth.api.signin.**
-keep class androidx.credentials.** { *; }
-dontwarn androidx.credentials.**
-keep class com.google.android.libraries.identity.googleid.** { *; }
-dontwarn com.google.android.libraries.identity.googleid.**


# Desugaring
-keep class java.time.** { *; }
-dontwarn java.time.**

# Play Core (Deferred components / SplitCompat)
-dontwarn com.google.android.play.core.**

