package sd.alumrabi.parent.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.R
import sd.alumrabi.parent.data.model.BackendConnectionState
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.ui.theme.*

/** رمز العمرابي الرسمي (vector شفاف). */
@Composable
fun OmrabiSymbol(size: Dp, modifier: Modifier = Modifier) {
    Image(
        painter = painterResource(R.drawable.ic_omrabi_symbol),
        contentDescription = "شعار العمرابي",
        modifier = modifier.size(size)
    )
}

/** شريط علوي مؤسسي قرمزي، مع رجوع اختياري وسطر فرعي (اسم الابن غالباً). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OmrabiTopBar(
    title: String,
    subtitle: String? = null,
    onBack: (() -> Unit)? = null,
    actions: @Composable RowScope.() -> Unit = {}
) {
    TopAppBar(
        title = {
            Column {
                Text(title, style = MaterialTheme.typography.titleMedium, color = OnBrand,
                    modifier = Modifier.semantics { heading() })
                if (subtitle != null) {
                    Text(subtitle, style = MaterialTheme.typography.labelMedium,
                        color = OnBrand.copy(alpha = 0.82f), maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
        },
        navigationIcon = {
            if (onBack != null) {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "رجوع", tint = OnBrand)
                }
            }
        },
        actions = actions,
        colors = TopAppBarDefaults.topAppBarColors(containerColor = Crimson700)
    )
}

/** بطاقة بيضاء بحد رفيع — الوحدة الأساسية للمحتوى. */
@Composable
fun PanelCard(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    padding: PaddingValues = PaddingValues(Space.lg),
    content: @Composable ColumnScope.() -> Unit
) {
    val base = modifier.fillMaxWidth()
    Surface(
        modifier = if (onClick != null) base.clip(Radius.card).clickable(onClick = onClick) else base,
        shape = Radius.card,
        color = CardSurface,
        border = BorderStroke(1.dp, Hairline),
        tonalElevation = Elevation.flat
    ) {
        Column(Modifier.padding(padding), content = content)
    }
}

/** عنوان قسم مع خط قرمزي قصير على اليمين (بداية السطر في RTL). */
@Composable
fun SectionHeader(text: String, trailing: (@Composable () -> Unit)? = null) {
    Row(
        Modifier.fillMaxWidth().padding(top = Space.sm, bottom = Space.sm),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(Modifier.width(3.dp).height(16.dp).background(Crimson600))
        Spacer(Modifier.width(Space.sm))
        Text(text, style = MaterialTheme.typography.titleSmall, color = InkPrimary,
            modifier = Modifier.weight(1f).semantics { heading() })
        trailing?.invoke()
    }
}

/** شارة حالة نصية دائماً — لا تعتمد على اللون وحده. */
@Composable
fun StatusChip(text: String, fg: Color, bg: Color) {
    Surface(shape = Radius.chip, color = bg) {
        Text(text, style = MaterialTheme.typography.labelMedium, color = fg,
            modifier = Modifier.padding(horizontal = Space.sm, vertical = Space.xxs + 1.dp))
    }
}

/** قيمة رقمية مع وصف. */
@Composable
fun Metric(label: String, value: String, modifier: Modifier = Modifier, accent: Color = InkPrimary) {
    Column(modifier) {
        Text(value, style = MaterialTheme.typography.headlineSmall, color = accent)
        Text(label, style = MaterialTheme.typography.labelMedium, color = InkSecondary)
    }
}

/** رمز دائري بحرف أول من الاسم للابن. */
@Composable
fun Monogram(name: String, size: Dp = 40.dp, selected: Boolean = true) {
    Box(
        Modifier.size(size).clip(CircleShape).background(if (selected) Crimson600 else Gray200),
        contentAlignment = Alignment.Center
    ) {
        Text(name.trim().take(1), style = MaterialTheme.typography.titleMedium,
            color = if (selected) OnBrand else InkSecondary)
    }
}

