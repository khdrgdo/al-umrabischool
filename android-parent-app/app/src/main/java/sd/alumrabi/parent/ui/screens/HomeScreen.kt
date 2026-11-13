@file:OptIn(ExperimentalMaterial3Api::class)

package sd.alumrabi.parent.ui.screens

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccessTime
import androidx.compose.material.icons.outlined.Campaign
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.EventAvailable
import androidx.compose.material.icons.outlined.Grade
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Payments
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import java.time.LocalDate
import java.time.LocalDateTime
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
import sd.alumrabi.parent.util.nextClass
import sd.alumrabi.parent.util.upcoming

@Composable
fun HomeScreen(
    guardian: GuardianInfo,
    children: List<LinkedChild>,
    selectedChildIndex: Int,
    announcements: List<AnnouncementItem>,
    events: List<CalendarEventItem>,
    readIds: Set<String>,
    connectionState: BackendConnectionState,
    lastSyncMillis: Long,
    isRefreshing: Boolean,
    onSelectChild: (Int) -> Unit,
    onRefresh: () -> Unit,
    onOpenRoute: (String) -> Unit,
    onSelectTab: (AppTab) -> Unit
) {
    SystemBars(statusBar = Crimson800, darkIcons = false)
    val child = children.getOrNull(selectedChildIndex)
    val unread = announcements.count { it.id !in readIds }

    PullToRefreshBox(
        isRefreshing = isRefreshing,
        onRefresh = onRefresh,
        modifier = Modifier.fillMaxSize()
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = Space.xxl),
            verticalArrangement = Arrangement.spacedBy(Space.lg)
        ) {
            item {
                HeroHeader(
                    guardian = guardian,
                    children = children,
                    selectedIndex = selectedChildIndex,
                    unread = unread,
                    onSelectChild = onSelectChild,
                    onBell = { onOpenRoute(Routes.Announcements) }
                )
            }
            if (children.size > 1) {
                item { Spacer(Modifier.height(0.dp)) }
            }
            if (connectionState != BackendConnectionState.CONNECTED_LIVE) {
                item {
                    SyncNotice(
                        connectionState, lastSyncMillis,
                        Modifier.padding(horizontal = Space.gutter)
                    )
                }
            }
            if (child == null) {
                item {
                    StatePanel(
                        title = "لا يوجد ابن مرتبط",
                        message = noChildMessage(),
                        modifier = Modifier.padding(horizontal = Space.gutter)
                    )
                }
            } else {
                item { Reveal(0) { TodayPanel(child, Modifier.padding(horizontal = Space.gutter)) } }
                item {
                    Reveal(1) {
                        QuickGrid(child, announcements.size, Modifier.padding(horizontal = Space.gutter), onOpenRoute, onSelectTab)
                    }
                }
                val important = announcements.firstOrNull {
                    (it.priority == "urgent" || it.priority == "important") && it.id !in readIds
                }
                if (important != null) {
                    item {
                        Reveal(2) {
                            ImportantNotice(important, Modifier.padding(horizontal = Space.gutter)) {
                                onOpenRoute(Routes.Announcements)
                            }
                        }
                    }
                }
                val upcoming = events.upcoming().take(2)
                if (upcoming.isNotEmpty()) {
                    item {
                        Reveal(3) {
                            Column(Modifier.padding(horizontal = Space.gutter)) {
                                SectionLabel("المواعيد القادمة")
                                Panel(onClick = { onOpenRoute(Routes.Announcements) }, padding = 0.dp) {
                                    upcoming.forEachIndexed { i, e ->
                                        if (i > 0) RowDivider()
                                        UpcomingRow(e)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            item {
                Text(
                    "آخر تحديث: ${Fmt.lastSync(lastSyncMillis)} · اسحب للأسفل للتحديث",
                    style = MaterialTheme.typography.bodySmall,
                    color = Ink500,
                    modifier = Modifier.padding(horizontal = Space.gutter)
                )
            }
        }
    }
}

private fun greeting(): String {
    val h = LocalDateTime.now().hour
    return when {
        h in 5..11 -> "صباح الخير"
        h in 12..16 -> "نهارك سعيد"
        else -> "مساء الخير"
    }
}

@Composable
private fun HeroHeader(
    guardian: GuardianInfo,
    children: List<LinkedChild>,
    selectedIndex: Int,
    unread: Int,
    onSelectChild: (Int) -> Unit,
    onBell: () -> Unit
) {
    Box(Modifier.fillMaxWidth()) {
        Column(Modifier.statusBarsPadding()) {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Space.gutter)
                    .padding(top = Space.md),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(Modifier.weight(1f)) {
                    Text(greeting(), style = MaterialTheme.typography.bodyMedium, color = OnBrand.copy(alpha = 0.8f))
                    Text(
                        Fmt.shortName(guardian.fullName, 3),
                        style = MaterialTheme.typography.titleLarge,
                        color = OnBrand,
                        maxLines = 1
                    )
                }
                CircleIconButton(
                    icon = Icons.Outlined.Notifications,
                    description = if (unread > 0) "الإشعارات، $unread غير مقروء" else "الإشعارات",
                    onClick = onBell,
                    container = OnBrand.copy(alpha = 0.16f),
                    tint = OnBrand,
                    showDot = unread > 0
                )
            }
            Spacer(Modifier.height(Space.lg))
            if (children.isNotEmpty()) {
                Reveal(1) { ChildPager(children, selectedIndex, onSelectChild) }
            } else {
                Spacer(Modifier.height(Space.md))
            }
        }
    }
}

@Composable
private fun ChildPager(children: List<LinkedChild>, selectedIndex: Int, onSelect: (Int) -> Unit) {
    val safe = selectedIndex.coerceIn(0, children.lastIndex)
    val pager = rememberPagerState(initialPage = safe, pageCount = { children.size })
    LaunchedEffect(pager.currentPage) {
        if (pager.currentPage != safe) onSelect(pager.currentPage)
    }
    LaunchedEffect(safe) {
        if (pager.currentPage != safe) pager.animateScrollToPage(safe)
    }
    Column {
        HorizontalPager(
            state = pager,
            contentPadding = PaddingValues(horizontal = Space.gutter),
            pageSpacing = 12.dp
        ) { page -> ChildCard(children[page]) }
        if (children.size > 1) {
            Spacer(Modifier.height(Space.md))
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                children.forEachIndexed { i, _ ->
                    val active = i == pager.currentPage
                    val w by animateDpAsState(if (active) 22.dp else 7.dp, label = "dot")
                    Box(
                        Modifier
                            .padding(horizontal = 3.dp)
                            .height(7.dp)
                            .width(w)
                            .clip(CircleShape)
                            .background(if (active) Crimson600 else LineStrong)
                    )
                }
            }
        }
    }
}

@Composable
private fun ChildCard(child: LinkedChild) {
    val att = child.attendance.attendanceSummary()
    val grades = child.grades.gradesSummary()
    Panel(padding = Space.lg) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Monogram(child.fullName, 52.dp)
            Spacer(Modifier.width(Space.md))
            Column(Modifier.weight(1f)) {
                Text(child.fullName, style = MaterialTheme.typography.titleMedium, color = Ink900, maxLines = 2)
                Text(
                    "${child.gradeName} · ${child.sectionName}",
                    style = MaterialTheme.typography.bodySmall,
                    color = Ink700
                )
                Text(
                    "رقم القيد ${child.studentNumber} · ${Fmt.relation(child.relation)}",
                    style = MaterialTheme.typography.bodySmall,
                    color = Ink500
                )
            }
        }
        Spacer(Modifier.height(Space.md))
        RowDivider()
        Spacer(Modifier.height(Space.md))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
            MiniRing(
                value = att.ratePercent?.toFloat()?.div(100f),
                center = att.ratePercent?.let { "$it%" } ?: "—",
                label = "الحضور",
                color = Teal
            )
            MiniRing(
                value = grades.averagePercent?.toFloat()?.div(100f),
                center = grades.averagePercent?.let { Fmt.percent(it) } ?: "—",
                label = "المعدل",
                color = Crimson600
            )
            val fees = child.fees
            val feeValue = if (!child.canViewFees || fees == null || fees.netDue <= 0.0) null else (fees.totalPaid / fees.netDue).toFloat()
            MiniRing(
                value = feeValue,
                center = feeValue?.let { Fmt.percent(it.coerceIn(0f, 1f) * 100.0) } ?: "—",
                label = "المسدّد",
                color = Gold
            )
        }
    }
}

