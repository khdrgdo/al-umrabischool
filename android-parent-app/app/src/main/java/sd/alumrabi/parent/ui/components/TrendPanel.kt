package sd.alumrabi.parent.ui.components

import androidx.compose.foundation.Canvas as DrawCanvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.data.model.PublishedGrade
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.trendPercents
import sd.alumrabi.parent.util.trendSummary
import kotlin.math.abs

/** تطور مستوى الطالب عبر النتائج المنشورة: كل المواد أو مادة محددة. */
@Composable
fun TrendPanel(
    grades: List<PublishedGrade>,
    subjects: List<String>,
    scope: String?,
    onScope: (String?) -> Unit,
    modifier: Modifier = Modifier
) {
    val values = grades.trendPercents(scope)
    val summary = values.trendSummary()
    Panel(modifier) {
        Text("تطور المستوى", style = MaterialTheme.typography.titleMedium, color = Ink900)
        Text("النتائج مرتبة زمنياً من الأقدم إلى الأحدث", style = MaterialTheme.typography.bodySmall, color = Ink500)
        Spacer(Modifier.height(Space.md))
        Row(
            Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(Space.sm)
        ) {
            ScopeChip("كل المواد", scope == null) { onScope(null) }
            subjects.forEach { s -> ScopeChip(s, scope == s) { onScope(s) } }
        }
        Spacer(Modifier.height(Space.md))
        if (summary == null) {
            Text(
                "يظهر الاتجاه بعد رصد نتيجتين أو أكثر.",
                style = MaterialTheme.typography.bodyMedium,
                color = Ink500
            )
        } else {
            val delta = summary.delta
            val points = abs(delta).toInt()
            when {
                delta >= 3 -> Pill("تحسّن بمقدار $points نقطة", Positive, PositiveBg)
                delta <= -3 -> Pill("تراجع بمقدار $points نقطة", Negative, NegativeBg)
                else -> Pill("مستوى مستقر", Ink700, Wash)
            }
            Spacer(Modifier.height(Space.xs))
            Text(
                "متوسط النتائج الأحدث " + summary.recent.toInt() + "% مقابل " + summary.earlier.toInt() + "% قبلها",
                style = MaterialTheme.typography.bodySmall,
                color = Ink700
            )
            Spacer(Modifier.height(Space.sm))
            TrendChart(values, Modifier.fillMaxWidth().height(140.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("الأقدم", style = MaterialTheme.typography.labelSmall, color = Ink500)
                Text("الخط المتقطع = 50%", style = MaterialTheme.typography.labelSmall, color = Ink500)
                Text("الأحدث", style = MaterialTheme.typography.labelSmall, color = Ink500)
            }
        }
    }
}

@Composable
private fun TrendChart(values: List<Double>, modifier: Modifier, lineColor: Color = Crimson500) {
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    val grid = Line
    val dashColor = LineStrong
    DrawCanvas(modifier) {
        val padX = 12.dp.toPx()
        val padY = 10.dp.toPx()
        val w = size.width - padX * 2
        val h = size.height - padY * 2
        fun xAt(i: Int): Float {
            val t = if (values.size == 1) 0.5f else i / (values.size - 1f)
            val x = padX + t * w
            return if (rtl) size.width - x else x
        }
        fun yAt(v: Double): Float = padY + h * (1f - (v.coerceIn(0.0, 100.0) / 100.0).toFloat())
        listOf(0.0, 50.0, 100.0).forEach { g ->
            val dashed = g == 50.0
            drawLine(
                color = if (dashed) dashColor else grid,
                start = Offset(0f, yAt(g)),
                end = Offset(size.width, yAt(g)),
                strokeWidth = 1.dp.toPx(),
                pathEffect = if (dashed) PathEffect.dashPathEffect(floatArrayOf(10f, 10f)) else null
            )
        }
        val path = Path()
        values.forEachIndexed { i, v ->
            if (i == 0) path.moveTo(xAt(i), yAt(v)) else path.lineTo(xAt(i), yAt(v))
        }
        drawPath(
            path,
            color = lineColor,
            style = Stroke(width = 3.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
        values.forEachIndexed { i, v ->
            drawCircle(
                color = lineColor,
                radius = (if (i == values.lastIndex) 6.dp else 4.dp).toPx(),
                center = Offset(xAt(i), yAt(v))
            )
        }
    }
}

@Composable
private fun ScopeChip(text: String, selected: Boolean, onClick: () -> Unit) {
    Text(
        text,
        style = MaterialTheme.typography.labelLarge,
        color = if (selected) OnBrand else Ink900,
        modifier = Modifier
            .clip(CircleShape)
            .background(if (selected) Crimson600 else Wash)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp)
    )
}
