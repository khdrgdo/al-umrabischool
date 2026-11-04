package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import sd.alumrabi.parent.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MoreScreen(
    onNavigateToFees: () -> Unit,
    onNavigateToAnnouncements: () -> Unit,
    onNavigateToSettings: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text("المزيد", fontSize = 18.sp, fontWeight = FontWeight.Bold)
                        Text("خدمات ومعلومات حسابك", fontSize = 11.sp, color = Color.White.copy(alpha = 0.76f))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = BurgundyPrimary,
                    titleContentColor = Color.White
                )
            )
        },
        containerColor = LavenderCanvas
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(horizontal = 18.dp, vertical = 18.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                Text(
                    "كل ما تحتاجه لمتابعة علاقتك بالمؤسسة في مكان واحد.",
                    color = TextSecondary,
                    fontSize = 12.sp,
                    lineHeight = 19.sp,
                    modifier = Modifier.padding(bottom = 4.dp)
                )
            }
            item {
                MoreActionCard(
                    title = "الرسوم والمدفوعات",
                    subtitle = "البيان المالي وسجل الإيصالات المعتمدة",
                    icon = Icons.Default.AccountBalanceWallet,
                    onClick = onNavigateToFees
                )
            }
            item {
                MoreActionCard(
                    title = "الإعلانات والتقويم",
                    subtitle = "تعاميم المؤسسة والمواعيد والفعاليات",
                    icon = Icons.Default.Campaign,
                    onClick = onNavigateToAnnouncements
                )
            }
            item {
                MoreActionCard(
                    title = "إعدادات الحساب",
                    subtitle = "بيانات ولي الأمر وإدارة جلسة الدخول",
                    icon = Icons.Default.Settings,
                    onClick = onNavigateToSettings
                )
            }
            item {
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    color = SurfaceWhite,
                    border = BorderStroke(1.dp, BorderLight)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.Info, contentDescription = null, tint = GoldAccent)
                        Spacer(Modifier.width(10.dp))
                        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                            Text("حول تطبيق العمرابي", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                            Text("بوابة الأسرة لمتابعة شؤون الأبناء التعليمية.", fontSize = 11.sp, color = TextSecondary)
                        }
                    }
                }
            }
            item {
                Text(
                    "تظهر المعلومات المنشورة والمعتمدة من إدارة المؤسسة فقط.",
                    color = TextSecondary,
                    fontSize = 10.sp,
                    lineHeight = 16.sp,
                    modifier = Modifier.padding(top = 6.dp)
                )
            }
        }
    }
}

@Composable
private fun MoreActionCard(
    title: String,
    subtitle: String,
    icon: ImageVector,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        color = SurfaceWhite,
        border = BorderStroke(1.dp, BorderLight),
        shadowElevation = 1.dp
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 15.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = BurgundyContainer,
                modifier = Modifier.size(44.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(icon, contentDescription = null, tint = BurgundyPrimary, modifier = Modifier.size(22.dp))
                }
            }
            Spacer(Modifier.width(13.dp))
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(title, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                Text(subtitle, fontSize = 10.sp, color = TextSecondary, lineHeight = 15.sp)
            }
            Icon(Icons.Default.ChevronLeft, contentDescription = null, tint = TextSecondary)
        }
    }
}
