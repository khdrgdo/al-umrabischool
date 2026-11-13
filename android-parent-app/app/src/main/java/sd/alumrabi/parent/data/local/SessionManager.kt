package sd.alumrabi.parent.data.local

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import sd.alumrabi.parent.data.api.AuthTokens
import sd.alumrabi.parent.data.model.AnnouncementItem
import sd.alumrabi.parent.data.model.CalendarEventItem
import sd.alumrabi.parent.data.model.GuardianInfo
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.data.model.SchoolInfo

/**
 * تخزين الجلسة مشفّر (AES256 عبر Android Keystore). لا تُخزَّن كلمة المرور أبداً، ورمز قفل التطبيق (PIN) يُخزَّن فقط كبصمة مملّحة (PBKDF2) داخل هذا الملف المشفّر؛
 * فقط رموز جلسة Supabase Auth وبيانات العرض المؤقتة. يُحذف الملف القديم غير المشفّر عند أول تشغيل.
 */
class SessionManager(context: Context) {
    private val json = Json { ignoreUnknownKeys = true; isLenient = true; encodeDefaults = true }
    private val prefs: SharedPreferences = openEncrypted(context.applicationContext)

    companion object {
        private const val LEGACY_PREF_NAME = "alumrabi_parent_session" // كان يحوي PIN نصياً
        private const val PREF_NAME = "alumrabi_parent_session_secure"
        private const val KEY_IS_LOGGED_IN = "is_logged_in"
        private const val KEY_GUARDIAN_ID = "guardian_id"
        private const val KEY_ACCOUNT_CODE = "account_code"
        private const val KEY_FULL_NAME = "full_name"
        private const val KEY_PHONE = "phone"
        private const val KEY_STATUS = "status"
        private const val KEY_CHILDREN_JSON = "children_json"
        private const val KEY_LAST_SYNC = "last_sync"
        private const val KEY_ACCESS = "access_token"
        private const val KEY_REFRESH = "refresh_token"
        private const val KEY_EXPIRES = "expires_at"

        private fun openEncrypted(ctx: Context): SharedPreferences {
            // حذف أي بيانات قديمة غير مشفّرة (تحوي PIN) فوراً.
            runCatching { ctx.deleteSharedPreferences(LEGACY_PREF_NAME) }
            fun create(): SharedPreferences {
                val key = MasterKey.Builder(ctx).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build()
                return EncryptedSharedPreferences.create(
                    ctx, PREF_NAME, key,
                    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                )
            }
            return try {
                create()
            } catch (_: Exception) {
                // مفتاح Keystore تالف/مفقود: نبدأ جلسة نظيفة بدل الانهيار أو الرجوع لتخزين غير مشفّر.
                runCatching { ctx.deleteSharedPreferences(PREF_NAME) }
                create()
            }
        }
    }

    fun saveTokens(tokens: AuthTokens) {
        prefs.edit()
            .putString(KEY_ACCESS, tokens.accessToken)
            .putString(KEY_REFRESH, tokens.refreshToken)
            .putLong(KEY_EXPIRES, tokens.expiresAtMillis)
            .apply()
    }

    fun getTokens(): AuthTokens? {
        val a = prefs.getString(KEY_ACCESS, null) ?: return null
        val r = prefs.getString(KEY_REFRESH, null) ?: return null
        return AuthTokens(a, r, prefs.getLong(KEY_EXPIRES, 0L))
    }

    fun saveSession(guardian: GuardianInfo, children: List<LinkedChild>) {
        val editor = prefs.edit()
        editor.putBoolean(KEY_IS_LOGGED_IN, true)
        editor.putString(KEY_GUARDIAN_ID, guardian.id)
        editor.putString(KEY_ACCOUNT_CODE, guardian.accountCode)
        editor.putString(KEY_FULL_NAME, guardian.fullName)
        editor.putString(KEY_PHONE, guardian.phone)
        editor.putString(KEY_STATUS, guardian.status)
        try {
            editor.putString(KEY_CHILDREN_JSON, json.encodeToString(children))
        } catch (_: Exception) {
            // Keep existing if serialization fails
        }
        editor.putLong(KEY_LAST_SYNC, System.currentTimeMillis())
        editor.apply()
    }

    fun isLoggedIn(): Boolean {
        return prefs.getBoolean(KEY_IS_LOGGED_IN, false) &&
            !prefs.getString(KEY_ACCOUNT_CODE, null).isNullOrBlank() &&
            getTokens() != null
    }

    fun getGuardian(): GuardianInfo? {
        if (!isLoggedIn()) return null
        return GuardianInfo(
            id = prefs.getString(KEY_GUARDIAN_ID, "") ?: "",
            accountCode = prefs.getString(KEY_ACCOUNT_CODE, "") ?: "",
            fullName = prefs.getString(KEY_FULL_NAME, "ولي الأمر") ?: "ولي الأمر",
            phone = prefs.getString(KEY_PHONE, "") ?: "",
            status = prefs.getString(KEY_STATUS, "active") ?: "active"
        )
    }

