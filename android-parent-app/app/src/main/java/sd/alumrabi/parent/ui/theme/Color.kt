package sd.alumrabi.parent.ui.theme

import androidx.compose.ui.graphics.Color

// هوية العمرابي: قرمزي عميق كلون وحيد للعلامة + محايدات دافئة (بدل الرمادي المزرق/الأبيض الصرف).
// القرمزي يُستعمل للأفعال والتحديد فقط؛ الباقي هدوء وتباين.

// ── مقياس القرمزي ──
val Crimson900 = Color(0xFF4E0A16)
val Crimson800 = Color(0xFF6B0F1F)
val Crimson700 = Color(0xFF7A1022)
val Crimson600 = Color(0xFFA11A2E) // الأزرار والتحديد
val Crimson500 = Color(0xFFB8283D)
val Crimson100 = Color(0xFFF6E3E6)
val Crimson50 = Color(0xFFFBF1F2)

// ── محايدات دافئة (مائلة قليلاً نحو لون العلامة) ──
val Ink900 = Color(0xFF211C1C)   // النص الأساسي
val Ink700 = Color(0xFF4A4443)   // النص الثانوي
val Ink500 = Color(0xFF6B6462)   // نص خافت (تباين 4.5:1 على الخلفية)
val Line = Color(0xFFE7E1DC)     // فواصل وحدود رفيعة
val LineStrong = Color(0xFFCFC7C1) // حدود الحقول
val Canvas = Color(0xFFF6F3F0)   // خلفية التطبيق
val Paper = Color(0xFFFFFFFF)    // أسطح المحتوى
val Wash = Color(0xFFEFEAE6)     // تعبئة هادئة
val OnBrand = Color(0xFFFFFFFF)

// ── حالات (خافتة كي يبقى القرمزي اللون الوحيد البارز) ──
val Positive = Color(0xFF1B6B45)
val PositiveBg = Color(0xFFE5F1EA)
val Caution = Color(0xFF8A5700)
val CautionBg = Color(0xFFF9EFD8)
val Negative = Crimson700
val NegativeBg = Crimson100
