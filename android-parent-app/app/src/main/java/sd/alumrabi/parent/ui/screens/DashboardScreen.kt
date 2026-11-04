package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import sd.alumrabi.parent.R
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
    val currentChild = children.getOrNull(selectedChildIndex)
    val connectionLabel = if (demoMode) {
        "وضع تجريبي • بيانات وهمية"
    } else when (connectionState) {
        BackendConnectionState.CONNECTED_LIVE -> "متصل بالخادم"
        BackendConnectionState.SYNCED_LOCAL -> "آخر بيانات محفوظة"
        BackendConnectionState.CONNECTING -> "جارٍ الاتصال"
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("مؤسسة العمرابي التعليمية", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.White)
                        Text(connectionLabel, fontSize = 10.sp, color = Color.White.copy(alpha = 0.78f))
                    }
                },
                navigationIcon = {
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = Color.White.copy(alpha = 0.08f),
                        modifier = Modifier.padding(start = 12.dp).size(38.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Image(
                                painter = painterResource(R.drawable.ic_launcher_foreground),
                                contentDescription = "شعار العمرابي",
                                modifier = Modifier.size(34.dp)
                            )
                        }
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateToSettings) {
                        Icon(Icons.Default.Settings, contentDescription = "الإعدادات", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = BurgundyPrimary)
            )
        },
        containerColor = LavenderCanvas
    ) { insets ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(insets),
            contentPadding = PaddingValues(horizontal = 18.dp, vertical = 18.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("مرحباً، ${guardian.fullName}", fontSize = 21.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                    Text("تابع شؤون أبنائك الدراسية من مكان واحد", fontSize = 12.sp, color = TextSecondary)
                }
            }

            item {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    SectionHeading("الأبناء المرتبطون بالحساب")
                    if (children.isEmpty()) {
                        Surface(shape = RoundedCornerShape(14.dp), color = SurfaceWhite, border = androidx.compose.foundation.BorderStroke(1.dp, BorderLight)) {
                            Text(
                                "لا يوجد أبناء مرتبطون بهذا الحساب حالياً. يرجى مراجعة إدارة المؤسسة لاعتماد الربط.",
                                modifier = Modifier.fillMaxWidth().padding(16.dp),
                                color = TextSecondary, fontSize = 13.sp, lineHeight = 20.sp
                            )
                        }
                    } else {
                        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            itemsIndexed(children) { index, child ->
                                val selected = index == selectedChildIndex
                                Surface(
                                    shape = RoundedCornerShape(12.dp),
                                    color = if (selected) BurgundyPrimary else SurfaceWhite,
                                    border = if (selected) null else androidx.compose.foundation.BorderStroke(1.dp, BorderLight),
                                    modifier = Modifier.clickable { onSelectChild(index) }
                                ) {
                                    Row(modifier = Modifier.padding(horizontal = 14.dp, vertical = 11.dp), verticalAlignment = Alignment.CenterVertically) {
                                        Icon(Icons.Default.Person, contentDescription = null, tint = if (selected) GoldAccent else TextSecondary, modifier = Modifier.size(17.dp))
                                        Spacer(Modifier.width(7.dp))
                                        Text(child.fullName, color = if (selected) Color.White else TextPrimary, fontSize = 12.sp, fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (currentChild != null) {
                item {
                    Surface(
                        shape = RoundedCornerShape(18.dp),
                        color = SurfaceWhite,
                        border = androidx.compose.foundation.BorderStroke(1.dp, BorderLight),
                        shadowElevation = 1.dp
                    ) {
                        Column(modifier = Modifier.fillMaxWidth().padding(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Surface(shape = RoundedCornerShape(12.dp), color = BurgundyContainer, modifier = Modifier.size(46.dp)) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Icon(Icons.Default.School, contentDescription = null, tint = BurgundyPrimary, modifier = Modifier.size(25.dp))
                                    }
                                }
                                Spacer(Modifier.width(12.dp))
                                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                    Text(currentChild.fullName, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                                    Text("${currentChild.gradeName} · ${currentChild.sectionName}", fontSize = 12.sp, color = TextSecondary)
                                }
                            }
                            HorizontalDivider(color = BorderLight)
                            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                                Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                    Text("الرقم المدرسي", fontSize = 10.sp, color = TextSecondary)
                                    Text(currentChild.studentNumber, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = BurgundyPrimary)
                                }
                                Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                    Text("صلة القرابة", fontSize = 10.sp, color = TextSecondary)
                                    Text(currentChild.relation ?: "ولي أمر", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = TextPrimary)
                                }
                            }
                            HorizontalDivider(color = BorderLight)
                            val present = currentChild.attendance.orEmpty().count { it.status == "present" }
                            val absent = currentChild.attendance.orEmpty().count { it.status == "absent" }
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                                QuickStatColumn("أيام الحضور", "$present", true)
                                QuickStatColumn("أيام الغياب", "$absent", absent == 0)
                                QuickStatColumn("المواد المرصودة", "${currentChild.grades.orEmpty().size}", true)
                            }
                        }
                    }
                }

                if (currentChild.canViewFees && currentChild.fees != null) {
                    item {
                        Surface(
                            shape = RoundedCornerShape(16.dp),
                            color = BurgundyPrimary,
                            modifier = Modifier.fillMaxWidth().clickable(onClick = onNavigateToFees)
                        ) {
                            Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                                Surface(shape = RoundedCornerShape(11.dp), color = GoldAccent.copy(alpha = 0.18f), modifier = Modifier.size(42.dp)) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Icon(Icons.Default.AccountBalanceWallet, contentDescription = null, tint = GoldAccent)
                                    }
                                }
                                Spacer(Modifier.width(12.dp))
                                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                    Text("الموقف المالي", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color.White)
                                    Text("المتبقي: ${formatAmount(currentChild.fees.remainingBalance)}", fontSize = 12.sp, color = Color.White.copy(alpha = 0.88f))
                                }
                                Text("التفاصيل ←", fontSize = 11.sp, color = GoldAccent, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }

            item {
                Column(verticalArrangement = Arrangement.spacedBy(11.dp)) {
                    SectionHeading("الخدمات")
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                        ServiceActionItem("النتائج والدرجات", "النتائج المنشورة", Icons.Default.Grade, Modifier.weight(1f), onNavigateToGrades)
                        ServiceActionItem("الحضور والغياب", "السجل اليومي", Icons.Default.CheckCircle, Modifier.weight(1f), onNavigateToAttendance)
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                        ServiceActionItem("الجدول الدراسي", "الحصص الدراسية", Icons.Default.CalendarMonth, Modifier.weight(1f), onNavigateToSchedule)
                        ServiceActionItem("الإعلانات", "التعاميم والتقويم", Icons.Default.Campaign, Modifier.weight(1f), onNavigateToAnnouncements)
                    }
                    if (currentChild?.canViewFees == true) {
                        Row(modifier = Modifier.fillMaxWidth()) {
                            ServiceActionItem("الرسوم والمدفوعات", "البيان والإيصالات", Icons.Default.AccountBalanceWallet, Modifier.fillMaxWidth(), onNavigateToFees)
                        }
                    }
                }
            }

            item {
                Text("تُعرض هنا البيانات التي اعتمدتها المؤسسة ونشرتها لحساب ولي الأمر.", fontSize = 10.sp, color = TextSecondary, lineHeight = 16.sp)
            }
        }
    }
}

