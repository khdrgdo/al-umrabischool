@file:OptIn(ExperimentalMaterial3Api::class)

package sd.alumrabi.parent.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.R
import sd.alumrabi.parent.data.model.BackendConnectionState
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.ui.theme.*
import sd.alumrabi.parent.util.Fmt

/** رمز العمرابي الرسمي (vector شفاف). tint للاستعمال فوق خلفية قرمزية (أبيض). */
@Composable
fun OmrabiSymbol(
    size: Dp,
    modifier: Modifier = Modifier,
    tint: Color? = null,
    description: String? = null
) {
    Image(
        painter = painterResource(R.drawable.ic_omrabi_symbol),
        contentDescription = description,
        modifier = modifier.size(size),
        colorFilter = if (tint != null) ColorFilter.tint(tint) else null
    )
}

/** شريط علوي فاتح بفاصل رفيع؛ القرمزي محجوز لشاشتي البداية والدخول وللأفعال. */
@Composable
fun OmrabiTopBar(
    title: String,
    subtitle: String? = null,
    onBack: (() -> Unit)? = null,
    actions: @Composable RowScope.() -> Unit = {}
) {
    Column(Modifier.background(Canvas)) {
        TopAppBar(
            title = {
                Column {
                    Text(
                        title,
                        style = MaterialTheme.typography.titleLarge,
                        color = Ink900,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.semantics { heading() }
                    )
                    if (subtitle != null) {
                        Text(
                            subtitle,
                            style = MaterialTheme.typography.bodySmall,
                            color = Ink500,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
            },
            navigationIcon = {
                if (onBack != null) {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = "رجوع", tint = Ink900)
                    }
                }
            },
            actions = actions,
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = Canvas,
                titleContentColor = Ink900,
                navigationIconContentColor = Ink900,
                actionIconContentColor = Ink900
            )
        )
        HorizontalDivider(color = Line)
    }
}

/** سطح أبيض واحد بحد رفيع يضم صفوفاً مفصولة بخطوط — بدل بطاقة منفصلة لكل عنصر. */
@Composable
fun GroupedList(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = Radius.card,
        color = Paper,
        border = BorderStroke(1.dp, Line)
    ) {
        Column(content = content)
    }
}

@Composable
fun RowDivider() {
    HorizontalDivider(color = Line, modifier = Modifier.padding(horizontal = Space.lg))
}

@Composable
fun SectionLabel(text: String, modifier: Modifier = Modifier) {
    Text(
        text,
        style = MaterialTheme.typography.titleSmall,
        color = Ink700,
        modifier = modifier
            .padding(top = Space.md, bottom = Space.xs, start = Space.xs)
            .semantics { heading() }
    )
}

/** صف قائمة: عنوان + سطر فرعي، أيقونة اختيارية في البداية، وسهم عند وجود إجراء. */
@Composable
fun ListRow(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    leading: ImageVector? = null,
    onClick: (() -> Unit)? = null,
    enabled: Boolean = true
) {
    val clickable = onClick != null && enabled
    val base = modifier
        .fillMaxWidth()
        .heightIn(min = 56.dp)
    Row(
        modifier = (if (clickable && onClick != null) base.clickable(onClick = onClick) else base)
            .padding(horizontal = Space.lg, vertical = Space.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (leading != null) {
            Icon(
                leading,
                contentDescription = null,
                tint = if (enabled) Ink700 else Ink500.copy(alpha = 0.6f),
                modifier = Modifier.size(22.dp)
            )
            Spacer(Modifier.width(Space.md))
        }
        Column(Modifier.weight(1f)) {
            Text(
                title,
                style = MaterialTheme.typography.bodyLarge,
                color = if (enabled) Ink900 else Ink500
            )
            if (subtitle != null) {
                Text(subtitle, style = MaterialTheme.typography.bodySmall, color = Ink500)
            }
        }
        if (clickable) {
            Spacer(Modifier.width(Space.sm))
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = Ink500
            )
        }
    }
}

/** شارة حالة نصية — لا تعتمد على اللون وحده. */
@Composable
fun StatusLabel(text: String, fg: Color, bg: Color, modifier: Modifier = Modifier) {
    Surface(modifier = modifier, shape = Radius.chip, color = bg) {
        Text(
            text,
            style = MaterialTheme.typography.labelMedium,
            color = fg,
            modifier = Modifier.padding(horizontal = Space.sm, vertical = 3.dp)
        )
    }
}

data class Stat(val value: String, val label: String)

