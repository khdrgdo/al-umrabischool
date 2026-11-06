package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import sd.alumrabi.parent.data.model.GuardianInfo
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt

@Composable
fun SettingsScreen(
    guardian: GuardianInfo,
    lastSyncMillis: Long,
    onBack: () -> Unit,
    onLogout: () -> Unit
) {
    val context = LocalContext.current
    val version = remember {
        try {
            context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "—"
        } catch (e: Exception) {
            "—"
        }
    }
    var confirming by remember { mutableStateOf(false) }
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
