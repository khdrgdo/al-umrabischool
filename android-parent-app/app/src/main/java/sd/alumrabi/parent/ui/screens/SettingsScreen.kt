package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
                        text = "الإعدادات وحساب ولي الأمر",
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
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            // Guardian Account Details (Clean, border-based container)
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(SurfaceWhite, RoundedCornerShape(12.dp))
                        .border(1.dp, BorderLight, RoundedCornerShape(12.dp))
                        .padding(16.dp)
                ) {
                    Column {
                        Text(
                            text = "ملف ولي الأمر المعتمد",
                            fontSize = 13.5.sp,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )

                        Spacer(modifier = Modifier.height(10.dp))

                        InfoRow(label = "الاسم", value = guardian.fullName)
                        InfoRow(label = "رقم الهاتف", value = if (guardian.phone.isNotBlank()) guardian.phone else "غير مسجل")
                        InfoRow(label = "معرّف الحساب (Account Code)", value = guardian.accountCode ?: "PAR-XXXXXX")
                        InfoRow(label = "حالة الحساب", value = if (guardian.status == "active") "مفعّل ونشط" else "بانتظار التفعيل")
                    }
                }
            }

            // School Contact Details
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(SurfaceWhite, RoundedCornerShape(12.dp))
                        .border(1.dp, BorderLight, RoundedCornerShape(12.dp))
                        .padding(16.dp)
                ) {
                    Column {
                        Text(
                            text = "بيانات التواصل الرسمية مع المدرسة",
                            fontSize = 13.5.sp,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )

                        Spacer(modifier = Modifier.height(10.dp))

                        InfoRow(label = "المؤسسة", value = "مدرسة العمرابي الثانوية بنين")
                        InfoRow(label = "المقر", value = "الخرطوم بحري — السودان")
                        InfoRow(label = "المتابعة الأكاديمية", value = "مكتب شؤون الطلاب والإدارة")
                        InfoRow(label = "إصدار التطبيق", value = "1.0.0 (النسخة الآمنة 2026.10)")
                    }
                }
            }

            // Privacy & Governance Note
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(BurgundyContainer.copy(alpha = 0.6f), RoundedCornerShape(12.dp))
                        .border(1.dp, BurgundyLight.copy(alpha = 0.2f), RoundedCornerShape(12.dp))
                        .padding(14.dp)
                ) {
                    Column {
                        Text(
                            text = "الخصوصية وحماية البيانات",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = BurgundyDark
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "بيانات الطلاب والنتائج محمية ومشفرة وتُعرض حصراً لولي الأمر المعتمد. لا يشارك التطبيق أي بيانات خاصة أو أرقام هواتف مع أي جهة خارجية.",
                            fontSize = 11.sp,
                            color = BurgundyDark,
                            lineHeight = 16.sp
                        )
                    }
                }
            }

            // Logout Button
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Button(
                    onClick = onLogout,
                    colors = ButtonDefaults.buttonColors(containerColor = StatusDanger),
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp)
                ) {
                    Icon(Icons.Default.ExitToApp, contentDescription = null, tint = Color.White)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "تسجيل الخروج من التطبيق",
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
fun InfoRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 5.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = label, fontSize = 12.sp, color = TextSecondary)
        Text(text = value, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = TextPrimary)
    }
}