@Composable
private fun MiniRing(value: Float?, center: String, label: String, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        ProgressRing(
            progress = value ?: 0f,
            ringSize = 64.dp,
            stroke = 7.dp,
            color = color
        ) {
            Text(center, style = MaterialTheme.typography.labelLarge.tabular(), color = Ink900)
        }
        Spacer(Modifier.height(4.dp))
        Text(label, style = MaterialTheme.typography.labelMedium, color = Ink500)
    }
}

@Composable
private fun TodayPanel(child: LinkedChild, modifier: Modifier = Modifier) {
    val today = LocalDate.now()
    val rec = child.attendance.orEmpty().firstOrNull { it.date.startsWith(today.toString()) }
    val weekend = Fmt.weekdayIndexSun0(today) in listOf(5, 6)
    val (title, fg, bg) = when {
        rec?.status == "present" -> Triple("حاضر اليوم", Positive, PositiveBg)
        rec?.status == "late" -> Triple("حضر متأخراً اليوم", Caution, CautionBg)
        rec?.status == "excused" -> Triple("غياب بعذر اليوم", Caution, CautionBg)
        rec?.status == "absent" -> Triple("غائب اليوم", Negative, NegativeBg)
        weekend -> Triple("عطلة نهاية الأسبوع", Ink700, Wash)
        else -> Triple("لم يُسجَّل حضور اليوم بعد", Ink700, Wash)
    }
    val next = child.schedule.nextClass()
    Panel(modifier = modifier) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconBubble(Icons.Outlined.EventAvailable, fg, bg)
            Spacer(Modifier.width(Space.md))
            Column(Modifier.weight(1f)) {
                Text("اليوم · ${Fmt.fullDate(today)}", style = MaterialTheme.typography.labelMedium, color = Ink500)
                Text(title, style = MaterialTheme.typography.titleMedium, color = Ink900)
                if (!rec?.reason.isNullOrBlank()) {
                    Text("السبب: ${rec?.reason}", style = MaterialTheme.typography.bodySmall, color = Ink500)
                }
            }
        }
        if (next != null) {
            Spacer(Modifier.height(Space.md))
            RowDivider()
            Spacer(Modifier.height(Space.md))
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconBubble(Icons.Outlined.Schedule, Indigo, IndigoBg)
                Spacer(Modifier.width(Space.md))
                Column(Modifier.weight(1f)) {
                    Text("الحصة القادمة", style = MaterialTheme.typography.labelMedium, color = Ink500)
                    Text(next.subject, style = MaterialTheme.typography.titleSmall, color = Ink900)
                }
                Text(
                    Fmt.time12(next.startsAt),
                    style = MaterialTheme.typography.titleSmall.tabular(),
                    color = Indigo
                )
            }
        }
    }
}

