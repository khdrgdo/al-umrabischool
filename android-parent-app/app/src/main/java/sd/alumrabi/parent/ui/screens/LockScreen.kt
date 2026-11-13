package sd.alumrabi.parent.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Backspace
import androidx.compose.material.icons.outlined.Fingerprint
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import sd.alumrabi.parent.security.AppLock
import sd.alumrabi.parent.security.Biometrics
import sd.alumrabi.parent.security.PinResult
import sd.alumrabi.parent.security.findFragmentActivity
import sd.alumrabi.parent.ui.components.OmrabiSymbol
import sd.alumrabi.parent.ui.theme.*

/** شاشة قفل تغطي التطبيق كله حتى يُدخَل الرمز أو تُقبل البصمة. */
@Composable
fun LockScreen(lock: AppLock, guardianName: String, onForgot: () -> Unit) {
    SystemBars(statusBar = Canvas, darkIcons = true)
    val context = LocalContext.current
    val activity = remember(context) { context.findFragmentActivity() }
    val bioAvailable = remember { Biometrics.available(context) }
    val canBio = lock.biometric && activity != null && bioAvailable

    var pin by remember { mutableStateOf("") }
    var message by remember { mutableStateOf<String?>(null) }
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    var confirmForgot by remember { mutableStateOf(false) }
    val remaining = lock.lockoutRemainingSec(now)

    LaunchedEffect(Unit) {
        while (true) {
            delay(500)
            now = System.currentTimeMillis()
        }
    }

    fun tryBiometric() {
        val a = activity ?: return
        Biometrics.prompt(
            activity = a,
            title = "فتح التطبيق",
            subtitle = "استخدم بصمتك للدخول",
            cancelText = "استخدام الرمز",
            onSuccess = { lock.unlock() }
        )
    }

    LaunchedEffect(canBio) { if (canBio) tryBiometric() }

    BackHandler { activity?.moveTaskToBack(true) }

    fun onDigit(d: String) {
        if (remaining > 0 || pin.length >= AppLock.PIN_LENGTH) return
        pin += d
        if (pin.length == AppLock.PIN_LENGTH) {
            when (val r = lock.verify(pin)) {
                is PinResult.Ok -> lock.unlock()
                is PinResult.Wrong -> {
                    message = "الرمز غير صحيح. تبقّى " + r.attemptsLeft + " محاولات"
                    pin = ""
                }
                is PinResult.LockedOut -> {
                    message = null
                    pin = ""
                    now = System.currentTimeMillis()
                }
            }
        }
    }

    Box(
        Modifier
            .fillMaxSize()
            .background(Canvas)
            .pointerInput(Unit) { detectTapGestures { } }
    ) {
        Column(
            Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Space.xxl),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(36.dp))
            Box(
                Modifier.size(68.dp).clip(CircleShape).background(Crimson600),
                contentAlignment = Alignment.Center
            ) { OmrabiSymbol(38.dp, tint = OnBrand) }
            Spacer(Modifier.height(Space.lg))
            Text("أدخل رمز القفل", style = MaterialTheme.typography.titleLarge, color = Ink900)
            Text(guardianName, style = MaterialTheme.typography.bodyMedium, color = Ink500)
            Spacer(Modifier.height(Space.xl))
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                for (i in 0 until AppLock.PIN_LENGTH) {
                    val filled = i < pin.length
                    Box(
                        Modifier
                            .size(14.dp)
                            .clip(CircleShape)
                            .background(if (filled) Crimson600 else Canvas)
                            .border(1.5.dp, if (filled) Crimson600 else LineStrong, CircleShape)
                    )
                }
            }
            Spacer(Modifier.height(Space.md))
            val shown = if (remaining > 0) "تجاوزت عدد المحاولات. حاول بعد " + remaining + " ثانية" else message
            Box(Modifier.height(24.dp), contentAlignment = Alignment.Center) {
                if (shown != null) Text(shown, style = MaterialTheme.typography.bodySmall, color = Negative)
            }
            Spacer(Modifier.height(Space.md))

            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                Column(
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    listOf(listOf("1", "2", "3"), listOf("4", "5", "6"), listOf("7", "8", "9")).forEach { row ->
                        Row(horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                            row.forEach { d -> KeyButton(d) { onDigit(d) } }
                        }
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                        if (canBio) KeyIcon(Icons.Outlined.Fingerprint, "البصمة") { tryBiometric() }
                        else Spacer(Modifier.size(68.dp))
                        KeyButton("0") { onDigit("0") }
                        KeyIcon(Icons.AutoMirrored.Outlined.Backspace, "حذف") {
                            if (pin.isNotEmpty()) pin = pin.dropLast(1)
                        }
                    }
                }
            }
            Spacer(Modifier.height(Space.lg))
            TextButton(onClick = { confirmForgot = true }) {
                Text("نسيت الرمز؟ تسجيل الخروج", color = Crimson700)
            }
            Spacer(Modifier.height(Space.lg))
        }
    }

    if (confirmForgot) {
        AlertDialog(
            onDismissRequest = { confirmForgot = false },
            title = { Text("تسجيل الخروج") },
            text = { Text("سيتم حذف البيانات المحفوظة على هذا الجهاز، وتحتاج لإدخال رقم الحساب وكلمة المرور من جديد.") },
            confirmButton = {
                TextButton(onClick = { confirmForgot = false; onForgot() }) {
                    Text("تسجيل الخروج", color = Crimson700)
                }
            },
            dismissButton = { TextButton(onClick = { confirmForgot = false }) { Text("إلغاء", color = Ink700) } },
            containerColor = Paper
        )
    }
}

@Composable
private fun KeyButton(label: String, onClick: () -> Unit) {
    Box(
        Modifier
            .size(68.dp)
            .clip(CircleShape)
            .background(Paper)
            .border(1.dp, Line, CircleShape)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(label, style = MaterialTheme.typography.headlineSmall.tabular(), color = Ink900)
    }
}

@Composable
private fun KeyIcon(icon: ImageVector, description: String, onClick: () -> Unit) {
    Box(
        Modifier.size(68.dp).clip(CircleShape).clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Icon(icon, contentDescription = description, tint = Ink700, modifier = Modifier.size(28.dp))
    }
}
