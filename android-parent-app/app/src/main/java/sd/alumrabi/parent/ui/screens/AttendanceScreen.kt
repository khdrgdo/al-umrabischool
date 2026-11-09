package sd.alumrabi.parent.ui.screens

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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.EventAvailable
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import java.time.LocalDate
import sd.alumrabi.parent.data.model.AttendanceRecord
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt
import sd.alumrabi.parent.util.Reports
import sd.alumrabi.parent.util.attendanceSummary
import sd.alumrabi.parent.util.byDate
import sd.alumrabi.parent.util.presentStreak
import sd.alumrabi.parent.util.recentAbsences
import sd.alumrabi.parent.util.shareText

private fun statusLabel(s: String) = when (s) {
    "present" -> "حاضر"
    "absent" -> "غائب"
    "late" -> "متأخر"
    "excused" -> "بعذر"
    else -> s
}

private fun statusColors(s: String): Pair<Color, Color> = when (s) {
    "present" -> Positive to PositiveBg
    "absent" -> Negative to NegativeBg
    "late", "excused" -> Caution to CautionBg
    else -> Ink700 to Wash
}

@Composable
fun AttendanceScreen(
    children: List<LinkedChild>,
    selectedChildIndex: Int,
    onSelectChild: (Int) -> Unit
) {
    SystemBars(statusBar = Canvas, darkIcons = true)
    val context = LocalContext.current
    val child = children.getOrNull(selectedChildIndex)
    val records = child?.attendance.orEmpty().sortedByDescending { it.date }
    val s = child?.attendance.attendanceSummary()

    Column(Modifier.fillMaxSize().background(Canvas).statusBarsPadding()) {
        ScreenHeader(
            title = "الحضور والغياب",
            subtitle = child?.fullName,
            modifier = Modifier.padding(horizontal = Space.gutter)
        ) {
            if (child != null && records.isNotEmpty()) {
                CircleIconButton(
                    icon = Icons.Outlined.Share,
                    description = "مشاركة ملخص الحضور",
                    onClick = { shareText(context, "ملخص الحضور", Reports.attendance(child)) }
                )
            }
        }
        ChildChips(children, selectedChildIndex, onSelectChild, Modifier.padding(vertical = Space.sm))
        if (child == null) {
            StatePanel("لا يوجد ابن مرتبط", noChildMessage(), Modifier.padding(Space.gutter))
        } else if (records.isEmpty()) {
            EmptyNote(
                Icons.Outlined.EventAvailable,
                "لا سجل حضور بعد",
                "يظهر سجل الحضور هنا بعد أن يبدأ المعلمون بتسجيله.",
                Modifier.padding(Space.gutter)
            )
        } else {
            val byDay = child.attendance.byDate()
            LazyColumn(
                contentPadding = PaddingValues(horizontal = Space.gutter, vertical = Space.sm),
                verticalArrangement = Arrangement.spacedBy(Space.md)
            ) {
                item {
                    Reveal(0) {
                        Panel {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                ProgressRing(
                                    progress = (s!!.ratePercent ?: 0) / 100f,
                                    ringSize = 88.dp,
                                    color = Teal
                                ) {
                                    Text(
                                        "${s.ratePercent ?: 0}%",
                                        style = MaterialTheme.typography.titleMedium.tabular(),
                                        color = Ink900
                                    )
                                }
                                Spacer(Modifier.width(Space.lg))
                                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                    Text("نسبة الحضور", style = MaterialTheme.typography.labelMedium, color = Ink500)
                                    val streak = child.attendance.presentStreak()
                                    if (streak >= 2) Pill("$streak أيام حضور متتالية", Positive, PositiveBg)
                                    val recent = child.attendance.recentAbsences()
                                    if (recent > 0) Pill("$recent غياب خلال أسبوعين", Caution, CautionBg)
                                    if (streak < 2 && recent == 0) {
                                        Text("${s.total} يوماً مسجلاً", style = MaterialTheme.typography.bodySmall, color = Ink700)
                                    }
                                }
                            }
                            Spacer(Modifier.height(Space.lg))
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(Space.sm)) {
                                CountChip("حضور", s.present, Positive, PositiveBg, Modifier.weight(1f))
                                CountChip("تأخر", s.late, Caution, CautionBg, Modifier.weight(1f))
                                CountChip("بعذر", s.excused, Caution, CautionBg, Modifier.weight(1f))
                                CountChip("غياب", s.absent, Negative, NegativeBg, Modifier.weight(1f))
                            }
                        }
                    }
                }
                item {
                    Reveal(1) {
                        Panel {
                            Text("آخر 5 أسابيع", style = MaterialTheme.typography.titleSmall, color = Ink900)
                            Spacer(Modifier.height(Space.md))
                            HeatGrid(byDay)
                        }
                    }
                }
                item { SectionLabel("السجل التفصيلي") }
                item {
                    Panel(padding = 0.dp) {
                        records.take(30).forEachIndexed { i, r ->
                            if (i > 0) RowDivider()
                            RecordRow(r)
                        }
                    }
                }
                item { Spacer(Modifier.height(Space.lg)) }
            }
        }
    }
}

