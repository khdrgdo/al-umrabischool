package sd.alumrabi.parent.data.ai

import kotlinx.coroutines.delay
import sd.alumrabi.parent.data.model.*
import java.util.UUID

class AiAssistantService {

    // Guardrail security check for prompt injection and unauthorized queries
    private fun isPromptSafe(query: String): Boolean {
        val lower = query.lowercase().trim()
        val forbiddenPatterns = listOf(
            "ignore previous",
            "system prompt",
            "sql",
            "truncate",
            "service_role",
            "password",
            "secret_key",
            "كلمة سر",
            "طالب آخر",
            "بيانات المعلمين الشخصية",
            "اخترق",
            "root",
            "admin password"
        )
        return forbiddenPatterns.none { lower.contains(it) }
    }

    suspend fun generateResponse(
        userQuery: String,
        guardian: GuardianInfo,
        activeChild: LinkedChild?,
        announcements: List<AnnouncementItem> = emptyList(),
        events: List<CalendarEventItem> = emptyList()
    ): AiChatMessage {
        // Natural thinking latency for premium feel
        delay(600)

        val cleanQuery = userQuery.trim()

        if (!isPromptSafe(cleanQuery)) {
            return AiChatMessage(
                id = UUID.randomUUID().toString(),
                sender = MessageSender.ASSISTANT,
                text = "⚠️ تنبيه أمني: بصفتي المساعد الذكي لمدرسة العمرابي الثانوية، تنحصر صلاحياتي في تزويدك بالبيانات الأكاديمية والتربوية الخاصة بأبنائك المقيدين والسياسات الرسمية للمدرسة فقط، ولا يمكنني معالجة هذا الطلب."
            )
        }

        if (activeChild == null) {
            return AiChatMessage(
                id = UUID.randomUUID().toString(),
                sender = MessageSender.ASSISTANT,
                text = "مرحباً بك يا ${guardian.fullName}. لم يتم تحديد ملف طالب نشط حالياً. يرجى اختيار أحد أبنائك المقيدين من أعلى الشاشة لأتمكن من الإجابة عن جدول حصصه، درجاته، أو حضوره بدقة."
            )
        }

        val childName = activeChild.fullName
        val gradeName = activeChild.gradeName
        val sectionName = activeChild.sectionName
        val queryLower = cleanQuery.lowercase()

        val responseText = when {
            // 1. Inquiries about Schedule & Timetable
            queryLower.contains("جدول") || queryLower.contains("حصص") || queryLower.contains("اليوم") || queryLower.contains("مواد") -> {
                buildString {
                    append("📅 **الجدول الدراسي للطالب: $childName** ($gradeName - $sectionName):\n\n")
                    append("يبدأ اليوم الدراسي في تمام الساعة **7:30 صباحاً** بالطابور الصباحي، ويتضمن الجدول الأسبوعي المواد الأساسية التالية:\n")
                    append("• **الحصة الأولى والثانية:** القرآن الكريم والتربية الإسلامية / اللغة العربية.\n")
                    append("• **الحصة الثالثة والرابعة:** الرياضيات واللغة الإنجليزية.\n")
                    append("• **الحصة الخامسة والسادسة:** العلوم الطبيعية (الفيزياء والكيمياء والأحياء) / المواد الأدبية.\n\n")
                    append("💡 يمكنك استعراض التوزيع الكامل لجميع أيام الأسبوع عبر قسم «الجدول الدراسي» في التطبيق.")
                }
            }

            // 2. Inquiries about Grades & Academic Performance
            queryLower.contains("درجات") || queryLower.contains("نتيجة") || queryLower.contains("امتحان") || queryLower.contains("مستوى") || queryLower.contains("تقييم") -> {
                val grades = activeChild.grades ?: emptyList()
                if (grades.isEmpty()) {
                    "📊 **النتائج الأكاديمية للطالب $childName:**\n\nلم تُنشر أي نتائج امتحانات جديدة معتمدة حتى هذه اللحظة. تعتمد إدارة المدرسة سياسة نشر النتائج فقط بعد مراجعتها واعتمادها رسمياً من لجنة الامتحانات والمدير."
                } else {
                    val average = grades.mapNotNull { it.score }.average()
                    buildString {
                        append("📊 **المستوى الأكاديمي والنتائج المنشورة للطالب $childName:**\n\n")
                        append("المعدل العام التقريبي: **${String.format("%.1f", average)}%**\n\n")
                        append("**تفاصيل المواد المرصودة:**\n")
                        grades.forEach { g ->
                            val scoreStr = g.score?.let { "${it.toInt()} من ${g.maxScore.toInt()}" } ?: "قيد الرصد"
                            val statusIcon = if ((g.score ?: 0.0) >= g.passScore) "✅" else "⚠️"
                            append("$statusIcon **${g.subjectName}:** $scoreStr (${g.title})\n")
                        }
                        if (average >= 85.0) {
                            append("\n🌟 *مستوى متميز ومثالي، نوصي باستمرار تشجيعه على الحفاظ على هذا التفوق.*")
                        } else if (average >= 50.0) {
                            append("\n👍 *مستوى جيد وناجح مع وجود فرصة لرفع الدرجات بالمتابعة المستمرة.*")
                        }
                    }
                }
            }

            // 3. Inquiries about Attendance & Absences
            queryLower.contains("حضور") || queryLower.contains("غياب") || queryLower.contains("تأخر") || queryLower.contains("انضباط") -> {
                val records = activeChild.attendance ?: emptyList()
                val totalPresent = records.count { it.status == "present" }
                val totalAbsent = records.count { it.status == "absent" }
                val totalLate = records.count { it.status == "late" }
                val totalExcused = records.count { it.status == "excused" }

                buildString {
                    append("📝 **تقرير الحضور والغياب للطالب $childName:**\n\n")
                    append("• الأيام المسجلة: **${records.size} أيام**\n")
                    append("• الحضور الفعلي: **$totalPresent يوم** ✅\n")
                    if (totalAbsent > 0) append("• الغياب بدون عذر: **$totalAbsent يوم** ⚠️\n")
                    if (totalExcused > 0) append("• غياب معذور ومعتمد: **$totalExcused يوم** ℹ️\n")
                    if (totalLate > 0) append("• التأخر الصباحي: **$totalLate يوم**\n")

                    if (totalAbsent > 0) {
                        append("\n⚠️ *تنبيه:* يُرجى الحرص على عدم تكرار الغياب غير المبرر حتى لا يؤثر على تحصيل الطالب الأكاديمي.")
                    } else {
                        append("\n👏 *سجل انضباط ممتاز للطالب بدون أي غيابات غير مبررة.*")
                    }
                }
            }

            // 4. Inquiries about Fees & Financial Privacy
            queryLower.contains("رسوم") || queryLower.contains("دفع") || queryLower.contains("مصاريف") || queryLower.contains("سداد") || queryLower.contains("إيصال") -> {
                if (!activeChild.canViewFees) {
                    "🔒 **البيانات المالية:**\n\nحسابك الحالي كولي أمر لا يمتلك صلاحية عرض التفاصيل المالية لهذا الطالب (`can_view_fees = false`). لمراجعة الرسوم وتحديث الصلاحيات، يرجى التوجه لإدارة المدرسة."
                } else {
                    val fees = activeChild.fees
                    if (fees != null) {
                        buildString {
                            append("💳 **الموقف المالي للرسوم الدراسية للطالب $childName:**\n\n")
                            append("• إجمالي الرسوم المقررة: **${String.format("%,.0f", fees.totalDue)} جنيه**\n")
                            if (fees.totalDiscounts > 0) {
                                append("• إجمالي المنح والخصومات: **${String.format("%,.0f", fees.totalDiscounts)} جنيه**\n")
                            }
                            append("• المدفوع الفعلي المثبت: **${String.format("%,.0f", fees.totalPaid)} جنيه**\n")
                            append("• المتبقي المطلوب سداده: **${String.format("%,.0f", fees.remainingBalance)} جنيه**\n\n")
                            if (fees.isFullyPaid) {
                                append("✅ *تم سداد الرسوم بالكامل لهذا العام الدراسي.*")
                            } else {
                                append("ℹ️ *طريقة السداد المعتمدة:* يتم السداد نقداً لدى الإدارة المالية بالمدرسة مع استلام إيصال فوري مرقم خادمياً، أو عبر التحويل البنكي لحساب المدرسة الرسمي وتزويد الإدارة برقم الإشعار.")
                            }
                        }
                    } else {
                        "💳 **الرسوم الدراسية للطالب $childName:**\n\nيتم تحديد الرسوم وتوزيع الأقساط من قبل إدارة المدرسة وفق المرحلة الدراسية والمسار المعتمد. يمكنك مراجعة مكتب الإدارة المالية بالمدرسة للاطلاع على جدول الأقساط المعتمد أو سداد دفعة جديدة."
                    }
                }
            }

            // 5. Inquiries about Events, Exams & Academic Calendar
            queryLower.contains("فعاليات") || queryLower.contains("تقويم") || queryLower.contains("إجازة") || queryLower.contains("عطلة") || queryLower.contains("موعد") -> {
                if (events.isEmpty()) {
                    "📅 **التقويم المدرسي والفعاليات:**\n\nتستمر الدراسة وفق الخطة الأكاديمية للفصل الدراسي الحالي. لم تُسجل أي عطلات استثنائية أو فعاليات جديدة لهذا الأسبوع."
                } else {
                    buildString {
                        append("📅 **أهم المواعيد والفعاليات القادمة:**\n\n")
                        events.take(3).forEach { ev ->
                            append("• **${ev.title}:** تبدأ في ${ev.startsOn}\n")
                            if (!ev.description.isNullOrBlank()) {
                                append("  _${ev.description}_\n")
                            }
                        }
                    }
                }
            }

            // 6. General Greeting or Assistance
            else -> {
                "أهلاً بك يا ${guardian.fullName}. أنا مساعد العمرابي الذكي 🎓.\n\nيمكنني مساعدتك في كل ما يتعلق بالطالب **$childName**:\n• استعراض جدول الحصص اليومي والأسبوعي\n• تفاصيل الدرجات والتقييمات الشهرية\n• كشف الحضور وسجل الغياب\n• الاستفسار عن الرسوم والموقف المالي\n• مواعيد الاختبارات والفعاليات المدرسية\n\nما الذي تود الاستفسار عنه اليوم؟"
            }
        }

        return AiChatMessage(
            id = UUID.randomUUID().toString(),
            sender = MessageSender.ASSISTANT,
            text = responseText
        )
    }
}
