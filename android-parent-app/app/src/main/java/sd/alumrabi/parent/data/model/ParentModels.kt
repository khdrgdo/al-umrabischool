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
    val attendance: List<AttendanceRecord>? = emptyList()
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
