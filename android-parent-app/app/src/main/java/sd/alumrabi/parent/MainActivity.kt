package sd.alumrabi.parent

import android.Manifest
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.imePadding
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import sd.alumrabi.parent.notify.NotificationWorker
import sd.alumrabi.parent.notify.Notifier
import sd.alumrabi.parent.ui.components.BrandHeaderLayer
import android.net.ConnectivityManager
import android.net.Network
import android.os.Bundle
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.compose.ui.platform.LocalLifecycleOwner
import sd.alumrabi.parent.security.AppLock
import sd.alumrabi.parent.util.SchoolContact
import sd.alumrabi.parent.ui.theme.ThemeState
import android.view.WindowManager
import androidx.fragment.app.FragmentActivity
import androidx.activity.compose.setContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import sd.alumrabi.parent.ui.components.OmrabiBottomBar
import sd.alumrabi.parent.ui.components.Routes
import sd.alumrabi.parent.ui.components.TabRoutes
import sd.alumrabi.parent.ui.screens.*
import sd.alumrabi.parent.ui.theme.AlUmrabiParentTheme
import sd.alumrabi.parent.ui.theme.Canvas
import sd.alumrabi.parent.ui.theme.Crimson700
import sd.alumrabi.parent.ui.theme.SystemBars

class MainActivity : FragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val isDebugBuild = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (isDebugBuild) {
            sd.alumrabi.parent.util.CrashReporter.install(this)
            val crash = sd.alumrabi.parent.util.CrashReporter.consume(this)
            if (crash != null) {
                showCrashScreen(crash)
                return
            }
        }
        // حافة لحافة: الترويسة الحمراء تمتد خلف شريط الحالة
        WindowCompat.setDecorFitsSystemWindows(window, false)
        Notifier.ensureChannel(this)
        // OWASP MASVS-PLATFORM: منع لقطات الشاشة ومعاينة التطبيقات الأخيرة للسجلات الأكاديمية والمالية
        // نسخة التجربة (debug) تسمح بلقطات الشاشة لمراجعة التصميم؛ نسخة الإصدار تمنعها دائماً
        val debuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (!debuggable) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }
        ThemeState.load(this)
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

