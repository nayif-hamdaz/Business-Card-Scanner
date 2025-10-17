# Flutter
-dontwarn io.flutter.embedding.**
-keep class io.flutter.embedding.** { *; }

# Keep ML Kit Document Scanner classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_internal_vk.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_document_scan.** { *; }

# Prevent removing JNI bridge methods
-keep class io.flutter.plugins.** { *; }
