package sd.alumrabi.parent.ui.screens

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlin.math.abs
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import sd.alumrabi.parent.ui.components.OmrabiSymbol
import sd.alumrabi.parent.ui.theme.*

private data class Spark(val x: Float, val y: Float, val r: Float, val phase: Float)

private val sparks = listOf(
    Spark(0.14f, 0.16f, 9f, 0.0f), Spark(0.84f, 0.12f, 12f, 0.35f), Spark(0.72f, 0.30f, 7f, 0.7f),
    Spark(0.22f, 0.62f, 8f, 0.2f), Spark(0.88f, 0.66f, 10f, 0.55f), Spark(0.10f, 0.84f, 6f, 0.85f),
    Spark(0.60f, 0.86f, 9f, 0.45f)
)

private fun DrawScope.sparkle(c: Offset, r: Float, color: Color) {
    val p = Path().apply {
        moveTo(c.x, c.y - r)
        quadraticBezierTo(c.x, c.y, c.x + r, c.y)
        quadraticBezierTo(c.x, c.y, c.x, c.y + r)
        quadraticBezierTo(c.x, c.y, c.x - r, c.y)
        quadraticBezierTo(c.x, c.y, c.x, c.y - r)
        close()
    }
    drawPath(p, color)
}

/** شاشة البداية: شعار بنابض، موجات هادئة، نجوم متلألئة، نص متدرّج، وشريط تقدّم ثم خروج بتلاشٍ. */
@Composable
fun AnimatedSplashScreen(onSplashFinished: () -> Unit) {
    SystemBars(
        statusBar = Crimson900,
        darkIcons = false,
        navigationBar = Crimson900,
        navigationIconsDark = false
    )
    val logoScale = remember { Animatable(0.55f) }
    val logoAlpha = remember { Animatable(0f) }
    val titleAlpha = remember { Animatable(0f) }
    val titleShift = remember { Animatable(26f) }
    val tagAlpha = remember { Animatable(0f) }
    val progress = remember { Animatable(0f) }
    val exit = remember { Animatable(1f) }

    LaunchedEffect(Unit) {
        launch { logoAlpha.animateTo(1f, tween(500)) }
        launch { logoScale.animateTo(1f, spring(dampingRatio = 0.55f, stiffness = Spring.StiffnessLow)) }
        launch { progress.animateTo(1f, tween(2200, easing = FastOutSlowInEasing)) }
        delay(600)
        launch { titleAlpha.animateTo(1f, tween(450)) }
        launch { titleShift.animateTo(0f, tween(450, easing = FastOutSlowInEasing)) }
        delay(380)
        tagAlpha.animateTo(1f, tween(450))
        delay(1000)
        exit.animateTo(0f, tween(280))
        onSplashFinished()
    }

    val infinite = rememberInfiniteTransition(label = "splash")
    val pulse by infinite.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(2800, easing = LinearEasing)),
        label = "pulse"
    )
    val twinkle by infinite.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1900, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "twinkle"
    )

    Box(
        Modifier
            .fillMaxSize()
            .graphicsLayer {
                alpha = exit.value
                scaleX = 1f + (1f - exit.value) * 0.06f
                scaleY = 1f + (1f - exit.value) * 0.06f
            }
    ) {
        Canvas(Modifier.fillMaxSize()) {
            val center = Offset(this.size.width / 2f, this.size.height * 0.42f)
            val a = logoAlpha.value
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(Color.White.copy(alpha = 0.20f * a), Color.Transparent),
                    center = center,
                    radius = 240.dp.toPx()
                ),
                radius = 240.dp.toPx(),
                center = center
            )
            for (k in 0..2) {
                val phase = (pulse + k / 3f) % 1f
                val radius = (90f + 190f * phase).dp.toPx()
                drawCircle(
                    color = Color.White.copy(alpha = (1f - phase) * 0.20f * a),
                    radius = radius,
                    center = center,
                    style = Stroke(width = 1.5.dp.toPx())
                )
            }
            sparks.forEach { s ->
                val tw = abs(((twinkle + s.phase) % 1f) * 2f - 1f)
                sparkle(
                    Offset(this.size.width * s.x, this.size.height * s.y),
                    s.r.dp.toPx() * (0.7f + 0.5f * tw),
                    Color.White.copy(alpha = (0.15f + 0.6f * tw) * a)
                )
            }
        }

        Column(
            Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Box(
                Modifier.graphicsLayer {
                    scaleX = logoScale.value
                    scaleY = logoScale.value
                    alpha = logoAlpha.value
                },
                contentAlignment = Alignment.Center
            ) {
                Box(
                    Modifier
                        .size(152.dp)
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.08f))
                        .border(1.dp, Color.White.copy(alpha = 0.28f), CircleShape)
                )
                OmrabiSymbol(size = 92.dp, tint = OnBrand, description = "شعار العمرابي")
            }
            Spacer(Modifier.height(28.dp))
            Text(
                "العمرابي",
                style = MaterialTheme.typography.displaySmall,
                color = OnBrand,
                textAlign = TextAlign.Center,
                modifier = Modifier.graphicsLayer {
                    alpha = titleAlpha.value
                    translationY = titleShift.value
                }
            )
            Spacer(Modifier.height(6.dp))
            Text(
                "بوابة أولياء الأمور",
                style = MaterialTheme.typography.bodyLarge,
                color = OnBrand.copy(alpha = 0.85f),
                textAlign = TextAlign.Center,
                modifier = Modifier.graphicsLayer { alpha = tagAlpha.value }
            )
            Spacer(Modifier.height(10.dp))
            Text(
                "الدرجات · الحضور · الرسوم · الجدول",
                style = MaterialTheme.typography.labelMedium,
                color = OnBrand.copy(alpha = 0.6f),
                textAlign = TextAlign.Center,
                modifier = Modifier.graphicsLayer { alpha = tagAlpha.value }
            )
        }

        Box(
            Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 64.dp)
                .width(168.dp)
                .height(3.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.18f))
        ) {
            Box(
                Modifier
                    .fillMaxWidth(progress.value)
                    .fillMaxHeight()
                    .clip(CircleShape)
                    .background(OnBrand)
            )
        }
    }
}
