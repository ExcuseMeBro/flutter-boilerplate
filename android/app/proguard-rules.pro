# Keep Flutter and plugin registrants.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase Messaging entry points.
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }
