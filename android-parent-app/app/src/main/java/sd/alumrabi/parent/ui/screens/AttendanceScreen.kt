package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.data.model.AttendanceRecord
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt
import sd.alumrabi.parent.util.attendanceSummary

@Composable
fun AttendanceScreen(
    children: List<LinkedChild>,
    selectedChildIndex: Int,
    onSelectChild: (Int) -> Unit,
    onSelectTab: (AppTab) -> Unit
) {
    SystemBars(statusBar = Canvas, darkIcons = true)
    val child = children.getOrNull(selectedChildIndex)
    val records = child?.attendance.orEmpty().sortedByDescending { it.date }

    Scaffold(
        containerColor = Canvas,
        topBar = { OmrabiTopBar(title = "الحضور والغياب", subtitle = child?.fullName) },
        bottomBar = { OmrabiBottomBar(currentRoute = Routes.Attendance, onSelect = onSelectTab) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(horizontal = Space.gutter, vertical = Space.lg),
            verticalArrangement = Arrangement.spacedBy(Space.sm)
        ) {
            if (children.size > 1) {
                item { ChildSwitcher(children, selectedChildIndex, onSelectChild) }
            }
            if (child == null) {
                item { StatePanel(title = "لا يوجد ابن مرتبط", message = noChildMessage()) }
            } else if (records.isEmpty()) {
                item {
                    StatePanel(
                        title = "لا يوجد سجل حضور بعد",
                        message = "لم يُسجَّل حضور لهذا الطالب حتى الآن. يظهر السجل هنا بعد اعتماده من المدرسة."
                    )
                }
            } else {
                val s = records.attendanceSummary()
                item {
                    StatStrip(
                        stats = listOf(
                            Stat(s.ratePercent?.let { "$it%" } ?: "—", "نسبة الحضور"),
                            Stat("${s.attended}", "أيام الحضور"),
                            Stat("${s.absent}", "أيام الغياب")
                        )
                    )
                }
                // مجموعة لكل شهر (السجل مرتب من الأحدث للأقدم)
                val groups = records.groupBy { it.date.take(7) }
                groups.forEach { (_, list) ->
                    val first = Fmt.parseDate(list.first().date)
                    item { SectionLabel(if (first != null) Fmt.monthYear(first) else "تاريخ غير محدد") }
                    item {
                        GroupedList {
                            list.forEachIndexed { index, record ->
                                if (index > 0) RowDivider()
                                AttendanceRow(record)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun AttendanceRow(record: AttendanceRecord) {
    val date = Fmt.parseDate(record.date)
    val (label, fg, bg) = when (record.status) {
        "present" -> Triple("حاضر", Ink700, Wash)
        "absent" -> Triple("غائب", Negative, NegativeBg)
        "late" -> Triple("متأخر", Caution, CautionBg)
        "excused" -> Triple("بعذر", Caution, CautionBg)
        else -> Triple(record.status, Ink700, Wash)
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 52.dp)
            .padding(horizontal = Space.lg, vertical = Space.sm),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(
                if (date != null) Fmt.fullDate(date) else record.date,
                style = MaterialTheme.typography.bodyLarge,
                color = Ink900
            )
            if (!record.reason.isNullOrBlank()) {
                Text("السبب: ${record.reason}", style = MaterialTheme.typography.bodySmall, color = Ink500)
            }
        }
        StatusLabel(label, fg, bg)
    }
}
