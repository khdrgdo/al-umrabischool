package sd.alumrabi.parent.data.ai

import sd.alumrabi.parent.data.model.*
import sd.alumrabi.parent.util.Fmt
import java.time.LocalDate
import java.util.UUID

/**
 * مساعد محلي بسيط: يجيب فقط من البيانات المعتمدة الموجودة في التطبيق،
 * ولا يخترع سياسات أو أرقاماً. لا يوجد نموذج لغوي ولا اتصال شبكي.
 */
class AiAssistantService {

    private val blocked = listOf(
        "ignore previous", "system prompt", "sql", "truncate", "service_role",
        "password", "secret_key", "كلمة سر", "كلمة المرور", "اخترق"
    )

    private fun reply(text: String) = AiChatMessage(
        id = UUID.randomUUID().toString(),
        sender = MessageSender.ASSISTANT,
        text = text
    )

    fun welcome(guardian: GuardianInfo, child: LinkedChild?): AiChatMessage {
        val name = Fmt.firstName(guardian.fullName)
        return if (child == null) {
            reply("مرحباً $name. لا يوجد ابن مرتبط بحسابك حالياً، لذلك لا أستطيع عرض بيانات. تواصل مع إدارة المدرسة لربط أبنائك.")
        } else {
            reply("مرحباً $name. أستطيع إخبارك بدرجات ${Fmt.firstName(child.fullName)} وحضوره ورسومه والإعلانات والمواعيد القادمة، من البيانات المعتمدة فقط.")
        }
    }

    fun generateResponse(
        userQuery: String,
        guardian: GuardianInfo,
        activeChild: LinkedChild?,
        announcements: List<AnnouncementItem> = emptyList(),
        events: List<CalendarEventItem> = emptyList()
    ): AiChatMessage {
        val q = userQuery.trim()
        val lower = q.lowercase()
        if (blocked.any { lower.contains(it) }) {
            return reply("لا أستطيع المساعدة في هذا الطلب. أستطيع فقط عرض بيانات ابنك الأكاديمية والإعلانات.")
        }

        fun has(vararg words: String) = words.any { q.contains(it) }

        // أسئلة لا تحتاج إلى ابن محدد
        if (has("إعلان", "اعلان", "إعلانات", "اعلانات")) return reply(announcementsText(announcements))
        if (has("تقويم", "موعد", "مواعيد", "امتحان", "إجازة", "اجازة", "فعالية")) return reply(eventsText(events))

        if (activeChild == null) {
            return reply("لا يوجد ابن مرتبط بحسابك حالياً. تواصل مع إدارة المدرسة لربط أبنائك.")
        }

        return when {
            has("جدول", "حصة", "حصص") ->
                reply("الجدول الدراسي غير متاح بعد في التطبيق. سيظهر هنا عندما تنشره المدرسة.")
            has("درجة", "درجات", "نتيجة", "نتائج", "معدل") -> reply(gradesText(activeChild))
            has("حضور", "غياب", "غائب", "تأخر") -> reply(attendanceText(activeChild))
            has("رسوم", "مصروفات", "سداد", "دفع", "قسط", "متبقي") -> reply(feesText(activeChild))
            else -> reply("يمكنني الإجابة عن: الدرجات، الحضور، الرسوم، الإعلانات، المواعيد القادمة. اكتب سؤالك بإحدى هذه الكلمات.")
        }
    }

    private fun gradesText(c: LinkedChild): String {
        val scored = c.grades.orEmpty().filter { !it.isAbsent && it.score != null }
        if (scored.isEmpty()) return "لا توجد درجات معتمدة منشورة لـ ${Fmt.firstName(c.fullName)} حتى الآن."
        val avg = scored.sumOf { (it.score ?: 0.0) / (if (it.maxScore > 0) it.maxScore else 100.0) * 100.0 } / scored.size
        val failed = scored.count { (it.score ?: 0.0) < it.passScore }
        val lines = mutableListOf(
            "عدد النتائج المنشورة: ${scored.size}",
            "المتوسط: ${Fmt.percent(avg)}",
            if (failed == 0) "لا توجد نتائج دون درجة النجاح." else "نتائج دون درجة النجاح: $failed"
        )
        scored.take(3).forEach { lines.add("${it.subjectName}: ${Fmt.score(it.score ?: 0.0)} من ${Fmt.score(it.maxScore)}") }
        return lines.joinToString("\n")
    }

    private fun attendanceText(c: LinkedChild): String {
        val records = c.attendance.orEmpty()
        if (records.isEmpty()) return "لا توجد سجلات حضور مسجلة لـ ${Fmt.firstName(c.fullName)} حتى الآن."
        val present = records.count { it.status == "present" }
        val absent = records.count { it.status == "absent" }
        val late = records.count { it.status == "late" }
        val excused = records.count { it.status == "excused" }
        return "من أصل ${records.size} يوماً مسجلاً:\nحضور: $present\nغياب: $absent\nتأخر: $late\nبعذر: $excused"
    }

    private fun feesText(c: LinkedChild): String {
        val f = c.fees
        if (!c.canViewFees || f == null) return "بيانات الرسوم غير متاحة لهذا الحساب. للاستفسار تواصل مع إدارة المدرسة."
        return "المطلوب بعد الخصومات: ${Fmt.number(f.netDue)}\nالمدفوع: ${Fmt.number(f.totalPaid)}\nالمتبقي: ${Fmt.number(f.remainingBalance)}"
    }

    private fun announcementsText(list: List<AnnouncementItem>): String {
        if (list.isEmpty()) return "لا توجد إعلانات منشورة حالياً."
        return list.take(3).joinToString("\n\n") { "${it.title}\n${Fmt.dateOrRaw(it.publishedAt)}" }
    }

    private fun eventsText(events: List<CalendarEventItem>): String {
        val today = LocalDate.now()
        val upcoming = events
            .filter { e ->
                val end = Fmt.parseDate(e.endsOn) ?: Fmt.parseDate(e.startsOn)
                end != null && !end.isBefore(today)
            }
            .sortedBy { Fmt.parseDate(it.startsOn) ?: today }
        if (upcoming.isEmpty()) return "لا توجد مواعيد قادمة في التقويم."
        return upcoming.take(3).joinToString("\n") { e ->
            val d = Fmt.parseDate(e.startsOn)
            "${if (d != null) Fmt.dayMonth(d) else e.startsOn}: ${e.title}"
        }
    }
}
