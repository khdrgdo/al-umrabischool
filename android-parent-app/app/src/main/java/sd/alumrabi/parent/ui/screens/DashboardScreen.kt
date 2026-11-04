package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.BorderStroke
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
        "بيانات تجريبية"
    } else when (connectionState) {
        BackendConnectionState.CONNECTED_LIVE -> "متصل بالخادم"
        BackendConnectionState.SYNCED_LOCAL -> "آخر بيانات محفوظة"
        BackendConnectionState.CONNECTING -> "جارٍ الاتصال"
    }
    val connectionBackground = when {
        demoMode -> StatusWarningBg
        connectionState == BackendConnectionState.CONNECTED_LIVE -> StatusSuccessBg
        else -> StatusWarningBg
    }
    val connectionForeground = when {
        demoMode -> StatusWarning
        connectionState == BackendConnectionState.CONNECTED_LIVE -> StatusSuccess
        else -> StatusWarning
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
                        Text("العمرابي", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color.White)
                        Text("بوابة أولياء الأمور", fontSize = 10.sp, color = Color.White.copy(alpha = 0.76f))
                    }
                },
                navigationIcon = {
                    Surface(
                        shape = RoundedCornerShape(11.dp),
                        color = Color.White.copy(alpha = 0.10f),
                        modifier = Modifier.padding(start = 12.dp).size(40.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Image(
                                painter = painterResource(R.drawable.ic_launcher_foreground),
                                contentDescription = "شعار العمرابي",
                                modifier = Modifier.size(35.dp)
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
            verticalArrangement = Arrangement.spacedBy(17.dp)
        ) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(
                        modifier = Modifier.weight(1f),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Text("مرحباً بعودتك", fontSize = 12.sp, color = TextSecondary)
                        Text(
                            guardian.fullName,
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary,
                            maxLines = 1
                        )
                        Text("كل تفاصيل أبنائك الدراسية في مكان واحد", fontSize = 11.sp, color = TextSecondary)
                    }
                    Surface(
                        shape = CircleShape,
                        color = connectionBackground
                    ) {
                        Text(
                            connectionLabel,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 7.dp),
                            fontSize = 9.sp,
                            color = connectionForeground,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }

            item {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    SectionHeading("الأبناء")
                    if (children.isEmpty()) {
                        Surface(
                            shape = RoundedCornerShape(16.dp),
                            color = SurfaceWhite,
                            border = BorderStroke(1.dp, BorderLight)
                        ) {
                            Column(
                                modifier = Modifier.fillMaxWidth().padding(18.dp),
                                verticalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                Icon(Icons.Default.Person, contentDescription = null, tint = BurgundyPrimary)
                                Text("لا يوجد أبناء مرتبطون بالحساب", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                                Text(
                                    "يرجى مراجعة إدارة المؤسسة لاعتماد ربط الأبناء بحساب ولي الأمر.",
                                    fontSize = 11.sp,
                                    color = TextSecondary,
                                    lineHeight = 17.sp
                                )
                            }
                        }
                    } else {
                        LazyRow(horizontalArrangement = Arrangement.spacedBy(9.dp)) {
                            itemsIndexed(children) { index, child ->
                                val selected = index == selectedChildIndex
                                Surface(
                                    modifier = Modifier.width(184.dp).clickable { onSelectChild(index) },
                                    shape = RoundedCornerShape(15.dp),
                                    color = if (selected) BurgundyPrimary else SurfaceWhite,
                                    border = if (selected) null else BorderStroke(1.dp, BorderLight),
                                    shadowElevation = if (selected) 2.dp else 0.dp
                                ) {
                                    Column(
                                        modifier = Modifier.padding(13.dp),
                                        verticalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            Surface(
                                                shape = RoundedCornerShape(9.dp),
                                                color = if (selected) Color.White.copy(alpha = 0.14f) else BurgundyContainer,
                                                modifier = Modifier.size(32.dp)
                                            ) {
                                                Box(contentAlignment = Alignment.Center) {
                                                    Icon(
                                                        Icons.Default.School,
                                                        contentDescription = null,
                                                        tint = if (selected) GoldAccent else BurgundyPrimary,
                                                        modifier = Modifier.size(18.dp)
                                                    )
                                                }
                                            }
                                            Spacer(Modifier.width(8.dp))
                                            Text(
                                                "المرحلة الدراسية",
                                                fontSize = 10.sp,
                                                color = if (selected) Color.White.copy(alpha = 0.78f) else TextSecondary,
                                                maxLines = 1
                                            )
                                        }
                                        Text(
                                            child.fullName,
                                            fontSize = 13.sp,
                                            color = if (selected) Color.White else TextPrimary,
                                            fontWeight = FontWeight.Bold,
                                            maxLines = 1
                                        )
                                        Text(
                                            "الصف: ${child.gradeName}  •  ${child.sectionName}",
                                            fontSize = 9.sp,
                                            color = if (selected) Color.White.copy(alpha = 0.78f) else TextSecondary,
                                            maxLines = 1
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (currentChild != null) {
                item {
                    StudentSummaryCard(
                        child = currentChild,
                        onNavigateToFees = onNavigateToFees
                    )
                }

                item {
                    Column(verticalArrangement = Arrangement.spacedBy(11.dp)) {
                        SectionHeading("الخدمات الدراسية")
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            ServiceActionItem(
                                "النتائج والدرجات",
                                "النتائج المعتمدة",
                                Icons.Default.Grade,
                                Modifier.weight(1f),
                                onNavigateToGrades
                            )
                            ServiceActionItem(
                                "الحضور والغياب",
                                "السجل اليومي",
                                Icons.Default.CheckCircle,
                                Modifier.weight(1f),
                                onNavigateToAttendance
                            )
                        }
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            ServiceActionItem(
                                "الجدول الدراسي",
                                "الحصص والمواعيد",
                                Icons.Default.CalendarMonth,
                                Modifier.weight(1f),
                                onNavigateToSchedule
                            )
                            ServiceActionItem(
                                "الإعلانات",
                                "التعاميم والتقويم",
                                Icons.Default.Campaign,
                                Modifier.weight(1f),
                                onNavigateToAnnouncements
                            )
                        }
                    }
                }
            }

            item {
                Text(
                    "تُعرض المعلومات التي اعتمدتها المؤسسة ونشرتها لحساب ولي الأمر فقط.",
                    fontSize = 10.sp,
                    color = TextSecondary,
                    lineHeight = 16.sp,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }
        }
    }
}

@Composable
private fun StudentSummaryCard(
    child: LinkedChild,
    onNavigateToFees: () -> Unit
) {
    val present = child.attendance.orEmpty().count { it.status == "present" }
    val absent = child.attendance.orEmpty().count { it.status == "absent" }
    Surface(
        shape = RoundedCornerShape(19.dp),
        color = SurfaceWhite,
        border = BorderStroke(1.dp, BorderLight),
        shadowElevation = 1.dp
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(13.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = BurgundyContainer,
                    modifier = Modifier.size(44.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.School, contentDescription = null, tint = BurgundyPrimary, modifier = Modifier.size(24.dp))
                    }
                }
                Spacer(Modifier.width(11.dp))
                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Text("الملف الدراسي", fontSize = 10.sp, color = TextSecondary)
                    Text(child.fullName, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = TextPrimary, maxLines = 1)
                    Text("${child.gradeName} · ${child.sectionName}", fontSize = 11.sp, color = TextSecondary)
                }
            }

            HorizontalDivider(color = BorderLight)

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Text("الرقم المدرسي", fontSize = 9.sp, color = TextSecondary)
                    Text(child.studentNumber, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = BurgundyPrimary)
                }
                Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Text("صلة القرابة", fontSize = 9.sp, color = TextSecondary)
                    Text(child.relation ?: "ولي أمر", fontSize = 12.sp, fontWeight = FontWeight.Medium, color = TextPrimary)
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                QuickStatColumn("سجلات حضور", present.toString(), true, Modifier.weight(1f))
                QuickStatColumn("سجلات غياب", absent.toString(), absent == 0, Modifier.weight(1f))
                QuickStatColumn("نتائج منشورة", child.grades.orEmpty().size.toString(), true, Modifier.weight(1f))
            }

            if (child.canViewFees && child.fees != null) {
                Surface(
                    modifier = Modifier.fillMaxWidth().clickable(onClick = onNavigateToFees),
                    shape = RoundedCornerShape(13.dp),
                    color = BurgundyPrimary
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 13.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.AccountBalanceWallet, contentDescription = null, tint = GoldAccent)
                        Spacer(Modifier.width(10.dp))
                        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text("الموقف المالي", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.White)
                            Text("المتبقي: ${formatAmount(child.fees.remainingBalance)}", fontSize = 10.sp, color = Color.White.copy(alpha = 0.82f))
                        }
                        Text("التفاصيل", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = GoldAccent)
                    }
                }
            }
        }
    }
}

