package sd.alumrabi.parent.util

import sd.alumrabi.parent.data.model.AttendanceRecord
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.data.model.PublishedGrade
import sd.alumrabi.parent.data.model.ScheduleEntry
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.Locale

object Terms {
    fun label(code: String): String = when (code) {
        "term_1" -> "الفصل الأول"
        "term_2" -> "الفصل الثاني"
        "annual" -> "السنوي"
        "midterm" -> "منتصف الفصل"
        "final" -> "الامتحان النهائي"
        "" -> "—"
        else -> code
    }
}

enum class Tone { Great, Good, Okay, Low }

data class Band(val label: String, val tone: Tone)

fun bandFor(percent: Double): Band = when {
    percent >= 85 -> Band("ممتاز", Tone.Great)
    percent >= 75 -> Band("جيد جداً", Tone.Good)
    percent >= 65 -> Band("جيد", Tone.Good)
    percent >= 50 -> Band("مقبول", Tone.Okay)
    else -> Band("دون المستوى", Tone.Low)
}

/** النسبة المئوية للدرجة؛ null للغياب أو عدم الرصد. */
fun PublishedGrade.percent(): Double? {
    val s = score ?: return null
    if (isAbsent || maxScore <= 0.0) return null
    return (s / maxScore) * 100.0
}

fun PublishedGrade.passed(): Boolean? {
    val s = score ?: return null
    if (isAbsent) return null
    return s >= passScore
}

data class SubjectStat(
    val subject: String,
    val averagePercent: Double?,
    val count: Int,
    val failed: Int,
    val items: List<PublishedGrade>
)

fun List<PublishedGrade>?.bySubject(): List<SubjectStat> =
    this.orEmpty().groupBy { it.subjectName }.map { (subject, items) ->
        val pcts = items.mapNotNull { it.percent() }
        SubjectStat(
            subject = subject,
            averagePercent = if (pcts.isEmpty()) null else pcts.average(),
            count = items.size,
            failed = items.count { it.passed() == false },
            items = items
        )
    }.sortedBy { it.subject }

fun List<PublishedGrade>?.overallPercent(): Double? {
    val p = this.orEmpty().mapNotNull { it.percent() }
    return if (p.isEmpty()) null else p.average()
}

fun List<AttendanceRecord>?.byDate(): Map<LocalDate, AttendanceRecord> =
    this.orEmpty().mapNotNull { r -> Fmt.parseDate(r.date)?.let { it to r } }.toMap()

/** أيام حضور متتالية حتى آخر سجل (التأخر يُحسب حضوراً). */
fun List<AttendanceRecord>?.presentStreak(): Int {
    var n = 0
    for (r in this.orEmpty().sortedByDescending { it.date }) {
        if (r.status == "present" || r.status == "late") n++ else break
    }
    return n
}

fun List<AttendanceRecord>?.recentAbsences(days: Int = 14, today: LocalDate = LocalDate.now()): Int {
    val from = today.minusDays(days.toLong())
    return this.orEmpty().count { r ->
        val d = Fmt.parseDate(r.date)
        r.status == "absent" && d != null && !d.isBefore(from)
    }
}

fun List<ScheduleEntry>?.forDay(weekday: Int): List<ScheduleEntry> =
    this.orEmpty().filter { it.weekday == weekday }.sortedWith(compareBy({ it.startsAt }, { it.periodOrder }))

private fun hhmm(now: LocalDateTime): String = String.format(Locale.US, "%02d:%02d", now.hour, now.minute)

/** الحصة الجارية أو التالية اليوم (تُهمل الفسحات)؛ null إن لم يبقَ شيء اليوم. */
fun List<ScheduleEntry>?.nextClass(now: LocalDateTime = LocalDateTime.now()): ScheduleEntry? {
    val t = hhmm(now)
    return forDay(Fmt.weekdayIndexSun0(now.toLocalDate())).firstOrNull { !it.isBreak && it.endsAt > t }
}

fun ScheduleEntry.isNow(now: LocalDateTime = LocalDateTime.now()): Boolean {
    if (weekday != Fmt.weekdayIndexSun0(now.toLocalDate())) return false
    val t = hhmm(now)
    return startsAt <= t && t < endsAt
}

/** نصوص المشاركة (تقارير مبنية على البيانات المعتمدة فقط). */
object Reports {
    fun grades(child: LinkedChild): String {
        val sb = StringBuilder()
        sb.append("تقرير النتائج — ").append(child.fullName).append('\n')
        sb.append(child.gradeName).append(" · ").append(child.sectionName).append('\n')
        val overall = child.grades.overallPercent()
        if (overall != null) sb.append("المعدل العام: ").append(Fmt.percent(overall)).append(" (").append(bandFor(overall).label).append(")\n")
        sb.append('\n')
        child.grades.bySubject().forEach { s ->
            val avg = s.averagePercent?.let { Fmt.percent(it) } ?: "—"
            sb.append("• ").append(s.subject).append(": ").append(avg).append('\n')
            s.items.forEach { g ->
                val sc = g.score
                val line = when {
                    g.isAbsent -> "غائب"
                    sc != null -> Fmt.score(sc) + " / " + Fmt.score(g.maxScore)
                    else -> "قيد الرصد"
                }
                sb.append("   - ").append(g.title).append(" (").append(Terms.label(g.term)).append("): ").append(line).append('\n')
            }
        }
        sb.append("\nمصدر البيانات: تطبيق العمرابي")
        return sb.toString()
    }

    fun attendance(child: LinkedChild): String {
        val s = child.attendance.attendanceSummary()
        val sb = StringBuilder()
        sb.append("ملخص الحضور — ").append(child.fullName).append('\n')
        sb.append(child.gradeName).append(" · ").append(child.sectionName).append('\n')
        sb.append("نسبة الحضور: ").append(s.ratePercent?.let { "$it%" } ?: "—").append('\n')
        sb.append("أيام الحضور: ").append(s.attended).append(" · الغياب: ").append(s.absent).append('\n')
        sb.append("\nمصدر البيانات: تطبيق العمرابي")
        return sb.toString()
    }

    fun receipt(child: LinkedChild, amount: Double, number: String, date: String, method: String): String =
        "إيصال سداد رسوم\nالطالب: ${child.fullName}\nالمبلغ: ${Fmt.money(amount)}\nطريقة الدفع: $method\nالتاريخ: $date\nرقم الإيصال: $number\n\nمصدر البيانات: تطبيق العمرابي"
}
