package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.data.model.AnnouncementItem
import sd.alumrabi.parent.data.model.CalendarEventItem
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt
import java.time.LocalDate

private fun isImportant(priority: String): Boolean =
    priority.lowercase() in setOf("high", "urgent", "important")

@Composable
fun AnnouncementsScreen(
    announcements: List<AnnouncementItem>,
    events: List<CalendarEventItem>,
    onBack: () -> Unit
) {
    val today = LocalDate.now()
    val upcoming = events
        .filter { e ->
            val end = Fmt.parseDate(e.endsOn) ?: Fmt.parseDate(e.startsOn)
            end != null && !end.isBefore(today)
        }
        .sortedBy { Fmt.parseDate(it.startsOn) ?: today }

    Scaffold(
        topBar = { OmrabiTopBar(title = "الإعلانات والتقويم", onBack = onBack) },
        containerColor = Canvas
    ) { padding ->
        LazyColumn(
            modifier = Modifier.padding(padding),
            contentPadding = PaddingValues(horizontal = Space.gutter, vertical = Space.md)
        ) {
            item { SectionLabel("الإعلانات") }
            if (announcements.isEmpty()) {
                item {
                    StatePanel(
                        title = "لا توجد إعلانات",
                        message = "لم تنشر المدرسة أي إعلان حتى الآن."
                    )
                }
            } else {
                item {
                    GroupedList {
                        announcements.forEachIndexed { index, a ->
                            if (index > 0) RowDivider()
                            Column(Modifier.fillMaxWidth().padding(Space.lg)) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        a.title,
                                        style = MaterialTheme.typography.titleMedium,
                                        color = Ink900,
                                        modifier = Modifier.weight(1f)
                                    )
                                    if (isImportant(a.priority)) {
                                        Spacer(Modifier.width(Space.sm))
                                        StatusLabel("هام", Crimson700, Crimson100)
                                    }
                                }
                                Spacer(Modifier.height(Space.xxs))
                                Text(
                                    Fmt.dateOrRaw(a.publishedAt),
                                    style = MaterialTheme.typography.labelMedium,
                                    color = Ink500
                                )
                                Spacer(Modifier.height(Space.sm))
                                Text(
                                    a.body,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = Ink700
                                )
                            }
                        }
                    }
                }
            }

            item { SectionLabel("المواعيد القادمة") }
            if (upcoming.isEmpty()) {
                item {
                    StatePanel(
                        title = "لا توجد مواعيد قادمة",
                        message = "لا توجد فعاليات أو امتحانات مجدولة في التقويم حالياً."
                    )
                }
            } else {
                item {
                    GroupedList {
                        upcoming.forEachIndexed { index, e ->
                            if (index > 0) RowDivider()
                            val start = Fmt.parseDate(e.startsOn)
                            val end = Fmt.parseDate(e.endsOn)
                            Row(Modifier.fillMaxWidth().padding(Space.lg)) {
                                Column(
                                    modifier = Modifier.width(56.dp),
                                    horizontalAlignment = Alignment.Start
                                ) {
                                    Text(
                                        start?.dayOfMonth?.toString() ?: "—",
                                        style = MaterialTheme.typography.titleLarge.tabular(),
                                        color = Crimson700
                                    )
                                    if (start != null) {
                                        Text(
                                            Fmt.monthName(start),
                                            style = MaterialTheme.typography.labelMedium,
                                            color = Ink500
                                        )
                                    }
                                }
                                Column(Modifier.weight(1f)) {
                                    Text(e.title, style = MaterialTheme.typography.titleMedium, color = Ink900)
                                    if (!e.description.isNullOrBlank()) {
                                        Spacer(Modifier.height(Space.xxs))
                                        Text(
                                            e.description,
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = Ink700
                                        )
                                    }
                                    if (end != null && start != null && end != start) {
                                        Spacer(Modifier.height(Space.xxs))
                                        Text(
                                            "حتى ${Fmt.dayMonth(end)}",
                                            style = MaterialTheme.typography.labelMedium,
                                            color = Ink500
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
            item { Spacer(Modifier.height(Space.xxl)) }
        }
    }
}
