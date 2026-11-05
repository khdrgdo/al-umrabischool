package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Grade
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import sd.alumrabi.parent.data.model.*
import sd.alumrabi.parent.ui.theme.*
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    guardian: GuardianInfo,
    children: List<LinkedChild>,
    selectedChildIndex: Int,
    connectionState: BackendConnectionState = BackendConnectionState.CONNECTED_LIVE,
    demoMode: Boolean = false,
    onSelectChild: (Int) -> Unit,
    onNavigateToGrades: () -> Unit,
    onNavigateToAttendance: () -> Unit,
    onNavigateToSchedule: () -> Unit,
    onNavigateToAnnouncements: () -> Unit,
    onNavigateToFees: () -> Unit,
    onNavigateToSettings: () -> Unit
) {
    val child = children.getOrNull(selectedChildIndex)
    val connectionLabel = if (demoMode) "بيانات تجريبية" else when (connectionState) {
        BackendConnectionState.CONNECTED_LIVE -> "متصل بالخادم"
        BackendConnectionState.SYNCED_LOCAL -> "آخر بيانات محفوظة"
        BackendConnectionState.CONNECTING -> "جارٍ الاتصال"
    }
    Scaffold(
        containerColor = LavenderCanvas,
        topBar = {
            TopAppBar(
                title = { Column { Text("العمرابي", color = TextPrimary, fontSize = 20.sp, fontWeight = FontWeight.ExtraBold); Text(connectionLabel, color = TextSecondary, fontSize = 11.sp) } },
                navigationIcon = { Box(Modifier.padding(start = 16.dp).size(38.dp), contentAlignment = Alignment.Center) { Text("A", color = BurgundyPrimary, fontSize = 27.sp, fontWeight = FontWeight.Black) } },
                actions = { IconButton(onClick = onNavigateToSettings) { Icon(Icons.Default.Settings, "الإعدادات", tint = TextPrimary) } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = LavenderCanvas)
            )
        },
        bottomBar = {
            NavigationBar(containerColor = SurfaceWhite, tonalElevation = 8.dp) {
                NavigationBarItem(selected = true, onClick = {}, icon = { Icon(Icons.Default.School, null) }, label = { Text("الرئيسية") })
                NavigationBarItem(selected = false, onClick = onNavigateToAttendance, icon = { Icon(Icons.Default.CheckCircle, null) }, label = { Text("الحضور") })
                NavigationBarItem(selected = false, onClick = onNavigateToGrades, icon = { Icon(Icons.Default.Grade, null) }, label = { Text("النتائج") })
                NavigationBarItem(selected = false, onClick = onNavigateToAnnouncements, icon = { Icon(Icons.Default.Campaign, null) }, label = { Text("الإعلانات") })
            }
        }
    ) { insets ->
        LazyColumn(Modifier.fillMaxSize().padding(insets), contentPadding = PaddingValues(start = 18.dp, end = 18.dp, top = 12.dp, bottom = 22.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text("مرحباً، ${guardian.fullName}", color = TextPrimary, fontSize = 23.sp, fontWeight = FontWeight.Bold)
                    Text("متابعة الأبناء وشؤونهم الدراسية من مكان واحد", color = TextSecondary, fontSize = 13.sp)
                }
            }
            item {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("الأبناء", color = TextPrimary, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.weight(1f))
                    Text("${children.size} مرتبط", color = TextSecondary, fontSize = 11.sp)
                }
                Spacer(Modifier.height(10.dp))
                if (children.isEmpty()) {
                    Surface(Modifier.fillMaxWidth(), color = SurfaceWhite, shape = RoundedCornerShape(22.dp), border = BorderStroke(1.dp, BorderLight)) {
                        Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text("لا يوجد أبناء مرتبطون بعد", color = TextPrimary, fontWeight = FontWeight.Bold, fontSize = 15.sp)
                            Text("يرجى مراجعة إدارة المؤسسة لاعتماد ربط الأبناء بحساب ولي الأمر.", color = TextSecondary, fontSize = 12.sp, lineHeight = 19.sp)
                        }
                    }
                } else {
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(9.dp)) {
                        itemsIndexed(children) { index, item ->
                            val selected = index == selectedChildIndex
                            Surface(shape = RoundedCornerShape(16.dp), color = if (selected) BurgundyPrimary else SurfaceWhite, border = if (selected) null else BorderStroke(1.dp, BorderLight), modifier = Modifier.clickable { onSelectChild(index) }) {
                                Row(Modifier.padding(horizontal = 15.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                                    Surface(shape = CircleShape, color = if (selected) Color.White.copy(alpha = .16f) else BurgundyContainer, modifier = Modifier.size(32.dp)) { Box(contentAlignment = Alignment.Center) { Icon(Icons.Default.Person, null, tint = if (selected) Color.White else BurgundyPrimary, modifier = Modifier.size(18.dp)) } }
                                    Spacer(Modifier.width(9.dp))
                                    Column { Text(item.fullName, color = if (selected) Color.White else TextPrimary, fontSize = 12.sp, fontWeight = FontWeight.Bold); Text(item.gradeName, color = if (selected) Color.White.copy(alpha = .76f) else TextSecondary, fontSize = 10.sp) }
                                }
                            }
                        }
                    }
                }
            }
            if (child != null) {
                item {
                    Surface(Modifier.fillMaxWidth(), color = TextPrimary, shape = RoundedCornerShape(26.dp)) {
                        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(15.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                                    Text("الملف الدراسي", color = Color.White.copy(alpha = .68f), fontSize = 11.sp)
                                    Text(child.fullName, color = Color.White, fontSize = 19.sp, fontWeight = FontWeight.Bold)
                                    Text("${child.gradeName}  ·  ${child.sectionName}", color = Color.White.copy(alpha = .78f), fontSize = 12.sp)
                                }
                                Surface(shape = RoundedCornerShape(18.dp), color = BurgundyPrimary, modifier = Modifier.size(56.dp)) { Box(contentAlignment = Alignment.Center) { Icon(Icons.Default.School, null, tint = Color.White, modifier = Modifier.size(28.dp)) } }
                            }
                            HorizontalDivider(color = Color.White.copy(alpha = .16f))
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Column { Text("الرقم المدرسي", color = Color.White.copy(alpha = .65f), fontSize = 10.sp); Text(child.studentNumber, color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.SemiBold) }
                                Column(horizontalAlignment = Alignment.End) { Text("صلة القرابة", color = Color.White.copy(alpha = .65f), fontSize = 10.sp); Text(child.relation ?: "ولي أمر", color = Color.White, fontSize = 13.sp) }
                            }
                            val present = child.attendance.orEmpty().count { it.status == "present" }
                            val absent = child.attendance.orEmpty().count { it.status == "absent" }
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                                Metric("حضور", present.toString(), Modifier.weight(1f)); Metric("غياب", absent.toString(), Modifier.weight(1f)); Metric("مواد", child.grades.orEmpty().size.toString(), Modifier.weight(1f))
                            }
                        }
                    }
                }
                if (child.canViewFees && child.fees != null) item {
                    Surface(Modifier.fillMaxWidth().clickable(onClick = onNavigateToFees), color = SurfaceWhite, shape = RoundedCornerShape(20.dp), border = BorderStroke(1.dp, BorderLight)) {
                        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                            Surface(shape = RoundedCornerShape(14.dp), color = BurgundyContainer, modifier = Modifier.size(46.dp)) { Box(contentAlignment = Alignment.Center) { Icon(Icons.Default.AccountBalanceWallet, null, tint = BurgundyPrimary) } }
                            Spacer(Modifier.width(12.dp)); Column(Modifier.weight(1f)) { Text("الرسوم والمدفوعات", color = TextPrimary, fontSize = 14.sp, fontWeight = FontWeight.Bold); Text("المتبقي: ${formatAmount(child.fees.remainingBalance)}", color = TextSecondary, fontSize = 12.sp) }; Text("التفاصيل", color = BurgundyPrimary, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
            item {
                Text("الخدمات", color = TextPrimary, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(10.dp))
                Column(verticalArrangement = Arrangement.spacedBy(9.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(9.dp)) { ServiceActionItem("النتائج والدرجات", "النتائج المنشورة", Icons.Default.Grade, Modifier.weight(1f), onNavigateToGrades); ServiceActionItem("الحضور والغياب", "السجل اليومي", Icons.Default.CheckCircle, Modifier.weight(1f), onNavigateToAttendance) }
                    Row(horizontalArrangement = Arrangement.spacedBy(9.dp)) { ServiceActionItem("الجدول الدراسي", "الحصص المعتمدة", Icons.Default.CalendarMonth, Modifier.weight(1f), onNavigateToSchedule); ServiceActionItem("الإعلانات", "التعاميم والتقويم", Icons.Default.Campaign, Modifier.weight(1f), onNavigateToAnnouncements) }
                    if (child?.canViewFees == true) ServiceActionItem("الرسوم والمدفوعات", "البيان والإيصالات", Icons.Default.AccountBalanceWallet, Modifier.fillMaxWidth(), onNavigateToFees)
                }
            }
            item { Text("تُعرض المعلومات التي اعتمدتها المؤسسة ونشرتها لحساب ولي الأمر فقط.", color = TextSecondary, fontSize = 11.sp, lineHeight = 18.sp) }
        }
    }
}

