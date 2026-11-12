package sd.alumrabi.parent.util

import java.time.Instant
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.ZonedDateTime

/** تنسيق الأوقات القادمة من الخادم (UTC) بتوقيت السودان. */
object TimeFmt {
    private val zone: ZoneId = ZoneId.of("Africa/Khartoum")
    private val months = arrayOf(
        "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
        "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
    )

    fun parse(iso: String?): ZonedDateTime? {
        if (iso.isNullOrBlank()) return null
        return runCatching { OffsetDateTime.parse(iso).atZoneSameInstant(zone) }.getOrNull()
            ?: runCatching { Instant.parse(iso).atZone(zone) }.getOrNull()
    }

    /** مثال: 8 نوفمبر 2026، 3:05 م */
    fun dateTime(iso: String?): String? {
        val z = parse(iso) ?: return null
        val h = z.hour
        val h12 = when {
            h == 0 -> 12
            h > 12 -> h - 12
            else -> h
        }
        val ap = if (h < 12) "ص" else "م"
        val min = if (z.minute < 10) "0" + z.minute else z.minute.toString()
        return z.dayOfMonth.toString() + " " + months[z.monthValue - 1] + " " + z.year + "، " + h12 + ":" + min + " " + ap
    }

    fun isRecent(iso: String?, days: Long = 3): Boolean {
        val z = parse(iso) ?: return false
        return z.toInstant().isAfter(Instant.now().minusSeconds(days * 86_400L))
    }
}
