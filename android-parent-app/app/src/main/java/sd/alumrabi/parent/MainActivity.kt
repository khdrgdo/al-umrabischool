package sd.alumrabi.parent

import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
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
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.launch
import sd.alumrabi.parent.data.api.AccountBlockedException
import sd.alumrabi.parent.data.api.AuthTokens
import sd.alumrabi.parent.data.api.ParentApiClient
import sd.alumrabi.parent.data.api.SessionExpiredException
import sd.alumrabi.parent.data.demo.DemoData
import sd.alumrabi.parent.data.local.SessionManager
import sd.alumrabi.parent.data.model.*
import sd.alumrabi.parent.ui.components.AppTab
import sd.alumrabi.parent.ui.components.Routes
import sd.alumrabi.parent.ui.screens.*
import sd.alumrabi.parent.ui.theme.AlUmrabiParentTheme
import sd.alumrabi.parent.ui.theme.Canvas
import sd.alumrabi.parent.ui.theme.Crimson700
import sd.alumrabi.parent.ui.theme.SystemBars

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // OWASP MASVS-PLATFORM: منع لقطات الشاشة ومعاينة التطبيقات الأخيرة للسجلات الأكاديمية والمالية
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        setContent {
            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
                AlUmrabiParentTheme {
                    Surface(modifier = Modifier.fillMaxSize(), color = Canvas) {
                        ParentAppNavHost()
                    }
                }
            }
        }
    }
}

private fun emptyGuardian() = GuardianInfo(
    id = "",
    accountCode = "",
    fullName = "ولي الأمر",
    phone = "",
    status = "active"
)

