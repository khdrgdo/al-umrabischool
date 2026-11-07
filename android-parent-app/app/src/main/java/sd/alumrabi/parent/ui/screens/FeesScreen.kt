package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.data.model.PaymentRecord
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt

/** الرسوم للقراءة فقط (APP-2): مستحق، إعفاءات، مدفوع، متبقٍ، إيصالات. */
@Composable
fun FeesScreen(
    children: List<LinkedChild>,
    selectedChildIndex: Int,
    onSelectChild: (Int) -> Unit,
    onSelectTab: (AppTab) -> Unit
) {
    SystemBars(statusBar = Canvas, darkIcons = true)
    val child = children.getOrNull(selectedChildIndex)
    val fees = child?.fees

    Scaffold(
        containerColor = Canvas,
        topBar = { OmrabiTopBar(title = "الرسوم الدراسية", subtitle = child?.fullName) },
        bottomBar = { OmrabiBottomBar(currentRoute = Routes.Fees, onSelect = onSelectTab) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(horizontal = Space.gutter, vertical = Space.lg),
            verticalArrangement = Arrangement.spacedBy(Space.sm)
        ) {
            if (children.size > 1) {
                item { ChildSwitcher(children, selectedChildIndex, onSelectChild) }
            }
            when {
                child == null -> item {
                    StatePanel(title = "لا يوجد ابن مرتبط", message = noChildMessage())
                }
                !child.canViewFees -> item {
                    StatePanel(
                        title = "الرسوم غير متاحة لحسابك",
                        message = "لا يملك حسابك صلاحية عرض رسوم هذا الطالب. تواصل مع إدارة المدرسة إن كان ذلك خطأ."
                    )
                }
                fees == null -> item {
                    StatePanel(
                        title = "بيانات الرسوم غير متاحة",
                        message = "تعذّر الحصول على بيانات الرسوم حالياً. حدّث البيانات من الصفحة الرئيسية وحاول لاحقاً."
                    )
                }
                else -> {
                    item {
                        GroupedList {
                            MoneyRow("إجمالي الرسوم المقررة", fees.totalDue)
                            if (fees.totalDiscounts > 0.0) {
                                RowDivider()
                                MoneyRow("الخصومات والمنح", fees.totalDiscounts)
                            }
                            RowDivider()
                            MoneyRow("المدفوع", fees.totalPaid)
                            RowDivider()
                            MoneyRow("المتبقي", fees.remainingBalance, emphasize = true)
                        }
                    }
                    if (fees.totalDue > 0.0 && fees.isFullyPaid) {
                        item {
                            StatusLabel("مسدّدة بالكامل", Positive, PositiveBg)
                        }
                    }
                    item { SectionLabel("الإيصالات") }
                    if (fees.payments.isEmpty()) {
                        item {
                            StatePanel(
                                title = "لا توجد مدفوعات مسجّلة",
                                message = "تظهر إيصالات السداد هنا بعد تسجيلها لدى الإدارة المالية."
                            )
                        }
                    } else {
                        item {
                            GroupedList {
                                fees.payments.forEachIndexed { index, payment ->
                                    if (index > 0) RowDivider()
                                    PaymentRow(payment)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun MoneyRow(label: String, amount: Double, emphasize: Boolean = false) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 52.dp)
            .padding(horizontal = Space.lg, vertical = Space.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            label,
            style = if (emphasize) MaterialTheme.typography.titleSmall else MaterialTheme.typography.bodyMedium,
            color = if (emphasize) Ink900 else Ink700,
            modifier = Modifier.weight(1f)
        )
        Text(
            "${Fmt.number(amount)} جنيه",
            style = (if (emphasize) MaterialTheme.typography.titleMedium else MaterialTheme.typography.bodyLarge).tabular(),
            color = if (emphasize && amount > 0.0) Crimson700 else Ink900
        )
    }
}

@Composable
private fun PaymentRow(payment: PaymentRecord) {
    val date = Fmt.dateOrRaw(payment.createdAt)
    val method = when (payment.paymentMethod) {
        "cash" -> "نقداً"
        "bank", "bank_transfer", "transfer" -> "تحويل بنكي"
        else -> payment.paymentMethod
    }
    val ltr: TextStyle = MaterialTheme.typography.bodySmall.copy(textDirection = TextDirection.Ltr)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 56.dp)
            .padding(horizontal = Space.lg, vertical = Space.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text("$date · $method", style = MaterialTheme.typography.bodyMedium, color = Ink900)
            Text("إيصال ${payment.receiptNumber}", style = ltr, color = Ink500)
        }
        Text(
            "${Fmt.number(payment.amount)} جنيه",
            style = MaterialTheme.typography.titleSmall.tabular(),
            color = Ink900
        )
    }
}
