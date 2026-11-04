package sd.alumrabi.parent.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val LightColorScheme = lightColorScheme(
    primary = BurgundyPrimary,
    onPrimary = SurfaceWhite,
    primaryContainer = BurgundyContainer,
    onPrimaryContainer = BurgundyPrimary,
    secondary = BurgundyLight,
    onSecondary = SurfaceWhite,
    tertiary = GoldAccent,
    onTertiary = TextPrimary,
    background = LavenderCanvas,
    onBackground = TextPrimary,
    surface = SurfaceWhite,
    onSurface = TextPrimary,
    outline = BorderLight
)

@Composable
fun AlUmrabiParentTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = BurgundyDark.toArgb()
            window.navigationBarColor = LavenderCanvas.toArgb()
            val insets = WindowCompat.getInsetsController(window, view)
            insets.isAppearanceLightStatusBars = false
            insets.isAppearanceLightNavigationBars = true
        }
    }
    MaterialTheme(colorScheme = LightColorScheme, content = content)
}
