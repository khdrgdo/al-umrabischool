package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccountBalanceWallet
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.EventAvailable
import androidx.compose.material.icons.outlined.Grade
import androidx.compose.material.icons.outlined.MenuBook
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import sd.alumrabi.parent.ui.theme.*

@Composable
fun LearningScreen(
    onNavigateToGrades: () -> Unit,
    onNavigateToAttendance: () -> Unit,
    onNavigateToSchedule: () -> Unit,
    onNavigateToFees: () -> Unit
) {
    Column(
        Modifier.fillMaxSize().background(AppCanvas).statusBarsPadding()
            .padding(horizontal = 20.dp, vertical = 22.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text("المتابعة الدراسية", color = AppRed, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            Text("كل ما يخص دراسة أبنائك", color = AppInk, fontSize = 25.sp, fontWeight = FontWeight.ExtraBold)
            Text("اختر الخدمة التي تريد متابعتها.", color = AppMuted, fontSize = 13.sp)
        }
        LearningAction("النتائج والتقييمات", "الدرجات المنشورة والتقييمات المعتمدة", Icons.Outlined.Grade, onNavigateToGrades)
        LearningAction("الحضور والغياب", "سجل الحضور والحالات المسجلة", Icons.Outlined.EventAvailable, onNavigateToAttendance)
        LearningAction("الجدول الدراسي", "الحصص ومواعيد الدراسة", Icons.Outlined.CalendarMonth, onNavigateToSchedule)
        LearningAction("الرسوم والمدفوعات", "المستحقات والإيصالات المسجلة", Icons.Outlined.AccountBalanceWallet, onNavigateToFees)
        Spacer(Modifier.weight(1f))
        Surface(color = AppRedSoft, shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
            Row(Modifier.padding(15.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Outlined.MenuBook, contentDescription = null, tint = AppRed)
                Spacer(Modifier.width(10.dp))
                Text("تظهر هنا المعلومات التي اعتمدتها إدارة المؤسسة فقط.", color = AppInk, fontSize = 11.sp, lineHeight = 17.sp)
            }
        }
    }
}

@Composable
private fun LearningAction(title: String, description: String, icon: ImageVector, onClick: () -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        shape = RoundedCornerShape(19.dp), color = AppSurface,
        border = BorderStroke(1.dp, AppBorder)
    ) {
        Row(Modifier.padding(horizontal = 16.dp, vertical = 17.dp), verticalAlignment = Alignment.CenterVertically) {
            Surface(shape = RoundedCornerShape(13.dp), color = AppRedSoft) {
                Icon(icon, contentDescription = null, tint = AppRed, modifier = Modifier.padding(12.dp).size(22.dp))
            }
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(title, color = AppInk, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                Text(description, color = AppMuted, fontSize = 11.sp)
            }
            Text("‹", color = AppRed, fontSize = 25.sp, fontWeight = FontWeight.Bold)
        }
    }
}
