package sd.alumrabi.parent.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.draw.clip
import androidx.compose.material.icons.outlined.MenuBook
import sd.alumrabi.parent.util.TimeFmt
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Grade
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt
import sd.alumrabi.parent.util.Reports
import sd.alumrabi.parent.util.Terms
import sd.alumrabi.parent.util.bandFor
import sd.alumrabi.parent.util.bySubject
import sd.alumrabi.parent.util.overallPercent
import sd.alumrabi.parent.util.passed
import sd.alumrabi.parent.util.percent
import sd.alumrabi.parent.util.shareText

@Composable
fun GradesScreen(
    children: List<LinkedChild>,
    selectedChildIndex: Int,
    onOpenSubjects: (() -> Unit)? = null,
    onSelectChild: (Int) -> Unit
) {
    SystemBars(statusBar = Canvas, darkIcons = true)
    val context = LocalContext.current
    val child = children.getOrNull(selectedChildIndex)
    val allGrades = child?.grades.orEmpty()
    val years = allGrades.mapNotNull { it.academicYear }.distinct().sortedDescending()
    var yearSel by remember(selectedChildIndex) { mutableStateOf<String?>(null) }
    val year = yearSel?.takeIf { it in years } ?: years.firstOrNull()
    val shownGrades = if (year == null) allGrades else allGrades.filter { it.academicYear == year || it.academicYear == null }
    val prevYear = year?.let { y -> years.getOrNull(years.indexOf(y) + 1) }
    val prevAvg = prevYear?.let { py -> allGrades.filter { it.academicYear == py }.bySubject().associate { it.subject to it.averagePercent } } ?: emptyMap()
    val subjects = shownGrades.bySubject()
    val overall = shownGrades.overallPercent()
    var expanded by remember(selectedChildIndex) { mutableStateOf<String?>(null) }
    var trendScope by remember(selectedChildIndex) { mutableStateOf<String?>(null) }

    Column(Modifier.fillMaxSize().background(Canvas).statusBarsPadding()) {
        ScreenHeader(
            title = "النتائج",
            subtitle = child?.fullName,
            modifier = Modifier.padding(horizontal = Space.gutter)
        ) {
            if (child != null && subjects.isNotEmpty()) {
                CircleIconButton(
                    icon = Icons.Outlined.Share,
                    description = "مشاركة تقرير النتائج",
                    onClick = { shareText(context, "تقرير النتائج", Reports.grades(child)) }
                )
            }
        }
        ChildChips(children, selectedChildIndex, onSelectChild, Modifier.padding(vertical = Space.sm))
        if (child == null) {
            StatePanel("لا يوجد ابن مرتبط", noChildMessage(), Modifier.padding(Space.gutter))
        } else if (subjects.isEmpty()) {
            EmptyNote(
                Icons.Outlined.Grade,
                "لا نتائج منشورة بعد",
                "تظهر النتائج هنا فور اعتمادها ونشرها من إدارة المدرسة.",
                Modifier.padding(Space.gutter)
            )
        } else {
            LazyColumn(
                contentPadding = PaddingValues(horizontal = Space.gutter, vertical = Space.sm),
                verticalArrangement = Arrangement.spacedBy(Space.md)
            ) {
                if (overall != null) {
                    item {
                        Reveal(0) {
                            val band = bandFor(overall)
                            val (fg, bg) = toneColors(band.tone)
                            Panel {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    ProgressRing(progress = (overall / 100.0).toFloat(), ringSize = 88.dp, color = fg) {
                                        Text(
                                            Fmt.percent(overall),
                                            style = MaterialTheme.typography.titleMedium.tabular(),
                                            color = Ink900
                                        )
                                    }
                                    Spacer(Modifier.width(Space.lg))
                                    Column(Modifier.weight(1f)) {
                                        Text("المعدل العام", style = MaterialTheme.typography.labelMedium, color = Ink500)
                                        Spacer(Modifier.height(4.dp))
                                        Pill(band.label, fg, bg)
                                        Spacer(Modifier.height(6.dp))
                                        Text(
                                            "${subjects.size} مواد · ${subjects.sumOf { it.count }} نتيجة",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = Ink700
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                if (years.size > 1) {
                    item {
                        Row(
                            Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(Space.sm)
                        ) {
                            years.forEach { y -> YearChip("سنة " + y, y == year) { yearSel = y } }
                        }
                    }
                }
                if (onOpenSubjects != null) {
                    item {
                        GroupedList {
                            ListRow(
                                title = "مواد الفصل وأساتذتها",
                                subtitle = "المواد التي يدرسها ابنك وأسماء أساتذتها",
                                leading = Icons.Outlined.MenuBook,
                                onClick = onOpenSubjects
                            )
                        }
                    }
                }
                item {
                    Reveal(1) {
                        TrendPanel(
                            grades = shownGrades,
                            subjects = subjects.map { it.subject },
                            scope = trendScope,
                            onScope = { trendScope = it }
                        )
                    }
                }
                items(subjects, key = { it.subject }) { s ->
                    val avg = s.averagePercent
                    val band = avg?.let { bandFor(it) }
                    val (fg, bg) = if (band != null) toneColors(band.tone) else (Ink700 to Wash)
                    val open = expanded == s.subject
                    Panel(onClick = { expanded = if (open) null else s.subject }) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text(s.subject, style = MaterialTheme.typography.titleMedium, color = Ink900)
                                Text(
                                    "${s.count} نتيجة" + if (s.failed > 0) " · ${s.failed} دون النجاح" else "",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Ink500
                                )
                                val lastAt = s.items.mapNotNull { it.gradedAt }.maxOrNull()
                                TimeFmt.dateTime(lastAt)?.let {
                                    Text("آخر رصد: " + it, style = MaterialTheme.typography.bodySmall, color = Ink500)
                                }
                                val pv = prevAvg[s.subject]
                                if (pv != null && avg != null && prevYear != null) {
                                    val d = avg - pv
                                    Text(
                                        prevYear + ": " + Fmt.percent(pv) + " (" + (if (d >= 0) "▲ " else "▼ ") + Fmt.percent(kotlin.math.abs(d)) + ")",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Ink700
                                    )
                                }
                            }
                            if (avg != null && band != null) {
                                Text(
                                    Fmt.percent(avg),
                                    style = MaterialTheme.typography.titleMedium.tabular(),
                                    color = fg
                                )
                                Spacer(Modifier.width(Space.sm))
                                Pill(band.label, fg, bg)
                            }
                        }
                        if (avg != null) {
                            Spacer(Modifier.height(Space.md))
                            FillBar(fraction = (avg / 100.0).toFloat(), color = fg)
                        }
                        AnimatedVisibility(visible = open) {
                            Column {
                                Spacer(Modifier.height(Space.md))
                                s.items.sortedByDescending { it.gradedAt ?: "" }.forEach { g ->
                                    RowDivider()
                                    Row(
                                        Modifier.fillMaxWidth().padding(vertical = Space.sm),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Column(Modifier.weight(1f)) {
                                            Row(verticalAlignment = Alignment.CenterVertically) {
                                                Text(g.title, style = MaterialTheme.typography.bodyMedium, color = Ink900)
                                                if (TimeFmt.isRecent(g.gradedAt)) {
                                                    Spacer(Modifier.width(6.dp))
                                                    Pill("جديد", Positive, PositiveBg)
                                                }
                                            }
                                            Text(
                                                Terms.label(g.term) + (TimeFmt.dateTime(g.gradedAt)?.let { " · رُصدت " + it } ?: ""),
                                                style = MaterialTheme.typography.bodySmall,
                                                color = Ink500
                                            )
                                        }
                                        val sc = g.score
                                        when {
                                            g.isAbsent -> Pill("غائب", Caution, CautionBg)
                                            sc == null -> Pill("قيد الرصد", Ink700, Wash)
                                            else -> {
                                                val ok = g.passed() != false
                                                Text(
                                                    Fmt.score(sc) + " / " + Fmt.score(g.maxScore),
                                                    style = MaterialTheme.typography.titleSmall.tabular(),
                                                    color = if (ok) Ink900 else Negative
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                item { Spacer(Modifier.height(Space.lg)) }
            }
        }
    }
}

@Composable
private fun YearChip(label: String, selected: Boolean, onClick: () -> Unit) {
    Box(
        Modifier
            .clip(CircleShape)
            .background(if (selected) Crimson600 else Paper)
            .clickable(onClick = onClick)
            .padding(horizontal = Space.lg, vertical = Space.sm)
    ) {
        Text(label, style = MaterialTheme.typography.labelLarge, color = if (selected) OnBrand else Ink900)
    }
}