/** شريط أرقام مفصول بخطوط رأسية (ملخص سريع). */
@Composable
fun StatStrip(stats: List<Stat>, modifier: Modifier = Modifier) {
    GroupedList(modifier) {
        Row(Modifier.fillMaxWidth().height(IntrinsicSize.Min)) {
            stats.forEachIndexed { index, stat ->
                if (index > 0) VerticalDivider(color = Line)
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .padding(vertical = Space.lg, horizontal = Space.sm),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        stat.value,
                        style = MaterialTheme.typography.titleLarge.tabular(),
                        color = Ink900
                    )
                    Text(
                        stat.label,
                        style = MaterialTheme.typography.labelMedium,
                        color = Ink500,
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

/** مبدّل الأبناء: يظهر فقط عند وجود أكثر من ابن. */
@Composable
fun ChildSwitcher(
    children: List<LinkedChild>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    if (children.size < 2) return
    LazyRow(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(Space.sm)) {
        itemsIndexed(children) { index, child ->
            val selected = index == selectedIndex
            Surface(
                selected = selected,
                onClick = { onSelect(index) },
                shape = Radius.field,
                color = if (selected) Crimson600 else Paper,
                border = if (selected) null else BorderStroke(1.dp, LineStrong)
            ) {
                Box(
                    modifier = Modifier
                        .heightIn(min = 44.dp)
                        .padding(horizontal = Space.lg),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        Fmt.shortName(child.fullName),
                        style = MaterialTheme.typography.labelLarge,
                        color = if (selected) OnBrand else Ink900
                    )
                }
            }
        }
    }
}

/** إشعار حالة المزامنة: لا يظهر عندما تكون البيانات حديثة. */
@Composable
fun SyncNotice(state: BackendConnectionState, lastSyncMillis: Long, modifier: Modifier = Modifier) {
    if (state == BackendConnectionState.CONNECTED_LIVE) return
    val offline = state == BackendConnectionState.SYNCED_LOCAL
    val fg = if (offline) Caution else Ink700
    val bg = if (offline) CautionBg else Wash
    val text = if (offline) {
        "لا يوجد اتصال بالخادم. تُعرض آخر بيانات محفوظة (آخر تحديث: ${Fmt.lastSync(lastSyncMillis)})."
    } else {
        "جارٍ تحديث البيانات…"
    }
    Surface(modifier = modifier.fillMaxWidth(), shape = Radius.field, color = bg) {
        Row(
            modifier = Modifier.padding(horizontal = Space.md, vertical = Space.md),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (offline) {
                Icon(Icons.Outlined.CloudOff, contentDescription = null, tint = fg, modifier = Modifier.size(18.dp))
            } else {
                CircularProgressIndicator(Modifier.size(16.dp), strokeWidth = 2.dp, color = fg)
            }
            Spacer(Modifier.width(Space.md))
            Text(text, style = MaterialTheme.typography.bodySmall, color = fg)
        }
    }
}

/** حالة فارغة / غير متاحة: نص صريح بدل أيقونة كبيرة. */
@Composable
fun StatePanel(
    title: String,
    message: String,
    modifier: Modifier = Modifier,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null
) {
    GroupedList(modifier) {
        Column(Modifier.padding(Space.xl)) {
            Text(title, style = MaterialTheme.typography.titleMedium, color = Ink900)
            Spacer(Modifier.height(Space.xs))
            Text(message, style = MaterialTheme.typography.bodyMedium, color = Ink700)
            if (actionLabel != null && onAction != null) {
                Spacer(Modifier.height(Space.lg))
                OutlineButton(text = actionLabel, onClick = onAction)
            }
        }
    }
}

@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    loading: Boolean = false
) {
    Button(
        onClick = onClick,
        enabled = enabled && !loading,
        modifier = modifier.heightIn(min = 52.dp),
        shape = Radius.field,
        colors = ButtonDefaults.buttonColors(
            containerColor = Crimson600,
            contentColor = OnBrand,
            disabledContainerColor = Crimson600.copy(alpha = 0.55f),
            disabledContentColor = OnBrand
        )
    ) {
        if (loading) {
            CircularProgressIndicator(Modifier.size(20.dp), color = OnBrand, strokeWidth = 2.dp)
        } else {
            Text(text, style = MaterialTheme.typography.labelLarge)
        }
    }
}

@Composable
fun OutlineButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.heightIn(min = 48.dp),
        shape = Radius.field,
        border = BorderStroke(1.dp, LineStrong),
        colors = ButtonDefaults.outlinedButtonColors(contentColor = Crimson700)
    ) {
        Text(text, style = MaterialTheme.typography.labelLarge)
    }
}

/** رمز دائري بحرف أول من الاسم. */
@Composable
fun Monogram(name: String, size: Dp = 48.dp) {
    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(Crimson100),
        contentAlignment = Alignment.Center
    ) {
        Text(
            name.trim().take(1),
            style = MaterialTheme.typography.titleMedium,
            color = Crimson700
        )
    }
}

/** صف «تسمية: قيمة». القيم اللاتينية (أكواد، هواتف) تُعرض LTR داخل الجملة العربية. */
@Composable
fun InfoRow(label: String, value: String, ltr: Boolean = false) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 52.dp)
            .padding(horizontal = Space.lg, vertical = Space.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            label,
            style = MaterialTheme.typography.bodyMedium,
            color = Ink500,
            modifier = Modifier.weight(1f)
        )
        Spacer(Modifier.width(Space.md))
        Text(
            value,
            style = if (ltr) {
                MaterialTheme.typography.bodyMedium.copy(textDirection = TextDirection.Ltr)
            } else {
                MaterialTheme.typography.bodyMedium
            },
            color = Ink900
        )
    }
}

fun noChildMessage() = "لا يوجد ابن مرتبط بحسابك حالياً. تواصل مع إدارة المدرسة لربط أبنائك."