@Composable
private fun SectionHeading(title: String) {
    Text(title, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
}

@Composable
fun QuickStatColumn(label: String, value: String, isPositive: Boolean) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(value, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = if (isPositive) BurgundyPrimary else StatusDanger)
        Text(label, fontSize = 10.sp, color = TextSecondary)
    }
}

@Composable
fun ServiceActionItem(
    title: String,
    subtitle: String,
    icon: ImageVector,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Surface(
        modifier = modifier.clickable(onClick = onClick),
        shape = RoundedCornerShape(14.dp),
        color = SurfaceWhite,
        border = androidx.compose.foundation.BorderStroke(1.dp, BorderLight)
    ) {
        Row(modifier = Modifier.padding(horizontal = 12.dp, vertical = 15.dp), verticalAlignment = Alignment.CenterVertically) {
            Surface(shape = RoundedCornerShape(10.dp), color = BurgundyContainer, modifier = Modifier.size(38.dp)) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(icon, contentDescription = null, tint = BurgundyPrimary, modifier = Modifier.size(20.dp))
                }
            }
            Spacer(Modifier.width(9.dp))
            Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(title, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                Text(subtitle, fontSize = 10.sp, color = TextSecondary)
            }
        }
    }
}

private fun formatAmount(value: Double): String = String.format(Locale.US, "%,.2f", value)
