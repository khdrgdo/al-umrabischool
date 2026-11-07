@file:OptIn(ExperimentalMaterial3Api::class)

package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Campaign
import androidx.compose.material.icons.outlined.EventAvailable
import androidx.compose.material.icons.outlined.Grade
import androidx.compose.material.icons.outlined.Payments
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.data.model.AnnouncementItem
import sd.alumrabi.parent.data.model.BackendConnectionState
import sd.alumrabi.parent.data.model.CalendarEventItem
import sd.alumrabi.parent.data.model.GuardianInfo
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt
import sd.alumrabi.parent.util.attendanceSummary
import sd.alumrabi.parent.util.gradesSummary
import sd.alumrabi.parent.util.upcoming

@Composable
fun HomeScreen(
    guardian: GuardianInfo,
    children: List<LinkedChild>,
    selectedChildIndex: Int,
    announcements: List<AnnouncementItem>,
    events: List<CalendarEventItem>,
    connectionState: BackendConnectionState,
    lastSyncMillis: Long,
    onSelectChild: (Int) -> Unit,
    onRefresh: () -> Unit,
    onOpenRoute: (String) -> Unit,
    onSelectTab: (AppTab) -> Unit
) {
    SystemBars(statusBar = Canvas, darkIcons = true)
    val child = children.getOrNull(selectedChildIndex)

    Scaffold(
        containerColor = Canvas,
        topBar = {
            OmrabiTopBar(
                title = "العمرابي",
                subtitle = "مرحباً، ${Fmt.firstName(guardian.fullName)}",
                actions = {
                    IconButton(onClick = onRefresh) {
                        Icon(Icons.Outlined.Refresh, contentDescription = "تحديث البيانات", tint = Ink900)
                    }
                }
            )
        },
        bottomBar = { OmrabiBottomBar(currentRoute = Routes.Home, onSelect = onSelectTab) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(horizontal = Space.gutter, vertical = Space.lg),
            verticalArrangement = Arrangement.spacedBy(Space.md)
        ) {
            if (connectionState != BackendConnectionState.CONNECTED_LIVE) {
                item { SyncNotice(connectionState, lastSyncMillis) }
            }
            if (children.size > 1) {
                item { ChildSwitcher(children, selectedChildIndex, onSelectChild) }
            }
            if (child == null) {
                item { StatePanel(title = "لا يوجد ابن مرتبط", message = noChildMessage()) }
            } else {
                item { StudentHeader(child) }
                item { StatStrip(stats = homeStats(child)) }

                val notice = announcements.firstOrNull {
                    it.priority == "urgent" || it.priority == "important"
                }
                if (notice != null) {
                    item { NoticeCard(notice) { onOpenRoute(Routes.Announcements) } }
                }

                item {
                    Column {
                        SectionLabel("الخدمات")
                        GroupedList {
                            ListRow(
                                title = "النتائج والدرجات",
                                subtitle = resultsLine(child),
                                leading = Icons.Outlined.Grade,
                                onClick = { onSelectTab(AppTab.Results) }
                            )
                            RowDivider()
                            ListRow(
                                title = "سجل الحضور",
                                subtitle = attendanceLine(child),
                                leading = Icons.Outlined.EventAvailable,
                                onClick = { onSelectTab(AppTab.Attendance) }
                            )
                            RowDivider()
                            ListRow(
                                title = "الرسوم الدراسية",
                                subtitle = feesLine(child),
                                leading = Icons.Outlined.Payments,
                                onClick = { onSelectTab(AppTab.Fees) }
                            )
                            RowDivider()
                            ListRow(
                                title = "الإعلانات والتقويم",
                                subtitle = announcementsLine(announcements, events),
                                leading = Icons.Outlined.Campaign,
                                onClick = { onOpenRoute(Routes.Announcements) }
                            )
                        }
                    }
                }
            }
            item {
                Text(
                    "آخر تحديث: ${Fmt.lastSync(lastSyncMillis)}",
                    style = MaterialTheme.typography.bodySmall,
                    color = Ink500,
                    modifier = Modifier.padding(horizontal = Space.xs)
                )
            }
        }
    }
}

@Composable
private fun StudentHeader(child: LinkedChild) {
    Column(Modifier.fillMaxWidth().padding(horizontal = Space.xs)) {
        Text(child.fullName, style = MaterialTheme.typography.headlineSmall, color = Ink900)
        Text(
            "${child.gradeName} · ${child.sectionName}",
            style = MaterialTheme.typography.bodyMedium,
            color = Ink700
        )
        Text(
            "رقم القيد ${child.studentNumber}",
            style = MaterialTheme.typography.bodySmall,
            color = Ink500
        )
    }
}

@Composable
private fun NoticeCard(item: AnnouncementItem, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        shape = Radius.card,
        color = Crimson50,
        border = BorderStroke(1.dp, Crimson100)
    ) {
        Column(Modifier.padding(Space.lg)) {
            Text("إعلان هام", style = MaterialTheme.typography.labelMedium, color = Crimson700)
            Text(item.title, style = MaterialTheme.typography.titleSmall, color = Ink900)
            Text(
                Fmt.dateOrRaw(item.publishedAt),
                style = MaterialTheme.typography.bodySmall,
                color = Ink500
            )
        }
    }
}

private fun homeStats(child: LinkedChild): List<Stat> {
    val att = child.attendance.attendanceSummary()
    val grades = child.grades.gradesSummary()
    return listOf(
        Stat(att.ratePercent?.let { "$it%" } ?: "—", "نسبة الحضور"),
        Stat("${att.absent}", "أيام الغياب"),
        Stat("${grades.count}", "نتائج منشورة")
    )
}

private fun resultsLine(child: LinkedChild): String {
    val s = child.grades.gradesSummary()
    if (s.count == 0) return "لم تُنشر نتائج بعد"
    val avg = s.averagePercent?.let { " · المتوسط ${Fmt.percent(it)}" } ?: ""
    return Fmt.plural(s.count, "نتيجة واحدة", "نتيجتان", "نتائج", "نتيجة") + avg
}

private fun attendanceLine(child: LinkedChild): String {
    val s = child.attendance.attendanceSummary()
    if (s.total == 0) return "لا يوجد سجل بعد"
    val rate = s.ratePercent?.let { "نسبة الحضور $it%" } ?: ""
    return if (s.absent > 0) "$rate · غياب ${Fmt.days(s.absent)}" else "$rate · بلا غياب"
}

private fun feesLine(child: LinkedChild): String {
    if (!child.canViewFees) return "غير متاحة لحسابك"
    val fees = child.fees ?: return "غير متاحة حالياً"
    if (fees.totalDue <= 0.0) return "لا توجد رسوم مقررة بعد"
    return if (fees.isFullyPaid) "مسدّدة بالكامل" else "المتبقي ${Fmt.number(fees.remainingBalance)} جنيه"
}

private fun announcementsLine(announcements: List<AnnouncementItem>, events: List<CalendarEventItem>): String {
    val upcoming = events.upcoming().size
    val a = if (announcements.isEmpty()) "لا إعلانات" else Fmt.plural(announcements.size, "إعلان واحد", "إعلانان", "إعلانات", "إعلاناً")
    val e = if (upcoming == 0) "لا فعاليات قادمة" else Fmt.plural(upcoming, "فعالية قادمة", "فعاليتان قادمتان", "فعاليات قادمة", "فعالية قادمة")
    return "$a · $e"
}