@Composable
private fun SectionHeading(title: String) {
    Text(title, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
}

@Composable
private fun QuickStatColumn(
    label: String,
    value: String,
    isPositive: Boolean,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        color = LavenderCanvas
    ) {
        Column(
            modifier = Modifier.padding(vertical = 10.dp, horizontal = 4.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(3.dp)
        ) {
            Text(value, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = if (isPositive) BurgundyPrimary else StatusDanger)
            Text(label, fontSize = 9.sp, color = TextSecondary, maxLines = 1)
        }
    }
}

@Composable
private fun ServiceActionItem(
    title: String,
    subtitle: String,
    icon: ImageVector,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Surface(
        modifier = modifier.heightIn(min = 102.dp).clickable(onClick = onClick),
        shape = RoundedCornerShape(15.dp),
        color = SurfaceWhite,
        border = BorderStroke(1.dp, BorderLight)
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(13.dp),
            verticalArrangement = Arrangement.spacedBy(7.dp)
        ) {
            Surface(
                shape = RoundedCornerShape(10.dp),
                color = BurgundyContainer,
                modifier = Modifier.size(36.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(icon, contentDescription = null, tint = BurgundyPrimary, modifier = Modifier.size(19.dp))
                }
            }
            Text(title, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = TextPrimary, maxLines = 1)
            Text(subtitle, fontSize = 9.sp, color = TextSecondary, maxLines = 1)
        }
    }
}

private fun formatAmount(value: Double): String = String.format(Locale.US, "%,.2f", value)
