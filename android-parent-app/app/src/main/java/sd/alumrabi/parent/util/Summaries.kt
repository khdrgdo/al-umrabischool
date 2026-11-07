package sd.alumrabi.parent.util

import sd.alumrabi.parent.data.model.AttendanceRecord
import sd.alumrabi.parent.data.model.CalendarEventItem
import sd.alumrabi.parent.data.model.PublishedGrade
import java.time.LocalDate
import kotlin.math.roundToInt

data class AttendanceSummary(
    val total: Int,
    val present: Int,
    val absent: Int,
    val late: Int,
    val excused: Int
) {
    val attended: Int get() = present + late
    val ratePercent: Int? get() = if (total == 0) null else ((attended * 100.0) / total).roundToInt()
}

fun List<AttendanceRecord>?.attendanceSummary(): AttendanceSummary {
    val list = this.orEmpty()
    return AttendanceSummary(
        total = list.size,
        present = list.count { it.status == "present" },
        absent = list.count { it.status == "absent" },
        late = list.count { it.status == "late" },
        excused = list.count { it.status == "excused" }
    )
}

data class GradesSummary(
    val count: Int,
    val averagePercent: Double?,
    val failed: Int
)

/** متوسط النسب المئوية (الدرجة ÷ الدرجة العظمى) للنتائج المرصودة فقط؛ الغياب لا يدخل في المتوسط. */
fun List<PublishedGrade>?.gradesSummary(): GradesSummary {
    val list = this.orEmpty()
    val scored = list.filter { !it.isAbsent && it.score != null && it.maxScore > 0.0 }
    val average = if (scored.isEmpty()) null else scored.map { ((it.score ?: 0.0) / it.maxScore) * 100.0 }.average()
    val failed = scored.count { (it.score ?: 0.0) < it.passScore }
    return GradesSummary(count = list.size, averagePercent = average, failed = failed)
}

/** الفعاليات التي لم تنتهِ بعد، مرتبة بتاريخ البدء. */
fun List<CalendarEventItem>.upcoming(today: LocalDate = LocalDate.now()): List<CalendarEventItem> =
    filter {
        val end = Fmt.parseDate(it.endsOn) ?: Fmt.parseDate(it.startsOn)
        end == null || !end.isBefore(today)
    }.sortedBy { it.startsOn }
