package sd.alumrabi.parent.data.local

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import sd.alumrabi.parent.data.api.AuthTokens
import sd.alumrabi.parent.data.model.AnnouncementItem
import sd.alumrabi.parent.data.model.CalendarEventItem
import sd.alumrabi.parent.data.model.GuardianInfo
import sd.alumrabi.parent.data.model.LinkedChild

/**
 * تخزين الجلسة مشفّر (AES256 عبر Android Keystore). لا تُخزَّن كلمة المرور ولا أي PIN أبداً؛
 * فقط رموز جلسة Supabase Auth وبيانات العرض المؤقتة. يُحذف الملف القديم غير المشفّر عند أول تشغيل.
 */
class SessionManager(context: Context) {
    private val json = Json { ignoreUnknownKeys = true; isLenient = true; encodeDefaults = true }
    private val prefs: SharedPreferences = openEncrypted(context.applicationContext)

    companion object {
        private const val LEGACY_PREF_NAME = "alumrabi_parent_session"
        private const val PREF_NAME = "alumrabi_parent_session_secure"
        private const val KEY_IS_LOGGED_IN = "is_logged_in"
        private const val KEY_GUARDIAN_ID = "guardian_id"
        private const val KEY_ACCOUNT_CODE = "account_code"
        private const val KEY_FULL_NAME = "full_name"
        private const val KEY_PHONE = "phone"
        private const val KEY_STATUS = "status"
        private const val KEY_CHILDREN_JSON = "children_json"
        private const val KEY_ANNOUNCEMENTS_JSON = "announcements_json"
        private const val KEY_EVENTS_JSON = "events_json"
        private const val KEY_LAST_SYNC = "last_sync"
        private const val KEY_ACCESS = "access_token"
        private const val KEY_REFRESH = "refresh_token"
        private const val KEY_EXPIRES = "expires_at"

        private fun openEncrypted(ctx: Context): SharedPreferences {
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
        val access = prefs.getString(KEY_ACCESS, null) ?: return null
        val refresh = prefs.getString(KEY_REFRESH, null) ?: return null
        return AuthTokens(access, refresh, prefs.getLong(KEY_EXPIRES, 0L))
    }

    fun saveSession(
        guardian: GuardianInfo,
        children: List<LinkedChild>,
        announcements: List<AnnouncementItem> = emptyList(),
        events: List<CalendarEventItem> = emptyList()
    ) {
        val editor = prefs.edit()
            .putBoolean(KEY_IS_LOGGED_IN, true)
            .putString(KEY_GUARDIAN_ID, guardian.id)
            .putString(KEY_ACCOUNT_CODE, guardian.accountCode)
            .putString(KEY_FULL_NAME, guardian.fullName)
            .putString(KEY_PHONE, guardian.phone)
            .putString(KEY_STATUS, guardian.status)
            .putLong(KEY_LAST_SYNC, System.currentTimeMillis())
        runCatching { json.encodeToString(children) }.getOrNull()?.let { editor.putString(KEY_CHILDREN_JSON, it) }
        runCatching { json.encodeToString(announcements) }.getOrNull()?.let { editor.putString(KEY_ANNOUNCEMENTS_JSON, it) }
        runCatching { json.encodeToString(events) }.getOrNull()?.let { editor.putString(KEY_EVENTS_JSON, it) }
        editor.apply()
    }

    fun isLoggedIn(): Boolean =
        prefs.getBoolean(KEY_IS_LOGGED_IN, false) &&
            !prefs.getString(KEY_ACCOUNT_CODE, null).isNullOrBlank() &&
            getTokens() != null

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

    private inline fun <reified T> readList(key: String): List<T> {
        if (!isLoggedIn()) return emptyList()
        val raw = prefs.getString(key, null) ?: return emptyList()
        return runCatching { json.decodeFromString<List<T>>(raw) }.getOrDefault(emptyList())
    }

    fun getChildren(): List<LinkedChild> = readList(KEY_CHILDREN_JSON)
    fun getAnnouncements(): List<AnnouncementItem> = readList(KEY_ANNOUNCEMENTS_JSON)
    fun getEvents(): List<CalendarEventItem> = readList(KEY_EVENTS_JSON)
    fun getLastSyncMillis(): Long = prefs.getLong(KEY_LAST_SYNC, 0L)

    fun clearSession() {
        prefs.edit().clear().apply()
    }
}