@Composable
private fun IconBubble(icon: ImageVector, fg: Color, bg: Color, size: Int = 44) {
    Box(
        Modifier
            .size(size.dp)
            .clip(CircleShape)
            .background(bg),
        contentAlignment = Alignment.Center
    ) {
        Icon(icon, contentDescription = null, tint = fg, modifier = Modifier.size((size * 0.5f).dp))
    }
}

@Composable
private fun QuickGrid(
    child: LinkedChild,
    announcementsCount: Int,
    modifier: Modifier,
    onOpenRoute: (String) -> Unit,
    onSelectTab: (AppTab) -> Unit
) {
    val g = child.grades.gradesSummary()
    val a = child.attendance.attendanceSummary()
    val fees = child.fees
    val feesLine = when {
        !child.canViewFees -> "غير متاحة لحسابك"
        fees == null -> "غير متاحة حالياً"
        fees.totalDue <= 0.0 -> "لا رسوم مقررة"
        fees.isFullyPaid -> "مسدّدة بالكامل"
        else -> "المتبقي ${Fmt.money(fees.remainingBalance)}"
    }
    val today = Fmt.weekdayIndexSun0(LocalDate.now())
    val todayClasses = child.schedule.orEmpty().count { it.weekday == today && !it.isBreak }
    Column(modifier, verticalArrangement = Arrangement.spacedBy(Space.md)) {
        SectionLabel("خدماتي")
        Row(horizontalArrangement = Arrangement.spacedBy(Space.md)) {
            Tile(
                "النتائج", if (g.count == 0) "لا نتائج منشورة" else g.averagePercent?.let { "المعدل ${Fmt.percent(it)}" } ?: "${g.count} نتيجة",
                Icons.Outlined.Grade, Crimson700, Crimson50, Modifier.weight(1f)
            ) { onSelectTab(AppTab.Results) }
            Tile(
                "الحضور", if (a.total == 0) "لا سجل بعد" else "نسبة ${a.ratePercent ?: 0}% · غياب ${a.absent}",
                Icons.Outlined.EventAvailable, Teal, TealBg, Modifier.weight(1f)
            ) { onSelectTab(AppTab.Attendance) }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(Space.md)) {
            Tile("الرسوم", feesLine, Icons.Outlined.Payments, Gold, GoldBg, Modifier.weight(1f)) { onSelectTab(AppTab.Fees) }
            Tile(
                "الجدول", if (todayClasses == 0) "لا حصص اليوم" else "$todayClasses حصص اليوم",
                Icons.Outlined.CalendarMonth, Indigo, IndigoBg, Modifier.weight(1f)
            ) { onOpenRoute(Routes.Schedule) }
        }
    }
}

