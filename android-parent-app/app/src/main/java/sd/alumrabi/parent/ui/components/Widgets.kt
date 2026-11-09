package sd.alumrabi.parent.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt

/** ظهور متدرّج للعناصر: تلاشٍ + انزلاق خفيف، بتأخير يعتمد على الترتيب. */
@Composable
fun Reveal(index: Int = 0, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    var visible by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(minOf(index, 8) * 60L)
        visible = true
    }
    AnimatedVisibility(
        visible = visible,
        modifier = modifier,
        enter = fadeIn(tween(380)) + slideInVertically(tween(380, easing = FastOutSlowInEasing)) { it / 10 }
    ) { content() }
}

/** قيمة تتصاعد من الصفر إلى الهدف عند الظهور (وعند تغيّر الهدف). */
@Composable
fun rememberCountUp(target: Float, durationMs: Int = 900): Float {
    var started by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { started = true }
    val v by animateFloatAsState(
        targetValue = if (started) target else 0f,
        animationSpec = tween(durationMs, easing = FastOutSlowInEasing),
        label = "countUp"
    )
    return v
}

/** ضغطة بتصغير لطيف بدل موجة Ripple افتراضية. */
fun Modifier.pressable(enabled: Boolean = true, onClick: () -> Unit): Modifier = composed {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (pressed) 0.97f else 1f,
        animationSpec = spring(stiffness = Spring.StiffnessMedium),
        label = "press"
    )
    this
        .graphicsLayer {
            scaleX = scale
            scaleY = scale
        }
        .clickable(interactionSource = source, indication = null, enabled = enabled, onClick = onClick)
}

@Composable
fun ShimmerBox(modifier: Modifier = Modifier, shape: Shape = RoundedCornerShape(16.dp)) {
    val transition = rememberInfiniteTransition(label = "shimmer")
    val x by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1300, easing = LinearEasing)),
        label = "shimmerX"
    )
    Box(
        modifier
            .clip(shape)
            .background(
                Brush.linearGradient(
                    colors = listOf(Wash, Paper, Wash),
                    start = Offset(x * 900f - 450f, 0f),
                    end = Offset(x * 900f, 300f)
                )
            )
    )
}

/** حلقة تقدّم متحركة. content يُرسم في وسطها. */
@Composable
fun ProgressRing(
    progress: Float,
    modifier: Modifier = Modifier,
    ringSize: Dp = 84.dp,
    stroke: Dp = 9.dp,
    color: Color = Crimson600,
    track: Color = Wash,
    content: @Composable BoxScope.() -> Unit = {}
) {
    val p = rememberCountUp(progress.coerceIn(0f, 1f), 1000)
    Box(modifier.size(ringSize), contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val w = stroke.toPx()
            val inset = w / 2f
            val arc = Size(this.size.width - w, this.size.height - w)
            drawArc(
                color = track, startAngle = -90f, sweepAngle = 360f, useCenter = false,
                topLeft = Offset(inset, inset), size = arc, style = Stroke(width = w, cap = StrokeCap.Round)
            )
            if (p > 0.002f) {
                drawArc(
                    color = color, startAngle = -90f, sweepAngle = 360f * p, useCenter = false,
                    topLeft = Offset(inset, inset), size = arc, style = Stroke(width = w, cap = StrokeCap.Round)
                )
            }
        }
        content()
    }
}

/** شريط تعبئة متحرك (يمتلئ من اتجاه القراءة). */
@Composable
fun FillBar(
    fraction: Float,
    modifier: Modifier = Modifier,
    color: Color = Crimson600,
    track: Color = Wash,
    height: Dp = 8.dp
) {
    val f = rememberCountUp(fraction.coerceIn(0f, 1f), 800)
    Box(
        modifier
            .fillMaxWidth()
            .height(height)
            .clip(CircleShape)
            .background(track)
    ) {
        Box(
            Modifier
                .fillMaxWidth(f)
                .fillMaxHeight()
                .clip(CircleShape)
                .background(color)
        )
    }
}

/** حبّة حالة نصية (لا تعتمد على اللون وحده). */
@Composable
fun Pill(text: String, fg: Color, bg: Color, modifier: Modifier = Modifier, icon: ImageVector? = null) {
    Row(
        modifier
            .clip(CircleShape)
            .background(bg)
            .padding(horizontal = 10.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon != null) {
            Icon(icon, contentDescription = null, tint = fg, modifier = Modifier.size(14.dp))
            Spacer(Modifier.width(4.dp))
        }
        Text(text, style = MaterialTheme.typography.labelMedium, color = fg)
    }
}

