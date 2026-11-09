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

object Notifier {
    const val CHANNEL_ID = "alumrabi_updates"
    private const val WORK_NAME = "alumrabi_updates_check"

    fun ensureChannel(ctx: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) == null) {
            val ch = NotificationChannel(CHANNEL_ID, "تحديثات المدرسة", NotificationManager.IMPORTANCE_DEFAULT)
            ch.description = "الإعلانات والمواعيد وتنبيهات الغياب"
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

    /** مفاتيح العناصر الحالية: a: إعلان، e: موعد، abs: غياب اليوم لابن مفعّلة له الإشعارات. */
    fun keys(payload: DashboardPayload): Set<String> {
        val today = LocalDate.now().toString()
        val set = HashSet<String>()
        payload.announcements.forEach { set.add("a:" + it.id) }
        payload.events.forEach { set.add("e:" + it.id) }
        payload.children.forEach { c ->
            val absentToday = c.attendance.orEmpty().any { it.status == "absent" && it.date.startsWith(today) }
            if (c.receivesNotifications && absentToday) set.add("abs:" + c.id + ":" + today)
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
        if (items.isEmpty()) return

        val launch = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
        val pending = if (launch != null) {
            PendingIntent.getActivity(ctx, 0, launch, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        } else null

        val shown: List<Pair<String, String>> =
            if (items.size > 3) listOf("لديك ${items.size} تحديثات جديدة" to "افتح التطبيق لعرض الإعلانات والمواعيد.") else items
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
