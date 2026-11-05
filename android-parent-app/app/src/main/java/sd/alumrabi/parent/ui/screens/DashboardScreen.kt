package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.Image
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
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import sd.alumrabi.parent.R
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
    val connectionLabel = if (demoMode) "بيانات تجريبية" else when (connectionState) {
        BackendConnectionState.CONNECTED_LIVE -> "متصل بالخادم"
        BackendConnectionState.SYNCED_LOCAL -> "آخر بيانات محفوظة"
        BackendConnectionState.CONNECTING -> "جارٍ الاتصال"
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
                        Text("العمرابي", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = BurgundyPrimary)
                        Text(connectionLabel, fontSize = 11.sp, color = TextSecondary)
                    }
                },
                navigationIcon = {
                    Surface(shape = RoundedCornerShape(14.dp), color = BurgundyContainer, modifier = Modifier.padding(start = 14.dp).size(44.dp)) {
                        Box(contentAlignment = Alignment.Center) {
                            Image(painterResource(R.drawable.ic_alumrabi_mark), "شعار العمرابي", Modifier.size(38.dp))
                        }
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateToSettings, modifier = Modifier.size(48.dp)) {
                        Icon(Icons.Default.Settings, "الإعدادات", tint = BurgundyPrimary)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = LavenderCanvas)
            )
        },
        containerColor = LavenderCanvas
    ) { insets ->
        LazyColumn(
            Modifier.fillMaxSize().padding(insets),
            contentPadding = PaddingValues(horizontal = 18.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text("مرحباً، " + guardian.fullName, fontSize = 22.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                    Text("هذه مساحتك لمتابعة الأبناء وشؤونهم الدراسية.", fontSize = 13.sp, color = TextSecondary)
                }
            }

            item {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        SectionHeading("الأبناء")
                        Spacer(Modifier.weight(1f))
                        Text(children.size.toString() + " مرتبط", fontSize = 11.sp, color = TextSecondary)
                    }
                    if (children.isEmpty()) {
                        Surface(shape = RoundedCornerShape(20.dp), color = SurfaceWhite, border = androidx.compose.foundation.BorderStroke(1.dp, BorderLight)) {
                            Column(Modifier.fillMaxWidth().padding(18.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                Text("لا يوجد أبناء مرتبطون بعد", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                                Text("يرجى مراجعة إدارة المؤسسة لاعتماد ربط الأبناء بحساب ولي الأمر.", fontSize = 12.sp, lineHeight = 19.sp, color = TextSecondary)
                            }
                        }
                    } else {
                        LazyRow(horizontalArrangement = Arrangement.spacedBy(9.dp)) {
                            itemsIndexed(children) { index, child ->
                                val selected = index == selectedChildIndex
                                Surface(
                                    shape = RoundedCornerShape(18.dp),
                                    color = if (selected) BurgundyPrimary else SurfaceWhite,
                                    border = if (selected) null else androidx.compose.foundation.BorderStroke(1.dp, BorderLight),
                                    modifier = Modifier.clickable { onSelectChild(index) }
                                ) {
                                    Row(Modifier.padding(horizontal = 16.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
                                        Surface(shape = CircleShape, color = if (selected) Color.White.copy(alpha = 0.14f) else BurgundyContainer, modifier = Modifier.size(30.dp)) {
                                            Box(contentAlignment = Alignment.Center) {
                                                Icon(Icons.Default.Person, null, tint = if (selected) GoldAccent else BurgundyPrimary, modifier = Modifier.size(17.dp))
                                            }
                                        }
                                        Spacer(Modifier.width(9.dp))
                                        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                            Text(child.fullName, color = if (selected) Color.White else TextPrimary, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                            Text(child.gradeName, color = if (selected) Color.White.copy(alpha = 0.72f) else TextSecondary, fontSize = 10.sp)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (currentChild != null) {
                item {
                    Surface(shape = RoundedCornerShape(26.dp), color = BurgundyPrimary, modifier = Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                                    Text("الملف الدراسي", color = Color.White.copy(alpha = 0.72f), fontSize = 11.sp)
                                    Text(currentChild.fullName, color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                                    Text(currentChild.gradeName + " · " + currentChild.sectionName, color = Color.White.copy(alpha = 0.78f), fontSize = 12.sp)
                                }
                                Surface(shape = RoundedCornerShape(18.dp), color = Color.White.copy(alpha = 0.12f), modifier = Modifier.size(58.dp)) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Icon(Icons.Default.School, null, tint = GoldAccent, modifier = Modifier.size(30.dp))
                                    }
                                }
                            }
                            HorizontalDivider(color = Color.White.copy(alpha = 0.18f))
                            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                                Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                    Text("الرقم المدرسي", fontSize = 10.sp, color = Color.White.copy(alpha = 0.68f))
                                    Text(currentChild.studentNumber, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = Color.White)
                                }
                                Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                    Text("صلة القرابة", fontSize = 10.sp, color = Color.White.copy(alpha = 0.68f))
                                    Text(currentChild.relation ?: "ولي أمر", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = Color.White)
                                }
                            }
                            val present = currentChild.attendance.orEmpty().count { it.status == "present" }
                            val absent = currentChild.attendance.orEmpty().count { it.status == "absent" }
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                                DarkStat("الحضور", present.toString(), Modifier.weight(1f))
                                DarkStat("الغياب", absent.toString(), Modifier.weight(1f))
                                DarkStat("المواد", currentChild.grades.orEmpty().size.toString(), Modifier.weight(1f))
                            }
                        }
                    }
                }

                if (currentChild.canViewFees && currentChild.fees != null) {
                    item {
                        Surface(
                            shape = RoundedCornerShape(22.dp),
                            color = SurfaceWhite,
                            border = androidx.compose.foundation.BorderStroke(1.dp, BorderLight),
                            modifier = Modifier.fillMaxWidth().clickable(onClick = onNavigateToFees)
                        ) {
                            Row(Modifier.padding(18.dp), verticalAlignment = Alignment.CenterVertically) {
                                Surface(shape = RoundedCornerShape(14.dp), color = BurgundyContainer, modifier = Modifier.size(48.dp)) {
                                    Box(contentAlignment = Alignment.Center) { Icon(Icons.Default.AccountBalanceWallet, null, tint = BurgundyPrimary) }
                                }
                                Spacer(Modifier.width(13.dp))
                                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                    Text("الرسوم والمدفوعات", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                                    Text("المتبقي: " + formatAmount(currentChild.fees.remainingBalance), fontSize = 12.sp, color = TextSecondary)
                                }
                                Text("التفاصيل", fontSize = 12.sp, color = BurgundyPrimary, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }

            item {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    SectionHeading("الخدمات")
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                        ServiceActionItem("النتائج والدرجات", "النتائج المنشورة", Icons.Default.Grade, Modifier.weight(1f), onNavigateToGrades)
                        ServiceActionItem("الحضور والغياب", "السجل اليومي", Icons.Default.CheckCircle, Modifier.weight(1f), onNavigateToAttendance)
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                        ServiceActionItem("الجدول الدراسي", "الحصص المعتمدة", Icons.Default.CalendarMonth, Modifier.weight(1f), onNavigateToSchedule)
                        ServiceActionItem("الإعلانات", "التعاميم والتقويم", Icons.Default.Campaign, Modifier.weight(1f), onNavigateToAnnouncements)
                    }
                    if (currentChild?.canViewFees == true) {
                        ServiceActionItem("الرسوم والمدفوعات", "البيان والإيصالات", Icons.Default.AccountBalanceWallet, Modifier.fillMaxWidth(), onNavigateToFees)
                    }
                }
            }

            item {
                Text("تُعرض المعلومات التي اعتمدتها المؤسسة ونشرتها لحساب ولي الأمر فقط.", fontSize = 11.sp, lineHeight = 18.sp, color = TextSecondary)
            }
        }
    }
}

@Composable
private fun SectionHeading(title: String) {
    Text(title, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
}

@Composable
private fun DarkStat(label: String, value: String, modifier: Modifier = Modifier) {
    Surface(modifier.heightIn(min = 66.dp), shape = RoundedCornerShape(16.dp), color = Color.White.copy(alpha = 0.10f)) {
        Column(Modifier.fillMaxWidth().padding(vertical = 10.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(value, color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold)
            Text(label, color = Color.White.copy(alpha = 0.72f), fontSize = 10.sp)
        }
    }
}

@Composable
fun ServiceActionItem(title: String, subtitle: String, icon: ImageVector, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Surface(
        modifier = modifier.heightIn(min = 82.dp).clickable(onClick = onClick),
        shape = RoundedCornerShape(20.dp),
        color = SurfaceWhite,
        border = androidx.compose.foundation.BorderStroke(1.dp, BorderLight)
    ) {
        Row(Modifier.padding(horizontal = 13.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
            Surface(shape = RoundedCornerShape(13.dp), color = BurgundyContainer, modifier = Modifier.size(42.dp)) {
                Box(contentAlignment = Alignment.Center) { Icon(icon, null, tint = BurgundyPrimary, modifier = Modifier.size(21.dp)) }
            }
            Spacer(Modifier.width(10.dp))
            Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(title, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                Text(subtitle, fontSize = 10.sp, color = TextSecondary)
            }
        }
    }
}

private fun formatAmount(value: Double): String = String.format(Locale.US, "%,.2f", value)
