package sd.alumrabi.parent.data.repository

import sd.alumrabi.parent.data.api.AccountBlockedException
import sd.alumrabi.parent.data.api.AuthTokens
import sd.alumrabi.parent.data.api.ParentApiClient
import sd.alumrabi.parent.data.api.SessionExpiredException
import sd.alumrabi.parent.data.local.SessionManager
import sd.alumrabi.parent.data.model.*

data class ParentSessionSnapshot(
    val guardian: GuardianInfo? = null,
    val children: List<LinkedChild> = emptyList(),
    val announcements: List<AnnouncementItem> = emptyList(),
    val events: List<CalendarEventItem> = emptyList(),
    val connection: BackendConnectionState = BackendConnectionState.CONNECTING,
    val hasSession: Boolean = false
)

/** Owns the parent session boundary: encrypted local session + authenticated remote source. */
class ParentRepository(
    private val sessions: SessionManager,
    private val api: ParentApiClient
) {
    suspend fun restoreSession(): ParentSessionSnapshot {
        val connection = api.checkConnection()
        val savedGuardian = sessions.getGuardian()
        val savedChildren = sessions.getChildren()
        val storedTokens = sessions.getTokens()
        if (savedGuardian == null || storedTokens == null) {
            return ParentSessionSnapshot(connection = connection)
        }

        var activeTokens: AuthTokens = storedTokens
        var mustSignOut = false
        if (activeTokens.isExpiringSoon()) {
            val refreshed = api.refreshSession(activeTokens.refreshToken)
            val fresh = refreshed.getOrNull()
            if (fresh != null) {
                activeTokens = fresh
                sessions.saveTokens(fresh)
            } else if (refreshed.exceptionOrNull() is SessionExpiredException) {
                mustSignOut = true
            }
        }

        if (!mustSignOut) {
            val dashboard = api.fetchDashboard(activeTokens.accessToken)
            val payload = dashboard.getOrNull()
            if (payload != null) {
                sessions.saveSession(payload.guardian, payload.children)
                return ParentSessionSnapshot(
                    guardian = payload.guardian, children = payload.children,
                    announcements = payload.announcements, events = payload.events,
                    connection = BackendConnectionState.CONNECTED_LIVE, hasSession = true
                )
            }
            val failure = dashboard.exceptionOrNull()
            if (failure is SessionExpiredException || failure is AccountBlockedException) mustSignOut = true
        }

        if (mustSignOut) {
            sessions.clearSession()
            return ParentSessionSnapshot(connection = connection)
        }
        return ParentSessionSnapshot(
            guardian = savedGuardian, children = savedChildren,
            connection = BackendConnectionState.SYNCED_LOCAL, hasSession = true
        )
    }

    fun persistAuthenticatedSession(tokens: AuthTokens, payload: DashboardPayload) {
        sessions.saveTokens(tokens)
        sessions.saveSession(payload.guardian, payload.children)
    }

    suspend fun endSession(demoMode: Boolean) {
        val token = sessions.getTokens()?.accessToken
        if (!demoMode && token != null) api.signOut(token)
        sessions.clearSession()
    }
}
