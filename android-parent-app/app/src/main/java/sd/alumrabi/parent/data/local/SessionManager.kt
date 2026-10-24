package sd.alumrabi.parent.data.local

import android.content.Context
import android.content.SharedPreferences
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import sd.alumrabi.parent.data.model.GuardianInfo
import sd.alumrabi.parent.data.model.LinkedChild

class SessionManager(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true; isLenient = true; encodeDefaults = true }

    companion object {
        private const val PREF_NAME = "alumrabi_parent_session"
        private const val KEY_IS_LOGGED_IN = "is_logged_in"
        private const val KEY_GUARDIAN_ID = "guardian_id"
        private const val KEY_ACCOUNT_CODE = "account_code"
        private const val KEY_FULL_NAME = "full_name"
        private const val KEY_PHONE = "phone"
        private const val KEY_STATUS = "status"
        private const val KEY_CHILDREN_JSON = "children_json"
        private const val KEY_LAST_SYNC = "last_sync"
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
            val childrenStr = json.encodeToString(children)
            editor.putString(KEY_CHILDREN_JSON, childrenStr)
        } catch (_: Exception) {
            // Keep existing if serialization fails
        }
        editor.putLong(KEY_LAST_SYNC, System.currentTimeMillis())
        editor.apply()
    }

    fun isLoggedIn(): Boolean {
        return prefs.getBoolean(KEY_IS_LOGGED_IN, false) && 
               !prefs.getString(KEY_ACCOUNT_CODE, null).isNullOrBlank()
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
        val raw = prefs.getString(KEY_CHILDREN_JSON, null) ?: return emptyList()
        return try {
            json.decodeFromString(raw)
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun getLastSyncMillis(): Long {
        return prefs.getLong(KEY_LAST_SYNC, 0L)
    }

    fun clearSession() {
        prefs.edit().clear().apply()
    }
}
