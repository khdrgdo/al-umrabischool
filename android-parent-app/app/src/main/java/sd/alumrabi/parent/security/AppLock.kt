package sd.alumrabi.parent.security

import android.os.SystemClock
import android.util.Base64
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import sd.alumrabi.parent.data.local.SessionManager
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

sealed interface PinResult {
    object Ok : PinResult
    data class Wrong(val attemptsLeft: Int) : PinResult
    data class LockedOut(val seconds: Int) : PinResult
}

/**
 * قفل التطبيق: رمز من 4 أرقام (يُخزَّن كبصمة PBKDF2 مملّحة فقط) + بصمة اختيارية.
 * بعد 5 محاولات خاطئة يُمنع الإدخال مؤقتاً، وتتضاعف المدة مع كل مرة (حتى 15 دقيقة).
 */
class AppLock(private val session: SessionManager) {
    companion object {
        const val PIN_LENGTH = 4
        private const val MAX_ATTEMPTS = 5
        private const val GRACE_MS = 20_000L
        private const val ITERATIONS = 60_000
    }

    var enabled by mutableStateOf(session.getPinRecord() != null && session.isLoggedIn())
        private set
    var biometric by mutableStateOf(session.isBiometricEnabled())
        private set
    var locked by mutableStateOf(session.getPinRecord() != null && session.isLoggedIn())
        private set

    private var backgroundedAt = 0L

    fun setPin(pin: String) {
        session.setPinRecord(hash(pin))
        session.setPinFails(0)
        session.setPinLockouts(0)
        session.setLockoutUntil(0L)
        enabled = true
        locked = false
    }

    fun setBiometric(on: Boolean) {
        session.setBiometricEnabled(on)
        biometric = on
    }

    fun disable() {
        session.setPinRecord(null)
        session.setBiometricEnabled(false)
        session.setPinFails(0)
        session.setPinLockouts(0)
        session.setLockoutUntil(0L)
        enabled = false
        biometric = false
        locked = false
    }

    /** بعد تسجيل الخروج: الجلسة (وبها الرمز) حُذفت، نزامن الحالة فقط. */
    fun reset() {
        enabled = false
        biometric = false
        locked = false
    }

    fun unlock() {
        session.setPinFails(0)
        session.setPinLockouts(0)
        session.setLockoutUntil(0L)
        locked = false
    }

    fun onBackground() {
        backgroundedAt = SystemClock.elapsedRealtime()
    }

    fun onForeground() {
        if (enabled && !locked && backgroundedAt > 0L &&
            SystemClock.elapsedRealtime() - backgroundedAt > GRACE_MS
        ) locked = true
    }

    fun lockoutRemainingSec(nowMs: Long = System.currentTimeMillis()): Int {
        val left = session.getLockoutUntil() - nowMs
        return if (left <= 0L) 0 else ((left + 999L) / 1000L).toInt()
    }

    fun verify(pin: String): PinResult {
        val remaining = lockoutRemainingSec()
        if (remaining > 0) return PinResult.LockedOut(remaining)
        val record = session.getPinRecord() ?: return PinResult.Ok
        if (matches(pin, record)) {
            session.setPinFails(0)
            session.setPinLockouts(0)
            return PinResult.Ok
        }
        val fails = session.getPinFails() + 1
        if (fails >= MAX_ATTEMPTS) {
            val lockouts = session.getPinLockouts()
            val waitSec = minOf(30 * (1 shl minOf(lockouts, 5)), 900)
            session.setPinFails(0)
            session.setPinLockouts(lockouts + 1)
            session.setLockoutUntil(System.currentTimeMillis() + waitSec * 1000L)
            return PinResult.LockedOut(waitSec)
        }
        session.setPinFails(fails)
        return PinResult.Wrong(MAX_ATTEMPTS - fails)
    }

    private fun derive(pin: String, salt: ByteArray): ByteArray =
        SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
            .generateSecret(PBEKeySpec(pin.toCharArray(), salt, ITERATIONS, 256)).encoded

    private fun hash(pin: String): String {
        val salt = ByteArray(16).also { SecureRandom().nextBytes(it) }
        return Base64.encodeToString(salt, Base64.NO_WRAP) + ":" + Base64.encodeToString(derive(pin, salt), Base64.NO_WRAP)
    }

    private fun matches(pin: String, record: String): Boolean {
        val parts = record.split(":")
        if (parts.size != 2) return false
        return try {
            val salt = Base64.decode(parts[0], Base64.NO_WRAP)
            val expected = Base64.decode(parts[1], Base64.NO_WRAP)
            MessageDigest.isEqual(expected, derive(pin, salt))
        } catch (_: Exception) {
            false
        }
    }
}
