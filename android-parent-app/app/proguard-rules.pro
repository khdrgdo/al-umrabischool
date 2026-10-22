# Proguard rules for Al-Umrabi Parent App
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Keep data models serialized by kotlinx.serialization
-keepclassmembers class * {
    *** Companion;
}
-keepclasseswithmembers class * {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,allowobfuscation,allowshrinking class sd.alumrabi.parent.data.model.** { *; }
