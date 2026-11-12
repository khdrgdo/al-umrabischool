package sd.alumrabi.parent.data.api

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.headers
import io.ktor.client.request.post
import io.ktor.client.request.put
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

/** جلسة Supabase Auth لولي الأمر. تُخزَّن مشفّرة فقط (انظر SessionManager). */
data class AuthTokens(
    val accessToken: String,
    val refreshToken: String,
    val expiresAtMillis: Long
) {
    fun isExpiringSoon(now: Long = System.currentTimeMillis()): Boolean = expiresAtMillis - now < 60_000L
}

class ParentApiClient(
    private val baseUrl: String = "https://c--8b91830b-7424-4960-81c7-67e94cdfd28d-prod.lovable.cloud",
    // نقطة التفعيل /api/public/parent-auth يخدمها تطبيق الويب (انظر README: Live app)، وليس واجهة Supabase.
    private val appBaseUrl: String = "https://al-umrabischool.lovable.app",
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
        // مهلات كافية لشبكات الهاتف البطيئة
        install(HttpTimeout) {
            requestTimeoutMillis = 20000
            connectTimeoutMillis = 10000
            socketTimeoutMillis = 20000
        }
    }

    // بريد الدخول مشتق من المعرّف (account_code) ولا يُستعمل للبريد الفعلي؛ كلمة المرور يختارها ولي الأمر ويديرها Supabase Auth.
    private fun loginEmail(accountCode: String) = "${accountCode.trim().lowercase()}@parents.alumrabi.invalid"

    private fun parseTokens(body: String): AuthTokens? {
        val o = json.parseToJsonElement(body).jsonObject
        val access = o["access_token"]?.jsonPrimitive?.contentOrNull ?: return null
        val refresh = o["refresh_token"]?.jsonPrimitive?.contentOrNull ?: return null
        val expiresIn = o["expires_in"]?.jsonPrimitive?.longOrNull ?: 3600L
        return AuthTokens(access, refresh, System.currentTimeMillis() + expiresIn * 1000L)
    }

    private val networkError = "تعذر الاتصال بخادم المدرسة. يرجى التحقق من اتصال الإنترنت والمحاولة لاحقاً."

    suspend fun signIn(accountCode: String, password: String): Result<AuthTokens> = withContext(Dispatchers.IO) {
        try {
            val response = client.post("$baseUrl/auth/v1/token?grant_type=password") {
                contentType(ContentType.Application.Json)
                headers { append("apikey", anonKey) }
                setBody(buildJsonObject {
                    put("email", loginEmail(accountCode))
                    put("password", password)
                })
            }
            when {
                response.status.isSuccess() ->
                    parseTokens(response.bodyAsText())?.let { Result.success(it) }
                        ?: Result.failure(Exception("استجابة غير متوقعة من الخادم"))
                response.status.value in 400..499 ->
                    Result.failure(Exception("بيانات الدخول غير صحيحة. تأكد من المعرّف وكلمة المرور، أو راجع إدارة المدرسة للحصول على رمز تفعيل."))
                else -> Result.failure(Exception("تعذر تسجيل الدخول من خادم المدرسة (${response.status.value})"))
            }
        } catch (_: Exception) {
            Result.failure(Exception(networkError))
        }
    }

    suspend fun refreshSession(refreshToken: String): Result<AuthTokens> = withContext(Dispatchers.IO) {
        try {
            val response = client.post("$baseUrl/auth/v1/token?grant_type=refresh_token") {
                contentType(ContentType.Application.Json)
                headers { append("apikey", anonKey) }
                setBody(buildJsonObject { put("refresh_token", refreshToken) })
            }
            if (response.status.isSuccess()) {
                parseTokens(response.bodyAsText())?.let { Result.success(it) }
                    ?: Result.failure(Exception("استجابة غير متوقعة من الخادم"))
            } else if (response.status.value in 400..499) {
                Result.failure(SessionExpiredException())
            } else {
                Result.failure(Exception(networkError))
            }
        } catch (_: Exception) {
            Result.failure(Exception(networkError))
        }
    }

    /** إنهاء الجلسة على الخادم (أفضل جهد؛ المسح المحلي يتم دائماً). */
    suspend fun signOut(accessToken: String) = withContext(Dispatchers.IO) {
        try {
            client.post("$baseUrl/auth/v1/logout") {
                headers {
                    append("apikey", anonKey)
                    append("Authorization", "Bearer $accessToken")
                }
            }
        } catch (_: Exception) {
        }
    }

    /** تفعيل أول مرة أو إعادة تعيين كلمة المرور برمز من الإدارة (لمرة واحدة، 72 ساعة). */
    suspend fun activate(accountCode: String, activationCode: String, newPassword: String): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            val response = client.post("$appBaseUrl/api/public/parent-auth") {
                contentType(ContentType.Application.Json)
                setBody(buildJsonObject {
                    put("account_code", accountCode.trim().uppercase())
                    put("activation_code", activationCode.trim())
                    put("password", newPassword)
                })
            }
            if (response.status.isSuccess()) {
                Result.success(Unit)
            } else {
                val msg = try {
                    json.parseToJsonElement(response.bodyAsText()).jsonObject["message"]?.jsonPrimitive?.contentOrNull
                } catch (_: Exception) { null }
                Result.failure(Exception(msg ?: "تعذر إكمال التفعيل (${response.status.value})"))
            }
        } catch (_: Exception) {
            Result.failure(Exception(networkError))
        }
    }

    /** لوحة ولي الأمر بجلسته هو: عزل الأسر يفرضه الخادم عبر auth.uid() داخل الدالة. */
    suspend fun fetchDashboard(accessToken: String): Result<DashboardPayload> = withContext(Dispatchers.IO) {
        try {
            val response = client.post("$baseUrl/rest/v1/rpc/parent_get_dashboard_data") {
                contentType(ContentType.Application.Json)
                headers {
                    append("apikey", anonKey)
                    append("Authorization", "Bearer $accessToken")
                }
                setBody(buildJsonObject { })
            }
            if (response.status.value == 401) return@withContext Result.failure(SessionExpiredException())
            if (!response.status.isSuccess()) {
                return@withContext Result.failure(Exception("تعذر جلب بيانات ولي الأمر من الخادم (${response.status.value})"))
            }
            val element = json.parseToJsonElement(response.bodyAsText()).jsonObject
            val err = element["error"]?.jsonPrimitive?.contentOrNull
            if (err != null) {
                val msg = element["message"]?.jsonPrimitive?.contentOrNull ?: "تعذر جلب بيانات ولي الأمر"
                return@withContext Result.failure(if (err == "ACCOUNT_SUSPENDED" || err == "ACCOUNT_INACTIVE" || err == "NOT_REGISTERED") AccountBlockedException(msg) else Exception(msg))
            }
            val g = element.obj("guardian") ?: return@withContext Result.failure(Exception("استجابة غير متوقعة من الخادم"))
            val guardian = GuardianInfo(
                id = g["id"]?.jsonPrimitive?.content ?: "",
                accountCode = g["account_code"]?.jsonPrimitive?.contentOrNull,
                fullName = g["full_name"]?.jsonPrimitive?.contentOrNull ?: "ولي الأمر",
                phone = g["phone"]?.jsonPrimitive?.contentOrNull ?: "",
                status = g["status"]?.jsonPrimitive?.contentOrNull ?: "active"
            )
            val children = element.arr("children")?.mapNotNull { (it as? JsonObject)?.let(::parseChild) } ?: emptyList()
            val announcements = element.arr("announcements")?.mapNotNull { (it as? JsonObject)?.let(::parseAnnouncement) } ?: emptyList()
            val events = element.arr("events")?.mapNotNull { (it as? JsonObject)?.let(::parseEvent) } ?: emptyList()
            val schoolObj = element.obj("school")
            val school = schoolObj?.let {
                SchoolInfo(
                    name = it["name"]?.jsonPrimitive?.contentOrNull ?: "",
                    whatsappNumber = it["whatsapp_number"]?.jsonPrimitive?.contentOrNull
                )
            }
            Result.success(DashboardPayload(guardian, children, announcements, events, school))
        } catch (_: Exception) {
            Result.failure(Exception("تعذر الاتصال بخادم المدرسة. يرجى التحقق من اتصال الإنترنت."))
        }
    }

    private fun errMsg(text: String, fallback: String): String = try {
        val o = json.parseToJsonElement(text).jsonObject
        o["msg"]?.jsonPrimitive?.contentOrNull
            ?: o["message"]?.jsonPrimitive?.contentOrNull
            ?: o["error_description"]?.jsonPrimitive?.contentOrNull
            ?: fallback
    } catch (_: Exception) {
        fallback
    }

    /** تسجيل اطلاع ولي الأمر على إعلانات (يظهر للإدارة). */
    suspend fun markAnnouncementsRead(accessToken: String, ids: List<String>): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            val response = client.post("$baseUrl/rest/v1/rpc/parent_mark_announcements_read") {
                contentType(ContentType.Application.Json)
                headers {
                    append("apikey", anonKey)
                    append("Authorization", "Bearer $accessToken")
                }
                setBody(buildJsonObject { put("p_ids", buildJsonArray { ids.forEach { add(it) } }) })
            }
            if (response.status.value == 401) Result.failure(SessionExpiredException())
            else if (response.status.isSuccess()) Result.success(Unit)
            else Result.failure(Exception("read " + response.status.value))
        } catch (_: Exception) {
            Result.failure(Exception(networkError))
        }
    }

    /** بلاغ مشكلة/سؤال/اقتراح إلى إدارة المدرسة. */
    suspend fun submitReport(
        accessToken: String, category: String, body: String, studentId: String?, appVersion: String, device: String
    ): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            val response = client.post("$baseUrl/rest/v1/rpc/parent_submit_report") {
                contentType(ContentType.Application.Json)
                headers {
                    append("apikey", anonKey)
                    append("Authorization", "Bearer $accessToken")
                }
                setBody(buildJsonObject {
                    put("p_category", category)
                    put("p_body", body)
                    put("p_student_id", studentId)
                    put("p_app_version", appVersion)
                    put("p_device", device)
                })
            }
            if (response.status.value == 401) return@withContext Result.failure(SessionExpiredException())
            if (!response.status.isSuccess()) return@withContext Result.failure(Exception("تعذر إرسال البلاغ (" + response.status.value + ")"))
            val o = json.parseToJsonElement(response.bodyAsText()).jsonObject
            when (o["error"]?.jsonPrimitive?.contentOrNull) {
                null -> Result.success(Unit)
                "RATE_LIMITED" -> Result.failure(Exception("وصلت للحد اليومي من البلاغات (5)، حاول غداً."))
                "INVALID" -> Result.failure(Exception("اكتب وصفاً أوضح (5 أحرف على الأقل)."))
                else -> Result.failure(Exception("تعذر إرسال البلاغ"))
            }
        } catch (_: Exception) {
            Result.failure(Exception(networkError))
        }
    }

    /** تغيير كلمة المرور من داخل التطبيق: نتحقق من الحالية بتسجيل دخول ثم نحدّث ونعيد جلسة جديدة. */
    suspend fun changePassword(accountCode: String, oldPassword: String, newPassword: String): Result<AuthTokens> = withContext(Dispatchers.IO) {
        val verified = signIn(accountCode, oldPassword)
        val tk = verified.getOrNull()
            ?: return@withContext Result.failure(
                Exception(
                    verified.exceptionOrNull()?.message?.takeIf { it.contains("الاتصال") } ?: "كلمة المرور الحالية غير صحيحة"
                )
            )
        try {
            val response = client.put("$baseUrl/auth/v1/user") {
                contentType(ContentType.Application.Json)
                headers {
                    append("apikey", anonKey)
                    append("Authorization", "Bearer " + tk.accessToken)
                }
                setBody(buildJsonObject { put("password", newPassword) })
            }
            if (!response.status.isSuccess()) {
                return@withContext Result.failure(Exception(errMsg(response.bodyAsText(), "تعذر تغيير كلمة المرور (" + response.status.value + ")")))
            }
            signIn(accountCode, newPassword)
        } catch (_: Exception) {
            Result.failure(Exception(networkError))
        }
    }

    // الخادم يعيد null (لا مصفوفة فارغة) عند غياب الدرجات/الحضور؛ القراءة الآمنة تمنع إسقاط الابن كله.
    private fun JsonObject.arr(key: String): JsonArray? = this[key] as? JsonArray
    private fun JsonObject.obj(key: String): JsonObject? = this[key] as? JsonObject

    private fun parseChild(obj: JsonObject): LinkedChild? {
        return try {
            val id = obj["id"]?.jsonPrimitive?.content ?: return null
            val studentNumber = obj["student_number"]?.jsonPrimitive?.content ?: "—"
            val fullName = obj["full_name"]?.jsonPrimitive?.content ?: "طالب"
            val status = obj["status"]?.jsonPrimitive?.content ?: "active"
            val relation = obj["relation"]?.jsonPrimitive?.contentOrNull ?: "ابن"
            val canViewFees = obj["can_view_fees"]?.jsonPrimitive?.booleanOrNull ?: true
            val receivesNotifications = obj["receives_notifications"]?.jsonPrimitive?.booleanOrNull ?: true
            val gradeName = obj["grade_name"]?.jsonPrimitive?.contentOrNull ?: "غير محدد"
            val sectionName = obj["section_name"]?.jsonPrimitive?.contentOrNull ?: "غير محدد"

            val grades = obj.arr("grades")?.mapNotNull {
                val g = it.jsonObject
                PublishedGrade(
                    subjectName = g["subject_name"]?.jsonPrimitive?.content ?: "مادة",
                    title = g["title"]?.jsonPrimitive?.content ?: "تقييم",
                    term = g["term"]?.jsonPrimitive?.content ?: "",
                    score = g["score"]?.jsonPrimitive?.doubleOrNull,
                    maxScore = g["max_score"]?.jsonPrimitive?.doubleOrNull ?: 100.0,
                    passScore = g["pass_score"]?.jsonPrimitive?.doubleOrNull ?: 50.0,
                    isAbsent = g["is_absent"]?.jsonPrimitive?.booleanOrNull ?: false,
                    gradedAt = g["graded_at"]?.jsonPrimitive?.contentOrNull,
                    academicYearId = g["academic_year_id"]?.jsonPrimitive?.contentOrNull,
                    academicYear = g["academic_year"]?.jsonPrimitive?.contentOrNull
                )
            } ?: emptyList()

            val attendance = obj.arr("attendance")?.mapNotNull {
                val a = it.jsonObject
                AttendanceRecord(
                    date = a["date"]?.jsonPrimitive?.content ?: "",
                    status = a["status"]?.jsonPrimitive?.content ?: "present",
                    reason = a["reason"]?.jsonPrimitive?.contentOrNull
                )
            } ?: emptyList()

            val feesObj = obj.obj("fees")
            val fees = if (feesObj != null) {
                val totalDue = feesObj["total_due"]?.jsonPrimitive?.doubleOrNull ?: 0.0
                val totalDiscounts = feesObj["total_discounts"]?.jsonPrimitive?.doubleOrNull ?: 0.0
                val totalPaid = feesObj["total_paid"]?.jsonPrimitive?.doubleOrNull ?: 0.0
                val payments = feesObj.arr("payments")?.mapNotNull {
                    val p = it.jsonObject
                    PaymentRecord(
                        amount = p["amount"]?.jsonPrimitive?.doubleOrNull ?: 0.0,
                        paymentMethod = p["payment_method"]?.jsonPrimitive?.content ?: "cash",
                        receiptNumber = p["receipt_number"]?.jsonPrimitive?.content ?: "—",
                        createdAt = p["created_at"]?.jsonPrimitive?.content ?: "",
                        feeName = p["fee_name"]?.jsonPrimitive?.contentOrNull
                    )
                } ?: emptyList()
                val items = feesObj.arr("items")?.mapNotNull {
                    val f = it as? JsonObject ?: return@mapNotNull null
                    FeeItem(
                        name = f["name"]?.jsonPrimitive?.contentOrNull ?: "رسوم",
                        description = f["description"]?.jsonPrimitive?.contentOrNull,
                        amount = f["amount"]?.jsonPrimitive?.doubleOrNull ?: 0.0,
                        discount = f["discount"]?.jsonPrimitive?.doubleOrNull ?: 0.0,
                        paid = f["paid"]?.jsonPrimitive?.doubleOrNull ?: 0.0,
                        dueDate = f["due_date"]?.jsonPrimitive?.contentOrNull,
                        isOptional = f["is_optional"]?.jsonPrimitive?.booleanOrNull ?: false
                    )
                } ?: emptyList()
                FeeStatement(totalDue, totalDiscounts, totalPaid, payments, items)
            } else null

            val schedule = obj.arr("schedule")?.mapNotNull {
                val s = it as? JsonObject ?: return@mapNotNull null
                ScheduleEntry(
                    weekday = s["weekday"]?.jsonPrimitive?.intOrNull ?: return@mapNotNull null,
                    periodOrder = s["period_order"]?.jsonPrimitive?.intOrNull ?: 0,
                    label = s["label"]?.jsonPrimitive?.contentOrNull ?: "",
                    startsAt = s["starts_at"]?.jsonPrimitive?.contentOrNull ?: "",
                    endsAt = s["ends_at"]?.jsonPrimitive?.contentOrNull ?: "",
                    isBreak = s["is_break"]?.jsonPrimitive?.booleanOrNull ?: false,
                    subject = s["subject"]?.jsonPrimitive?.contentOrNull ?: "",
                    room = s["room"]?.jsonPrimitive?.contentOrNull
                )
            } ?: emptyList()

            val subjects = obj.arr("subjects")?.mapNotNull {
                val s = it as? JsonObject ?: return@mapNotNull null
                SubjectInfo(
                    subjectName = s["subject_name"]?.jsonPrimitive?.contentOrNull ?: return@mapNotNull null,
                    teacherName = s["teacher_name"]?.jsonPrimitive?.contentOrNull,
                    weeklyPeriods = s["weekly_periods"]?.jsonPrimitive?.intOrNull ?: 0
                )
            } ?: emptyList()

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
                fees = fees,
                schedule = schedule,
                subjects = subjects
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
                publishedAt = obj["published_at"]?.jsonPrimitive?.content ?: "",
                targeted = obj["targeted"]?.jsonPrimitive?.booleanOrNull ?: false,
                readAt = obj["read_at"]?.jsonPrimitive?.contentOrNull
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
}

/** الجلسة منتهية أو مرفوضة: يلزم تسجيل دخول جديد. */
class SessionExpiredException : Exception("انتهت الجلسة. يرجى تسجيل الدخول من جديد.")

/** الحساب موقوف/غير مفعّل/غير مرتبط: يُمسح التخزين المحلي ويعود المستخدم لشاشة الدخول. */
class AccountBlockedException(message: String) : Exception(message)
