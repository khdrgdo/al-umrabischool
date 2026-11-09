package sd.alumrabi.parent.util

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.provider.CalendarContract
import android.widget.Toast
import java.time.LocalDate
import java.time.ZoneOffset

fun shareText(context: Context, title: String, text: String) {
    val send = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_SUBJECT, title)
        putExtra(Intent.EXTRA_TEXT, text)
    }
    val chooser = Intent.createChooser(send, title).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    try {
        context.startActivity(chooser)
    } catch (_: Exception) {
        Toast.makeText(context, "تعذر فتح المشاركة", Toast.LENGTH_SHORT).show()
    }
}

fun addToCalendar(context: Context, title: String, description: String?, start: LocalDate, end: LocalDate?) {
    val begin = start.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
    val finish = (end ?: start).plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
    val intent = Intent(Intent.ACTION_INSERT).apply {
        data = CalendarContract.Events.CONTENT_URI
        putExtra(CalendarContract.Events.TITLE, title)
        if (!description.isNullOrBlank()) putExtra(CalendarContract.Events.DESCRIPTION, description)
        putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, true)
        putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, begin)
        putExtra(CalendarContract.EXTRA_EVENT_END_TIME, finish)
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    try {
        context.startActivity(intent)
    } catch (_: ActivityNotFoundException) {
        Toast.makeText(context, "لا يوجد تطبيق تقويم على هذا الجهاز", Toast.LENGTH_SHORT).show()
    }
}