    fun getChildren(): List<LinkedChild> {
        if (!isLoggedIn()) return emptyList()
        val raw = prefs.getString(KEY_CHILDREN_JSON, null) ?: return emptyList()
        return try {
            json.decodeFromString(raw)
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun saveContent(announcements: List<AnnouncementItem>, events: List<CalendarEventItem>) {
        try {
            prefs.edit()
                .putString("announcements_json", json.encodeToString(announcements))
                .putString("events_json", json.encodeToString(events))
                .apply()
        } catch (_: Exception) {
        }
    }

    fun getAnnouncements(): List<AnnouncementItem> {
        if (!isLoggedIn()) return emptyList()
        val raw = prefs.getString("announcements_json", null) ?: return emptyList()
        return try { json.decodeFromString<List<AnnouncementItem>>(raw) } catch (_: Exception) { emptyList() }
    }

    fun getEvents(): List<CalendarEventItem> {
        if (!isLoggedIn()) return emptyList()
        val raw = prefs.getString("events_json", null) ?: return emptyList()
        return try { json.decodeFromString<List<CalendarEventItem>>(raw) } catch (_: Exception) { emptyList() }
    }

    fun getReadIds(): Set<String> = prefs.getStringSet("read_announcements", emptySet())?.toSet() ?: emptySet()

    fun markRead(ids: Collection<String>) {
        val merged = getReadIds() + ids
        prefs.edit().putStringSet("read_announcements", merged).apply()
    }

    fun getNotifiedIds(): Set<String> = prefs.getStringSet("notified_ids", emptySet())?.toSet() ?: emptySet()

    fun hasNotifyBaseline(): Boolean = prefs.contains("notified_ids")

    fun addNotified(ids: Collection<String>) {
        prefs.edit().putStringSet("notified_ids", getNotifiedIds() + ids).apply()
    }

    // ── قفل التطبيق (يُحذف كله مع clearSession عند تسجيل الخروج) ──
    fun getPinRecord(): String? = prefs.getString("pin_record", null)

    fun setPinRecord(value: String?) {
        prefs.edit().apply { if (value == null) remove("pin_record") else putString("pin_record", value) }.apply()
    }

    fun isBiometricEnabled(): Boolean = prefs.getBoolean("lock_biometric", false)

    fun setBiometricEnabled(on: Boolean) { prefs.edit().putBoolean("lock_biometric", on).apply() }

    fun getPinFails(): Int = prefs.getInt("pin_fails", 0)

    fun setPinFails(n: Int) { prefs.edit().putInt("pin_fails", n).apply() }

    fun getPinLockouts(): Int = prefs.getInt("pin_lockouts", 0)

    fun setPinLockouts(n: Int) { prefs.edit().putInt("pin_lockouts", n).apply() }

    fun getLockoutUntil(): Long = prefs.getLong("pin_lockout_until", 0L)

    fun setLockoutUntil(millis: Long) { prefs.edit().putLong("pin_lockout_until", millis).apply() }

    fun saveSchool(school: SchoolInfo?) {
        if (school == null) return
        try { prefs.edit().putString("school_json", json.encodeToString(school)).apply() } catch (_: Exception) { }
    }

    fun getSchool(): SchoolInfo? {
        if (!isLoggedIn()) return null
        val raw = prefs.getString("school_json", null) ?: return null
        return try { json.decodeFromString<SchoolInfo>(raw) } catch (_: Exception) { null }
    }

    // خط أساس إشعارات الدرجات والدفعات (v2): يمنع إغراق المستخدم بنتائج قديمة بعد التحديث.
    fun hasBaselineV2(): Boolean = prefs.getBoolean("notify_v2", false)

    fun markBaselineV2() { prefs.edit().putBoolean("notify_v2", true).apply() }

    // إعلانات فتحها ولي الأمر ولم يصل تسجيل اطلاعها للخادم بعد (دون إنترنت).
    fun getUnsyncedReads(): Set<String> = prefs.getStringSet("unsynced_reads", emptySet())?.toSet() ?: emptySet()

    fun addUnsyncedReads(ids: Collection<String>) { prefs.edit().putStringSet("unsynced_reads", getUnsyncedReads() + ids).apply() }

    fun clearUnsyncedReads(ids: Collection<String>) { prefs.edit().putStringSet("unsynced_reads", getUnsyncedReads() - ids.toSet()).apply() }

    fun getLastSyncMillis(): Long = prefs.getLong(KEY_LAST_SYNC, 0L)

    fun clearSession() {
        prefs.edit().clear().apply()
    }
}
