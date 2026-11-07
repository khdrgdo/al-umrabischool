package sd.alumrabi.parent.ui.screens

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.Campaign
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import sd.alumrabi.parent.data.model.GuardianInfo
import sd.alumrabi.parent.ui.components.*
import sd.alumrabi.parent.ui.theme.*

@Composable
fun MoreScreen(
    guardian: GuardianInfo,
    onOpenRoute: (String) -> Unit,
    onSelectTab: (AppTab) -> Unit
) {
    Scaffold(
        topBar = { OmrabiTopBar(title = "المزيد", subtitle = guardian.fullName) },
        bottomBar = { OmrabiBottomBar(currentRoute = Routes.More, onSelect = onSelectTab) },
        containerColor = Canvas
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(horizontal = Space.gutter)
                .verticalScroll(rememberScrollState())
        ) {
            SectionLabel("الخدمات")
            GroupedList {
                ListRow(
                    title = "الإعلانات والتقويم",
                    subtitle = "إعلانات المدرسة والمواعيد القادمة",
                    leading = Icons.Outlined.Campaign,
                    onClick = { onOpenRoute(Routes.Announcements) }
                )
                RowDivider()
                ListRow(
                    title = "المساعد",
                    subtitle = "إجابات من بيانات ابنك المعتمدة",
                    leading = Icons.Outlined.ChatBubbleOutline,
                    onClick = { onOpenRoute(Routes.Assistant) }
                )
                RowDivider()
                ListRow(
                    title = "الجدول الدراسي",
                    subtitle = "غير متاح بعد",
                    leading = Icons.Outlined.CalendarMonth,
                    enabled = false
                )
            }
            SectionLabel("الحساب")
            GroupedList {
                ListRow(
                    title = "الإعدادات وحسابي",
                    subtitle = "بيانات الحساب وتسجيل الخروج",
                    leading = Icons.Outlined.Settings,
                    onClick = { onOpenRoute(Routes.Settings) }
                )
            }
        }
    }
}
