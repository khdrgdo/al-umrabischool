package sd.alumrabi.parent

import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Grade
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
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
import sd.alumrabi.parent.ui.theme.BurgundyPrimary
import sd.alumrabi.parent.ui.theme.LavenderCanvas
import sd.alumrabi.parent.ui.theme.SurfaceWhite
import sd.alumrabi.parent.ui.theme.TextSecondary

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

private data class ParentTab(
    val route: String,
    val label: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector
)

@Composable
fun ParentAppNavHost() {
    val context = LocalContext.current
    val sessionManager = remember { SessionManager(context) }
    val navController = rememberNavController()
    val coroutineScope = rememberCoroutineScope()

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
        val apiClient = ParentApiClient()
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

    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route
    val tabs = remember {
        listOf(
            ParentTab("dashboard", "الرئيسية", Icons.Default.Home),
            ParentTab("grades", "النتائج", Icons.Default.Grade),
            ParentTab("attendance", "الحضور", Icons.Default.CheckCircle),
            ParentTab("schedule", "الجدول", Icons.Default.CalendarMonth),
            ParentTab("more", "المزيد", Icons.Default.MoreHoriz)
        )
    }
    val rootRoutes = remember(tabs) { tabs.map { it.route }.toSet() }
    val showBottomBar = currentRoute in rootRoutes

    Scaffold(
        containerColor = LavenderCanvas,
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        bottomBar = {
            if (showBottomBar) {
                NavigationBar(
                    containerColor = SurfaceWhite,
                    contentColor = BurgundyPrimary,
                    tonalElevation = 5.dp
                ) {
                    tabs.forEach { tab ->
                        val selected = currentRoute == tab.route
                        NavigationBarItem(
                            selected = selected,
                            onClick = {
                                if (!selected) {
                                    navController.navigate(tab.route) {
                                        popUpTo("dashboard") { saveState = true }
                                        launchSingleTop = true
                                        restoreState = true
                                    }
                                }
                            },
                            icon = {
                                Icon(
                                    imageVector = tab.icon,
                                    contentDescription = tab.label
                                )
                            },
                            label = {
                                Text(
                                    text = tab.label,
                                    maxLines = 1
                                )
                            },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = BurgundyPrimary,
                                selectedTextColor = BurgundyPrimary,
                                indicatorColor = Color(0xFFF7EDED),
                                unselectedIconColor = TextSecondary,
                                unselectedTextColor = TextSecondary
                            )
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = "splash",
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            enterTransition = {
                slideIntoContainer(
                    AnimatedContentTransitionScope.SlideDirection.Start,
                    animationSpec = tween(240)
                ) + fadeIn(animationSpec = tween(240))
            },
            exitTransition = {
                slideOutOfContainer(
                    AnimatedContentTransitionScope.SlideDirection.Start,
                    animationSpec = tween(240)
                ) + fadeOut(animationSpec = tween(240))
            },
            popEnterTransition = {
                slideIntoContainer(
                    AnimatedContentTransitionScope.SlideDirection.End,
                    animationSpec = tween(240)
                ) + fadeIn(animationSpec = tween(240))
            },
            popExitTransition = {
                slideOutOfContainer(
                    AnimatedContentTransitionScope.SlideDirection.End,
                    animationSpec = tween(240)
                ) + fadeOut(animationSpec = tween(240))
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

            composable("more") {
                MoreScreen(
                    onNavigateToFees = { navController.navigate("fees") },
                    onNavigateToAnnouncements = { navController.navigate("announcements") },
                    onNavigateToSettings = { navController.navigate("settings") }
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
                                coroutineScope.launch {
                                    ParentApiClient().signOut(tokenToRevoke)
                                }
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
}
