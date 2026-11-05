package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import sd.alumrabi.parent.ui.theme.AppInk
import sd.alumrabi.parent.ui.theme.AppMuted
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.R
import sd.alumrabi.parent.ui.theme.AppCanvas
import sd.alumrabi.parent.ui.theme.AppRed

@Composable
fun BootScreen() {
    Box(Modifier.fillMaxSize().background(AppCanvas).statusBarsPadding().navigationBarsPadding(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(22.dp)) {
            Image(painterResource(R.drawable.ic_alumrabi_mark), "شعار العمرابي", Modifier.size(104.dp))
            CircularProgressIndicator(color = AppRed, strokeWidth = 2.dp, modifier = Modifier.size(23.dp))
            Text("نجهّز مساحة الأسرة", color = AppInk, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            Text("نتحقق من بيانات الحساب بأمان", color = AppMuted, fontSize = 11.sp)
        }
    }
}
