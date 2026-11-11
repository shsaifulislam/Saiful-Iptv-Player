# Flutter Wrapper Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Media & ExoPlayer Codecs
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }

# Supabase & Serialization Models
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Android TV & Leanback
-keep class androidx.leanback.** { *; }

