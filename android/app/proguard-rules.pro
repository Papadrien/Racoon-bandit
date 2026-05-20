# ── Firebase Analytics ────────────────────────────────────────────────────────
# Nécessaire uniquement si minifyEnabled = true dans le buildType release.
# À activer en même temps que minifyEnabled.

-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Google Mobile Ads ─────────────────────────────────────────────────────────
-keep class com.google.android.gms.ads.** { *; }

# ── Flutter ───────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
