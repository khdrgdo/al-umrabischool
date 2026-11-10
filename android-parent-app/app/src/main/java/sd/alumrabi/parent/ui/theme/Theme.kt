package sd.alumrabi.parent.ui.theme

import android.app.Activity
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.view.WindowCompat
import sd.alumrabi.parent.R

/** IBM Plex Sans Arabic (OFL) — مدمج في التطبيق، يعمل دون إنترنت. */
val PlexArabic = FontFamily(
    Font(R.font.plex_arabic_regular, FontWeight.Normal),
    Font(R.font.plex_arabic_medium, FontWeight.Medium),
    Font(R.font.plex_arabic_semibold, FontWeight.SemiBold),
    Font(R.font.plex_arabic_bold, FontWeight.Bold)
)

// ارتفاع السطر ~1.6× لأن الحروف العربية والتشكيل تحتاج مساحة رأسية؛ ولا حجم نص أقل من 12sp.
private fun style(size: Int, line: Int, weight: FontWeight) =
    TextStyle(fontFamily = PlexArabic, fontSize = size.sp, lineHeight = line.sp, fontWeight = weight)

val OmrabiTypography = Typography(
    displaySmall = style(28, 38, FontWeight.Bold),
    headlineMedium = style(24, 34, FontWeight.Bold),
    headlineSmall = style(20, 30, FontWeight.Bold),
    titleLarge = style(18, 28, FontWeight.Bold),
    titleMedium = style(16, 26, FontWeight.SemiBold),
    titleSmall = style(14, 22, FontWeight.SemiBold),
    bodyLarge = style(16, 26, FontWeight.Normal),
    bodyMedium = style(14, 23, FontWeight.Normal),
    bodySmall = style(12, 19, FontWeight.Normal),
    labelLarge = style(14, 20, FontWeight.Medium),
    labelMedium = style(12, 18, FontWeight.Medium),
    labelSmall = style(12, 16, FontWeight.Medium)
)

/** أرقام متساوية العرض لتصطف الأعمدة (درجات، مبالغ). */
fun TextStyle.tabular(): TextStyle = copy(fontFeatureSettings = "tnum")

/** شبكة مسافات 4dp. */
object Space {
    val xxs = 2.dp
    val xs = 4.dp
    val sm = 8.dp
    val md = 12.dp
    val lg = 16.dp
    val xl = 20.dp
    val xxl = 28.dp
    val gutter = 16.dp
}

/** زوايا هادئة: بلا مبالغة في الاستدارة. */
object Radius {
    val chip = RoundedCornerShape(6.dp)
    val field = RoundedCornerShape(8.dp)
    val card = RoundedCornerShape(12.dp)
}

private fun omrabiColors(dark: Boolean): ColorScheme = if (dark) {
    darkColorScheme(
        primary = Crimson600,
        onPrimary = OnBrand,
        primaryContainer = Crimson100,
        onPrimaryContainer = Crimson700,
        secondary = Ink900,
        onSecondary = Canvas,
        secondaryContainer = Wash,
        onSecondaryContainer = Ink900,
        tertiary = Crimson700,
        background = Canvas,
        onBackground = Ink900,
        surface = Paper,
        onSurface = Ink900,
        surfaceVariant = Wash,
        onSurfaceVariant = Ink700,
        surfaceTint = Paper,
        outline = LineStrong,
        outlineVariant = Line,
        error = Negative,
        onError = Canvas,
        surfaceContainerLowest = Paper,
        surfaceContainerLow = Paper,
        surfaceContainer = Paper,
        surfaceContainerHigh = Paper,
        surfaceContainerHighest = Wash
    )
} else {
    lightColorScheme(
        primary = Crimson600,
        onPrimary = OnBrand,
        primaryContainer = Crimson100,
        onPrimaryContainer = Crimson800,
        secondary = Ink900,
        onSecondary = OnBrand,
        secondaryContainer = Wash,
        onSecondaryContainer = Ink900,
        tertiary = Crimson700,
        background = Canvas,
        onBackground = Ink900,
        surface = Paper,
        onSurface = Ink900,
        surfaceVariant = Wash,
        onSurfaceVariant = Ink700,
        surfaceTint = Paper,
        outline = LineStrong,
        outlineVariant = Line,
        error = Negative,
        onError = OnBrand,
        surfaceContainerLowest = Paper,
        surfaceContainerLow = Paper,
        surfaceContainer = Paper,
        surfaceContainerHigh = Paper,
        surfaceContainerHighest = Wash
    )
}

/** ألوان شريط الحالة وشريط التنقل لكل شاشة (الشاشات الداكنة تحتاج أيقونات فاتحة). */
@Composable
fun SystemBars(
    statusBar: Color,
    darkIcons: Boolean,
    navigationBar: Color = Paper,
    navigationIconsDark: Boolean = true
) {
    val view = LocalView.current
    val statusDarkIcons = darkIcons && !ThemeState.dark
    val navDarkIcons = navigationIconsDark && !ThemeState.dark
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            // الشريطان شفافان دائماً (حافة لحافة)؛ لون الخلفية تصنعه الشاشة نفسها خلفهما.
            window.statusBarColor = android.graphics.Color.TRANSPARENT
            window.navigationBarColor = android.graphics.Color.TRANSPARENT
            if (android.os.Build.VERSION.SDK_INT >= 29) window.isNavigationBarContrastEnforced = false
            val controller = WindowCompat.getInsetsController(window, view)
            controller.isAppearanceLightStatusBars = statusDarkIcons
            controller.isAppearanceLightNavigationBars = navDarkIcons
        }
    }
}

@Composable
fun AlUmrabiParentTheme(content: @Composable () -> Unit) {
    val dark = when (ThemeState.mode) {
        ThemeMode.Dark -> true
        ThemeMode.Light -> false
        ThemeMode.System -> isSystemInDarkTheme()
    }
    // تُكتب قبل رسم الأبناء لتقرأها ألوان Color.kt في نفس الإطار.
    ThemeState.dark = dark
    MaterialTheme(
        colorScheme = omrabiColors(dark),
        typography = OmrabiTypography,
        shapes = Shapes(
            small = Radius.chip,
            medium = Radius.field,
            large = Radius.card
        ),
        content = content
    )
}
