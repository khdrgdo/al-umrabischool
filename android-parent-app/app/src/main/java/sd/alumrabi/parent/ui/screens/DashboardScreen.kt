package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccountBalanceWallet
import androidx.compose.material.icons.outlined.Announcement
import androidx.compose.material.icons.outlined.ArrowOutward
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.ChevronLeft
import androidx.compose.material.icons.outlined.Grade
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.School
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import sd.alumrabi.parent.R
import sd.alumrabi.parent.data.model.*
import sd.alumrabi.parent.ui.theme.*
import java.util.Locale

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
    val statusText = when {
        demoMode -> "معاينة محلية"
        connectionState == BackendConnectionState.CONNECTED_LIVE -> "متصل بالمؤسسة"
        connectionState == BackendConnectionState.SYNCED_LOCAL -> "آخر بيانات محفوظة"
        else -> "جارٍ التحقق من الاتصال"
    }
    LazyColumn(
        modifier = Modifier.fillMaxSize().background(AppCanvas).statusBarsPadding(),
        contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = 18.dp, bottom = 26.dp),
        verticalArrangement = Arrangement.spacedBy(22.dp)
    ) {
        item {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
                    Surface(shape = RoundedCornerShape(13.dp), color = AppSurface, border = BorderStroke(1.dp, AppBorder), modifier = Modifier.size(43.dp)) {
                        Image(painterResource(R.drawable.ic_alumrabi_mark), "شعار العمرابي", Modifier.padding(5.dp))
                    }
                    Spacer(Modifier.width(11.dp))
                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text("العمرابي", color = AppInk, fontSize = 17.sp, fontWeight = FontWeight.ExtraBold)
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(Modifier.size(6.dp).clip(CircleShape).background(if (connectionState == BackendConnectionState.CONNECTED_LIVE && !demoMode) StatusSuccess else StatusWarning))
                            Spacer(Modifier.width(5.dp))
                            Text(statusText, color = AppMuted, fontSize = 10.sp)
                        }
                    }
                }
                IconButton(onClick = onNavigateToSettings) {
                    Icon(Icons.Outlined.Settings, "إعدادات الحساب", tint = AppInk)
                }
            }
        }
        item {
            Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
                Text("مساحة الأسرة", color = AppRed, fontSize = 11.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
                Text("أهلاً، ${guardian.fullName}", color = AppInk, fontSize = 25.sp, fontWeight = FontWeight.ExtraBold, lineHeight = 34.sp)
                Text("هنا تتابع رحلة أبنائك التعليمية في العمرابي.", color = AppMuted, fontSize = 13.sp, lineHeight = 21.sp)
            }
        }
        item {
            Column(verticalArrangement = Arrangement.spacedBy(11.dp)) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text("الأبناء المرتبطون", color = AppInk, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.weight(1f))
                    Text("${children.size} أبناء", color = AppMuted, fontSize = 11.sp)
                }
                if (children.isEmpty()) {
                    Surface(shape = RoundedCornerShape(20.dp), color = AppSurface, border = BorderStroke(1.dp, AppBorder)) {
                        Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                            Surface(shape = CircleShape, color = AppRedSoft) { Icon(Icons.Outlined.Person, null, tint = AppRed, modifier = Modifier.padding(12.dp)) }
                            Spacer(Modifier.width(12.dp))
                            Column {
                                Text("لا يوجد أبناء مرتبطون بعد", color = AppInk, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                                Text("راجع إدارة المؤسسة لاعتماد الربط بحسابك.", color = AppMuted, fontSize = 11.sp, lineHeight = 17.sp)
                            }
                        }
                    }
                } else {
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(9.dp), contentPadding = PaddingValues(end = 2.dp)) {
                        itemsIndexed(children) { index, item ->
                            val selected = index == selectedChildIndex
                            Surface(
                                modifier = Modifier.clip(RoundedCornerShape(14.dp)).clickable { onSelectChild(index) },
                                color = if (selected) AppInk else AppSurface,
                                shape = RoundedCornerShape(14.dp),
                                border = if (selected) null else BorderStroke(1.dp, AppBorder)
                            ) {
                                Row(Modifier.padding(horizontal = 14.dp, vertical = 11.dp), verticalAlignment = Alignment.CenterVertically) {
                                    Surface(shape = CircleShape, color = if (selected) Color.White.copy(alpha = .12f) else AppRedSoft) {
                                        Text(item.fullName.take(1), modifier = Modifier.padding(horizontal = 9.dp, vertical = 7.dp), color = if (selected) Color.White else AppRed, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                                    }
                                    Spacer(Modifier.width(8.dp))
                                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                        Text(item.fullName.substringBefore(' '), color = if (selected) Color.White else AppInk, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                                        Text(item.gradeName, color = if (selected) Color.White.copy(alpha = .7f) else AppMuted, fontSize = 9.sp)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if (child != null) {
            item {
                Surface(shape = RoundedCornerShape(25.dp), color = AppInk, modifier = Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(19.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                        Row(verticalAlignment = Alignment.Top) {
                            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                                Text("الملف الدراسي", color = Color.White.copy(alpha = .65f), fontSize = 10.sp, letterSpacing = .7.sp)
                                Text(child.fullName, color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                                Text("${child.gradeName}  ·  ${child.sectionName}", color = Color.White.copy(alpha = .76f), fontSize = 12.sp)
                            }
                            Surface(shape = RoundedCornerShape(15.dp), color = AppRed, modifier = Modifier.size(47.dp)) {
                                Box(contentAlignment = Alignment.Center) { Icon(Icons.Outlined.School, null, tint = Color.White, modifier = Modifier.size(25.dp)) }
                            }
                        }
                        HorizontalDivider(color = Color.White.copy(alpha = .15f))
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                Text("الرقم المدرسي", color = Color.White.copy(alpha = .55f), fontSize = 9.sp)
                                Text(child.studentNumber, color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                            }
                            Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                Text("صلة القرابة", color = Color.White.copy(alpha = .55f), fontSize = 9.sp)
                                Text(child.relation ?: "ولي أمر", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                            }
                        }
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            DarkMetric("الحضور", child.attendance.orEmpty().count { it.status == "present" }.toString(), Modifier.weight(1f))
                            DarkMetric("الغياب", child.attendance.orEmpty().count { it.status == "absent" }.toString(), Modifier.weight(1f))
                            DarkMetric("المواد", child.grades.orEmpty().size.toString(), Modifier.weight(1f))
                        }
                    }
                }
            }
        }
        item {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text("الخدمات الدراسية", color = AppInk, fontSize = 16.sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.weight(1f))
                    Text("الوصول السريع", color = AppMuted, fontSize = 10.sp)
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    ServiceTile("النتائج", "الدرجات المنشورة", Icons.Outlined.Grade, Modifier.weight(1f), onNavigateToGrades)
                    ServiceTile("الحضور", "سجل الانتظام", Icons.Outlined.CheckCircle, Modifier.weight(1f), onNavigateToAttendance)
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    ServiceTile("الجدول", "الحصص الدراسية", Icons.Outlined.CalendarMonth, Modifier.weight(1f), onNavigateToSchedule)
                    ServiceTile("الإعلانات", "أخبار المؤسسة", Icons.Outlined.Announcement, Modifier.weight(1f), onNavigateToAnnouncements)
                }
                if (child?.canViewFees == true) {
                    ServiceTile("الرسوم", "المستحقات والإيصالات", Icons.Outlined.AccountBalanceWallet, Modifier.fillMaxWidth(), onNavigateToFees)
                }
            }
        }
        if (child != null && child.canViewFees && child.fees != null) {
            item {
                Surface(shape = RoundedCornerShape(20.dp), color = AppRedSoft, modifier = Modifier.fillMaxWidth().clickable(onClick = onNavigateToFees)) {
                    Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text("المتبقي من الرسوم", color = AppRedDark, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                            Text(formatAmount(child.fees.remainingBalance) + " ج.س", color = AppInk, fontSize = 20.sp, fontWeight = FontWeight.ExtraBold)
                        }
                        Icon(Icons.Outlined.ArrowOutward, null, tint = AppRed)
                    }
                }
            }
        }
        item {
            Surface(shape = RoundedCornerShape(19.dp), color = AppSurface, border = BorderStroke(1.dp, AppBorder), modifier = Modifier.fillMaxWidth().clickable(onClick = onNavigateToAnnouncements)) {
                Row(Modifier.padding(15.dp), verticalAlignment = Alignment.CenterVertically) {
                    Surface(shape = RoundedCornerShape(12.dp), color = AppRedSoft) {
                        Icon(Icons.Outlined.Announcement, null, tint = AppRed, modifier = Modifier.padding(10.dp).size(20.dp))
                    }
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Text("تواصل مع أخبار المؤسسة", color = AppInk, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                        Text("الإعلانات والتعاميم والتقويم الدراسي", color = AppMuted, fontSize = 10.sp)
                    }
                    Icon(Icons.Outlined.ChevronLeft, null, tint = AppMuted)
                }
            }
        }
        item {
            Text("تُعرض هنا المعلومات التي اعتمدتها المؤسسة ونشرتها لحساب ولي الأمر.", color = AppMuted, fontSize = 10.sp, lineHeight = 17.sp)
        }
    }
}

@Composable
private fun DarkMetric(label: String, value: String, modifier: Modifier = Modifier) {
    Surface(modifier.heightIn(min = 62.dp), shape = RoundedCornerShape(13.dp), color = Color.White.copy(alpha = .08f)) {
        Column(Modifier.fillMaxWidth().padding(vertical = 9.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(value, color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold)
            Text(label, color = Color.White.copy(alpha = .65f), fontSize = 9.sp)
        }
    }
}

@Composable
private fun ServiceTile(title: String, detail: String, icon: androidx.compose.ui.graphics.vector.ImageVector, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Surface(modifier = modifier.heightIn(min = 82.dp).clickable(onClick = onClick), shape = RoundedCornerShape(18.dp), color = AppSurface, border = BorderStroke(1.dp, AppBorder)) {
        Row(Modifier.padding(horizontal = 13.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
            Surface(shape = RoundedCornerShape(12.dp), color = AppRedSoft) {
                Icon(icon, null, tint = AppRed, modifier = Modifier.padding(10.dp).size(20.dp))
            }
            Spacer(Modifier.width(10.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(title, color = AppInk, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                Text(detail, color = AppMuted, fontSize = 9.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

private fun formatAmount(value: Double): String = String.format(Locale.US, "%,.0f", value)
