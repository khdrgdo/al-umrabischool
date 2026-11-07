package sd.alumrabi.parent.ui.screens

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import sd.alumrabi.parent.ui.components.OmrabiSymbol
import sd.alumrabi.parent.ui.theme.*

/** شاشة بداية هادئة: رمز المدرسة على قرمزي صاف، تلاشٍ واحد، بلا توهج أو حالة خادم مزيّفة. */
@Composable
fun AnimatedSplashScreen(onSplashFinished: () -> Unit) {
    SystemBars(
        statusBar = Crimson700,
        darkIcons = false,
        navigationBar = Crimson700,
        navigationIconsDark = false
    )
    val fade = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        fade.animateTo(1f, tween(450))
        delay(650)
        onSplashFinished()
    }
    Box(
        modifier = Modifier.fillMaxSize().background(Crimson700),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier.alpha(fade.value).padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            OmrabiSymbol(size = 96.dp, tint = OnBrand, description = "شعار العمرابي")
            Spacer(Modifier.height(24.dp))
            Text(
                "العمرابي",
                style = MaterialTheme.typography.titleLarge,
                color = OnBrand,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(4.dp))
            Text(
                "بوابة أولياء الأمور",
                style = MaterialTheme.typography.bodyMedium,
                color = OnBrand.copy(alpha = 0.8f),
                textAlign = TextAlign.Center
            )
        }
    }
}
