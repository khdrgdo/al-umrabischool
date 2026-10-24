package sd.alumrabi.parent.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class GuardianInfo(
    val id: String,
    @SerialName("account_code") val accountCode: String? = null,
    @SerialName("full_name") val fullName: String,
    val phone: String,
    val status: String = "pending_activation"
)

@Serializable
data class PublishedGrade(
    @SerialName("subject_name") val subjectName: String,
    val title: String,
    val term: String,
    val score: Double? = null,
    @SerialName("max_score") val maxScore: Double = 100.0,
    @SerialName("pass_score") val passScore: Double = 50.0,
    @SerialName("is_absent") val isAbsent: Boolean = false
)

@Serializable
data class AttendanceRecord(
    val date: String,
    val status: String, // present, absent, late, excused
    val reason: String? = null
)

@Serializable
data class PaymentRecord(
    val amount: Double,
    @SerialName("payment_method") val paymentMethod: String,
    @SerialName("receipt_number") val receiptNumber: String,
    @SerialName("created_at") val createdAt: String
)

@Serializable
data class FeeStatement(
    @SerialName("total_due") val totalDue: Double = 0.0,
    @SerialName("total_discounts") val totalDiscounts: Double = 0.0,
    @SerialName("total_paid") val totalPaid: Double = 0.0,
    val payments: List<PaymentRecord> = emptyList()
) {
    val netDue: Double get() = (totalDue - totalDiscounts).coerceAtLeast(0.0)
    val remainingBalance: Double get() = (netDue - totalPaid).coerceAtLeast(0.0)
    val isFullyPaid: Boolean get() = remainingBalance <= 0.0
}

@Serializable
data class LinkedChild(
    val id: String,
    @SerialName("student_number") val studentNumber: String,
    @SerialName("full_name") val fullName: String,
    val status: String,
    val relation: String? = "ابن",
    @SerialName("can_view_fees") val canViewFees: Boolean = true,
    @SerialName("receives_notifications") val receivesNotifications: Boolean = true,
    @SerialName("grade_name") val gradeName: String = "غير محدد",
    @SerialName("section_name") val sectionName: String = "غير محدد",
    val grades: List<PublishedGrade>? = emptyList(),
    val attendance: List<AttendanceRecord>? = emptyList(),
    val fees: FeeStatement? = null
)

@Serializable
data class AnnouncementItem(
    val id: String,
    val title: String,
    val body: String,
    val priority: String = "normal",
    @SerialName("published_at") val publishedAt: String
)

@Serializable
data class CalendarEventItem(
    val id: String,
    val title: String,
    val description: String? = null,
    @SerialName("event_type") val eventType: String,
    @SerialName("starts_on") val startsOn: String,
    @SerialName("ends_on") val endsOn: String? = null
)

@Serializable
data class DashboardPayload(
    val guardian: GuardianInfo,
    val children: List<LinkedChild> = emptyList(),
    val announcements: List<AnnouncementItem> = emptyList(),
    val events: List<CalendarEventItem> = emptyList()
)

@Serializable
data class LoginResponse(
    val success: Boolean,
    val message: String? = null,
    @SerialName("guardian_id") val guardianId: String? = null,
    @SerialName("account_code") val accountCode: String? = null,
    @SerialName("full_name") val fullName: String? = null,
    val status: String? = null,
    @SerialName("requires_new_password") val requiresNewPassword: Boolean = false
)

enum class MessageSender {
    USER, ASSISTANT, SYSTEM
}

@Serializable
data class AiChatMessage(
    val id: String,
    val sender: MessageSender,
    val text: String,
    val timestamp: Long = System.currentTimeMillis(),
    val isTyping: Boolean = false,
    val relatedAction: String? = null
)

enum class BackendConnectionState {
    CONNECTED_LIVE,
    SYNCED_LOCAL,
    CONNECTING
}
