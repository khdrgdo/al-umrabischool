package sd.alumrabi.parent.ui.theme

import android.app.Activity
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val AlOmrabiColors = lightColorScheme(
    primary = AppRed,
    onPrimary = AppSurface,
    primaryContainer = AppRedSoft,
    onPrimaryContainer = AppRedDark,
    secondary = AppInk,
    onSecondary = AppSurface,
    tertiary = AppSuccess,
    onTertiary = AppSurface,
    background = AppCanvas,
    onBackground = AppInk,
    surface = AppSurface,
    onSurface = AppInk,
    surfaceVariant = ColorTokens.surfaceVariant,
    onSurfaceVariant = AppMuted,
    outline = AppBorder,
    error = AppDanger,
    onError = AppSurface
)

private object ColorTokens { val surfaceVariant = androidx.compose.ui.graphics.Color(0xFFF0EFEC) }

@Composable
fun AlUmrabiParentTheme(content: @Composable () -> Unit) {
    val view = LocalView.current
    if (!view.isInEditMode) SideEffect {
        val window = (view.context as Activity).window
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.TRANSPARENT
        val controller = WindowCompat.getInsetsController(window, view)
        controller.isAppearanceLightStatusBars = true
        controller.isAppearanceLightNavigationBars = true
    }
    MaterialTheme(colorScheme = AlOmrabiColors, typography = Typography(), content = content)
}