@Composable
private fun CountChip(label: String, n: Int, fg: Color, bg: Color, modifier: Modifier) {
    Column(
        modifier
            .clip(RoundedCornerShape(12.dp))
            .background(bg)
            .padding(vertical = Space.md),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(n.toString(), style = MaterialTheme.typography.titleMedium.tabular(), color = fg)
        Text(label, style = MaterialTheme.typography.labelSmall, color = fg)
    }
}

@Composable
private fun HeatGrid(byDay: Map<LocalDate, AttendanceRecord>) {
    val today = LocalDate.now()
    val startOfWeek = today.minusDays(Fmt.weekdayIndexSun0(today).toLong())
    val first = startOfWeek.minusWeeks(4)
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            for (d in 0..6) {
                Text(
                    Fmt.weekdayNameSun0(d).take(3),
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.labelSmall,
                    color = Ink500
                )
            }
        }
        for (w in 0..4) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                for (d in 0..6) {
                    val date = first.plusWeeks(w.toLong()).plusDays(d.toLong())
                    val rec = byDay[date]
                    val (fg, bg) = if (rec != null) statusColors(rec.status) else (Ink500 to Wash)
                    Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                        Box(
                            Modifier
                                .size(34.dp)
                                .clip(CircleShape)
                                .background(if (date.isAfter(today)) Color.Transparent else bg),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                date.dayOfMonth.toString(),
                                style = MaterialTheme.typography.labelSmall.tabular(),
                                color = if (date.isAfter(today)) Ink500.copy(alpha = 0.4f) else fg
                            )
                        }
                    }
                }
            }
        }
        Spacer(Modifier.height(2.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(Space.md), verticalAlignment = Alignment.CenterVertically) {
            Legend("حاضر", Positive)
            Legend("متأخر/بعذر", Caution)
            Legend("غائب", Negative)
        }
    }
}

@Composable
private fun Legend(text: String, color: Color) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(8.dp).clip(CircleShape).background(color))
        Spacer(Modifier.width(4.dp))
        Text(text, style = MaterialTheme.typography.labelSmall, color = Ink700)
    }
}

@Composable
private fun RecordRow(r: AttendanceRecord) {
    val (fg, bg) = statusColors(r.status)
    val d = Fmt.parseDate(r.date)
    Row(
        Modifier.fillMaxWidth().padding(horizontal = Space.lg, vertical = Space.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(
                if (d != null) Fmt.fullDate(d) else r.date,
                style = MaterialTheme.typography.bodyMedium,
                color = Ink900
            )
            if (!r.reason.isNullOrBlank()) {
                Text("السبب: ${r.reason}", style = MaterialTheme.typography.bodySmall, color = Ink500)
            }
        }
        Pill(statusLabel(r.status), fg, bg)
    }
}
