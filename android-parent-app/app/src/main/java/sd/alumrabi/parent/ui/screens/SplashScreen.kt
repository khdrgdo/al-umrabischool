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
import sd.alumrabi.parent.ui.theme.GoldAccent

@Composable
fun AnimatedSplashScreen(onSplashFinished: () -> Unit) {
    val emblemScale = remember { Animatable(0.78f) }
    val contentAlpha = remember { Animatable(0f) }
    val lineWidth = remember { Animatable(0f) }

    LaunchedEffect(Unit) {
        emblemScale.animateTo(1f, animationSpec = tween(720, easing = FastOutSlowInEasing))
        contentAlpha.animateTo(1f, animationSpec = tween(420))
        lineWidth.animateTo(1f, animationSpec = tween(500))
        delay(520)
        onSplashFinished()
    }

    Box(Modifier.fillMaxSize().background(BurgundyDark), contentAlignment = Alignment.Center) {
        Box(Modifier.align(Alignment.TopEnd).padding(top = 80.dp, end = 22.dp).size(220.dp).alpha(0.045f).background(GoldAccent, CircleShape))
        Box(Modifier.align(Alignment.BottomStart).padding(bottom = 120.dp, start = 18.dp).size(150.dp).alpha(0.035f).background(Color.White, CircleShape))

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 28.dp)
        ) {
            Surface(shape = RoundedCornerShape(34.dp), color = Color.White.copy(alpha = 0.08f), modifier = Modifier.size(156.dp).scale(emblemScale), tonalElevation = 0.dp) {
                Box(contentAlignment = Alignment.Center) {
                    Image(painterResource(R.drawable.ic_alumrabi_mark), "شعار مؤسسة العمرابي", Modifier.size(126.dp).alpha(contentAlpha.value))
                }
            }
            Spacer(Modifier.height(34.dp))
            Text("مؤسسة العمرابي التعليمية", color = Color.White, fontSize = 23.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center, modifier = Modifier.alpha(contentAlpha.value))
            Spacer(Modifier.height(9.dp))
            Text("بوابة الأسرة التعليمية", color = Color.White.copy(alpha = 0.72f), fontSize = 14.sp, fontWeight = FontWeight.Medium, modifier = Modifier.alpha(contentAlpha.value))
            Spacer(Modifier.height(20.dp))
            Box(Modifier.width(72.dp * lineWidth.value).height(3.dp).background(GoldAccent, RoundedCornerShape(3.dp)))
        }

        Text("الأبناء • التعلّم • المتابعة", color = Color.White.copy(alpha = 0.48f), fontSize = 11.sp, modifier = Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 34.dp))
    }
}
