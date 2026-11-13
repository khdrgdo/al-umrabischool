package sd.alumrabi.parent.security

import android.content.Context
import android.content.ContextWrapper
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity

object Biometrics {
    fun available(context: Context): Boolean =
        BiometricManager.from(context)
            .canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS

    fun prompt(
        activity: FragmentActivity,
        title: String,
        subtitle: String,
        cancelText: String,
        onSuccess: () -> Unit,
        onFailure: () -> Unit = {}
    ) {
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                onSuccess()
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                onFailure()
            }
        }
        val prompt = BiometricPrompt(activity, ContextCompat.getMainExecutor(activity), callback)
        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .setSubtitle(subtitle)
            .setNegativeButtonText(cancelText)
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            .build()
        prompt.authenticate(info)
    }
}

fun Context.findFragmentActivity(): FragmentActivity? {
    var c: Context? = this
    while (c is ContextWrapper) {
        if (c is FragmentActivity) return c
        c = c.baseContext
    }
    return null
}
