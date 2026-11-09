package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.Campaign
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.data.model.GuardianInfo
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*

@Composable
fun MoreScreen(
    guardian: GuardianInfo,
    unreadAnnouncements: Int,
    onOpenRoute: (String) -> Unit,
    onCheckNow: (() -> Unit)? = null
) {
    SystemBars(statusBar = Canvas, darkIcons = true)
    Column(
        Modifier
            .fillMaxSize()
            .background(Canvas)
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Space.gutter)
    ) {
        ScreenHeader(title = "المزيد")
        Reveal(0) {
            Panel {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Monogram(guardian.fullName, 52.dp)
                    Spacer(Modifier.width(Space.md))
                    Column(Modifier.weight(1f)) {
                        Text(guardian.fullName, style = MaterialTheme.typography.titleMedium, color = Ink900)
                        val code = guardian.accountCode
                        if (!code.isNullOrBlank()) {
                            Text("رقم ولي الأمر $code", style = MaterialTheme.typography.bodySmall, color = Ink500)
                        }
                    }
                    Pill(
                        if (guardian.status == "active") "مفعّل" else "بانتظار التفعيل",
                        if (guardian.status == "active") Positive else Caution,
                        if (guardian.status == "active") PositiveBg else CautionBg
                    )
                }
            }
        }
        Spacer(Modifier.padding(top = Space.lg))
        SectionLabel("الخدمات")
        Reveal(1) {
            GroupedList {
                ListRow(
                    title = "الجدول الدراسي",
                    subtitle = "حصص الأسبوع والفسحات",
                    leading = Icons.Outlined.CalendarMonth,
                    onClick = { onOpenRoute(Routes.Schedule) }
                )
                RowDivider()
                ListRow(
                    title = if (unreadAnnouncements > 0) "الإعلانات والتقويم ($unreadAnnouncements جديد)" else "الإعلانات والتقويم",
                    subtitle = "إعلانات المدرسة ومواعيدها",
                    leading = Icons.Outlined.Campaign,
                    onClick = { onOpenRoute(Routes.Announcements) }
                )
                RowDivider()
                ListRow(
                    title = "المساعد الذكي",
                    subtitle = "ملخصات وإجابات من بيانات ابنك",
                    leading = Icons.Outlined.AutoAwesome,
                    onClick = { onOpenRoute(Routes.Assistant) }
                )
            }
        }
        Spacer(Modifier.padding(top = Space.lg))
        SectionLabel("الحساب")
        Reveal(2) {
            GroupedList {
                ListRow(
                    title = "الإعدادات وحسابي",
                    subtitle = "بيانات الحساب وتسجيل الخروج",
                    leading = Icons.Outlined.Settings,
                    onClick = { onOpenRoute(Routes.Settings) }
                )
                if (onCheckNow != null) {
                    RowDivider()
                    ListRow(
                        title = "فحص الإشعارات الآن (للتجربة)",
                        subtitle = "يشغّل الفحص الدوري فوراً",
                        leading = Icons.Outlined.Notifications,
                        onClick = onCheckNow
                    )
                }
            }
        }
        Spacer(Modifier.padding(top = Space.xxl))
    }
}
