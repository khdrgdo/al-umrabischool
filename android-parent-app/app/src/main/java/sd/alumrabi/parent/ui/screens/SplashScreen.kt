package sd.alumrabi.parent.ui.screens

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import sd.alumrabi.parent.R
import sd.alumrabi.parent.ui.theme.BurgundyDark
import sd.alumrabi.parent.ui.theme.BurgundyPrimary
import sd.alumrabi.parent.ui.theme.GoldAccent

@Composable
fun AnimatedSplashScreen(
    onSplashFinished: () -> Unit
) {
    val emblemScale = remember { Animatable(0.88f) }
    val contentAlpha = remember { Animatable(0f) }

    LaunchedEffect(Unit) {
        emblemScale.animateTo(
            targetValue = 1f,
            animationSpec = tween(650, easing = FastOutSlowInEasing)
        )
        contentAlpha.animateTo(
            targetValue = 1f,
            animationSpec = tween(420)
        )
        delay(850)
        onSplashFinished()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BurgundyDark),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .size(300.dp)
                .alpha(0.05f)
                .background(GoldAccent, CircleShape)
        )

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 30.dp)
        ) {
            Surface(
                shape = RoundedCornerShape(30.dp),
                color = Color.White.copy(alpha = 0.08f),
                modifier = Modifier
                    .size(144.dp)
                    .scale(emblemScale.value),
                tonalElevation = 0.dp
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Image(
                        painter = painterResource(R.drawable.ic_alumrabi_mark),
                        contentDescription = "شعار العمرابي",
                        modifier = Modifier
                            .size(116.dp)
                            .alpha(contentAlpha.value)
                    )
                }
            }

            Spacer(Modifier.height(30.dp))

            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.alpha(contentAlpha.value)
            ) {
                Text(
                    text = "مؤسسة العمرابي التعليمية",
                    color = Color.White,
                    fontSize = 23.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center
                )
                Spacer(Modifier.height(8.dp))
                Box(
                    modifier = Modifier
                        .width(52.dp)
                        .height(2.dp)
                        .background(GoldAccent, RoundedCornerShape(2.dp))
                )
                Spacer(Modifier.height(12.dp))
                Text(
                    text = "تطبيق أولياء الأمور",
                    color = Color(0xFFE9DCC8),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }

        Text(
            text = "متابعة الأبناء • النتائج • الحضور • الإعلانات",
            color = Color.White.copy(alpha = 0.55f),
            fontSize = 10.sp,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
                .padding(bottom = 34.dp)
        )
    }
}
