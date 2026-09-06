# YessFish — R8-regels (Google Play "app-optimalisatie": vermomming/obfuscation ≥ 25%).
# Flutter's eigen regels (flutter_proguard_rules.pro) neemt de Flutter-Gradle-plugin automatisch mee;
# Firebase, Play Services en media3 leveren hun eigen consumer-regels. Hieronder alleen de
# bekende pijnpunten van onze plugins.
-keepattributes Signature,*Annotation*,EnclosingMethod,InnerClasses,SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Eigen app-code (MainActivity, widget-provider, notificatie-receivers) intact laten
-keep class nl.sbuilder.yessfish.** { *; }

# in_app_purchase → Google Play Billing
-keep class com.android.vending.billing.** { *; }
-keep class com.android.billingclient.** { *; }

# flutter_local_notifications gebruikt Gson-reflectie op zijn eigen modellen
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * { @com.google.gson.annotations.SerializedName <fields>; }

# home_widget (App Widget provider + callbacks)
-keep class es.antonborri.home_widget.** { *; }

# Crashlytics: bruikbare stacktraces
-keep public class * extends java.lang.Exception

# Onschuldige waarschuwingen over optionele afhankelijkheden
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
