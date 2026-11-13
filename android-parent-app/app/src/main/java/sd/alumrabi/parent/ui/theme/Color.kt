package sd.alumrabi.parent.ui.theme

import androidx.compose.ui.graphics.Color

// هوية العمرابي: قرمزي عميق كلون وحيد للعلامة + محايدات دافئة (بدل الرمادي المزرق/الأبيض الصرف).
// القرمزي يُستعمل للأفعال والتحديد فقط؛ الباقي هدوء وتباين.
// الألوان التي تتغير بين الوضعين معرّفة كخصائص (getter) تقرأ ThemeState.dark فتتحدث الشاشات فور تبديل المظهر.

private fun themed(light: Long, dark: Long): Color = Color(if (ThemeState.dark) dark else light)

// ── مقياس القرمزي ──
val Crimson900 = Color(0xFF4E0A16)
val Crimson800 = Color(0xFF6B0F1F)
val Crimson600 = Color(0xFFA11A2E) // الأزرار والتحديد
val Crimson500 = Color(0xFFB8283D)
/** لون الترويسة المتدرّجة: ثابت في الوضعين (لا يتأثر بالمظهر). */
val CrimsonHeaderMid = Color(0xFF7A1022)
val Crimson700: Color get() = themed(0xFF7A1022, 0xFFE8899A) // نص قرمزي: يفتح في الوضع الداكن
val Crimson100: Color get() = themed(0xFFF6E3E6, 0xFF3D1C22)
val Crimson50: Color get() = themed(0xFFFBF1F2, 0xFF2A171B)

// ── محايدات دافئة (مائلة قليلاً نحو لون العلامة) ──
val Ink900: Color get() = themed(0xFF211C1C, 0xFFF3EDEB)   // النص الأساسي
val Ink700: Color get() = themed(0xFF4A4443, 0xFFD3CBC8)   // النص الثانوي
val Ink500: Color get() = themed(0xFF6B6462, 0xFFA69D9A)   // نص خافت
val Line: Color get() = themed(0xFFE7E1DC, 0xFF3A3231)     // فواصل وحدود رفيعة
val LineStrong: Color get() = themed(0xFFCFC7C1, 0xFF574E4C) // حدود الحقول
val Canvas: Color get() = themed(0xFFF6F3F0, 0xFF131010)   // خلفية التطبيق
val Paper: Color get() = themed(0xFFFFFFFF, 0xFF1D1919)    // أسطح المحتوى
val Wash: Color get() = themed(0xFFEFEAE6, 0xFF2A2424)     // تعبئة هادئة
val OnBrand = Color(0xFFFFFFFF)

// ── حالات (خافتة كي يبقى القرمزي اللون الوحيد البارز) ──
val Positive: Color get() = themed(0xFF1B6B45, 0xFF6FCB9A)
val PositiveBg: Color get() = themed(0xFFE5F1EA, 0xFF143021)
val Caution: Color get() = themed(0xFF8A5700, 0xFFE5B454)
val CautionBg: Color get() = themed(0xFFF9EFD8, 0xFF33270E)
val Negative: Color get() = Crimson700
val NegativeBg: Color get() = Crimson100

// ── ألوان البيانات (للرسوم والبلاطات فقط؛ القرمزي يبقى لون العلامة والأفعال) ──
val Teal: Color get() = themed(0xFF1F7A7A, 0xFF5FC4C4)
val TealBg: Color get() = themed(0xFFE2F1F1, 0xFF123232)
val Indigo: Color get() = themed(0xFF3F4C9A, 0xFF9FA9E8)
val IndigoBg: Color get() = themed(0xFFE8EAF6, 0xFF1F2340)
val Gold: Color get() = themed(0xFF9A6B00, 0xFFE3B24A)
val GoldBg: Color get() = themed(0xFFFBF1D4, 0xFF33270E)
