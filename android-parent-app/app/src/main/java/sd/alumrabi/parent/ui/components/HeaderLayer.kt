package sd.alumrabi.parent.ui.components

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.ui.theme.Crimson600
import sd.alumrabi.parent.ui.theme.CrimsonHeaderMid
import sd.alumrabi.parent.ui.theme.Crimson800

/** ارتفاع محتوى الترويسة تحت شريط الحالة في كل شاشة. */
object HeaderMetrics {
    val Login: Dp = 260.dp
    val Home: Dp = 210.dp
}

/**
 * ترويسة حمراء واحدة دائمة خلف كل الشاشات: تملأ الشاشة في البداية، ثم تنكمش إلى ترويسة الدخول،
 * ثم إلى ترويسة الرئيسية، وتختفي في بقية الشاشات؛ فيبدو الانتقال بينها إطاراً واحداً.
 */
@Composable
fun BrandHeaderLayer(route: String?, modifier: Modifier = Modifier) {
    val density = LocalDensity.current
    val statusTop = with(density) { WindowInsets.statusBars.getTop(density).toDp() }
    BoxWithConstraints(modifier.fillMaxSize()) {
        val splash = route == null || route == Routes.Splash
        val target: Dp = when {
            splash -> maxHeight
            route == Routes.Login -> statusTop + HeaderMetrics.Login
            route == Routes.Home -> statusTop + HeaderMetrics.Home
            else -> 0.dp
        }
        val height by animateDpAsState(target, tween(650, easing = FastOutSlowInEasing), label = "headerHeight")
        val corner by animateDpAsState(if (splash) 0.dp else 32.dp, tween(650, easing = FastOutSlowInEasing), label = "headerCorner")
        Box(
            Modifier
                .fillMaxWidth()
                .height(height)
                .background(
                    Brush.verticalGradient(listOf(Crimson800, CrimsonHeaderMid, Crimson600)),
                    RoundedCornerShape(bottomStart = corner, bottomEnd = corner)
                )
        )
    }
}
