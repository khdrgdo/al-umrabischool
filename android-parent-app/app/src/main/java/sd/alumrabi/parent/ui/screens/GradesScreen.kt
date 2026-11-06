package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.data.model.PublishedGrade
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt
import sd.alumrabi.parent.util.gradesSummary

@Composable
fun GradesScreen(
    children: List<LinkedChild>,
    selectedChildIndex: Int,
    onSelectChild: (Int) -> Unit,
    onSelectTab: (AppTab) -> Unit
) {
    SystemBars(statusBar = Canvas, darkIcons = true)
    val child = children.getOrNull(selectedChildIndex)
    val grades = child?.grades.orEmpty()

    Scaffold(
        containerColor = Canvas,
        topBar = { OmrabiTopBar(title = "النتائج", subtitle = child?.fullName) },
        bottomBar = { OmrabiBottomBar(currentRoute = Routes.Results, onSelect = onSelectTab) }
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
            } else if (grades.isEmpty()) {
                item {
                    StatePanel(
                        title = "لم تُنشر نتائج بعد",
                        message = "تظهر النتائج هنا بعد اعتمادها ونشرها من إدارة المدرسة."
                    )
                }
            } else {
                val summary = grades.gradesSummary()
                item {
                    StatStrip(
                        stats = listOf(
                            Stat("${summary.count}", "نتيجة منشورة"),
                            Stat(summary.averagePercent?.let { Fmt.percent(it) } ?: "—", "متوسط النسب"),
                            Stat("${summary.failed}", "دون درجة النجاح")
                        )
                    )
                }
                grades.groupBy { it.subjectName }.forEach { (subject, items) ->
                    item { SectionLabel(subject) }
                    item {
                        GroupedList {
                            items.forEachIndexed { index, grade ->
                                if (index > 0) RowDivider()
                                GradeRow(grade)
                            }
                        }
                    }
                }
                item { Spacer(Modifier.height(Space.sm)) }
            }
        }
    }
}

@Composable
private fun GradeRow(grade: PublishedGrade) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 56.dp)
            .padding(horizontal = Space.lg, vertical = Space.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(grade.title, style = MaterialTheme.typography.bodyLarge, color = Ink900)
            if (grade.term.isNotBlank()) {
                Text(grade.term, style = MaterialTheme.typography.bodySmall, color = Ink500)
            }
        }
        val score = grade.score
        if (grade.isAbsent) {
            StatusLabel("غائب", Negative, NegativeBg)
        } else if (score != null) {
            val pass = score >= grade.passScore
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    "${Fmt.score(score)} / ${Fmt.score(grade.maxScore)}",
                    style = MaterialTheme.typography.titleSmall.tabular(),
                    color = if (pass) Positive else Negative
                )
                Text(
                    if (pass) "ناجح" else "راسب",
                    style = MaterialTheme.typography.labelMedium,
                    color = if (pass) Positive else Negative
                )
            }
        } else {
            Text("قيد الرصد", style = MaterialTheme.typography.bodySmall, color = Ink500)
        }
    }
}
