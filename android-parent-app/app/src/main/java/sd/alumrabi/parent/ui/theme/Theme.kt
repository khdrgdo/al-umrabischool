package sd.alumrabi.parent.ui.theme

import android.app.Activity
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
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

private fun style(size: Int, line: Int, weight: FontWeight) =
    TextStyle(fontFamily = PlexArabic, fontSize = size.sp, lineHeight = line.sp, fontWeight = weight)

val OmrabiTypography = Typography(
    displaySmall = style(30, 38, FontWeight.Bold),
    headlineMedium = style(24, 32, FontWeight.Bold),
    headlineSmall = style(20, 28, FontWeight.Bold),
    titleLarge = style(18, 26, FontWeight.Bold),
    titleMedium = style(16, 24, FontWeight.SemiBold),
    titleSmall = style(14, 20, FontWeight.SemiBold),
    bodyLarge = style(16, 26, FontWeight.Normal),
    bodyMedium = style(14, 22, FontWeight.Normal),
    bodySmall = style(12, 18, FontWeight.Normal),
    labelLarge = style(14, 20, FontWeight.SemiBold),
    labelMedium = style(12, 16, FontWeight.Medium),
    labelSmall = style(11, 14, FontWeight.Medium)
)

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

/** زوايا: حادة نسبياً لهوية مؤسسية، دون مبالغة في الاستدارة. */
object Radius {
    val chip = RoundedCornerShape(6.dp)
    val field = RoundedCornerShape(8.dp)
    val card = RoundedCornerShape(12.dp)
    val sheet = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
}

/** ارتفاعات الظل: بطاقات بحدود رفيعة بدل الظلال الثقيلة. */
object Elevation {
    val flat = 0.dp
    val raised = 1.dp
    val floating = 6.dp
}

private val OmrabiColors = lightColorScheme(
    primary = Crimson600,
    onPrimary = OnBrand,
    primaryContainer = Crimson100,
    onPrimaryContainer = Crimson800,
    secondary = Charcoal800,
    onSecondary = White,
    secondaryContainer = Gray200,
    onSecondaryContainer = Charcoal800,
    tertiary = Crimson700,
    background = Canvas,
    onBackground = InkPrimary,
    surface = CardSurface,
    onSurface = InkPrimary,
    surfaceVariant = Gray100,
    onSurfaceVariant = InkSecondary,
    outline = Gray300,
    outlineVariant = Hairline,
    error = Crimson700,
    onError = White
)

@Composable
fun AlUmrabiParentTheme(content: @Composable () -> Unit) {
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = Crimson700.toArgb()
            window.navigationBarColor = White.toArgb()
            val controller = WindowCompat.getInsetsController(window, view)
            controller.isAppearanceLightStatusBars = false
            controller.isAppearanceLightNavigationBars = true
        }
    }
    MaterialTheme(
        colorScheme = OmrabiColors,
        typography = OmrabiTypography,
        shapes = Shapes(
            small = Radius.chip,
            medium = Radius.field,
            large = Radius.card
        ),
        content = content
    )
}