/** لوحة بيضاء بزوايا 18dp وظل ناعم وحد رفيع. */
@Composable
fun Panel(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    color: Color = Paper,
    padding: Dp = Space.lg,
    content: @Composable ColumnScope.() -> Unit
) {
    val shape = RoundedCornerShape(18.dp)
    val base = modifier
        .fillMaxWidth()
        .shadow(2.dp, shape, ambientColor = Ink900.copy(alpha = 0.08f), spotColor = Ink900.copy(alpha = 0.08f))
        .clip(shape)
        .background(color)
        .border(1.dp, Line, shape)
    Column(
        modifier = (if (onClick != null) base.pressable(onClick = onClick) else base).padding(padding),
        content = content
    )
}

/** خلفية قرمزية متدرجة للبطاقات المميزة. */
fun Modifier.brandGradient(shape: Shape): Modifier =
    this.clip(shape).background(Brush.linearGradient(listOf(Crimson800, Crimson600)))

@Composable
fun ScreenHeader(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    actions: @Composable RowScope.() -> Unit = {}
) {
    Row(
        modifier
            .fillMaxWidth()
            .padding(horizontal = Space.gutter)
            .padding(top = Space.lg, bottom = Space.sm),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(
                title,
                style = MaterialTheme.typography.headlineMedium,
                color = Ink900,
                modifier = Modifier.semantics { heading() }
            )
            if (subtitle != null) {
                Text(
                    subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = Ink500,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
        actions()
    }
}

@Composable
fun CircleIconButton(
    icon: ImageVector,
    description: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    container: Color = Wash,
    tint: Color = Ink900,
    showDot: Boolean = false
) {
    Box(
        modifier
            .size(44.dp)
            .clip(CircleShape)
            .background(container)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Icon(icon, contentDescription = description, tint = tint, modifier = Modifier.size(22.dp))
        if (showDot) {
            Box(
                Modifier
                    .align(Alignment.TopEnd)
                    .padding(10.dp)
                    .size(10.dp)
                    .border(1.5.dp, container, CircleShape)
                    .clip(CircleShape)
                    .background(Crimson500)
            )
        }
    }
}

/** مبدّل الأبناء بشرائح حيّة (صورة رمزية + اسم) مع حركة تحديد. */
@Composable
fun ChildChips(
    children: List<LinkedChild>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    if (children.size < 2) return
    val haptic = LocalHapticFeedback.current
    LazyRow(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(Space.sm),
        contentPadding = PaddingValues(horizontal = Space.gutter)
    ) {
        itemsIndexed(children) { index, child ->
            val selected = index == selectedIndex
            val bg by animateColorAsState(if (selected) Crimson600 else Paper, label = "chipBg")
            val fg by animateColorAsState(if (selected) OnBrand else Ink900, label = "chipFg")
            Row(
                Modifier
                    .clip(CircleShape)
                    .background(bg)
                    .border(1.dp, if (selected) Crimson600 else LineStrong, CircleShape)
                    .pressable {
                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        onSelect(index)
                    }
                    .padding(start = 6.dp, end = 14.dp, top = 6.dp, bottom = 6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    Modifier
                        .size(28.dp)
                        .clip(CircleShape)
                        .background(if (selected) OnBrand.copy(alpha = 0.22f) else Crimson100),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        child.fullName.trim().take(1),
                        style = MaterialTheme.typography.labelMedium,
                        color = if (selected) OnBrand else Crimson700
                    )
                }
                Spacer(Modifier.width(8.dp))
                Text(Fmt.firstName(child.fullName), style = MaterialTheme.typography.labelLarge, color = fg)
            }
        }
    }
}

/** حالة فارغة هادئة بأيقونة داخل دائرة. */
@Composable
fun EmptyNote(icon: ImageVector, title: String, message: String, modifier: Modifier = Modifier) {
    Column(
        modifier
            .fillMaxWidth()
            .padding(horizontal = Space.xl, vertical = Space.xxl),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            Modifier
                .size(72.dp)
                .clip(CircleShape)
                .background(Wash),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, contentDescription = null, tint = Ink500, modifier = Modifier.size(32.dp))
        }
        Spacer(Modifier.height(Space.lg))
        Text(title, style = MaterialTheme.typography.titleMedium, color = Ink900, textAlign = TextAlign.Center)
        Spacer(Modifier.height(Space.xs))
        Text(message, style = MaterialTheme.typography.bodyMedium, color = Ink700, textAlign = TextAlign.Center)
    }
}