@Composable
private fun Metric(label: String, value: String, modifier: Modifier = Modifier) {
    Surface(modifier.heightIn(min = 62.dp), shape = RoundedCornerShape(15.dp), color = Color.White.copy(alpha = .09f)) {
        Column(Modifier.fillMaxWidth().padding(vertical = 9.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) { Text(value, color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold); Text(label, color = Color.White.copy(alpha = .7f), fontSize = 10.sp) }
    }
}

@Composable
fun ServiceActionItem(title: String, subtitle: String, icon: ImageVector, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Surface(modifier = modifier.heightIn(min = 78.dp).clickable(onClick = onClick), shape = RoundedCornerShape(18.dp), color = SurfaceWhite, border = BorderStroke(1.dp, BorderLight)) {
        Row(Modifier.padding(horizontal = 11.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
            Surface(shape = RoundedCornerShape(12.dp), color = BurgundyContainer, modifier = Modifier.size(40.dp)) { Box(contentAlignment = Alignment.Center) { Icon(icon, null, tint = BurgundyPrimary, modifier = Modifier.size(20.dp)) } }
            Spacer(Modifier.width(9.dp)); Column(verticalArrangement = Arrangement.spacedBy(3.dp)) { Text(title, color = TextPrimary, fontSize = 11.sp, fontWeight = FontWeight.Bold); Text(subtitle, color = TextSecondary, fontSize = 9.sp) }
        }
    }
}

private fun formatAmount(value: Double): String = String.format(Locale.US, "%,.2f", value)