private fun MainActivity.showCrashScreen(text: String) {
    val pad = (16 * resources.displayMetrics.density).toInt()
    val tv = android.widget.TextView(this).apply {
        this.text = text
        setTextIsSelectable(true)
        textSize = 11f
        setTextColor(android.graphics.Color.BLACK)
        setPadding(pad, pad, pad, pad)
        layoutDirection = android.view.View.LAYOUT_DIRECTION_LTR
    }
    val btn = android.widget.Button(this).apply {
        this.text = "متابعة تشغيل التطبيق"
        setOnClickListener { recreate() }
    }
    val title = android.widget.TextView(this).apply {
        this.text = "توقف التطبيق في المرة السابقة بسبب هذا الخطأ (صوّر الشاشة وأرسلها):"
        setTextColor(android.graphics.Color.BLACK)
        textSize = 14f
        setPadding(pad, pad * 2, pad, 0)
    }
    val col = android.widget.LinearLayout(this).apply {
        orientation = android.widget.LinearLayout.VERTICAL
        setBackgroundColor(android.graphics.Color.WHITE)
        addView(title)
        addView(
            android.widget.ScrollView(this@showCrashScreen).apply { addView(tv) },
            android.widget.LinearLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f)
        )
        addView(btn)
    }
    setContentView(col)
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
    val lock = remember { AppLock(sessionManager) }
    val isDebuggable = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    var guardian by remember { mutableStateOf(sessionManager.getGuardian() ?: emptyGuardian()) }
    var children by remember { mutableStateOf(sessionManager.getChildren()) }
    var announcements by remember { mutableStateOf(sessionManager.getAnnouncements()) }
    var events by remember { mutableStateOf(sessionManager.getEvents()) }
    var readIds by remember { mutableStateOf(sessionManager.getReadIds()) }
    var connectionState by remember { mutableStateOf(BackendConnectionState.CONNECTING) }
    var lastSync by remember { mutableLongStateOf(sessionManager.getLastSyncMillis()) }
    var selectedChildIndex by remember { mutableIntStateOf(0) }
    var refreshing by remember { mutableStateOf(false) }

    val safeIndex = if (children.isEmpty()) 0 else selectedChildIndex.coerceIn(0, children.lastIndex)
    val unread = announcements.count { it.id !in readIds }

    fun resetLocalState() {
        Notifier.cancel(context)
        sessionManager.clearSession()
        lock.reset()
        guardian = emptyGuardian()
        children = emptyList()
        announcements = emptyList()
        events = emptyList()
        readIds = emptySet()
        selectedChildIndex = 0
        lastSync = 0L
        connectionState = BackendConnectionState.SYNCED_LOCAL
        navController.navigate(Routes.Login) { popUpTo(0) }
    }

    fun doLogout() {
        val token = sessionManager.getTokens()?.accessToken
        if (token != null) scope.launch { apiClient.signOut(token) }
        resetLocalState()
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
            sessionManager.saveContent(payload.announcements, payload.events)
            sessionManager.addNotified(Notifier.keys(payload))
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

    LaunchedEffect(Unit) {
        if (sessionManager.isLoggedIn()) Notifier.schedule(context)
        syncOnce()
    }

    // عمل دون إنترنت: عند عودة الشبكة نعيد المزامنة تلقائياً إن كنا نعرض بيانات محفوظة،
    // وعند العودة للتطبيق بعد أكثر من 10 دقائق نحدّث البيانات. القفل يُفعَّل عند مغادرة التطبيق.
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_STOP -> lock.onBackground()
                Lifecycle.Event.ON_START -> {
                    lock.onForeground()
                    if (connectionState != BackendConnectionState.CONNECTING &&
                        sessionManager.isLoggedIn() &&
                        System.currentTimeMillis() - lastSync > 10 * 60_000L
                    ) scope.launch { syncOnce() }
                }
                else -> {}
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    DisposableEffect(Unit) {
        val cm = context.getSystemService(ConnectivityManager::class.java)
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                scope.launch {
                    if (connectionState == BackendConnectionState.SYNCED_LOCAL && sessionManager.isLoggedIn()) syncOnce()
                }
            }
        }
        runCatching { cm?.registerDefaultNetworkCallback(callback) }
        onDispose { runCatching { cm?.unregisterNetworkCallback(callback) } }
    }

    val notifPermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { }

    fun navigateTab(tab: AppTab) {
        navController.navigate(tab.route) {
            popUpTo(Routes.Home) { saveState = true }
            launchSingleTop = true
            restoreState = true
        }
    }

    val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route
    val isTab = currentRoute != null && currentRoute in TabRoutes

    BackHandler(enabled = isTab && currentRoute != Routes.Home) { navigateTab(AppTab.Home) }

    LaunchedEffect(currentRoute) {
        if (currentRoute == Routes.Home && Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            // بعض الأجهزة (ColorOS وغيرها) لا تجد نافذة الإذن فتنهار؛ نتجاهل الفشل بدل إغلاق التطبيق.
            runCatching { notifPermission.launch(Manifest.permission.POST_NOTIFICATIONS) }
        }
    }

    Box(Modifier.fillMaxSize()) {
    BrandHeaderLayer(currentRoute)
    Column(Modifier.fillMaxSize()) {
        Box(Modifier.weight(1f).imePadding()) {
            NavHost(
                navController = navController,
                startDestination = Routes.Splash,
                modifier = Modifier.fillMaxSize(),
                enterTransition = {
                    val to = targetState.destination.route
                    when {
                        to == Routes.Login -> fadeIn(tween(350, delayMillis = 250))
                        to == Routes.Home -> fadeIn(tween(300, delayMillis = 150))
                        to != null && to in TabRoutes -> fadeIn(tween(220))
                        else -> slideInHorizontally(tween(260)) { -it / 6 } + fadeIn(tween(220))
                    }
                },
                exitTransition = {
                    val to = targetState.destination.route
                    if (to != null && to in TabRoutes) fadeOut(tween(120))
                    else slideOutHorizontally(tween(260)) { it / 8 } + fadeOut(tween(140))
                },
                popEnterTransition = { fadeIn(tween(220)) + slideInHorizontally(tween(260)) { it / 8 } },
                popExitTransition = { slideOutHorizontally(tween(260)) { -it / 6 } + fadeOut(tween(160)) }
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
                            readIds = sessionManager.getReadIds()
                            selectedChildIndex = 0
                            sessionManager.saveTokens(tokens)
                            sessionManager.saveSession(payload.guardian, payload.children)
                            sessionManager.saveContent(payload.announcements, payload.events)
                            sessionManager.addNotified(Notifier.keys(payload))
                            Notifier.schedule(context)
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
                        readIds = readIds,
                        connectionState = connectionState,
                        lastSyncMillis = lastSync,
                        isRefreshing = refreshing,
                        onSelectChild = { selectedChildIndex = it },
                        onRefresh = {
                            scope.launch {
                                refreshing = true
                                try { syncOnce() } finally { refreshing = false }
                            }
                        },
                        onOpenRoute = { navController.navigate(it) },
                        onSelectTab = { navigateTab(it) }
                    )
                }

                composable(Routes.Results) { GradesScreen(children, safeIndex) { selectedChildIndex = it } }
                composable(Routes.Attendance) { AttendanceScreen(children, safeIndex) { selectedChildIndex = it } }
                composable(Routes.Fees) { FeesScreen(children, safeIndex) { selectedChildIndex = it } }

                composable(Routes.More) {
                    MoreScreen(
                        guardian = guardian,
                        unreadAnnouncements = unread,
                        onOpenRoute = { navController.navigate(it) },
                        onContactSchool = {
                            SchoolContact.openWhatsApp(context, guardian.fullName, guardian.accountCode, children.getOrNull(safeIndex)?.fullName)
                        },
                        onCheckNow = if (isDebuggable) {
                            {
                                WorkManager.getInstance(context).enqueue(OneTimeWorkRequestBuilder<NotificationWorker>().build())
                                Toast.makeText(context, "جارٍ فحص الجديد…", Toast.LENGTH_SHORT).show()
                            }
                        } else null
                    )
                }

                composable(Routes.Schedule) {
                    ScheduleScreen(
                        children = children,
                        selectedChildIndex = safeIndex,
                        onSelectChild = { selectedChildIndex = it },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(Routes.Announcements) {
                    AnnouncementsScreen(
                        announcements = announcements,
                        events = events,
                        readIds = readIds,
                        onMarkRead = { ids ->
                            sessionManager.markRead(ids)
                            readIds = sessionManager.getReadIds()
                        },
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
                        lock = lock,
                        onBack = { navController.popBackStack() },
                        onLogout = { doLogout() }
                    )
                }
            }
        }
        if (isTab) {
            OmrabiBottomBar(
                currentRoute = currentRoute,
                onSelect = { navigateTab(it) },
                badges = mapOf(Routes.More to unread)
            )
        }
    }
    if (lock.locked) {
        LockScreen(lock = lock, guardianName = guardian.fullName, onForgot = { doLogout() })
    }
    }
}
