package sd.alumrabi.parent.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import sd.alumrabi.parent.data.api.AuthTokens
import sd.alumrabi.parent.data.model.*
import sd.alumrabi.parent.data.repository.ParentRepository

data class ParentAppUiState(
    val guardian: GuardianInfo = GuardianInfo("", "", "ولي الأمر", "", "active"),
    val children: List<LinkedChild> = emptyList(),
    val announcements: List<AnnouncementItem> = emptyList(),
    val events: List<CalendarEventItem> = emptyList(),
    val connection: BackendConnectionState = BackendConnectionState.CONNECTING,
    val selectedChildIndex: Int = 0,
    val isRestoring: Boolean = true,
    val hasSession: Boolean = false,
    val demoMode: Boolean = false
)

class ParentAppViewModel(private val repository: ParentRepository) : ViewModel() {
    private val _uiState = MutableStateFlow(ParentAppUiState())
    val uiState: StateFlow<ParentAppUiState> = _uiState.asStateFlow()

    init { restoreSession() }

    private fun restoreSession() = viewModelScope.launch {
        val snapshot = repository.restoreSession()
        _uiState.update { it.copy(
            guardian = snapshot.guardian ?: it.guardian,
            children = snapshot.children,
            announcements = snapshot.announcements,
            events = snapshot.events,
            connection = snapshot.connection,
            hasSession = snapshot.hasSession,
            isRestoring = false
        ) }
    }

    fun onAuthenticated(tokens: AuthTokens, payload: DashboardPayload) {
        repository.persistAuthenticatedSession(tokens, payload)
        _uiState.update { it.copy(
            guardian = payload.guardian, children = payload.children,
            announcements = payload.announcements, events = payload.events,
            connection = BackendConnectionState.CONNECTED_LIVE,
            selectedChildIndex = 0, hasSession = true, demoMode = false
        ) }
    }

    fun onDemoAuthenticated(payload: DashboardPayload) {
        _uiState.update { it.copy(
            guardian = payload.guardian, children = payload.children,
            announcements = payload.announcements, events = payload.events,
            connection = BackendConnectionState.SYNCED_LOCAL,
            selectedChildIndex = 0, hasSession = true, demoMode = true
        ) }
    }

    fun selectChild(index: Int) {
        if (index in _uiState.value.children.indices) _uiState.update { it.copy(selectedChildIndex = index) }
    }

    suspend fun logout() {
        repository.endSession(_uiState.value.demoMode)
        _uiState.value = ParentAppUiState(isRestoring = false, connection = _uiState.value.connection)
    }
}
