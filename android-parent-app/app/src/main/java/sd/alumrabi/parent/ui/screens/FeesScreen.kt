package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.data.model.PaymentRecord
import sd.alumrabi.parent.ui.theme.*
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FeesScreen(child: LinkedChild?, onBack: () -> Unit) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("الرسوم والمدفوعات", fontSize = 17.sp, fontWeight = FontWeight.Bold) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, contentDescription = "رجوع") } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = AppInk, titleContentColor = Color.White, navigationIconContentColor = Color.White)
            )
        },
        containerColor = LavenderCanvas
    ) { padding ->
        when {
            child == null -> EmptyFeesState("لم يتم تحديد طالب لعرض بياناته.", Modifier.padding(padding))
            !child.canViewFees -> EmptyFeesState("لا يملك هذا الحساب صلاحية الاطلاع على الرسوم لهذا الطالب.", Modifier.padding(padding))
            child.fees == null -> EmptyFeesState("لا توجد بيانات مالية منشورة لهذا الطالب حتى الآن.", Modifier.padding(padding))
            else -> {
                val statement = child.fees
                LazyColumn(
                    modifier = Modifier.fillMaxSize().padding(padding),
                    contentPadding = PaddingValues(18.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    item {
                        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(child.fullName, fontSize = 17.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                            Text("${child.gradeName} · ${child.sectionName}  |  ${child.studentNumber}", fontSize = 11.sp, color = TextSecondary)
                        }
                    }
                    item {
                        Surface(shape = RoundedCornerShape(18.dp), color = BurgundyPrimary) {
                            Column(modifier = Modifier.fillMaxWidth().padding(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                                Text("المبلغ المتبقي", color = Color.White.copy(alpha = 0.8f), fontSize = 12.sp)
                                Text(formatFeesAmount(statement.remainingBalance), color = Color.White, fontSize = 27.sp, fontWeight = FontWeight.Bold)
                                Text(if (statement.isFullyPaid) "تم سداد المستحقات المسجلة" else "الرصيد حسب آخر بيان مالي منشور", color = GoldAccent, fontSize = 11.sp)
                            }
                        }
                    }
                    item {
                        Surface(shape = RoundedCornerShape(14.dp), color = SurfaceWhite, border = androidx.compose.foundation.BorderStroke(1.dp, BorderLight)) {
                            Column(modifier = Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(13.dp)) {
                                FeeLine("إجمالي الرسوم", statement.totalDue)
                                FeeLine("الإعفاءات والخصومات", statement.totalDiscounts, negative = true)
                                FeeLine("صافي الرسوم", statement.netDue)
                                HorizontalDivider(color = BorderLight)
                                FeeLine("إجمالي المدفوع", statement.totalPaid, emphasize = true)
                                FeeLine("المتبقي", statement.remainingBalance, emphasize = true)
                            }
                        }
                    }
                    item {
                        Text("سجل المدفوعات", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                    }
                    if (statement.payments.isEmpty()) {
                        item {
                            Surface(shape = RoundedCornerShape(12.dp), color = SurfaceWhite, border = androidx.compose.foundation.BorderStroke(1.dp, BorderLight)) {
                                Text("لا توجد إيصالات مسجلة حتى الآن.", modifier = Modifier.fillMaxWidth().padding(16.dp), fontSize = 12.sp, color = TextSecondary)
                            }
                        }
                    } else {
                        items(statement.payments) { payment -> PaymentRow(payment) }
                    }
                    item {
                        Text("تعرض هذه الشاشة القيود المالية والإيصالات المسجلة في النظام فقط. لا يتم تنفيذ الدفع من داخل التطبيق.", fontSize = 10.sp, color = TextSecondary, lineHeight = 16.sp)
                    }
                }
            }
        }
    }
}

@Composable
private fun FeeLine(label: String, amount: Double, negative: Boolean = false, emphasize: Boolean = false) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
        Text(label, fontSize = 12.sp, color = if (emphasize) TextPrimary else TextSecondary, fontWeight = if (emphasize) FontWeight.Bold else FontWeight.Normal)
        Text(
            (if (negative) "− " else "") + formatFeesAmount(amount),
            fontSize = 13.sp,
            color = if (emphasize) BurgundyPrimary else TextPrimary,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun PaymentRow(payment: PaymentRecord) {
    Surface(shape = RoundedCornerShape(12.dp), color = SurfaceWhite, border = androidx.compose.foundation.BorderStroke(1.dp, BorderLight)) {
        Row(modifier = Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.ReceiptLong, contentDescription = null, tint = BurgundyPrimary, modifier = Modifier.size(23.dp))
            Spacer(Modifier.width(11.dp))
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text("إيصال ${payment.receiptNumber}", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                Text("${payment.paymentMethod} · ${payment.createdAt.take(10)}", fontSize = 10.sp, color = TextSecondary)
            }
            Text(formatFeesAmount(payment.amount), fontSize = 13.sp, fontWeight = FontWeight.Bold, color = BurgundyPrimary)
        }
    }
}

@Composable
private fun EmptyFeesState(message: String, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize().padding(24.dp), contentAlignment = Alignment.Center) {
        Surface(shape = RoundedCornerShape(14.dp), color = SurfaceWhite, border = androidx.compose.foundation.BorderStroke(1.dp, BorderLight)) {
            Text(message, modifier = Modifier.padding(20.dp), fontSize = 13.sp, color = TextSecondary, lineHeight = 20.sp)
        }
    }
}

private fun formatFeesAmount(value: Double): String = String.format(Locale.US, "%,.2f", value)
