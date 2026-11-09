package sd.alumrabi.parent.ui.screens

import androidx.compose.animation.AnimatedVisibility
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Campaign
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.EventAvailable
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import java.time.LocalDate
import sd.alumrabi.parent.data.model.AnnouncementItem
import sd.alumrabi.parent.data.model.CalendarEventItem
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt
import sd.alumrabi.parent.util.addToCalendar
import sd.alumrabi.parent.util.upcoming

@Composable
fun AnnouncementsScreen(
    announcements: List<AnnouncementItem>,
    events: List<CalendarEventItem>,
    readIds: Set<String>,
    onMarkRead: (Collection<String>) -> Unit,
    initialTab: Int = 0,
    onBack: () -> Unit
) {
    SystemBars(statusBar = Canvas, darkIcons = true)
    val context = LocalContext.current
    var tab by remember { mutableIntStateOf(initialTab.coerceIn(0, 1)) }
    var open by remember { mutableStateOf<String?>(null) }
    val unread = announcements.filter { it.id !in readIds }
    val upcoming = events.upcoming()

    Column(Modifier.fillMaxSize().background(Canvas)) {
        OmrabiTopBar(
            title = "الإعلانات والتقويم",
            onBack = onBack,
            actions = {
                if (tab == 0 && unread.isNotEmpty()) {
                    CircleIconButton(
                        icon = Icons.Outlined.DoneAll,
                        description = "تعليم الكل كمقروء",
                        onClick = { onMarkRead(unread.map { it.id }) }
                    )
                    Spacer(Modifier.width(Space.sm))
                }
            }
        )
        Row(
            Modifier.fillMaxWidth().padding(horizontal = Space.gutter, vertical = Space.sm),
            horizontalArrangement = Arrangement.spacedBy(Space.sm)
        ) {
            TabChip("الإعلانات" + if (unread.isNotEmpty()) " (${unread.size})" else "", tab == 0) { tab = 0 }
            TabChip("التقويم", tab == 1) { tab = 1 }
        }
        if (tab == 0) {
            if (announcements.isEmpty()) {
                EmptyNote(Icons.Outlined.Campaign, "لا إعلانات", "ستظهر إعلانات المدرسة هنا.", Modifier.padding(Space.gutter))
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(horizontal = Space.gutter, vertical = Space.sm),
                    verticalArrangement = Arrangement.spacedBy(Space.md)
                ) {
                    items(announcements, key = { it.id }) { a ->
                        val isNew = a.id !in readIds
                        val isOpen = open == a.id
                        Panel(onClick = {
                            open = if (isOpen) null else a.id
                            if (isNew) onMarkRead(listOf(a.id))
                        }) {
                            Row(verticalAlignment = Alignment.Top) {
                                if (isNew) {
                                    Box(
                                        Modifier
                                            .padding(top = 8.dp, end = Space.sm)
                                            .size(8.dp)
                                            .clip(CircleShape)
                                            .background(Crimson600)
                                    )
                                }
                                Column(Modifier.weight(1f)) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text(
                                            a.title,
                                            style = MaterialTheme.typography.titleSmall,
                                            color = Ink900,
                                            modifier = Modifier.weight(1f),
                                            maxLines = if (isOpen) 6 else 2
                                        )
                                        if (a.priority == "urgent") Pill("عاجل", Negative, NegativeBg)
                                        else if (a.priority == "important") Pill("هام", Caution, CautionBg)
                                    }
                                    Text(Fmt.dateOrRaw(a.publishedAt), style = MaterialTheme.typography.bodySmall, color = Ink500)
                                    Spacer(Modifier.height(Space.sm))
                                    Text(
                                        a.body,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = Ink700,
                                        maxLines = if (isOpen) Int.MAX_VALUE else 2
                                    )
                                }
                            }
                        }
                    }
                    item { Spacer(Modifier.height(Space.lg)) }
                }
            }
        } else {
            if (upcoming.isEmpty()) {
                EmptyNote(Icons.Outlined.CalendarMonth, "لا مواعيد قادمة", "ستظهر مواعيد المدرسة هنا.", Modifier.padding(Space.gutter))
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(horizontal = Space.gutter, vertical = Space.sm),
                    verticalArrangement = Arrangement.spacedBy(Space.md)
                ) {
                    items(upcoming, key = { it.id }) { e ->
                        val start = Fmt.parseDate(e.startsOn)
                        val end = Fmt.parseDate(e.endsOn)
                        Panel {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Column(
                                    Modifier
                                        .width(52.dp)
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(Wash)
                                        .padding(vertical = 8.dp),
                                    horizontalAlignment = Alignment.CenterHorizontally
                                ) {
                                    Text(start?.dayOfMonth?.toString() ?: "—", style = MaterialTheme.typography.titleMedium.tabular(), color = Crimson700)
                                    if (start != null) Text(Fmt.monthName(start), style = MaterialTheme.typography.labelSmall, color = Ink500)
                                }
                                Spacer(Modifier.width(Space.md))
                                Column(Modifier.weight(1f)) {
                                    Text(e.title, style = MaterialTheme.typography.titleSmall, color = Ink900)
                                    if (start != null) {
                                        val range = if (end != null && end != start) "${Fmt.dayMonth(start)} – ${Fmt.dayMonth(end)}" else Fmt.fullDate(start)
                                        Text(range, style = MaterialTheme.typography.bodySmall, color = Ink500)
                                        Text(Fmt.relativeDay(start), style = MaterialTheme.typography.labelMedium, color = Indigo)
                                    }
                                }
                                if (start != null) {
                                    CircleIconButton(
                                        icon = Icons.Outlined.EventAvailable,
                                        description = "إضافة إلى التقويم",
                                        onClick = { addToCalendar(context, e.title, e.description, start, end) }
                                    )
                                }
                            }
                            if (!e.description.isNullOrBlank()) {
                                Spacer(Modifier.height(Space.sm))
                                Text(e.description, style = MaterialTheme.typography.bodySmall, color = Ink700)
                            }
                        }
                    }
                    item { Spacer(Modifier.height(Space.lg)) }
                }
            }
        }
    }
}

@Composable
private fun TabChip(text: String, selected: Boolean, onClick: () -> Unit) {
    Box(
        Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(if (selected) Crimson600 else Paper)
            .pressable(onClick = onClick)
            .padding(horizontal = Space.lg, vertical = Space.sm)
    ) {
        Text(text, style = MaterialTheme.typography.labelLarge, color = if (selected) OnBrand else Ink900)
    }
}
