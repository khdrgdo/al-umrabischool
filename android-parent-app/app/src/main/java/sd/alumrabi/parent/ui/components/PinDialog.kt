package sd.alumrabi.parent.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import sd.alumrabi.parent.security.AppLock
import sd.alumrabi.parent.ui.theme.*

/** حوار إدخال رمز من 4 أرقام؛ يستدعي onComplete تلقائياً عند اكتمال الرقم الرابع. */
@Composable
fun PinEntryDialog(
    title: String,
    message: String,
    error: String?,
    onComplete: (String) -> Unit,
    onDismiss: () -> Unit
) {
    var pin by remember { mutableStateOf("") }
    val focus = remember { FocusRequester() }
    LaunchedEffect(Unit) {
        delay(200)
        runCatching { focus.requestFocus() }
    }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column {
                Text(message, style = MaterialTheme.typography.bodyMedium, color = Ink700)
                Spacer(Modifier.height(Space.md))
                OutlinedTextField(
                    value = pin,
                    onValueChange = { v ->
                        val digits = v.filter { it.isDigit() }.take(AppLock.PIN_LENGTH)
                        pin = digits
                        if (digits.length == AppLock.PIN_LENGTH) onComplete(digits)
                    },
                    singleLine = true,
                    isError = error != null,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                    visualTransformation = PasswordVisualTransformation(),
                    textStyle = LocalTextStyle.current.copy(
                        textDirection = TextDirection.Ltr,
                        textAlign = TextAlign.Center,
                        letterSpacing = 8.sp
                    ),
                    modifier = Modifier.fillMaxWidth().focusRequester(focus)
                )
                if (error != null) {
                    Spacer(Modifier.height(Space.xs))
                    Text(error, style = MaterialTheme.typography.bodySmall, color = Negative)
                }
            }
        },
        confirmButton = {},
        dismissButton = { TextButton(onClick = onDismiss) { Text("إلغاء", color = Ink700) } },
        containerColor = Paper
    )
}
