# Kairo — release shrinking rules.
#
# Flutter's own engine classes are kept by the Flutter Gradle plugin. These
# rules cover the plugins this app uses that reflect over their own classes.

# flutter_secure_storage relies on the platform keystore APIs.
-keep class androidx.security.crypto.** { *; }

# Keep annotations used by the plugin registrant.
-keepattributes *Annotation*

# Kotlin metadata is needed for the plugin channels to resolve method names.
-keep class kotlin.Metadata { *; }
