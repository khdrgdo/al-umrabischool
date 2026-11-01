package sd.alumrabi.parent.data.api

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.client.request.headers
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import io.ktor.serialization.kotlinx.json.json
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.*
import sd.alumrabi.parent.data.model.*

class ParentApiClient(
    private val baseUrl: String = "https://c--8b91830b-7424-4960-81c7-67e94cdfd28d-prod.lovable.cloud",
    private val anonKey: String = "sb_publishable_Cfv0pugkUHNlXrkWNX45JQ_ebr24viE"
) {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        encodeDefaults = true
    }

    private val client = HttpClient(CIO) {
        install(ContentNegotiation) {
            json(json)
        }
        install(HttpTimeout) {
            requestTimeoutMillis = 6000
            connectTimeoutMillis = 5000
            socketTimeoutMillis = 6000
        }
    }

    suspend fun checkConnection(): BackendConnectionState = withContext(Dispatchers.IO) {
        try {
            val response = client.get("$baseUrl/rest/v1/") {
                headers {
                    append("apikey", anonKey)
                    append("Authorization", "Bearer $anonKey")
                }
            }
            if (response.status.isSuccess()) {
                BackendConnectionState.CONNECTED_LIVE
            } else {
                BackendConnectionState.SYNCED_LOCAL
            }
        } catch (_: Exception) {
            BackendConnectionState.SYNCED_LOCAL
        }
    }

    suspend fun login(accountCode: String, pin: String): Result<LoginResponse> = withContext(Dispatchers.IO) {
        val cleanCode = accountCode.trim().uppercase()
        val cleanPin = pin.trim()

        try {
            val response = client.post("$baseUrl/rest/v1/rpc/parent_app_login") {
                contentType(ContentType.Application.Json)
                headers {
                    append("apikey", anonKey)
                    append("Authorization", "Bearer $anonKey")
                }
                setBody(buildJsonObject {
                    put("_account_code", cleanCode)
                    put("_code_or_pin", cleanPin)
                })
            }

            if (response.status.isSuccess()) {
                val body = response.body<LoginResponse>()
                return@withContext Result.success(body)
            } else {
                return@withContext Result.failure(Exception("تعذر تسجيل الدخول من خادم المدرسة (${response.status.value})"))
            }
        } catch (_: Exception) {
            Result.failure(Exception("تعذر الاتصال بخادم المدرسة. يرجى التحقق من اتصال الإنترنت والمحاولة لاحقاً."))
        }
    }

    suspend fun fetchPortalData(guardianId: String, accountCode: String, pin: String): Result<DashboardPayload> = withContext(Dispatchers.IO) {
        try {
            val response = client.post("$baseUrl/rest/v1/rpc/parent_get_portal_data") {
                contentType(ContentType.Application.Json)
                headers {
                    append("apikey", anonKey)
                    append("Authorization", "Bearer $anonKey")
                }
                setBody(buildJsonObject {
                    put("_guardian_id", guardianId)
                    put("_account_code", accountCode)
                    put("_pin", pin)
                })
            }

            if (response.status.isSuccess()) {
                val rawText = response.bodyAsText()
                val element = json.parseToJsonElement(rawText).jsonObject
                if (element["success"]?.jsonPrimitive?.booleanOrNull == true) {
                    val guardianObj = element["guardian"]?.jsonObject
                    val guardian = if (guardianObj != null) {
                        GuardianInfo(
                            id = guardianObj["id"]?.jsonPrimitive?.content ?: guardianId,
                            accountCode = guardianObj["account_code"]?.jsonPrimitive?.content ?: accountCode,
                            fullName = guardianObj["full_name"]?.jsonPrimitive?.content ?: "ولي الأمر",
                            phone = guardianObj["phone"]?.jsonPrimitive?.content ?: "",
                            status = guardianObj["status"]?.jsonPrimitive?.content ?: "active"
                        )
                    } else {
                        GuardianInfo(id = guardianId, accountCode = accountCode, fullName = "ولي الأمر", phone = "", status = "active")
                    }

                    val children = element["children"]?.jsonArray?.mapNotNull { parseChild(it.jsonObject) } ?: emptyList()
                    val announcements = element["announcements"]?.jsonArray?.mapNotNull { parseAnnouncement(it.jsonObject) } ?: emptyList()
                    val events = element["events"]?.jsonArray?.mapNotNull { parseEvent(it.jsonObject) } ?: emptyList()

                    Result.success(DashboardPayload(guardian, children, announcements, events))
                } else {
                    val msg = element["message"]?.jsonPrimitive?.content ?: "تعذر جلب بيانات ولي الأمر"
                    Result.failure(Exception(msg))
                }
            } else {
                Result.failure(Exception("تعذر جلب بيانات ولي الأمر من الخادم (${response.status.value})"))
            }
        } catch (_: Exception) {
            Result.failure(Exception("تعذر الاتصال بخادم المدرسة. يرجى التحقق من اتصال الإنترنت."))
        }
    }

    private fun parseChild(obj: JsonObject): LinkedChild? {
        return try {
            val id = obj["id"]?.jsonPrimitive?.content ?: return null
            val studentNumber = obj["student_number"]?.jsonPrimitive?.content ?: "—"
            val fullName = obj["full_name"]?.jsonPrimitive?.content ?: "طالب"
            val status = obj["status"]?.jsonPrimitive?.content ?: "active"
            val relation = obj["relation"]?.jsonPrimitive?.contentOrNull ?: "ابن"
            val canViewFees = obj["can_view_fees"]?.jsonPrimitive?.booleanOrNull ?: true
            val receivesNotifications = obj["receives_notifications"]?.jsonPrimitive?.booleanOrNull ?: true
            val gradeName = obj["grade_name"]?.jsonPrimitive?.contentOrNull ?: "المرحلة الثانوية"
            val sectionName = obj["section_name"]?.jsonPrimitive?.contentOrNull ?: "شعبة (أ)"

            val grades = obj["grades"]?.jsonArray?.mapNotNull {
                val g = it.jsonObject
                PublishedGrade(
                    subjectName = g["subject_name"]?.jsonPrimitive?.content ?: "مادة",
                    title = g["title"]?.jsonPrimitive?.content ?: "تقييم",
                    term = g["term"]?.jsonPrimitive?.content ?: "الفصل الأول",
                    score = g["score"]?.jsonPrimitive?.doubleOrNull,
                    maxScore = g["max_score"]?.jsonPrimitive?.doubleOrNull ?: 100.0,
                    passScore = g["pass_score"]?.jsonPrimitive?.doubleOrNull ?: 50.0,
                    isAbsent = g["is_absent"]?.jsonPrimitive?.booleanOrNull ?: false
                )
            } ?: emptyList()

            val attendance = obj["attendance"]?.jsonArray?.mapNotNull {
                val a = it.jsonObject
                AttendanceRecord(
                    date = a["date"]?.jsonPrimitive?.content ?: "",
                    status = a["status"]?.jsonPrimitive?.content ?: "present",
                    reason = a["reason"]?.jsonPrimitive?.contentOrNull
                )
            } ?: emptyList()

            val feesObj = obj["fees"]?.jsonObject
            val fees = if (feesObj != null) {
                val totalDue = feesObj["total_due"]?.jsonPrimitive?.doubleOrNull ?: 0.0
                val totalDiscounts = feesObj["total_discounts"]?.jsonPrimitive?.doubleOrNull ?: 0.0
                val totalPaid = feesObj["total_paid"]?.jsonPrimitive?.doubleOrNull ?: 0.0
                val payments = feesObj["payments"]?.jsonArray?.mapNotNull {
                    val p = it.jsonObject
                    PaymentRecord(
                        amount = p["amount"]?.jsonPrimitive?.doubleOrNull ?: 0.0,
                        paymentMethod = p["payment_method"]?.jsonPrimitive?.content ?: "cash",
                        receiptNumber = p["receipt_number"]?.jsonPrimitive?.content ?: "REC-001",
                        createdAt = p["created_at"]?.jsonPrimitive?.content ?: ""
                    )
                } ?: emptyList()
                FeeStatement(totalDue, totalDiscounts, totalPaid, payments)
            } else null

            LinkedChild(
                id = id,
                studentNumber = studentNumber,
                fullName = fullName,
                status = status,
                relation = relation,
                canViewFees = canViewFees,
                receivesNotifications = receivesNotifications,
                gradeName = gradeName,
                sectionName = sectionName,
                grades = grades,
                attendance = attendance,
                fees = fees
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun parseAnnouncement(obj: JsonObject): AnnouncementItem? {
        return try {
            AnnouncementItem(
                id = obj["id"]?.jsonPrimitive?.content ?: "",
                title = obj["title"]?.jsonPrimitive?.content ?: "",
                body = obj["body"]?.jsonPrimitive?.content ?: "",
                priority = obj["priority"]?.jsonPrimitive?.content ?: "normal",
                publishedAt = obj["published_at"]?.jsonPrimitive?.content ?: ""
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun parseEvent(obj: JsonObject): CalendarEventItem? {
        return try {
            CalendarEventItem(
                id = obj["id"]?.jsonPrimitive?.content ?: "",
                title = obj["title"]?.jsonPrimitive?.content ?: "",
                description = obj["description"]?.jsonPrimitive?.contentOrNull,
                eventType = obj["event_type"]?.jsonPrimitive?.content ?: "general",
                startsOn = obj["starts_on"]?.jsonPrimitive?.content ?: "",
                endsOn = obj["ends_on"]?.jsonPrimitive?.contentOrNull
            )
        } catch (_: Exception) {
            null
        }
    }

    suspend fun fetchAnnouncements(): Result<List<AnnouncementItem>> = withContext(Dispatchers.IO) {
        Result.success(getSeedAnnouncements())
    }

    suspend fun fetchEvents(): Result<List<CalendarEventItem>> = withContext(Dispatchers.IO) {
        Result.success(getSeedEvents())
    }

    fun getSeedChildrenForGuardian(guardianId: String): List<LinkedChild> {
        return when (guardianId) {
            "guard-1" -> listOf(
                LinkedChild(
                    id = "std-1",
                    studentNumber = "STD-2026-001",
                    fullName = "محمد عبد الله أحمد",
                    status = "active",
                    relation = "ابن",
                    canViewFees = true,
                    gradeName = "الصف الأول الثانوي",
                    sectionName = "شعبة (أ)",
                    grades = listOf(
                        PublishedGrade(
                            subjectName = "القرآن الكريم والتربية الإسلامية",
                            title = "امتحان أعمال السنة",
                            term = "الفصل الأول",
                            score = 98.0,
                            maxScore = 100.0,
                            passScore = 50.0
                        ),
                        PublishedGrade(
                            subjectName = "اللغة العربية",
                            title = "امتحان أعمال السنة",
                            term = "الفصل الأول",
                            score = 91.0,
                            maxScore = 100.0,
                            passScore = 50.0
                        ),
                        PublishedGrade(
                            subjectName = "الرياضيات",
                            title = "امتحان أعمال السنة",
                            term = "الفصل الأول",
                            score = 96.0,
                            maxScore = 100.0,
                            passScore = 50.0
                        ),
                        PublishedGrade(
                            subjectName = "اللغة الإنجليزية",
                            title = "امتحان أعمال السنة",
                            term = "الفصل الأول",
                            score = 88.0,
                            maxScore = 100.0,
                            passScore = 50.0
                        )
                    ),
                    attendance = listOf(
                        AttendanceRecord(date = "2026-10-23", status = "present"),
                        AttendanceRecord(date = "2026-10-22", status = "present"),
                        AttendanceRecord(date = "2026-10-21", status = "present"),
                        AttendanceRecord(date = "2026-10-20", status = "present")
                    ),
                    fees = FeeStatement(
                        totalDue = 120000.0,
                        totalDiscounts = 20000.0,
                        totalPaid = 100000.0,
                        payments = listOf(
                            PaymentRecord(
                                amount = 100000.0,
                                paymentMethod = "bank_transfer",
                                receiptNumber = "REC-2026-00101",
                                createdAt = "2026-09-01 10:30:00"
                            )
                        )
                    )
                ),
                LinkedChild(
                    id = "std-2",
                    studentNumber = "STD-2026-002",
                    fullName = "فاطمة عبد الله أحمد",
                    status = "active",
                    relation = "ابنة",
                    canViewFees = true,
                    gradeName = "الصف الثالث الثانوي",
                    sectionName = "شعبة علمي (أ)",
                    grades = listOf(
                        PublishedGrade(
                            subjectName = "الفيزياء",
                            title = "امتحان منتصف الفصل الدراسي الأول",
                            term = "الفصل الأول",
                            score = 86.0,
                            maxScore = 100.0,
                            passScore = 50.0
                        ),
                        PublishedGrade(
                            subjectName = "الكيمياء",
                            title = "امتحان منتصف الفصل الدراسي الأول",
                            term = "الفصل الأول",
                            score = 92.0,
                            maxScore = 100.0,
                            passScore = 50.0
                        ),
                        PublishedGrade(
                            subjectName = "الأحياء",
                            title = "امتحان منتصف الفصل الدراسي الأول",
                            term = "الفصل الأول",
                            score = 90.0,
                            maxScore = 100.0,
                            passScore = 50.0
                        )
                    ),
                    attendance = listOf(
                        AttendanceRecord(date = "2026-10-23", status = "present"),
                        AttendanceRecord(date = "2026-10-22", status = "present"),
                        AttendanceRecord(date = "2026-10-21", status = "absent", reason = "إجازة مرضية معتمدة"),
                        AttendanceRecord(date = "2026-10-20", status = "present")
                    ),
                    fees = FeeStatement(
                        totalDue = 140000.0,
                        totalDiscounts = 0.0,
                        totalPaid = 140000.0,
                        payments = listOf(
                            PaymentRecord(
                                amount = 140000.0,
                                paymentMethod = "cash",
                                receiptNumber = "REC-2026-00102",
                                createdAt = "2026-09-02 09:15:00"
                            )
                        )
                    )
                )
            )
            "guard-2" -> listOf(
                LinkedChild(
                    id = "std-3",
                    studentNumber = "STD-2026-003",
                    fullName = "عمر عثمان علي",
                    status = "active",
                    relation = "ابن",
                    canViewFees = true,
                    gradeName = "الصف الأول الثانوي",
                    sectionName = "شعبة (أ)",
                    grades = listOf(
                        PublishedGrade(
                            subjectName = "الرياضيات",
                            title = "امتحان منتصف الفصل الأول",
                            term = "الفصل الأول",
                            score = 92.0,
                            maxScore = 100.0,
                            passScore = 50.0
                        )
                    ),
                    attendance = listOf(
                        AttendanceRecord(date = "2026-10-23", status = "present"),
                        AttendanceRecord(date = "2026-10-22", status = "present")
                    ),
                    fees = FeeStatement(
                        totalDue = 120000.0,
                        totalDiscounts = 0.0,
                        totalPaid = 60000.0,
                        payments = listOf(
                            PaymentRecord(
                                amount = 60000.0,
                                paymentMethod = "cash",
                                receiptNumber = "REC-2026-00201",
                                createdAt = "2026-09-05 11:00:00"
                            )
                        )
                    )
                )
            )
            else -> emptyList()
        }
    }

    private fun getSeedAnnouncements(): List<AnnouncementItem> = listOf(
        AnnouncementItem(
            id = "ann-1",
            title = "انطلاق امتحانات منتصف الفصل الدراسي الأول",
            body = "تعلن إدارة مدرسة العمرابي الثانوية بنين عن انطلاق امتحانات منتصف الفصل الدراسي الأول لجميع الصفوف، يرجى الالتزام بالحضور الصباحي المبكر في تمام الساعة 7:30 صباحاً.",
            priority = "high",
            publishedAt = "2026-10-23"
        ),
        AnnouncementItem(
            id = "ann-2",
            title = "اجتماع مجلس الآباء والمعلمين الدوري",
            body = "يسر إدارة المدرسة دعوة السادة أولياء الأمور الكرام لحضور اللقاء الدوري لمجلس الآباء والمعلمين لمناقشة المستوى التحصيلي للطلاب وتعزيز سبل الرعاية التربوية.",
            priority = "normal",
            publishedAt = "2026-10-21"
        )
    )

    private fun getSeedEvents(): List<CalendarEventItem> = listOf(
        CalendarEventItem(
            id = "ev-1",
            title = "امتحانات منتصف الفصل الدراسي الأول",
            description = "فترة الامتحانات التحريرية الشاملة لجميع المواد الدراسية",
            eventType = "exam",
            startsOn = "2026-10-25",
            endsOn = "2026-11-03"
        ),
        CalendarEventItem(
            id = "ev-2",
            title = "عطلة نهاية الفصل الدراسي الأول",
            description = "العطلة الرسمية المدرسية بين الفصلين الدراسيين",
            eventType = "holiday",
            startsOn = "2026-12-15",
            endsOn = "2026-12-25"
        )
    )
}
