package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Payments
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.data.model.FeeItem
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt
import sd.alumrabi.parent.util.Reports
import sd.alumrabi.parent.util.shareText

@Composable
fun FeesScreen(
    children: List<LinkedChild>,
    selectedChildIndex: Int,
    onSelectChild: (Int) -> Unit
) {
    SystemBars(statusBar = Canvas, darkIcons = true)
    val context = LocalContext.current
    val child = children.getOrNull(selectedChildIndex)
    val fees = child?.fees

    Column(Modifier.fillMaxSize().background(Canvas).statusBarsPadding()) {
        ScreenHeader(
            title = "الرسوم الدراسية",
            subtitle = child?.fullName,
            modifier = Modifier.padding(horizontal = Space.gutter)
        )
        ChildChips(children, selectedChildIndex, onSelectChild, Modifier.padding(vertical = Space.sm))
        when {
            child == null -> StatePanel("لا يوجد ابن مرتبط", noChildMessage(), Modifier.padding(Space.gutter))
            !child.canViewFees -> EmptyNote(
                Icons.Outlined.Lock,
                "الرسوم غير متاحة لحسابك",
                "لا تملك صلاحية عرض الرسوم لهذا الابن. تواصل مع إدارة المدرسة.",
                Modifier.padding(Space.gutter)
            )
            fees == null -> EmptyNote(
                Icons.Outlined.Payments,
                "بيانات الرسوم غير متاحة حالياً",
                "ستظهر هنا حالة الرسوم والمدفوعات فور توفرها. جرّب التحديث لاحقاً.",
                Modifier.padding(Space.gutter)
            )
            else -> LazyColumn(
                contentPadding = PaddingValues(horizontal = Space.gutter, vertical = Space.sm),
                verticalArrangement = Arrangement.spacedBy(Space.md)
            ) {
                item {
                    Reveal(0) {
                        val frac = if (fees.netDue <= 0.0) 0f else (fees.totalPaid / fees.netDue).toFloat().coerceIn(0f, 1f)
                        Panel {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                ProgressRing(progress = frac, ringSize = 88.dp, color = Gold) {
                                    Text(
                                        Fmt.percent(frac * 100.0),
                                        style = MaterialTheme.typography.titleMedium.tabular(),
                                        color = Ink900
                                    )
                                }
                                Spacer(Modifier.width(Space.lg))
                                Column(Modifier.weight(1f)) {
                                    Text("المتبقي", style = MaterialTheme.typography.labelMedium, color = Ink500)
                                    Text(
                                        Fmt.money(fees.remainingBalance),
                                        style = MaterialTheme.typography.titleLarge.tabular(),
                                        color = if (fees.isFullyPaid) Positive else Ink900
                                    )
                                    Spacer(Modifier.height(4.dp))
                                    if (fees.isFullyPaid && fees.netDue > 0.0) Pill("مسدّدة بالكامل", Positive, PositiveBg)
                                    else if (fees.totalDue <= 0.0) Pill("لا رسوم مقررة", Ink700, Wash)
                                }
                            }
                            Spacer(Modifier.height(Space.lg))
                            RowDivider()
                            FigureRow("إجمالي الرسوم", Fmt.money(fees.totalDue))
                            if (fees.totalDiscounts > 0.0) FigureRow("الخصومات", "− " + Fmt.money(fees.totalDiscounts), Positive)
                            FigureRow("المستحق بعد الخصم", Fmt.money(fees.netDue))
                            FigureRow("المدفوع", Fmt.money(fees.totalPaid))
                        }
                    }
                }
                val regularItems = fees.items.filter { !it.isOptional }
                val optionalItems = fees.items.filter { it.isOptional }
                if (regularItems.isNotEmpty()) {
                    item { SectionLabel("بنود الرسوم") }
                    item { FeeItemsPanel(regularItems) }
                }
                if (optionalItems.isNotEmpty()) {
                    item { SectionLabel("رسوم اختيارية مسجَّلة لابنك") }
                    item { FeeItemsPanel(optionalItems) }
                }
                item { SectionLabel("سجل المدفوعات") }
                if (fees.payments.isEmpty()) {
                    item { EmptyNote(Icons.Outlined.Payments, "لا مدفوعات مسجلة", "ستظهر الإيصالات هنا بعد تسجيل أول دفعة.") }
                } else {
                    item {
                        Panel(padding = 0.dp) {
                            fees.payments.forEachIndexed { i, p ->
                                if (i > 0) RowDivider()
                                Row(
                                    Modifier.fillMaxWidth().padding(Space.lg),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column(Modifier.weight(1f)) {
                                        Text(Fmt.money(p.amount), style = MaterialTheme.typography.titleSmall.tabular(), color = Ink900)
                                        Text(
                                            listOfNotNull(p.feeName, Fmt.dateOrRaw(p.createdAt)).joinToString(" · "),
                                            style = MaterialTheme.typography.bodySmall,
                                            color = Ink500
                                        )
                                        Text("إيصال ${p.receiptNumber}", style = MaterialTheme.typography.labelSmall, color = Ink500)
                                    }
                                    CircleIconButton(
                                        icon = Icons.Outlined.Share,
                                        description = "مشاركة الإيصال",
                                        onClick = {
                                            shareText(
                                                context, "إيصال سداد",
                                                Reports.receipt(child, p.amount, p.receiptNumber, Fmt.dateOrRaw(p.createdAt), p.paymentMethod)
                                            )
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                item { Spacer(Modifier.height(Space.lg)) }
            }
        }
    }
}

@Composable
private fun FigureRow(label: String, value: String, color: androidx.compose.ui.graphics.Color = Ink900) {
    Row(Modifier.fillMaxWidth().padding(top = Space.md), verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = Ink700, modifier = Modifier.weight(1f))
        Text(value, style = MaterialTheme.typography.titleSmall.tabular(), color = color)
    }
}

@Composable
private fun FeeItemsPanel(list: List<FeeItem>) {
    Panel {
        list.forEachIndexed { i, fee ->
            if (i > 0) { Spacer(Modifier.height(Space.md)); RowDivider(); Spacer(Modifier.height(Space.md)) }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(fee.name, style = MaterialTheme.typography.titleSmall, color = Ink900)
                    if (!fee.dueDate.isNullOrBlank()) {
                        Text("الاستحقاق: ${Fmt.dateOrRaw(fee.dueDate)}", style = MaterialTheme.typography.bodySmall, color = Ink500)
                    }
                }
                if (fee.remaining <= 0.0 && fee.net > 0.0) Pill("مسدّد", Positive, PositiveBg)
                else Text(Fmt.money(fee.remaining), style = MaterialTheme.typography.titleSmall.tabular(), color = Ink900)
            }
            if (fee.net > 0.0) {
                Spacer(Modifier.height(Space.sm))
                FillBar(fraction = (fee.paid / fee.net).toFloat().coerceIn(0f, 1f), color = Gold, height = 6.dp)
                Spacer(Modifier.height(4.dp))
                Text(
                    "المدفوع ${Fmt.money(fee.paid)} من ${Fmt.money(fee.net)}",
                    style = MaterialTheme.typography.bodySmall,
                    color = Ink500
                )
            }
        }
    }
}
