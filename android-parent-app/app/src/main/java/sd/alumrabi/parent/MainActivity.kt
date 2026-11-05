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
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material.icons.outlined.Campaign
import androidx.compose.material.icons.outlined.EventAvailable
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.MenuBook
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowCompat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.*
import kotlinx.coroutines.launch
import sd.alumrabi.parent.data.api.ParentApiClient
import sd.alumrabi.parent.data.repository.ParentRepository
import sd.alumrabi.parent.data.local.SessionManager
import sd.alumrabi.parent.ui.ParentAppViewModel
import sd.alumrabi.parent.ui.screens.*
import sd.alumrabi.parent.ui.theme.AlUmrabiParentTheme
import sd.alumrabi.parent.ui.theme.AppCanvas

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.TRANSPARENT
        setContent {
            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
                AlUmrabiParentTheme { ParentAppNavHost() }
            }
        }
    }
}

private data class MainDestination(val route: String, val label: String, val icon: androidx.compose.ui.graphics.vector.ImageVector)

@Composable
fun ParentAppNavHost() {
    val context = LocalContext.current
    val sessions = remember { SessionManager(context) }
    val api = remember { ParentApiClient() }
    val repository = remember { ParentRepository(sessions, api) }
    val factory = remember { object : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T = ParentAppViewModel(repository) as T
    } }
    val app: ParentAppViewModel = viewModel(factory = factory)
    val state by app.uiState.collectAsStateWithLifecycle()
    val nav = rememberNavController()
    val scope = rememberCoroutineScope()
    val entry by nav.currentBackStackEntryAsState()
    val route = entry?.destination?.route ?: "boot"

    val destinations = listOf(
        MainDestination("home", "الرئيسية", Icons.Outlined.Home),
        MainDestination("grades", "النتائج", Icons.Outlined.MenuBook),
        MainDestination("attendance", "الحضور", Icons.Outlined.EventAvailable),
        MainDestination("announcements", "الأخبار", Icons.Outlined.Campaign),
        MainDestination("settings", "حسابي", Icons.Outlined.AccountCircle)
    )
    val topLevel = destinations.any { it.route == route }

    LaunchedEffect(state.isRestoring, state.hasSession) {
        if (!state.isRestoring && route == "boot") {
            nav.navigate(if (state.hasSession) "home" else "login") {
                popUpTo("boot") { inclusive = true }
                launchSingleTop = true
            }
        }
    }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        containerColor = AppCanvas,
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        bottomBar = {
            if (topLevel) NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface,
                tonalElevation = 3.dp,
                windowInsets = NavigationBarDefaults.windowInsets
            ) {
                destinations.forEach { destination ->
                    NavigationBarItem(
                        selected = route == destination.route,
                        onClick = {
                            nav.navigate(destination.route) {
                                popUpTo("home") { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(destination.icon, contentDescription = destination.label) },
                        label = { Text(destination.label) },
                        alwaysShowLabel = true
                    )
                }
            }
        }
    ) { inner ->
        NavHost(
            navController = nav,
            startDestination = "boot",
            modifier = Modifier.fillMaxSize().padding(inner),
            enterTransition = { slideIntoContainer(AnimatedContentTransitionScope.SlideDirection.Start, tween(220)) + fadeIn(tween(220)) },
            exitTransition = { slideOutOfContainer(AnimatedContentTransitionScope.SlideDirection.Start, tween(180)) + fadeOut(tween(180)) },
            popEnterTransition = { slideIntoContainer(AnimatedContentTransitionScope.SlideDirection.End, tween(220)) + fadeIn(tween(220)) },
            popExitTransition = { slideOutOfContainer(AnimatedContentTransitionScope.SlideDirection.End, tween(180)) + fadeOut(tween(180)) }
        ) {
            composable("boot") { BootScreen() }
            composable("login") {
                LoginScreen(
                    onLoginSuccess = { tokens, payload ->
                        app.onAuthenticated(tokens, payload)
                        nav.navigate("home") { popUpTo("login") { inclusive = true }; launchSingleTop = true }
                    },
                    onDemoLoginSuccess = { payload ->
                        app.onDemoAuthenticated(payload)
                        nav.navigate("home") { popUpTo("login") { inclusive = true }; launchSingleTop = true }
                    }
                )
            }
            composable("home") {
                DashboardScreen(
                    guardian = state.guardian, children = state.children,
                    selectedChildIndex = state.selectedChildIndex,
                    connectionState = state.connection, demoMode = state.demoMode,
                    onSelectChild = app::selectChild,
                    onNavigateToGrades = { nav.navigate("grades") },
                    onNavigateToAttendance = { nav.navigate("attendance") },
                    onNavigateToSchedule = { nav.navigate("schedule") },
                    onNavigateToAnnouncements = { nav.navigate("announcements") },
                    onNavigateToFees = { nav.navigate("fees") },
                    onNavigateToSettings = { nav.navigate("settings") }
                )
            }
            composable("grades") { GradesScreen(child = state.children.getOrNull(state.selectedChildIndex), onBack = { nav.popBackStack() }) }
            composable("attendance") { AttendanceScreen(child = state.children.getOrNull(state.selectedChildIndex), onBack = { nav.popBackStack() }) }
            composable("schedule") { ScheduleScreen(child = state.children.getOrNull(state.selectedChildIndex), onBack = { nav.popBackStack() }) }
            composable("fees") { FeesScreen(child = state.children.getOrNull(state.selectedChildIndex), onBack = { nav.popBackStack() }) }
            composable("announcements") { AnnouncementsScreen(announcements = state.announcements, events = state.events, onBack = { nav.popBackStack() }) }
            composable("settings") {
                SettingsScreen(state.guardian, onBack = { nav.popBackStack() }, onLogout = {
                    scope.launch {
                        app.logout()
                        nav.navigate("login") { popUpTo("home") { inclusive = true }; launchSingleTop = true }
                    }
                })
            }
        }
    }
}
