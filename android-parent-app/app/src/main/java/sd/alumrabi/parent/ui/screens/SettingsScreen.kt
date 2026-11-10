package sd.alumrabi.parent.ui.screens

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.data.model.GuardianInfo
import sd.alumrabi.parent.security.AppLock
import sd.alumrabi.parent.security.Biometrics
import sd.alumrabi.parent.security.PinResult
import sd.alumrabi.parent.security.findFragmentActivity
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt

private enum class PinFlow { None, SetFirst, SetConfirm, VerifyDisable }

@Composable
fun SettingsScreen(
    guardian: GuardianInfo,
    lastSyncMillis: Long,
    lock: AppLock,
    onBack: () -> Unit,
    onLogout: () -> Unit
) {
    SystemBars(statusBar = Canvas, darkIcons = true)
    val context = LocalContext.current
    val activity = remember(context) { context.findFragmentActivity() }
    val bioAvailable = remember { Biometrics.available(context) }
    val version = remember {
        try {
            context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "—"
        } catch (e: Exception) {
            "—"
        }
    }
    var confirming by remember { mutableStateOf(false) }
    var flow by remember { mutableStateOf(PinFlow.None) }
    var firstPin by remember { mutableStateOf("") }
    var flowError by remember { mutableStateOf<String?>(null) }
    var attempt by remember { mutableIntStateOf(0) }
    val statusText = if (guardian.status == "active") "مفعّل" else "بانتظار التفعيل"

    Scaffold(
        topBar = { OmrabiTopBar(title = "الإعدادات وحسابي", onBack = onBack) },
        containerColor = Canvas
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(horizontal = Space.gutter)
                .verticalScroll(rememberScrollState())
        ) {
            Spacer(Modifier.height(Space.md))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Monogram(guardian.fullName, 56.dp)
                Spacer(Modifier.width(Space.lg))
                Column {
                    Text(guardian.fullName, style = MaterialTheme.typography.titleLarge, color = Ink900)
                    Text("ولي أمر", style = MaterialTheme.typography.bodyMedium, color = Ink500)
                }
            }

            SectionLabel("الحساب")
            GroupedList {
                if (!guardian.accountCode.isNullOrBlank()) {
                    InfoRow("رمز الحساب", guardian.accountCode, ltr = true)
                    RowDivider()
                }
                if (guardian.phone.isNotBlank()) {
                    InfoRow("رقم الهاتف", guardian.phone, ltr = true)
                    RowDivider()
                }
                InfoRow("حالة الحساب", statusText)
            }

            SectionLabel("المظهر")
            GroupedList {
                Row(
                    Modifier.fillMaxWidth().padding(Space.md),
                    horizontalArrangement = Arrangement.spacedBy(Space.sm)
                ) {
                    ThemeMode.values().forEach { m ->
                        ModeChip(m.label, ThemeState.mode == m, Modifier.weight(1f)) {
                            ThemeState.set(context, m)
                        }
                    }
                }
            }

            SectionLabel("الأمان")
            GroupedList {
                SwitchRow(
                    title = "قفل التطبيق برمز",
                    subtitle = "يُطلب رمز من 4 أرقام عند فتح التطبيق وبعد مغادرته",
                    checked = lock.enabled,
                    onChange = { on ->
                        flowError = null
                        attempt++
                        flow = if (on) PinFlow.SetFirst else PinFlow.VerifyDisable
                    }
                )
                if (lock.enabled && bioAvailable && activity != null) {
                    RowDivider()
                    SwitchRow(
                        title = "الفتح بالبصمة",
                        subtitle = "بدلاً من إدخال الرمز في كل مرة",
                        checked = lock.biometric,
                        onChange = { on ->
                            if (on) {
                                Biometrics.prompt(
                                    activity = activity,
                                    title = "تفعيل الفتح بالبصمة",
                                    subtitle = "المس مستشعر البصمة للتأكيد",
                                    cancelText = "إلغاء",
                                    onSuccess = { lock.enableBiometric(true) }
                                )
                            } else {
                                lock.enableBiometric(false)
                            }
                        }
                    )
                }
            }

            SectionLabel("التطبيق")
            GroupedList {
                InfoRow("الإصدار", version, ltr = true)
                RowDivider()
                InfoRow("آخر مزامنة", Fmt.lastSync(lastSyncMillis))
            }

            Spacer(Modifier.height(Space.md))
            Text(
                "تُعرض في التطبيق البيانات المعتمدة من المدرسة للقراءة فقط. لتعديل أي بيانات تواصل مع إدارة المدرسة.",
                style = MaterialTheme.typography.bodySmall,
                color = Ink500
            )

            Spacer(Modifier.height(Space.xxl))
            OutlineButton(
                text = "تسجيل الخروج",
                onClick = { confirming = true },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(Modifier.height(Space.xxl))
        }
    }

    when (flow) {
        PinFlow.None -> {}
        PinFlow.SetFirst -> key(attempt) {
            PinEntryDialog(
                title = "إنشاء رمز القفل",
                message = "اختر رمزاً من 4 أرقام لا يعرفه غيرك.",
                error = flowError,
                onComplete = { pin ->
                    firstPin = pin
                    flowError = null
                    attempt++
                    flow = PinFlow.SetConfirm
                },
                onDismiss = { flow = PinFlow.None; flowError = null }
            )
        }
        PinFlow.SetConfirm -> key(attempt) {
            PinEntryDialog(
                title = "تأكيد الرمز",
                message = "أعد إدخال الرمز نفسه للتأكيد.",
                error = flowError,
                onComplete = { pin ->
                    if (pin == firstPin) {
                        lock.setPin(pin)
                        flow = PinFlow.None
                        flowError = null
                        Toast.makeText(context, "تم تفعيل قفل التطبيق", Toast.LENGTH_SHORT).show()
                    } else {
                        flowError = "الرمزان غير متطابقين، أعد المحاولة"
                        attempt++
                        flow = PinFlow.SetFirst
                    }
                },
                onDismiss = { flow = PinFlow.None; flowError = null }
            )
        }
        PinFlow.VerifyDisable -> key(attempt) {
            PinEntryDialog(
                title = "إيقاف القفل",
                message = "أدخل الرمز الحالي لإيقاف قفل التطبيق.",
                error = flowError,
                onComplete = { pin ->
                    when (val r = lock.verify(pin)) {
                        is PinResult.Ok -> {
                            lock.disable()
                            flow = PinFlow.None
                            flowError = null
                            Toast.makeText(context, "تم إيقاف قفل التطبيق", Toast.LENGTH_SHORT).show()
                        }
                        is PinResult.Wrong -> { flowError = "الرمز غير صحيح"; attempt++ }
                        is PinResult.LockedOut -> { flowError = "حاول بعد " + r.seconds + " ثانية"; attempt++ }
                    }
                },
                onDismiss = { flow = PinFlow.None; flowError = null }
            )
        }
    }

    if (confirming) {
        AlertDialog(
            onDismissRequest = { confirming = false },
            title = { Text("تسجيل الخروج") },
            text = { Text("سيتم حذف البيانات المحفوظة على هذا الجهاز. هل تريد المتابعة؟") },
            confirmButton = {
                TextButton(onClick = { confirming = false; onLogout() }) {
                    Text("تسجيل الخروج", color = Crimson700)
                }
            },
            dismissButton = {
                TextButton(onClick = { confirming = false }) { Text("إلغاء", color = Ink700) }
            },
            containerColor = Paper
        )
    }
}

@Composable
private fun ModeChip(label: String, selected: Boolean, modifier: Modifier, onClick: () -> Unit) {
    Box(
        modifier
            .clip(CircleShape)
            .background(if (selected) Crimson600 else Wash)
            .clickable(onClick = onClick)
            .padding(vertical = 10.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            label,
            style = MaterialTheme.typography.labelLarge,
            color = if (selected) OnBrand else Ink900
        )
    }
}

@Composable
private fun SwitchRow(title: String, subtitle: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .heightIn(min = 56.dp)
            .clickable { onChange(!checked) }
            .padding(horizontal = Space.lg, vertical = Space.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyLarge, color = Ink900)
            Text(subtitle, style = MaterialTheme.typography.bodySmall, color = Ink500)
        }
        Spacer(Modifier.width(Space.sm))
        Switch(
            checked = checked,
            onCheckedChange = onChange,
            colors = SwitchDefaults.colors(checkedTrackColor = Crimson600, checkedThumbColor = OnBrand)
        )
    }
}
