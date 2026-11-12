package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.MenuBook
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt
import sd.alumrabi.parent.util.bandFor
import sd.alumrabi.parent.util.bySubject

/** مواد الفصل لشعبة الابن وأسماء أساتذتها (من تكليفات التدريس المعتمدة). */
@Composable
fun SubjectsScreen(
    children: List<LinkedChild>,
    selectedChildIndex: Int,
    onSelectChild: (Int) -> Unit,
    onBack: () -> Unit
) {
    SystemBars(statusBar = Canvas, darkIcons = true)
    val child = children.getOrNull(selectedChildIndex)
    val subjects = child?.subjects.orEmpty()
    val allGrades = child?.grades.orEmpty()
    val latestYear = allGrades.mapNotNull { it.academicYear }.maxOrNull()
    val currentGrades = if (latestYear == null) allGrades else allGrades.filter { it.academicYear == latestYear || it.academicYear == null }
    val avgBySubject = currentGrades.bySubject().associate { it.subject to it.averagePercent }

    Column(Modifier.fillMaxSize().background(Canvas)) {
        OmrabiTopBar(title = "مواد الفصل وأساتذتها", onBack = onBack)
        ChildChips(children, selectedChildIndex, onSelectChild, Modifier.padding(vertical = Space.sm))
        when {
            child == null -> StatePanel("لا يوجد ابن مرتبط", noChildMessage(), Modifier.padding(Space.gutter))
            subjects.isEmpty() -> EmptyNote(
                Icons.Outlined.MenuBook,
                "لم تُسجَّل المواد بعد",
                "ستظهر هنا مواد " + child.fullName + " وأسماء أساتذتها حين تعتمدها الإدارة.",
                Modifier.padding(Space.gutter)
            )
            else -> LazyColumn(
                contentPadding = PaddingValues(horizontal = Space.gutter, vertical = Space.sm),
                verticalArrangement = Arrangement.spacedBy(Space.md)
            ) {
                item {
                    Text(
                        child.gradeName + " · " + child.sectionName + " — " + subjects.size + " مواد",
                        style = MaterialTheme.typography.labelMedium,
                        color = Ink500
                    )
                }
                items(subjects) { s ->
                    val avg = avgBySubject[s.subjectName]
                    val band = avg?.let { bandFor(it) }
                    Panel {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text(s.subjectName, style = MaterialTheme.typography.titleMedium, color = Ink900)
                                Text(
                                    "الأستاذ: " + (s.teacherName?.takeIf { it.isNotBlank() } ?: "لم يُعيَّن بعد"),
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = Ink700
                                )
                                if (s.weeklyPeriods > 0) {
                                    Text(
                                        s.weeklyPeriods.toString() + " حصص في الأسبوع",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Ink500
                                    )
                                }
                            }
                            if (avg != null && band != null) {
                                val (fg, bg) = toneColors(band.tone)
                                Text(Fmt.percent(avg), style = MaterialTheme.typography.titleSmall.tabular(), color = fg)
                                Spacer(Modifier.width(Space.sm))
                                Pill(band.label, fg, bg)
                            }
                        }
                    }
                }
                item { Spacer(Modifier.padding(top = Space.lg)) }
            }
        }
    }
}
