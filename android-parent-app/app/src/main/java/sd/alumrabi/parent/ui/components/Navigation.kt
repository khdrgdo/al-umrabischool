package sd.alumrabi.parent.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.EventAvailable
import androidx.compose.material.icons.outlined.Grade
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.MoreHoriz
import androidx.compose.material.icons.outlined.Payments
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
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
}

/** وجهات الشريط السفلي (حسب وثيقة APP-2: 5 وجهات كحد أقصى). */
enum class AppTab(val route: String, val label: String, val icon: ImageVector) {
    Home(Routes.Home, "الرئيسية", Icons.Outlined.Home),
    Results(Routes.Results, "النتائج", Icons.Outlined.Grade),
    Attendance(Routes.Attendance, "الحضور", Icons.Outlined.EventAvailable),
    Fees(Routes.Fees, "الرسوم", Icons.Outlined.Payments),
    More(Routes.More, "المزيد", Icons.Outlined.MoreHoriz)
}

@Composable
fun OmrabiBottomBar(currentRoute: String?, onSelect: (AppTab) -> Unit) {
    Column {
        HorizontalDivider(color = Line)
        NavigationBar(containerColor = Paper, tonalElevation = 0.dp) {
            AppTab.entries.forEach { tab ->
                NavigationBarItem(
                    selected = currentRoute == tab.route,
                    onClick = { onSelect(tab) },
                    icon = { Icon(tab.icon, contentDescription = null) },
                    label = { Text(tab.label, style = MaterialTheme.typography.labelMedium) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = Crimson700,
                        selectedTextColor = Crimson700,
                        indicatorColor = Crimson100,
                        unselectedIconColor = Ink500,
                        unselectedTextColor = Ink500
                    )
                )
            }
        }
    }
}
