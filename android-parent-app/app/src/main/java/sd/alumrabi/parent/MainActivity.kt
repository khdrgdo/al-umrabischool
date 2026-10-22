package sd.alumrabi.parent

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import sd.alumrabi.parent.data.model.DashboardPayload
import sd.alumrabi.parent.data.model.GuardianInfo
import sd.alumrabi.parent.data.model.LinkedChild
import sd.alumrabi.parent.ui.screens.*
import sd.alumrabi.parent.ui.theme.AlUmrabiParentTheme
import sd.alumrabi.parent.ui.theme.LavenderCanvas

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            // Strict Arabic RTL Layout
            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
                AlUmrabiParentTheme {
                    Surface(
                        modifier = Modifier.fillMaxSize(),
                        color = LavenderCanvas
                    ) {
                        ParentAppNavHost()
                    }
                }
            }
        }
    }
}

@Composable
fun ParentAppNavHost() {
    val navController = rememberNavController()

    // State
    var isLoggedIn by remember { mutableStateOf(false) }
    var selectedChildIndex by remember { mutableIntStateOf(0) }

    // Mock/Initial Authenticated Guardian data placeholder
    var currentGuardian by remember {
        mutableStateOf(
            GuardianInfo(
                id = "",
                accountCode = "",
                fullName = "ولي الأمر",
                phone = "",
                status = "active"
            )
        )
    }

    var currentChildren by remember {
        mutableStateOf<List<LinkedChild>>(emptyList())
    }

    val startDestination = if (isLoggedIn) "dashboard" else "login"

    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        composable("login") {
            LoginScreen(
                onLoginSuccess = { accountCode ->
                    currentGuardian = currentGuardian.copy(accountCode = accountCode)
                    isLoggedIn = true
                    navController.navigate("dashboard") {
                        popUpTo("login") { inclusive = true }
                    }
                }
            )
        }

        composable("dashboard") {
            val activeChild = currentChildren.getOrNull(selectedChildIndex)

            DashboardScreen(
                guardian = currentGuardian,
                children = currentChildren,
                selectedChildIndex = selectedChildIndex,
                onSelectChild = { index -> selectedChildIndex = index },
                onNavigateToGrades = { navController.navigate("grades") },
                onNavigateToAttendance = { navController.navigate("attendance") },
                onNavigateToSchedule = { navController.navigate("schedule") },
                onNavigateToAnnouncements = { navController.navigate("announcements") },
                onNavigateToSettings = { navController.navigate("settings") }
            )
        }

        composable("grades") {
            val activeChild = currentChildren.getOrNull(selectedChildIndex)
            GradesScreen(
                child = activeChild,
                onBack = { navController.popBackStack() }
            )
        }

        composable("attendance") {
            val activeChild = currentChildren.getOrNull(selectedChildIndex)
            AttendanceScreen(
                child = activeChild,
                onBack = { navController.popBackStack() }
            )
        }

        composable("schedule") {
            val activeChild = currentChildren.getOrNull(selectedChildIndex)
            AttendanceScreen( // Using same structure for schedule periods
                child = activeChild,
                onBack = { navController.popBackStack() }
            )
        }

        composable("announcements") {
            AnnouncementsScreen(
                announcements = emptyList(),
                events = emptyList(),
                onBack = { navController.popBackStack() }
            )
        }

        composable("settings") {
            SettingsScreen(
                guardian = currentGuardian,
                onBack = { navController.popBackStack() },
                onLogout = {
                    isLoggedIn = false
                    navController.navigate("login") {
                        popUpTo("dashboard") { inclusive = true }
                    }
                }
            )
        }
    }
}
