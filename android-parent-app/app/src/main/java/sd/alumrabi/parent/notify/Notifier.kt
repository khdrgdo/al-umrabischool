package sd.alumrabi.parent.notify

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.time.LocalDate
import java.util.concurrent.TimeUnit
import sd.alumrabi.parent.R
import sd.alumrabi.parent.data.model.DashboardPayload
import sd.alumrabi.parent.data.model.PublishedGrade

object Notifier {
    const val CHANNEL_ID = "alumrabi_updates"
    private const val WORK_NAME = "alumrabi_updates_check"

    fun ensureChannel(ctx: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) == null) {
            val ch = NotificationChannel(CHANNEL_ID, "تحديثات المدرسة", NotificationManager.IMPORTANCE_DEFAULT)
            ch.description = "الإعلانات والمواعيد والنتائج والدفعات وتنبيهات الغياب"
            nm.createNotificationChannel(ch)
        }
    }

    /** فحص دوري في الخلفية كل 15 دقيقة (أدنى فاصل يسمح به أندرويد) عند توفر الإنترنت. */
    fun schedule(ctx: Context) {
        val request = PeriodicWorkRequestBuilder<NotificationWorker>(15, TimeUnit.MINUTES)
            .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
            .build()
        WorkManager.getInstance(ctx.applicationContext)
            .enqueueUniquePeriodicWork(WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, request)
    }

    fun cancel(ctx: Context) {
        WorkManager.getInstance(ctx.applicationContext).cancelUniqueWork(WORK_NAME)
    }

    fun gradeKey(childId: String, g: PublishedGrade): String = "g:" + childId + ":" + g.subjectName + "|" + g.title + "|" + g.term

    private fun num(d: Double): String = if (d % 1.0 == 0.0) d.toLong().toString() else String.format(java.util.Locale.US, "%.1f", d)

    /** مفاتيح العناصر الحالية: a: إعلان، e: موعد، abs: غياب اليوم لابن مفعّلة له الإشعارات. */
    fun keys(payload: DashboardPayload): Set<String> {
        val today = LocalDate.now().toString()
        val set = HashSet<String>()
        payload.announcements.forEach { set.add("a:" + it.id) }
        payload.events.forEach { set.add("e:" + it.id) }
        payload.children.forEach { c ->
            val absentToday = c.attendance.orEmpty().any { it.status == "absent" && it.date.startsWith(today) }
            if (c.receivesNotifications && absentToday) set.add("abs:" + c.id + ":" + today)
            if (c.receivesNotifications) {
                c.grades.orEmpty().filter { it.score != null && !it.isAbsent }.forEach { set.add(gradeKey(c.id, it)) }
                if (c.canViewFees) c.fees?.payments.orEmpty().forEach { set.add("p:" + c.id + ":" + it.receiptNumber) }
            }
        }
        return set
    }

    fun post(ctx: Context, payload: DashboardPayload, fresh: Set<String>) {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return
        ensureChannel(ctx)

        val items = ArrayList<Pair<String, String>>()
        payload.announcements.filter { "a:" + it.id in fresh }.forEach {
            val prefix = if (it.priority == "urgent") "إعلان عاجل: " else ""
            items.add((prefix + it.title) to it.body)
        }
        payload.events.filter { "e:" + it.id in fresh }.forEach {
            items.add(("موعد جديد: " + it.title) to (it.description ?: it.startsOn))
        }
        val today = LocalDate.now().toString()
        payload.children.filter { "abs:" + it.id + ":" + today in fresh }.forEach {
            items.add("تنبيه غياب" to (it.fullName + " مسجَّل غائباً اليوم"))
        }
        payload.children.filter { it.receivesNotifications }.forEach { c ->
            val gs = c.grades.orEmpty().filter { gradeKey(c.id, it) in fresh }
            if (gs.size == 1) {
                val g = gs[0]
                items.add(("نتيجة جديدة: " + g.subjectName) to (c.fullName + " — " + g.title + ": " + num(g.score ?: 0.0) + " / " + num(g.maxScore)))
            } else if (gs.size > 1) {
                items.add(("نتائج جديدة لـ " + c.fullName) to ("نشرت المدرسة " + gs.size + " نتائج جديدة."))
            }
            if (c.canViewFees) {
                c.fees?.payments.orEmpty().filter { "p:" + c.id + ":" + it.receiptNumber in fresh }.forEach { p ->
                    items.add("تم تسجيل دفعة" to (c.fullName + " — " + num(p.amount) + " (إيصال " + p.receiptNumber + ")"))
                }
            }
        }
        if (items.isEmpty()) return

        val launch = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
        val pending = if (launch != null) {
            PendingIntent.getActivity(ctx, 0, launch, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        } else null

        val shown: List<Pair<String, String>> =
            if (items.size > 3) listOf("لديك ${items.size} تحديثات جديدة" to "افتح التطبيق لعرض التفاصيل.") else items
        val baseId = (System.currentTimeMillis() % 100000L).toInt()
        shown.forEachIndexed { i, (title, text) ->
            val n = NotificationCompat.Builder(ctx, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_omrabi_symbol)
                .setContentTitle(title)
                .setContentText(text)
                .setStyle(NotificationCompat.BigTextStyle().bigText(text))
                .setAutoCancel(true)
                .setContentIntent(pending)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .build()
            try {
                NotificationManagerCompat.from(ctx).notify(baseId + i, n)
            } catch (_: SecurityException) {
            }
        }
    }
}
