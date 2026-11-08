package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import java.time.LocalDate
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt
import sd.alumrabi.parent.util.forDay
import sd.alumrabi.parent.util.isNow

@Composable
fun ScheduleScreen(
    children: List<LinkedChild>,
    selectedChildIndex: Int,
    onSelectChild: (Int) -> Unit,
    onBack: () -> Unit
) {
    SystemBars(statusBar = Canvas, darkIcons = true)
    val child = children.getOrNull(selectedChildIndex)
    val schedule = child?.schedule.orEmpty()
    val todayIdx = Fmt.weekdayIndexSun0(LocalDate.now())
    val days = remember(schedule) {
        val present = schedule.map { it.weekday }.toSet()
        (listOf(0, 1, 2, 3, 4) + present).distinct().sorted()
    }
    var selectedDay by remember(selectedChildIndex) { mutableIntStateOf(if (todayIdx in days) todayIdx else days.first()) }

    Column(Modifier.fillMaxSize().background(Canvas)) {
        OmrabiTopBar(title = "الجدول الدراسي", subtitle = child?.fullName, onBack = onBack)
        ChildChips(children, selectedChildIndex, onSelectChild, Modifier.padding(bottom = Space.sm))
        if (child == null) {
            StatePanel("لا يوجد ابن مرتبط", noChildMessage(), Modifier.padding(Space.gutter))
        } else if (schedule.isEmpty()) {
            EmptyNote(
                Icons.Outlined.CalendarMonth,
                "الجدول غير متاح بعد",
                "يظهر جدول الحصص هنا بعد أن تعتمده إدارة المدرسة.",
                Modifier.padding(Space.gutter)
            )
        } else {
            LazyRow(
                contentPadding = PaddingValues(horizontal = Space.gutter),
                horizontalArrangement = Arrangement.spacedBy(Space.sm)
            ) {
                items(days) { d ->
                    val sel = d == selectedDay
                    Column(
                        Modifier
                            .clip(RoundedCornerShape(14.dp))
                            .background(if (sel) Crimson600 else Paper)
                            .pressable { selectedDay = d }
                            .padding(horizontal = Space.lg, vertical = Space.sm),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            Fmt.weekdayNameSun0(d),
                            style = MaterialTheme.typography.labelLarge,
                            color = if (sel) OnBrand else Ink900
                        )
                        if (d == todayIdx) {
                            Box(
                                Modifier
                                    .padding(top = 3.dp)
                                    .width(6.dp)
                                    .height(6.dp)
                                    .clip(CircleShape)
                                    .background(if (sel) OnBrand else Crimson600)
                            )
                        } else Spacer(Modifier.height(9.dp))
                    }
                }
            }
            val entries = schedule.forDay(selectedDay)
            if (entries.isEmpty()) {
                EmptyNote(
                    Icons.Outlined.CalendarMonth,
                    "لا حصص في ${Fmt.weekdayNameSun0(selectedDay)}",
                    "لا توجد حصص مسجلة لهذا اليوم.",
                    Modifier.padding(Space.gutter)
                )
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(horizontal = Space.gutter, vertical = Space.lg),
                    verticalArrangement = Arrangement.spacedBy(Space.sm)
                ) {
                    items(entries, key = { "${it.weekday}-${it.periodOrder}-${it.startsAt}" }) { e ->
                        val now = e.isNow()
                        val bg = when {
                            e.isBreak -> Wash
                            now -> Crimson50
                            else -> Paper
                        }
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(14.dp))
                                .background(bg)
                                .padding(Space.md),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(Modifier.width(72.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(Fmt.time12(e.startsAt), style = MaterialTheme.typography.labelLarge.tabular(), color = Ink900)
                                Text(Fmt.time12(e.endsAt), style = MaterialTheme.typography.labelSmall.tabular(), color = Ink500)
                            }
                            Box(
                                Modifier
                                    .width(3.dp)
                                    .height(36.dp)
                                    .clip(CircleShape)
                                    .background(if (e.isBreak) LineStrong else if (now) Crimson600 else Indigo)
                            )
                            Spacer(Modifier.width(Space.md))
                            Column(Modifier.weight(1f)) {
                                Text(
                                    if (e.isBreak) (e.label.ifBlank { "فسحة" }) else e.subject.ifBlank { e.label },
                                    style = MaterialTheme.typography.titleSmall,
                                    color = Ink900
                                )
                                val sub = listOfNotNull(
                                    e.label.takeIf { !e.isBreak && it.isNotBlank() },
                                    e.room?.takeIf { it.isNotBlank() }?.let { "القاعة $it" }
                                ).joinToString(" · ")
                                if (sub.isNotEmpty()) Text(sub, style = MaterialTheme.typography.bodySmall, color = Ink500)
                            }
                            if (now) Pill("الآن", Crimson700, Crimson100)
                        }
                    }
                }
            }
        }
    }
}
