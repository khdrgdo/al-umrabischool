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
import sd.alumrabi.parent.data.api.AccountBlockedException
import sd.alumrabi.parent.data.api.AuthTokens
import sd.alumrabi.parent.data.api.ParentApiClient
import sd.alumrabi.parent.data.api.SessionExpiredException
import sd.alumrabi.parent.data.local.SessionManager
import sd.alumrabi.parent.data.model.*
import sd.alumrabi.parent.ui.screens.*
import sd.alumrabi.parent.ui.theme.AlUmrabiParentTheme
import sd.alumrabi.parent.ui.theme.LavenderCanvas

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        setContent {
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
    var currentChildren by remember { mutableStateOf(sessionManager.getChildren()) }
    var announcements by remember { mutableStateOf<List<AnnouncementItem>>(emptyList()) }
    var events by remember { mutableStateOf<List<CalendarEventItem>>(emptyList()) }
    var connectionState by remember { mutableStateOf(BackendConnectionState.CONNECTING) }
    var selectedChildIndex by remember { mutableIntStateOf(0) }
    var demoMode by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        connectionState = apiClient.checkConnection()

        val savedGuardian = sessionManager.getGuardian()
        val storedTokens = sessionManager.getTokens()
        if (savedGuardian != null && storedTokens != null) {
            var activeTokens: AuthTokens = storedTokens
            var mustSignOut = false

            if (activeTokens.isExpiringSoon()) {
                val refreshed = apiClient.refreshSession(activeTokens.refreshToken)
                val newTokens = refreshed.getOrNull()
                if (newTokens != null) {
                    activeTokens = newTokens
                    sessionManager.saveTokens(newTokens)
                } else if (refreshed.exceptionOrNull() is SessionExpiredException) {
                    mustSignOut = true
                }
            }

            if (!mustSignOut) {
                val dashboard = apiClient.fetchDashboard(activeTokens.accessToken)
                val payload = dashboard.getOrNull()
                if (payload != null) {
                    currentGuardian = payload.guardian
                    currentChildren = payload.children
                    announcements = payload.announcements
                    events = payload.events
                    sessionManager.saveSession(payload.guardian, payload.children)
                } else {
                    val failure = dashboard.exceptionOrNull()
                    if (failure is SessionExpiredException || failure is AccountBlockedException) {
                        mustSignOut = true
                    }
                }
            }

            if (mustSignOut) {
                sessionManager.clearSession()
                currentGuardian = GuardianInfo("", "", "ولي الأمر", "", "active")
                currentChildren = emptyList()
                announcements = emptyList()
                events = emptyList()
                navController.navigate("login") {
                    popUpTo("splash") { inclusive = true }
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
                animationSpec = tween(260)
            ) + fadeIn(animationSpec = tween(260))
        },
        exitTransition = {
            slideOutOfContainer(
                AnimatedContentTransitionScope.SlideDirection.Start,
                animationSpec = tween(260)
            ) + fadeOut(animationSpec = tween(260))
        },
        popEnterTransition = {
            slideIntoContainer(
                AnimatedContentTransitionScope.SlideDirection.End,
                animationSpec = tween(260)
            ) + fadeIn(animationSpec = tween(260))
        },
        popExitTransition = {
            slideOutOfContainer(
                AnimatedContentTransitionScope.SlideDirection.End,
                animationSpec = tween(260)
            ) + fadeOut(animationSpec = tween(260))
        }
    ) {
        composable("splash") {
            AnimatedSplashScreen(
                onSplashFinished = {
                    val target = if (sessionManager.isLoggedIn() && currentChildren.isNotEmpty()) {
                        "dashboard"
                    } else {
                        "login"
                    }
                    navController.navigate(target) {
                        popUpTo("splash") { inclusive = true }
                    }
                }
            )
        }

        composable("login") {
            LoginScreen(
                onLoginSuccess = { tokens, payload ->
                    demoMode = false
                    currentGuardian = payload.guardian
                    currentChildren = payload.children
                    announcements = payload.announcements
                    events = payload.events
                    selectedChildIndex = 0
                    sessionManager.saveTokens(tokens)
                    sessionManager.saveSession(payload.guardian, payload.children)
                    navController.navigate("dashboard") {
                        popUpTo("login") { inclusive = true }
                    }
                },
                onDemoLoginSuccess = { payload ->
                    // بيانات محلية مؤقتة: لا تُخزَّن كجلسة ولا تُرسل إلى الخادم.
                    demoMode = true
                    currentGuardian = payload.guardian
                    currentChildren = payload.children
                    announcements = payload.announcements
                    events = payload.events
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
                connectionState = connectionState,
                demoMode = demoMode,
                onSelectChild = { selectedChildIndex = it },
                onNavigateToGrades = { navController.navigate("grades") },
                onNavigateToAttendance = { navController.navigate("attendance") },
                onNavigateToSchedule = { navController.navigate("schedule") },
                onNavigateToAnnouncements = { navController.navigate("announcements") },
                onNavigateToFees = { navController.navigate("fees") },
                onNavigateToSettings = { navController.navigate("settings") }
            )
        }

        composable("grades") {
            GradesScreen(
                child = currentChildren.getOrNull(selectedChildIndex),
                onBack = { navController.popBackStack() }
            )
        }

        composable("fees") {
            FeesScreen(
                child = currentChildren.getOrNull(selectedChildIndex),
                onBack = { navController.popBackStack() }
            )
        }

        composable("attendance") {
            AttendanceScreen(
                child = currentChildren.getOrNull(selectedChildIndex),
                onBack = { navController.popBackStack() }
            )
        }

        composable("schedule") {
            ScheduleScreen(
                child = currentChildren.getOrNull(selectedChildIndex),
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
                    if (!demoMode) {
                        val tokenToRevoke = sessionManager.getTokens()?.accessToken
                        if (tokenToRevoke != null) {
                            coroutineScope.launch { apiClient.signOut(tokenToRevoke) }
                        }
                    }
                    demoMode = false
                    sessionManager.clearSession()
                    currentGuardian = GuardianInfo("", "", "ولي الأمر", "", "active")
                    currentChildren = emptyList()
                    announcements = emptyList()
                    events = emptyList()
                    selectedChildIndex = 0
                    navController.navigate("login") {
                        popUpTo("dashboard") { inclusive = true }
                    }
                }
            )
        }
    }
}
