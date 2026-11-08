package sd.alumrabi.parent.util

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.Locale

/** تنسيقات موحّدة: أرقام لاتينية (0-9) وأسماء أشهر عربية في كل التطبيق، دون اعتماد على لغة الجهاز. */
object Fmt {
    private val months = listOf(
        "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
        "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
    )

    // DayOfWeek.value: 1 = الاثنين ... 7 = الأحد
    private val weekdays = listOf("الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت", "الأحد")

    fun parseDate(raw: String?): LocalDate? {
        if (raw.isNullOrBlank() || raw.length < 10) return null
        return try {
            LocalDate.parse(raw.substring(0, 10))
        } catch (_: Exception) {
            null
        }
    }

    fun monthName(date: LocalDate): String = months[date.monthValue - 1]
    fun weekdayName(date: LocalDate): String = weekdays[date.dayOfWeek.value - 1]

    fun dayMonth(date: LocalDate): String = "${date.dayOfMonth} ${monthName(date)}"
    fun fullDate(date: LocalDate): String = "${weekdayName(date)} ${date.dayOfMonth} ${monthName(date)}"
    fun longDate(date: LocalDate): String = "${date.dayOfMonth} ${monthName(date)} ${date.year}"
    fun monthYear(date: LocalDate): String = "${monthName(date)} ${date.year}"

    fun dateOrRaw(raw: String?): String {
        val d = parseDate(raw)
        return if (d != null) longDate(d) else (raw ?: "")
    }

    /** «اليوم 2:30 م» / «أمس 9:05 ص» / «3 نوفمبر 11:00 ص». */
    fun lastSync(millis: Long): String {
        if (millis <= 0L) return "لم تتم المزامنة بعد"
        val zone = ZoneId.systemDefault()
        val dt = Instant.ofEpochMilli(millis).atZone(zone)
        val hour24 = dt.hour
        val hour12 = if (hour24 % 12 == 0) 12 else hour24 % 12
        val suffix = if (hour24 < 12) "ص" else "م"
        val time = String.format(Locale.US, "%d:%02d %s", hour12, dt.minute, suffix)
        val today = LocalDate.now(zone)
        val date = dt.toLocalDate()
        return when (date) {
            today -> "اليوم $time"
            today.minusDays(1) -> "أمس $time"
            else -> "${dayMonth(date)} $time"
        }
    }

    fun number(value: Double): String = String.format(Locale.US, "%,.0f", value)

    fun score(value: Double): String =
        if (value % 1.0 == 0.0) value.toLong().toString() else String.format(Locale.US, "%.1f", value)

    fun percent(value: Double): String = String.format(Locale.US, "%.0f", value) + "%"

    fun firstName(full: String): String =
        full.trim().split(Regex("\\s+")).firstOrNull().orEmpty().ifBlank { "ولي الأمر" }

    fun shortName(full: String, words: Int = 2): String =
        full.trim().split(Regex("\\s+")).take(words).joinToString(" ")

    /** صيغة العدد العربية: واحد / مثنى / 3-10 جمع قلة / 11+ تمييز مفرد منصوب. */
    fun plural(n: Int, one: String, two: String, few: String, many: String): String = when {
        n == 1 -> one
        n == 2 -> two
        n in 3..10 -> "$n $few"
        else -> "$n $many"
    }

    fun days(n: Int): String = plural(n, "يوم واحد", "يومان", "أيام", "يوماً")

    fun money(value: Double): String = number(value) + " جنيه"

    /** 0 = الأحد ... 6 = السبت (نفس ترقيم قاعدة البيانات). */
    private val weekdaysSun0 = listOf("الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت")
    fun weekdayNameSun0(weekday: Int): String = weekdaysSun0.getOrElse(weekday) { "" }
    fun weekdayIndexSun0(date: LocalDate): Int = date.dayOfWeek.value % 7

    /** «اليوم» / «غداً» / «بعد 5 أيام» / «منذ يومين». */
    fun relativeDay(date: LocalDate, today: LocalDate = LocalDate.now()): String {
        val diff = (date.toEpochDay() - today.toEpochDay()).toInt()
        return when {
            diff == 0 -> "اليوم"
            diff == 1 -> "غداً"
            diff == 2 -> "بعد يومين"
            diff in 3..10 -> "بعد $diff أيام"
            diff > 10 -> "بعد $diff يوماً"
            diff == -1 -> "أمس"
            diff == -2 -> "منذ يومين"
            else -> "منذ " + days(-diff)
        }
    }

    /** «07:45» → «7:45 ص». */
    fun time12(hhmm: String): String {
        val parts = hhmm.split(":")
        val h = parts.getOrNull(0)?.toIntOrNull() ?: return hhmm
        val m = parts.getOrNull(1)?.toIntOrNull() ?: 0
        val h12 = if (h % 12 == 0) 12 else h % 12
        return String.format(Locale.US, "%d:%02d %s", h12, m, if (h < 12) "ص" else "م")
    }

    /** صلة ولي الأمر بالطالب كما تُخزَّن في قاعدة البيانات. */
    fun relation(code: String?): String = when (code) {
        "father" -> "الأب"
        "mother" -> "الأم"
        "brother" -> "الأخ"
        "uncle" -> "العم/الخال"
        "legal_guardian" -> "الوصي"
        "other" -> "قريب"
        null, "" -> "ولي الأمر"
        else -> code
    }

    fun studentStatus(code: String): String = when (code) {
        "active" -> "منتظم"
        "transferred_out" -> "منقول"
        "withdrawn" -> "منسحب"
        "graduated" -> "متخرج"
        "suspended" -> "موقوف"
        else -> code
    }
}
