package sd.alumrabi.parent.ui.theme

import androidx.compose.ui.graphics.Color

// ── هوية العمرابي: أحمر قرمزي عميق + فحمي + رمادي فاتح + أبيض ──
// Crimson scale
val Crimson900 = Color(0xFF4E0A16)
val Crimson800 = Color(0xFF6B0F1F)
val Crimson700 = Color(0xFF7A1022) // deep, headers / pressed
val Crimson600 = Color(0xFFA11A2E) // brand symbol & primary actions
val Crimson500 = Color(0xFFB8283D)
val Crimson100 = Color(0xFFF7E4E7)
val Crimson50 = Color(0xFFFCF3F4)

// Charcoal / neutral scale
val Charcoal900 = Color(0xFF16181C)
val Charcoal800 = Color(0xFF23262B) // primary text
val Charcoal600 = Color(0xFF4A4F57) // secondary text
val Charcoal400 = Color(0xFF7D828A) // hints / disabled text
val Gray300 = Color(0xFFD5D7DB)    // strong borders
val Gray200 = Color(0xFFE6E7EA)    // dividers & card borders
val Gray100 = Color(0xFFF3F3F4)    // app canvas
val White = Color(0xFFFFFFFF)

// Semantic roles
val Canvas = Gray100
val CardSurface = White
val InkPrimary = Charcoal800
val InkSecondary = Charcoal600
val InkMuted = Charcoal400
val Hairline = Gray200
val OnBrand = White

// Status (kept muted so the crimson stays the single brand accent)
val Positive = Color(0xFF1F7A4D)
val PositiveBg = Color(0xFFE8F4EE)
val Caution = Color(0xFF9A6200)
val CautionBg = Color(0xFFFBF1DE)
val Negative = Crimson700          // absence / failure use the brand red family
val NegativeBg = Crimson100
val Neutral = Charcoal600
val NeutralBg = Gray100

// ── أسماء قديمة محفوظة كأسماء مستعارة للهوية الجديدة فقط (لا ألوان خضراء/ذهبية/لافندر) ──
val BurgundyPrimary = Crimson600
val BurgundyDark = Crimson700
val BurgundyLight = Crimson500
val BurgundyContainer = Crimson50
val LavenderCanvas = Canvas
val SurfaceWhite = CardSurface
val TextPrimary = InkPrimary
val TextSecondary = InkSecondary
val BorderLight = Hairline
val StatusSuccess = Positive
val StatusSuccessBg = PositiveBg
val StatusWarning = Caution
val StatusWarningBg = CautionBg
val StatusDanger = Negative
val StatusDangerBg = NegativeBg
