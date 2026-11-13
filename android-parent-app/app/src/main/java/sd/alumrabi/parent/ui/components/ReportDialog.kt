package sd.alumrabi.parent.ui.components

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import sd.alumrabi.parent.ui.theme.*

private val categories = listOf("bug" to "مشكلة", "question" to "سؤال", "suggestion" to "اقتراح")

/** بلاغ إلى إدارة المدرسة (مشكلة بالتطبيق أو سؤال أو اقتراح). */
@Composable
fun ReportDialog(onDismiss: () -> Unit, onSubmit: suspend (String, String) -> Result<Unit>) {
    var category by remember { mutableStateOf("bug") }
    var text by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    var busy by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    AlertDialog(
        onDismissRequest = { if (!busy) onDismiss() },
        title = { Text("الإبلاغ عن مشكلة") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    categories.forEach { (key, label) ->
                        Box(
                            Modifier
                                .weight(1f)
                                .clip(CircleShape)
                                .background(if (category == key) Crimson600 else Wash)
                                .clickable { category = key }
                                .padding(vertical = 8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(label, style = MaterialTheme.typography.labelLarge, color = if (category == key) OnBrand else Ink900)
                        }
                    }
                }
                OutlinedTextField(
                    value = text,
                    onValueChange = { if (it.length <= 2000) text = it },
                    label = { Text("اكتب التفاصيل") },
                    minLines = 3,
                    maxLines = 6,
                    modifier = Modifier.fillMaxWidth()
                )
                Text(
                    "يصل البلاغ إلى إدارة المدرسة مع رقم نسخة التطبيق ونوع الجهاز.",
                    style = MaterialTheme.typography.bodySmall,
                    color = Ink500
                )
                val e = error
                if (e != null) Text(e, style = MaterialTheme.typography.bodySmall, color = Negative)
            }
        },
        confirmButton = {
            TextButton(
                enabled = !busy,
                onClick = {
                    if (text.trim().length < 5) {
                        error = "اكتب وصفاً أوضح (5 أحرف على الأقل)"
                    } else {
                        error = null
                        busy = true
                        scope.launch {
                            val r = onSubmit(category, text.trim())
                            busy = false
                            r.onSuccess {
                                Toast.makeText(context, "وصل بلاغك إلى المدرسة، شكراً لك", Toast.LENGTH_LONG).show()
                                onDismiss()
                            }.onFailure { error = it.message ?: "تعذر إرسال البلاغ" }
                        }
                    }
                }
            ) { Text(if (busy) "جارٍ الإرسال…" else "إرسال", color = Crimson700) }
        },
        dismissButton = { TextButton(enabled = !busy, onClick = onDismiss) { Text("إلغاء", color = Ink700) } },
        containerColor = Paper
    )
}
