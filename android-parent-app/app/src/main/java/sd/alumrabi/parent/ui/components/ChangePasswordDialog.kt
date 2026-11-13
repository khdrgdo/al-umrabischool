package sd.alumrabi.parent.ui.components

import android.widget.Toast
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import sd.alumrabi.parent.ui.theme.*

@Composable
fun ChangePasswordDialog(onDismiss: () -> Unit, onSubmit: suspend (String, String) -> Result<Unit>) {
    var oldPw by remember { mutableStateOf("") }
    var pw1 by remember { mutableStateOf("") }
    var pw2 by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    var busy by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    AlertDialog(
        onDismissRequest = { if (!busy) onDismiss() },
        title = { Text("تغيير كلمة المرور") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                PwField("كلمة المرور الحالية", oldPw) { oldPw = it }
                PwField("كلمة المرور الجديدة (8 أحرف فأكثر)", pw1) { pw1 = it }
                PwField("تأكيد كلمة المرور الجديدة", pw2) { pw2 = it }
                val e = error
                if (e != null) Text(e, style = MaterialTheme.typography.bodySmall, color = Negative)
            }
        },
        confirmButton = {
            TextButton(
                enabled = !busy,
                onClick = {
                    error = when {
                        oldPw.isBlank() -> "أدخل كلمة المرور الحالية"
                        pw1.length < 8 -> "كلمة المرور الجديدة 8 أحرف على الأقل"
                        pw1 != pw2 -> "كلمتا المرور غير متطابقتين"
                        pw1 == oldPw -> "اختر كلمة مختلفة عن الحالية"
                        else -> null
                    }
                    if (error == null) {
                        busy = true
                        scope.launch {
                            val r = onSubmit(oldPw, pw1)
                            busy = false
                            r.onSuccess {
                                Toast.makeText(context, "تم تغيير كلمة المرور", Toast.LENGTH_SHORT).show()
                                onDismiss()
                            }.onFailure { error = it.message ?: "تعذر تغيير كلمة المرور" }
                        }
                    }
                }
            ) { Text(if (busy) "جارٍ الحفظ…" else "حفظ", color = Crimson700) }
        },
        dismissButton = { TextButton(enabled = !busy, onClick = onDismiss) { Text("إلغاء", color = Ink700) } },
        containerColor = Paper
    )
}

@Composable
private fun PwField(label: String, value: String, onChange: (String) -> Unit) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label) },
        singleLine = true,
        visualTransformation = PasswordVisualTransformation(),
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
        modifier = Modifier.fillMaxWidth()
    )
}
