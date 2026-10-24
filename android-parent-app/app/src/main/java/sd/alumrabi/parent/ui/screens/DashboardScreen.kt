package sd.alumrabi.parent.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import sd.alumrabi.parent.data.model.*
import sd.alumrabi.parent.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    guardian: GuardianInfo,
    children: List<LinkedChild>,
    selectedChildIndex: Int,
    connectionState: BackendConnectionState = BackendConnectionState.CONNECTED_LIVE,
    onSelectChild: (Int) -> Unit,
    onNavigateToGrades: () -> Unit,
    onNavigateToAttendance: () -> Unit,
    onNavigateToSchedule: () -> Unit,
    onNavigateToAnnouncements: () -> Unit,
    onNavigateToAiAssistant: () -> Unit,
    onNavigateToSettings: () -> Unit
) {
    val currentChild = children.getOrNull(selectedChildIndex)

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "مدرسة العمرابي الثانوية",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            // Connection Health Pill
                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = if (connectionState == BackendConnectionState.CONNECTED_LIVE) 
                                    Color(0xFF10B981) else Color(0xFFF59E0B),
                                modifier = Modifier.padding(top = 1.dp)
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(5.dp)
                                            .background(Color.White, CircleShape)
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = if (connectionState == BackendConnectionState.CONNECTED_LIVE) "سحابي" else "محلي",
                                        fontSize = 9.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White
                                    )
                                }
                            }
                        }
                        Text(
                            text = "مرحباً، ${guardian.fullName}",
                            fontSize = 11.5.sp,
                            color = Color.White.copy(alpha = 0.85f)
                        )
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateToSettings) {
                        Icon(
                            Icons.Default.Settings,
                            contentDescription = "الإعدادات",
                            tint = Color.White
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = BurgundyPrimary)
            )
        },
        containerColor = LavenderCanvas
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            // 1. Multi-Child Selector (Pill Tabs with Smooth Active State)
            item {
                Text(
                    text = "الأبناء المقيدون",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(8.dp))

                if (children.isEmpty()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(SurfaceWhite, RoundedCornerShape(10.dp))
                            .border(1.dp, BorderLight, RoundedCornerShape(10.dp))
                            .padding(16.dp)
                    ) {
                        Text(
                            text = "لا يوجد أبناء مرتبطون بهذا الحساب حالياً. يرجى مراجعة إدارة المدرسة لاعتماد الربط.",
                            fontSize = 12.sp,
                            color = TextSecondary
                        )
                    }
                } else {
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        itemsIndexed(children) { index, child ->
                            val isSelected = index == selectedChildIndex
                            Surface(
                                shape = RoundedCornerShape(20.dp),
                                color = if (isSelected) BurgundyPrimary else SurfaceWhite,
                                border = if (isSelected) null else androidx.compose.foundation.BorderStroke(1.dp, BorderLight),
                                shadowElevation = if (isSelected) 2.dp else 0.dp,
                                modifier = Modifier.clickable { onSelectChild(index) }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        Icons.Default.Person,
                                        contentDescription = null,
                                        tint = if (isSelected) Color.White else TextSecondary,
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = child.fullName,
                                        fontSize = 12.sp,
                                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                        color = if (isSelected) Color.White else TextPrimary
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = "(${child.relation})",
                                        fontSize = 10.sp,
                                        color = if (isSelected) Color.White.copy(alpha = 0.8f) else TextSecondary
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // 2. Active Student Identity Summary (No bloated cards; clean typography + border)
            if (currentChild != null) {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(SurfaceWhite, RoundedCornerShape(12.dp))
                            .border(1.dp, BorderLight, RoundedCornerShape(12.dp))
                            .padding(16.dp)
                    ) {
                        Column {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text(
                                        text = currentChild.fullName,
                                        fontSize = 15.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = TextPrimary
                                    )
                                    Text(
                                        text = "${currentChild.gradeName} • ${currentChild.sectionName}",
                                        fontSize = 12.sp,
                                        color = TextSecondary,
                                        modifier = Modifier.padding(top = 2.dp)
                                    )
                                }
                                Surface(
                                    shape = RoundedCornerShape(6.dp),
                                    color = Color(0xFFF1F5F9)
                                ) {
                                    Text(
                                        text = currentChild.studentNumber,
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = BurgundyPrimary,
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                    )
                                }
                            }

                            HorizontalDivider(
                                color = BorderLight,
                                thickness = 0.8.dp,
                                modifier = Modifier.padding(vertical = 12.dp)
                            )

                            // Quick Stats Bar
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceAround
                            ) {
                                val presentCount = currentChild.attendance?.count { it.status == "present" } ?: 0
                                val absentCount = currentChild.attendance?.count { it.status == "absent" } ?: 0
                                val gradesCount = currentChild.grades?.size ?: 0

                                QuickStatColumn(label = "الحضور المسجل", value = "$presentCount يوم", isPositive = true)
                                QuickStatColumn(label = "الغياب غير المعذور", value = "$absentCount يوم", isPositive = absentCount == 0)
                                QuickStatColumn(label = "المواد المرصودة", value = "$gradesCount مادة", isPositive = true)
                            }
                        }
                    }
                }
            }

            // 3. AI Assistant Hero Banner (Institutional & Secure)
            item {
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = BurgundyContainer,
                    border = androidx.compose.foundation.BorderStroke(1.dp, BurgundyLight.copy(alpha = 0.3f)),
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onNavigateToAiAssistant() }
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Surface(
                            shape = CircleShape,
                            color = BurgundyPrimary,
                            modifier = Modifier.size(42.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text("ع", color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = "مساعد العمرابي الذكي",
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = BurgundyPrimary
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Surface(
                                    shape = RoundedCornerShape(4.dp),
                                    color = Color(0xFFC5A059)
                                ) {
                                    Text(
                                        text = "AI آمن ومحمي",
                                        fontSize = 9.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White,
                                        modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                                    )
                                }
                            }
                            Text(
                                text = "اسأل عن جدول الحصص اليوم، ملخص الدرجات، ومواعيد الامتحانات بدقة.",
                                fontSize = 11.5.sp,
                                color = TextSecondary,
                                modifier = Modifier.padding(top = 2.dp)
                            )
                        }
                        Icon(
                            Icons.Default.ArrowBack,
                            contentDescription = "فتح المحادثة",
                            tint = BurgundyPrimary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }

            // 4. Quick Services Grid
            item {
                Text(
                    text = "الخدمات والمتابعة المباشرة",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(8.dp))

                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        ServiceActionItem(
                            title = "الجدول الدراسي",
                            subtitle = "الحصص والمعلمون",
                            icon = Icons.Default.DateRange,
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateToSchedule
                        )
                        ServiceActionItem(
                            title = "الدرجات والنتائج",
                            subtitle = "أعمال السنة والامتحانات",
                            icon = Icons.Default.Star,
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateToGrades
                        )
                    }
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        ServiceActionItem(
                            title = "سجل الحضور",
                            subtitle = "المتابعة اليومية",
                            icon = Icons.Default.CheckCircle,
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateToAttendance
                        )
                        ServiceActionItem(
                            title = "الإعلانات والتقويم",
                            subtitle = "التعاميم المدرسية",
                            icon = Icons.Default.Notifications,
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateToAnnouncements
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun QuickStatColumn(label: String, value: String, isPositive: Boolean) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
            color = if (isPositive) TextPrimary else Color(0xFFE11D48)
        )
        Text(
            text = label,
            fontSize = 10.5.sp,
            color = TextSecondary,
            modifier = Modifier.padding(top = 2.dp)
        )
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
    Box(
        modifier = modifier
            .background(SurfaceWhite, RoundedCornerShape(10.dp))
            .border(1.dp, BorderLight, RoundedCornerShape(10.dp))
            .clickable(onClick = onClick)
            .padding(14.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Surface(
                shape = RoundedCornerShape(8.dp),
                color = BurgundyPrimary.copy(alpha = 0.08f),
                modifier = Modifier.size(36.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        icon,
                        contentDescription = null,
                        tint = BurgundyPrimary,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
            Spacer(modifier = Modifier.width(10.dp))
            Column {
                Text(
                    text = title,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                Text(
                    text = subtitle,
                    fontSize = 10.5.sp,
                    color = TextSecondary,
                    modifier = Modifier.padding(top = 1.dp)
                )
            }
        }
    }
}
