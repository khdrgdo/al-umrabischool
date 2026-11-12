package sd.alumrabi.parent.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EventAvailable
import androidx.compose.material.icons.filled.Grade
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material.icons.outlined.EventAvailable
import androidx.compose.material.icons.outlined.Grade
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.MoreHoriz
import androidx.compose.material.icons.outlined.Payments
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import sd.alumrabi.parent.ui.theme.*

object Routes {
    const val Splash = "splash"
    const val Login = "login"
    const val Home = "home"
    const val Results = "results"
    const val Attendance = "attendance"
    const val Fees = "fees"
    const val More = "more"
    const val Announcements = "announcements"
    const val Assistant = "assistant"
    const val Settings = "settings"
    const val Schedule = "schedule"
    const val Subjects = "subjects"
}

/** وجهات الشريط السفلي (حسب وثيقة APP-2: 5 وجهات كحد أقصى). */
enum class AppTab(val route: String, val label: String, val icon: ImageVector, val selectedIcon: ImageVector) {
    Home(Routes.Home, "الرئيسية", Icons.Outlined.Home, Icons.Filled.Home),
    Results(Routes.Results, "النتائج", Icons.Outlined.Grade, Icons.Filled.Grade),
    Attendance(Routes.Attendance, "الحضور", Icons.Outlined.EventAvailable, Icons.Filled.EventAvailable),
    Fees(Routes.Fees, "الرسوم", Icons.Outlined.Payments, Icons.Filled.Payments),
    More(Routes.More, "المزيد", Icons.Outlined.MoreHoriz, Icons.Filled.MoreHoriz)
}

val TabRoutes: Set<String> = AppTab.entries.map { it.route }.toSet()

/** شريط سفلي عائم الزوايا بقرص تحديد يتمدد بنابض، وشارة للعناصر غير المقروءة. */
@Composable
fun OmrabiBottomBar(
    currentRoute: String?,
    onSelect: (AppTab) -> Unit,
    badges: Map<String, Int> = emptyMap()
) {
    Surface(
        color = Paper,
        shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp),
        shadowElevation = 16.dp,
        tonalElevation = 0.dp
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 8.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            AppTab.entries.forEach { tab ->
                TabItem(
                    tab = tab,
                    selected = currentRoute == tab.route,
                    badge = badges[tab.route] ?: 0,
                    onClick = { onSelect(tab) },
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun TabItem(
    tab: AppTab,
    selected: Boolean,
    badge: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val pillWidth by animateDpAsState(
        targetValue = if (selected) 64.dp else 36.dp,
        animationSpec = spring(dampingRatio = 0.68f, stiffness = Spring.StiffnessMediumLow),
        label = "pillWidth"
    )
    val pillColor by animateColorAsState(if (selected) Crimson100 else Color.Transparent, label = "pillColor")
    val tint by animateColorAsState(if (selected) Crimson700 else Ink500, label = "tabTint")
    Column(
        modifier
            .clip(RoundedCornerShape(16.dp))
            .clickable(onClick = onClick)
            .padding(vertical = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            Modifier
                .width(pillWidth)
                .height(32.dp)
                .clip(CircleShape)
                .background(pillColor),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                if (selected) tab.selectedIcon else tab.icon,
                contentDescription = null,
                tint = tint,
                modifier = Modifier.size(24.dp)
            )
            if (badge > 0) {
                Box(
                    Modifier
                        .align(Alignment.TopEnd)
                        .padding(top = 3.dp, end = 12.dp)
                        .size(10.dp)
                        .border(1.5.dp, Paper, CircleShape)
                        .clip(CircleShape)
                        .background(Crimson500)
                )
            }
        }
        Text(
            tab.label,
            style = MaterialTheme.typography.labelMedium,
            color = tint,
            modifier = Modifier.padding(top = 2.dp)
        )
    }
}