/** شريط تنبيه حالة الاتصال. */
@Composable
fun ConnectionBanner(state: BackendConnectionState) {
    if (state == BackendConnectionState.CONNECTED_LIVE) return
    val (text, fg, bg) = when (state) {
        BackendConnectionState.CONNECTING -> Triple("جارٍ الاتصال بخادم المدرسة…", InkSecondary, Gray200)
        else -> Triple("أنت غير متصل — تُعرض آخر بيانات محفوظة وقد لا تكون محدثة", Caution, CautionBg)
    }
    Row(
        Modifier.fillMaxWidth().background(bg).padding(horizontal = Space.lg, vertical = Space.sm),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (state == BackendConnectionState.CONNECTING) {
            CircularProgressIndicator(Modifier.size(14.dp), strokeWidth = 2.dp, color = fg)
        } else {
            Icon(Icons.Default.Warning, null, tint = fg, modifier = Modifier.size(16.dp))
        }
        Spacer(Modifier.width(Space.sm))
        Text(text, style = MaterialTheme.typography.labelMedium, color = fg)
    }
}

/** حالة فارغة / خطأ / عدم توفر — موحدة لكل الشاشات. */
@Composable
fun StatePanel(
    title: String,
    message: String,
    icon: ImageVector = Icons.Default.Info,
    tone: Color = InkSecondary,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Column(
        modifier.fillMaxWidth().padding(horizontal = Space.xxl, vertical = 48.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(Modifier.size(56.dp).clip(CircleShape).background(Gray200), contentAlignment = Alignment.Center) {
            Icon(icon, null, tint = tone, modifier = Modifier.size(26.dp))
        }
        Spacer(Modifier.height(Space.lg))
        Text(title, style = MaterialTheme.typography.titleMedium, color = InkPrimary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(Space.xs))
        Text(message, style = MaterialTheme.typography.bodyMedium, color = InkSecondary, textAlign = TextAlign.Center)
        if (actionLabel != null && onAction != null) {
            Spacer(Modifier.height(Space.lg))
            OutlinedButton(onClick = onAction, shape = Radius.field, border = BorderStroke(1.dp, Crimson600)) {
                Icon(Icons.Default.Refresh, null, tint = Crimson600, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(Space.xs))
                Text(actionLabel, color = Crimson600)
            }
        }
    }
}

@Composable
fun LoadingPanel(message: String = "جارٍ التحميل…") {
    Column(
        Modifier.fillMaxWidth().padding(vertical = 64.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        CircularProgressIndicator(color = Crimson600, strokeWidth = 3.dp)
        Spacer(Modifier.height(Space.md))
        Text(message, style = MaterialTheme.typography.bodyMedium, color = InkSecondary)
    }
}

/** شريط اختيار الابن النشط داخل الشاشات الفرعية. */
@Composable
fun ChildContextBar(child: LinkedChild?, canSwitch: Boolean, onSwitch: () -> Unit) {
    if (child == null) return
    Row(
        Modifier.fillMaxWidth().background(CardSurface)
            .then(if (canSwitch) Modifier.clickable(onClick = onSwitch) else Modifier)
            .padding(horizontal = Space.lg, vertical = Space.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Monogram(child.fullName, 32.dp)
        Spacer(Modifier.width(Space.md))
        Column(Modifier.weight(1f)) {
            Text(child.fullName, style = MaterialTheme.typography.titleSmall, color = InkPrimary,
                maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text("${child.gradeName} · ${child.sectionName} · ${child.studentNumber}",
                style = MaterialTheme.typography.labelSmall, color = InkSecondary, maxLines = 1)
        }
        if (canSwitch) Text("تبديل", style = MaterialTheme.typography.labelLarge, color = Crimson600)
    }
    HorizontalDivider(color = Hairline)
}

fun noChildMessage() = "لا يوجد ابن مرتبط بحسابك حالياً. تواصل مع إدارة المدرسة لربط أبنائك."
