package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import sd.alumrabi.parent.BuildConfig
import sd.alumrabi.parent.data.model.GuardianInfo
import sd.alumrabi.parent.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    guardian: GuardianInfo,
    onBack: () -> Unit,
    onLogout: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "الإعدادات والحساب",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "رجوع",
                            tint = Color.White
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = BurgundyPrimary)
            )
        },
        containerColor = LavenderCanvas
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding).padding(horizontal = 16.dp, vertical = 14.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            item {
                SettingsSection(title = "حساب ولي الأمر") {
                    InfoRow(label = "الاسم", value = guardian.fullName)
                    InfoRow(label = "رقم الهاتف", value = guardian.phone.ifBlank { "غير مسجل" })
                    InfoRow(label = "معرّف الحساب", value = guardian.accountCode.ifBlank { "غير متاح" })
                    InfoRow(
                        label = "حالة الحساب",
                        value = if (guardian.status == "active") "مفعّل ونشط" else "بانتظار التفعيل"
                    )
                }
            }

            item {
                SettingsSection(title = "معلومات المؤسسة") {
                    InfoRow(label = "الجهة", value = "مؤسسة العمرابي التعليمية")
                    InfoRow(label = "التواصل الرسمي", value = "يُعتمد ويُضاف من إدارة المؤسسة")
                    InfoRow(label = "إصدار التطبيق", value = BuildConfig.VERSION_NAME)
                }
            }

            item {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp),
                    color = BurgundyContainer.copy(alpha = 0.72f),
                    border = BorderStroke(1.dp, BurgundyLight.copy(alpha = 0.16f))
                ) {
                    Column(
                        modifier = Modifier.padding(15.dp),
                        verticalArrangement = Arrangement.spacedBy(5.dp)
                    ) {
                        Text(
                            "الخصوصية وسلامة الحساب",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = BurgundyDark
                        )
                        Text(
                            "تظهر بيانات الأبناء المرتبطة بحساب ولي الأمر المعتمد وفق الصلاحيات المطبقة في النظام. لا تشارك كلمة المرور أو رمز التفعيل مع أي شخص.",
                            fontSize = 11.sp,
                            color = BurgundyDark,
                            lineHeight = 17.sp
                        )
                    }
                }
            }

            item {
                Spacer(Modifier.height(4.dp))
                Button(
                    onClick = onLogout,
                    colors = ButtonDefaults.buttonColors(containerColor = StatusDanger),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth().height(50.dp)
                ) {
                    Icon(Icons.Default.ExitToApp, contentDescription = null, tint = Color.White)
                    Spacer(Modifier.width(8.dp))
                    Text(
                        text = "تسجيل الخروج",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }
        }
    }
}

@Composable
private fun SettingsSection(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(15.dp),
        color = SurfaceWhite,
        border = BorderStroke(1.dp, BorderLight)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(title, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
            HorizontalDivider(color = BorderLight)
            content()
        }
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 3.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            modifier = Modifier.width(112.dp),
            fontSize = 11.sp,
            color = TextSecondary
        )
        Text(
            text = value,
            modifier = Modifier.weight(1f),
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            color = TextPrimary
        )
    }
}
