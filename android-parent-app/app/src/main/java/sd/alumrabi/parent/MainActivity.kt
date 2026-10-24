package sd.alumrabi.parent

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.launch
import sd.alumrabi.parent.data.api.ParentApiClient
import sd.alumrabi.parent.data.model.AnnouncementItem
import sd.alumrabi.parent.data.model.CalendarEventItem
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
    val coroutineScope = rememberCoroutineScope()
    val apiClient = remember { ParentApiClient() }

    // Session State
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

    var announcements by remember {
        mutableStateOf<List<AnnouncementItem>>(emptyList())
    }

    var events by remember {
        mutableStateOf<List<CalendarEventItem>>(emptyList())
    }

    var selectedChildIndex by remember { mutableIntStateOf(0) }

    // Fetch announcements and events in background
    LaunchedEffect(Unit) {
        coroutineScope.launch {
            val annResult = apiClient.fetchAnnouncements()
            announcements = annResult.getOrDefault(emptyList())

            val evResult = apiClient.fetchEvents()
            events = evResult.getOrDefault(emptyList())
        }
    }

    NavHost(
        navController = navController,
        startDestination = "splash",
        enterTransition = {
            slideIntoContainer(
                AnimatedContentTransitionScope.SlideDirection.Start,
                animationSpec = tween(320)
            ) + fadeIn(animationSpec = tween(320))
        },
        exitTransition = {
            slideOutOfContainer(
                AnimatedContentTransitionScope.SlideDirection.Start,
                animationSpec = tween(320)
            ) + fadeOut(animationSpec = tween(320))
        },
        popEnterTransition = {
            slideIntoContainer(
                AnimatedContentTransitionScope.SlideDirection.End,
                animationSpec = tween(320)
            ) + fadeIn(animationSpec = tween(320))
        },
        popExitTransition = {
            slideOutOfContainer(
                AnimatedContentTransitionScope.SlideDirection.End,
                animationSpec = tween(320)
            ) + fadeOut(animationSpec = tween(320))
        }
    ) {
        composable("splash") {
            AnimatedSplashScreen(
                onSplashFinished = {
                    navController.navigate("login") {
                        popUpTo("splash") { inclusive = true }
                    }
                }
            )
        }

        composable("login") {
            LoginScreen(
                onLoginSuccess = { guardian, children ->
                    currentGuardian = guardian
                    currentChildren = children
                    selectedChildIndex = 0
                    navController.navigate("dashboard") {
                        popUpTo("login") { inclusive = true }
                    }
                }
            )
        }

        composable("dashboard") {
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
            ScheduleScreen(
                child = activeChild,
                onBack = { navController.popBackStack() }
            )
        }

        composable("announcements") {
            AnnouncementsScreen(
                announcements = announcements,
                events = events,
                onBack = { navController.popBackStack() }
            )
        }

        composable("settings") {
            SettingsScreen(
                guardian = currentGuardian,
                onBack = { navController.popBackStack() },
                onLogout = {
                    currentGuardian = currentGuardian.copy(id = "", accountCode = "")
                    currentChildren = emptyList()
                    navController.navigate("login") {
                        popUpTo("dashboard") { inclusive = true }
                    }
                }
            )
        }
    }
}