@Composable
fun ParentAppNavHost() {
    val context = LocalContext.current
    val sessionManager = remember { SessionManager(context) }
    val navController = rememberNavController()
    val scope = rememberCoroutineScope()
    val apiClient = remember { ParentApiClient() }
    val isDebuggable = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    var guardian by remember { mutableStateOf(sessionManager.getGuardian() ?: emptyGuardian()) }
    var children by remember { mutableStateOf(sessionManager.getChildren()) }
    var announcements by remember { mutableStateOf<List<AnnouncementItem>>(emptyList()) }
    var events by remember { mutableStateOf<List<CalendarEventItem>>(emptyList()) }
    var connectionState by remember { mutableStateOf(BackendConnectionState.CONNECTING) }
    var lastSync by remember { mutableLongStateOf(sessionManager.getLastSyncMillis()) }
    var selectedChildIndex by remember { mutableIntStateOf(0) }

    val safeIndex = if (children.isEmpty()) 0 else selectedChildIndex.coerceIn(0, children.lastIndex)

    fun resetLocalState() {
        sessionManager.clearSession()
        guardian = emptyGuardian()
        children = emptyList()
        announcements = emptyList()
        events = emptyList()
        selectedChildIndex = 0
        lastSync = 0L
        connectionState = BackendConnectionState.SYNCED_LOCAL
        navController.navigate(Routes.Login) { popUpTo(0) }
    }

    suspend fun syncOnce() {
        val savedGuardian = sessionManager.getGuardian()
        val savedTokens = sessionManager.getTokens()
        if (savedGuardian == null || savedTokens == null) return
        connectionState = BackendConnectionState.CONNECTING
        var current: AuthTokens = savedTokens
        if (current.isExpiringSoon()) {
            val refreshed = apiClient.refreshSession(current.refreshToken)
            val renewed = refreshed.getOrNull()
            if (renewed != null) {
                current = renewed
                sessionManager.saveTokens(renewed)
            } else {
                if (refreshed.exceptionOrNull() is SessionExpiredException) {
                    resetLocalState()
                } else {
                    // فشل شبكة عابر: نبقى على البيانات المحفوظة ولا نقطع الجلسة
                    connectionState = BackendConnectionState.SYNCED_LOCAL
                }
                return
            }
        }
        val result = apiClient.fetchDashboard(current.accessToken)
        val payload = result.getOrNull()
        if (payload != null) {
            guardian = payload.guardian
            children = payload.children
            announcements = payload.announcements
            events = payload.events
            sessionManager.saveSession(payload.guardian, payload.children)
            lastSync = sessionManager.getLastSyncMillis()
            connectionState = BackendConnectionState.CONNECTED_LIVE
        } else {
            val ex = result.exceptionOrNull()
            if (ex is SessionExpiredException || ex is AccountBlockedException) {
                resetLocalState()
            } else {
                connectionState = BackendConnectionState.SYNCED_LOCAL
            }
        }
    }

    LaunchedEffect(Unit) { syncOnce() }

    fun navigateTab(tab: AppTab) {
        navController.navigate(tab.route) {
            popUpTo(Routes.Home) { saveState = true }
            launchSingleTop = true
            restoreState = true
        }
    }

    val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route
    if (currentRoute == Routes.Splash) SystemBars(Crimson700, false) else SystemBars(Canvas, true)

    NavHost(
        navController = navController,
        startDestination = Routes.Splash,
        enterTransition = { fadeIn(tween(200)) },
        exitTransition = { fadeOut(tween(120)) },
        popEnterTransition = { fadeIn(tween(200)) },
        popExitTransition = { fadeOut(tween(120)) }
    ) {
        composable(Routes.Splash) {
            AnimatedSplashScreen(
                onSplashFinished = {
                    val target = if (sessionManager.isLoggedIn()) Routes.Home else Routes.Login
                    navController.navigate(target) { popUpTo(Routes.Splash) { inclusive = true } }
                }
            )
        }

        composable(Routes.Login) {
            LoginScreen(
                onDemo = if (isDebuggable) {
                    {
                        val demo = DemoData.payload()
                        guardian = demo.guardian
                        children = demo.children
                        announcements = demo.announcements
                        events = demo.events
                        selectedChildIndex = 0
                        lastSync = 0L
                        connectionState = BackendConnectionState.CONNECTED_LIVE
                        navController.navigate(Routes.Home) { popUpTo(Routes.Login) { inclusive = true } }
                    }
                } else null,
                onLoginSuccess = { tokens, payload ->
                    guardian = payload.guardian
                    children = payload.children
                    announcements = payload.announcements
                    events = payload.events
                    selectedChildIndex = 0
                    sessionManager.saveTokens(tokens)
                    sessionManager.saveSession(payload.guardian, payload.children)
                    lastSync = sessionManager.getLastSyncMillis()
                    connectionState = BackendConnectionState.CONNECTED_LIVE
                    navController.navigate(Routes.Home) { popUpTo(Routes.Login) { inclusive = true } }
                }
            )
        }

        composable(Routes.Home) {
            HomeScreen(
                guardian = guardian,
                children = children,
                selectedChildIndex = safeIndex,
                announcements = announcements,
                events = events,
                connectionState = connectionState,
                lastSyncMillis = lastSync,
                onSelectChild = { selectedChildIndex = it },
                onRefresh = { scope.launch { syncOnce() } },
                onOpenRoute = { navController.navigate(it) },
                onSelectTab = { navigateTab(it) }
            )
        }

        composable(Routes.Results) {
            GradesScreen(
                children = children,
                selectedChildIndex = safeIndex,
                onSelectChild = { selectedChildIndex = it },
                onSelectTab = { navigateTab(it) }
            )
        }

        composable(Routes.Attendance) {
            AttendanceScreen(
                children = children,
                selectedChildIndex = safeIndex,
                onSelectChild = { selectedChildIndex = it },
                onSelectTab = { navigateTab(it) }
            )
        }

        composable(Routes.Fees) {
            FeesScreen(
                children = children,
                selectedChildIndex = safeIndex,
                onSelectChild = { selectedChildIndex = it },
                onSelectTab = { navigateTab(it) }
            )
        }

        composable(Routes.More) {
            MoreScreen(
                guardian = guardian,
                onOpenRoute = { navController.navigate(it) },
                onSelectTab = { navigateTab(it) }
            )
        }

        composable(Routes.Announcements) {
            AnnouncementsScreen(
                announcements = announcements,
                events = events,
                onBack = { navController.popBackStack() }
            )
        }

        composable(Routes.Assistant) {
            AiAssistantScreen(
                guardian = guardian,
                activeChild = children.getOrNull(safeIndex),
                announcements = announcements,
                events = events,
                onBack = { navController.popBackStack() }
            )
        }

        composable(Routes.Settings) {
            SettingsScreen(
                guardian = guardian,
                lastSyncMillis = lastSync,
                onBack = { navController.popBackStack() },
                onLogout = {
                    val token = sessionManager.getTokens()?.accessToken
                    if (token != null) scope.launch { apiClient.signOut(token) }
                    resetLocalState()
                }
            )
        }
    }
}
