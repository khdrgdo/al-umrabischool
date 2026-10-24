package sd.alumrabi.parent.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import sd.alumrabi.parent.ui.theme.*

@Composable
fun AnimatedSplashScreen(
    onSplashFinished: () -> Unit
) {
    val scaleAnim = remember { Animatable(0.6f) }
    val alphaAnim = remember { Animatable(0f) }
    val textAlphaAnim = remember { Animatable(0f) }
    val pulseScale = rememberInfiniteTransition(label = "pulse")
    val pulseGlow by pulseScale.animateFloat(
        initialValue = 0.95f,
        targetValue = 1.05f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "glow"
    )

    LaunchedEffect(Unit) {
        // Animate emblem scale & fade
        scaleAnim.animateTo(
            targetValue = 1f,
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            )
        )
        alphaAnim.animateTo(1f, animationSpec = tween(500))

        // Animate text fade-in
        textAlphaAnim.animateTo(1f, animationSpec = tween(600))

        // Hold splash screen for branding duration
        delay(1200)

        // Exit transition
        onSplashFinished()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        BurgundyPrimary,
                        Color(0xFF380808),
                        Color(0xFF1F0404)
                    )
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        // Ambient background glow
        Box(
            modifier = Modifier
                .size(240.dp)
                .scale(pulseGlow)
                .alpha(0.18f)
                .background(Color(0xFFD4AF37), CircleShape)
        )

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(32.dp)
        ) {
            // Animated Shield / Emblem
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .scale(scaleAnim.value)
                    .alpha(alphaAnim.value)
            ) {
                // Outer Gold Ring
                Surface(
                    shape = RoundedCornerShape(26.dp),
                    color = Color(0xFFD4AF37),
                    modifier = Modifier.size(104.dp),
                    shadowElevation = 10.dp
                ) {
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(3.dp)
                    ) {
                        // Inner Burgundy Face
                        Surface(
                            shape = RoundedCornerShape(23.dp),
                            color = BurgundyPrimary,
                            modifier = Modifier.fillMaxSize()
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(
                                    text = "ع",
                                    color = Color.White,
                                    fontSize = 52.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(28.dp))

            // School Title & Subtitle with Staggered Fade
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.alpha(textAlphaAnim.value)
            ) {
                Text(
                    text = "مدرسة العمرابي الثانوية",
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    letterSpacing = 0.5.sp,
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(6.dp))

                Text(
                    text = "بوابة أولياء الأمور والمتابعة الأكاديمية",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    color = Color(0xFFF3E5AB),
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(3.dp))

                Text(
                    text = "نظام الإدارة المدرسية المعتمد",
                    fontSize = 11.sp,
                    color = Color.White.copy(alpha = 0.7f),
                    textAlign = TextAlign.Center
                )
            }
        }

        // Bottom Institutional Versioning Footer
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 32.dp)
                .alpha(textAlphaAnim.value)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                Box(
                    modifier = Modifier
                        .size(6.dp)
                        .background(Color(0xFF10B981), CircleShape)
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = "الخادم متصل وجاهز للعمل",
                    fontSize = 10.sp,
                    color = Color.White.copy(alpha = 0.8f)
                )
            }

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = "الإصدار 1.0.0 · Build 2026.10",
                fontSize = 10.sp,
                color = Color.White.copy(alpha = 0.45f)
            )
        }
    }
}
