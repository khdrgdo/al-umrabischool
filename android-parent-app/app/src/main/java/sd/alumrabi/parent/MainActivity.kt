package sd.alumrabi.parent

import android.os.Bundle
import android.view.WindowManager
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.launch
import sd.alumrabi.parent.data.api.ParentApiClient
import sd.alumrabi.parent.data.local.SessionManager
import sd.alumrabi.parent.data.model.*
import sd.alumrabi.parent.ui.screens.*
import sd.alumrabi.parent.ui.theme.AlUmrabiParentTheme
import sd.alumrabi.parent.ui.theme.LavenderCanvas

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // OWASP MASVS-PLATFORM: Prevent recents snapshot and screenshot data leakage of academic/financial records
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
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
    val context = LocalContext.current
    val sessionManager = remember { SessionManager(context) }
    val navController = rememberNavController()
    val coroutineScope = rememberCoroutineScope()
    val apiClient = remember { ParentApiClient() }

    // Session State initialized from persistent local storage
    var currentGuardian by remember {
        mutableStateOf(
            sessionManager.getGuardian() ?: GuardianInfo(
                id = "",
                accountCode = "",
                fullName = "ولي الأمر",
                phone = "",
                status = "active"
            )
        )
    }

    var currentChildren by remember {
        mutableStateOf(sessionManager.getChildren())
    }

    var announcements by remember {
        mutableStateOf<List<AnnouncementItem>>(emptyList())
    }

    var events by remember {
        mutableStateOf<List<CalendarEventItem>>(emptyList())
    }

    var connectionState by remember {
        mutableStateOf(BackendConnectionState.CONNECTING)
    }

    var selectedChildIndex by remember { mutableIntStateOf(0) }

    // Background Network Health & Live Sync
    LaunchedEffect(Unit) {
        coroutineScope.launch {
            connectionState = apiClient.checkConnection()
            val annResult = apiClient.fetchAnnouncements()
            announcements = annResult.getOrDefault(emptyList())

            val evResult = apiClient.fetchEvents()
            events = evResult.getOrDefault(emptyList())

            // If guardian has saved credentials, refresh portal data silently
            val savedGuardian = sessionManager.getGuardian()
            if (savedGuardian != null && !savedGuardian.accountCode.isNullOrBlank()) {
                val portalResult = apiClient.fetchPortalData(savedGuardian.id, savedGuardian.accountCode, sessionManager.getPin())
                portalResult.getOrNull()?.let { payload ->
                    currentGuardian = payload.guardian
                    currentChildren = payload.children
                    sessionManager.saveSession(payload.guardian, payload.children, sessionManager.getPin())
                }
            }
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
                    val target = if (sessionManager.isLoggedIn() && currentChildren.isNotEmpty()) "dashboard" else "login"
                    navController.navigate(target) {
                        popUpTo("splash") { inclusive = true }
                    }
                }
            )
        }

        composable("login") {
            LoginScreen(
                onLoginSuccess = { guardian, children, pin ->
                    currentGuardian = guardian
                    currentChildren = children
                    selectedChildIndex = 0
                    sessionManager.saveSession(guardian, children, pin)
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
                connectionState = connectionState,
                onSelectChild = { index -> selectedChildIndex = index },
                onNavigateToGrades = { navController.navigate("grades") },
                onNavigateToAttendance = { navController.navigate("attendance") },
                onNavigateToSchedule = { navController.navigate("schedule") },
                onNavigateToAnnouncements = { navController.navigate("announcements") },
                onNavigateToAiAssistant = { navController.navigate("ai_assistant") },
                onNavigateToSettings = { navController.navigate("settings") }
            )
        }

        composable("ai_assistant") {
            val activeChild = currentChildren.getOrNull(selectedChildIndex)
            AiAssistantScreen(
                guardian = currentGuardian,
                activeChild = activeChild,
                announcements = announcements,
                events = events,
                onBack = { navController.popBackStack() }
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
                    sessionManager.clearSession()
                    currentGuardian = GuardianInfo(id = "", accountCode = "", fullName = "ولي الأمر", phone = "", status = "active")
                    currentChildren = emptyList()
                    navController.navigate("login") {
                        popUpTo("dashboard") { inclusive = true }
                    }
                }
            )
        }
    }
}
