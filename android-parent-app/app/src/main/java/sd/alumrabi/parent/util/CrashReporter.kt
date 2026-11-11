package sd.alumrabi.parent.util

import android.content.Context
import android.os.Build
import android.util.Log
import java.io.File

/** نسخة التجربة فقط: يحفظ آخر خطأ مفاجئ ليُعرض عند التشغيل التالي بدل أن يختفي التطبيق بلا تفسير. */
object CrashReporter {
    private const val FILE = "last_crash.txt"

    fun install(context: Context) {
        val app = context.applicationContext
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            runCatching {
                File(app.filesDir, FILE).writeText(
                    Log.getStackTraceString(error).take(6000) +
                        "\nAndroid SDK " + Build.VERSION.SDK_INT + " · " + Build.MANUFACTURER + " " + Build.MODEL
                )
            }
            previous?.uncaughtException(thread, error)
        }
    }

    fun consume(context: Context): String? {
        val f = File(context.filesDir, FILE)
        if (!f.exists()) return null
        val text = runCatching { f.readText() }.getOrNull()
        runCatching { f.delete() }
        return text
    }
}
