package sd.alumrabi.parent.ui.theme

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

enum class ThemeMode(val key: String, val label: String) {
    Light("light", "فاتح"),
    Dark("dark", "داكن"),
    System("system", "تلقائي")
}

/** حالة المظهر: الوضع المختار (محفوظ على الجهاز) والنتيجة الفعلية dark التي تقرأها ألوان التصميم. */
object ThemeState {
    private const val PREFS = "alumrabi_ui"
    private const val KEY = "theme_mode"

    var mode by mutableStateOf(ThemeMode.System)
        private set

    /** تُحدَّث من AlUmrabiParentTheme؛ الألوان في Color.kt تقرأها فتُعاد رسم الشاشات تلقائياً. */
    var dark by mutableStateOf(false)

    fun load(context: Context) {
        val saved = runCatching {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
        }.getOrNull()
        mode = ThemeMode.values().firstOrNull { it.key == saved } ?: ThemeMode.System
    }

    fun set(context: Context, value: ThemeMode) {
        mode = value
        runCatching {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, value.key).apply()
        }
    }
}
