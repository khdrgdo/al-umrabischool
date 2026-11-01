package sd.alumrabi.parent.data.local

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import sd.alumrabi.parent.data.api.AuthTokens
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

    fun getLastSyncMillis(): Long = prefs.getLong(KEY_LAST_SYNC, 0L)

    fun clearSession() {
        prefs.edit().clear().apply()
    }
}
