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
import sd.alumrabi.parent.ui.theme.*

@Composable
fun AnimatedSplashScreen(onSplashFinished: () -> Unit) {
    val scale = remember { Animatable(0.84f) }
    val alpha = remember { Animatable(0f) }
    val rule = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        scale.animateTo(1f, tween(680, easing = FastOutSlowInEasing))
        alpha.animateTo(1f, tween(420))
        rule.animateTo(1f, tween(420))
        delay(620)
        onSplashFinished()
    }
    Box(Modifier.fillMaxSize().background(LavenderCanvas), contentAlignment = Alignment.Center) {
        Box(Modifier.align(Alignment.TopEnd).padding(top = 82.dp, end = 24.dp).size(190.dp).alpha(.045f).background(BurgundyPrimary, CircleShape))
        Box(Modifier.align(Alignment.BottomStart).padding(start = 18.dp, bottom = 112.dp).size(118.dp).alpha(.035f).background(BurgundyPrimary, CircleShape))
        Column(Modifier.fillMaxWidth().padding(horizontal = 30.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Surface(shape = RoundedCornerShape(34.dp), color = SurfaceWhite, shadowElevation = 12.dp, modifier = Modifier.size(164.dp).scale(scale.value)) {
                Box(contentAlignment = Alignment.Center) {
                    Image(painterResource(R.drawable.brand_mark), "شعار العمرابي", Modifier.size(142.dp).alpha(alpha.value))
                }
            }
            Spacer(Modifier.height(28.dp))
            Text("العمرابي", color = TextPrimary, fontSize = 31.sp, fontWeight = FontWeight.ExtraBold, letterSpacing = (-1).sp, modifier = Modifier.alpha(alpha.value))
            Spacer(Modifier.height(5.dp))
            Text("AL - OMRABI", color = BurgundyPrimary, fontSize = 12.sp, fontWeight = FontWeight.Bold, letterSpacing = 5.sp, modifier = Modifier.alpha(alpha.value))
            Spacer(Modifier.height(17.dp))
            Box(Modifier.width(92.dp * rule.value).height(2.dp).background(BurgundyPrimary, RoundedCornerShape(2.dp)))
            Spacer(Modifier.height(15.dp))
            Text("ريادة  ·  تفوق  ·  مستقبل أفضل", color = TextSecondary, fontSize = 13.sp, textAlign = TextAlign.Center, modifier = Modifier.alpha(alpha.value))
        }
        Text("بوابة الأسرة التعليمية", color = TextSecondary.copy(alpha = .72f), fontSize = 11.sp, modifier = Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 28.dp))
    }
}