@Composable
private fun Tile(
    title: String,
    line: String,
    icon: ImageVector,
    fg: Color,
    bg: Color,
    modifier: Modifier,
    onClick: () -> Unit
) {
    Column(
        modifier
            .clip(RoundedCornerShape(18.dp))
            .background(bg)
            .pressable(onClick = onClick)
            .padding(Space.lg)
    ) {
        Box(
            Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(Paper.copy(alpha = 0.75f)),
            contentAlignment = Alignment.Center
        ) { Icon(icon, contentDescription = null, tint = fg, modifier = Modifier.size(22.dp)) }
        Spacer(Modifier.height(Space.md))
        Text(title, style = MaterialTheme.typography.titleMedium, color = Ink900)
        Text(line, style = MaterialTheme.typography.bodySmall, color = Ink700, maxLines = 2)
    }
}

@Composable
private fun ImportantNotice(item: AnnouncementItem, modifier: Modifier, onClick: () -> Unit) {
    Panel(modifier = modifier, onClick = onClick, color = Crimson50) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconBubble(Icons.Outlined.Campaign, Crimson700, Crimson100)
            Spacer(Modifier.width(Space.md))
            Column(Modifier.weight(1f)) {
                Text(
                    if (item.priority == "urgent") "إعلان عاجل" else "إعلان هام",
                    style = MaterialTheme.typography.labelMedium,
                    color = Crimson700
                )
                Text(item.title, style = MaterialTheme.typography.titleSmall, color = Ink900, maxLines = 2)
                Text(Fmt.dateOrRaw(item.publishedAt), style = MaterialTheme.typography.bodySmall, color = Ink500)
            }
        }
    }
}

@Composable
private fun UpcomingRow(e: CalendarEventItem) {
    val start = Fmt.parseDate(e.startsOn)
    Row(
        Modifier
            .fillMaxWidth()
            .padding(Space.lg),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(
            Modifier
                .width(48.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(Wash)
                .padding(vertical = 6.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(start?.dayOfMonth?.toString() ?: "—", style = MaterialTheme.typography.titleMedium.tabular(), color = Crimson700)
            if (start != null) Text(Fmt.monthName(start), style = MaterialTheme.typography.labelSmall, color = Ink500)
        }
        Spacer(Modifier.width(Space.md))
        Column(Modifier.weight(1f)) {
            Text(e.title, style = MaterialTheme.typography.titleSmall, color = Ink900, maxLines = 1)
            if (start != null) Text(Fmt.relativeDay(start), style = MaterialTheme.typography.bodySmall, color = Ink500)
        }
        Icon(Icons.Outlined.AccessTime, contentDescription = null, tint = Ink500, modifier = Modifier.size(18.dp))
    }
}
