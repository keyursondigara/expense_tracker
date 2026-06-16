# Keep ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }

# Keep Flutter ML Kit plugin
-keep class com.google_mlkit_text_recognition.** { *; }

# Ignore missing ML Kit language classes
-dontwarn com.google.mlkit.vision.text.**