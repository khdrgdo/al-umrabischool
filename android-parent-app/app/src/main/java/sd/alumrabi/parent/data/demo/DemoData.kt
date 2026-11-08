package sd.alumrabi.parent.data.demo

import sd.alumrabi.parent.data.model.*
import java.time.DayOfWeek
import java.time.LocalDate

/**
 * بيانات اصطناعية للاختبار فقط. تُستخدم من زر التجربة الذي يظهر في النسخة التجريبية (debug) فقط،
 * ولا تُحفظ في الجهاز ولا تتصل بالخادم. لا تمثّل أي طالب حقيقي.
 */
object DemoData {

    private fun recentSchoolDays(count: Int): List<LocalDate> {
        val out = mutableListOf<LocalDate>()
        var d = LocalDate.now().minusDays(1)
        while (out.size < count) {
            if (d.dayOfWeek != DayOfWeek.FRIDAY && d.dayOfWeek != DayOfWeek.SATURDAY) out.add(d)
            d = d.minusDays(1)
        }
        return out
    }

    private fun attendance(pattern: List<String>): List<AttendanceRecord> =
        recentSchoolDays(pattern.size).mapIndexed { i, day ->
            AttendanceRecord(
                date = day.toString(),
                status = pattern[i],
                reason = if (pattern[i] == "excused") "ظرف صحي" else null
            )
        }

    private fun grade(subject: String, title: String, score: Double?, max: Double = 100.0, pass: Double = 50.0, absent: Boolean = false) =
        PublishedGrade(subject, title, "الفصل الأول", score, max, pass, absent)

    private fun demoItems(f: FeeStatement, today: LocalDate): List<FeeItem> {
        val act = f.totalDue * 0.2
        val tui = f.totalDue - act
        val actPaid = minOf(f.totalPaid, act)
        val tuiPaid = (f.totalPaid - actPaid).coerceAtLeast(0.0)
        return listOf(
            FeeItem("رسوم دراسية", "القسط الأساسي", tui, f.totalDiscounts, tuiPaid, today.plusDays(25).toString()),
            FeeItem("رسوم أنشطة", null, act, 0.0, actPaid, today.minusDays(10).toString())
        )
    }

    private fun demoSchedule(): List<ScheduleEntry> {
        val subjects = listOf("اللغة العربية", "الرياضيات", "العلوم", "اللغة الإنجليزية", "التربية الإسلامية", "الاجتماعيات")
        val starts = listOf("07:45", "08:35", "09:25", "10:35", "11:25", "12:15")
        val ends = listOf("08:30", "09:20", "10:10", "11:20", "12:10", "13:00")
        val out = mutableListOf<ScheduleEntry>()
        for (day in 0..4) {
            for (p in 0..5) {
                out.add(ScheduleEntry(day, p + 1, "الحصة ${p + 1}", starts[p], ends[p], false, subjects[(p + day) % subjects.size], "قاعة ${p + 1}"))
            }
            out.add(ScheduleEntry(day, 3, "الفسحة", "10:10", "10:35", true, "", null))
        }
        return out
    }

    fun payload(): DashboardPayload {
        val today = LocalDate.now()
        val guardian = GuardianInfo(
            id = "demo-guardian",
            accountCode = "DEMO",
            fullName = "ولي أمر (بيانات تجريبية)",
            phone = "",
            status = "active"
        )

        val kg = LinkedChild(
            id = "demo-1", studentNumber = "DEMO-001", fullName = "أحمد تجريبي الرياض",
            status = "active", relation = "ابن",
            gradeName = "رياض أطفال — المستوى الثاني", sectionName = "بنين — شعبة أ",
            grades = emptyList(),
            attendance = attendance(listOf("present", "present", "late", "present", "present", "absent", "present", "present")),
            fees = FeeStatement(
                totalDue = 600000.0, totalDiscounts = 50000.0, totalPaid = 300000.0,
                payments = listOf(PaymentRecord(300000.0, "cash", "DEMO-R-001", today.minusDays(40).toString()))
            )
        )

        val basic = LinkedChild(
            id = "demo-2", studentNumber = "DEMO-002", fullName = "فاطمة تجريبية الأساس",
            status = "active", relation = "ابنة",
            gradeName = "الصف الرابع الأساسي", sectionName = "بنات — شعبة ب",
            grades = listOf(
                grade("اللغة العربية", "امتحان نصف الفصل", 88.0),
                grade("الرياضيات", "امتحان نصف الفصل", 92.5),
                grade("العلوم", "امتحان نصف الفصل", 45.0),
                grade("التربية الإسلامية", "اختبار قصير", 19.0, max = 20.0, pass = 10.0)
            ),
            attendance = attendance(List(14) { "present" }),
            fees = FeeStatement(totalDue = 900000.0, totalDiscounts = 0.0, totalPaid = 900000.0,
                payments = listOf(PaymentRecord(900000.0, "bank", "DEMO-R-002", today.minusDays(60).toString())))
        )

        val mid = LinkedChild(
            id = "demo-3", studentNumber = "DEMO-003", fullName = "محمد تجريبي المتوسط",
            status = "active", relation = "ابن",
            gradeName = "الصف الثاني المتوسط", sectionName = "بنين — شعبة ج",
            grades = listOf(
                grade("اللغة الإنجليزية", "امتحان نصف الفصل", 71.0),
                grade("الرياضيات", "امتحان نصف الفصل", null, absent = true),
                grade("الجغرافيا", "اختبار قصير", 38.0)
            ),
            attendance = attendance(listOf("present", "excused", "absent", "absent", "present", "late", "present", "present", "present", "present")),
            fees = null, canViewFees = false
        )

        val sec = LinkedChild(
            id = "demo-4", studentNumber = "DEMO-004", fullName = "عائشة تجريبية الثانوي",
            status = "active", relation = "ابنة",
            gradeName = "الصف الثالث الثانوي", sectionName = "بنات — علمي",
            grades = listOf(
                grade("الفيزياء", "امتحان نصف الفصل", 79.0),
                grade("الكيمياء", "امتحان نصف الفصل", 84.0),
                grade("الأحياء", "امتحان نصف الفصل", 90.0),
                grade("اللغة العربية", "اختبار قصير", 17.5, max = 20.0, pass = 10.0)
            ),
            attendance = attendance(List(12) { if (it == 4) "late" else "present" }),
            fees = FeeStatement(totalDue = 1200000.0, totalDiscounts = 100000.0, totalPaid = 400000.0,
                payments = listOf(
                    PaymentRecord(250000.0, "cash", "DEMO-R-003", today.minusDays(75).toString()),
                    PaymentRecord(150000.0, "cash", "DEMO-R-004", today.minusDays(20).toString())
                ))
        )

        return DashboardPayload(
            guardian = guardian,
            children = listOf(kg, basic, mid, sec).map { it.copy(fees = it.fees?.let { f -> f.copy(items = demoItems(f, today)) }, schedule = demoSchedule()) },
            announcements = listOf(
                AnnouncementItem("demo-a1", "إعلان تجريبي هام", "هذا نص إعلان اصطناعي لاختبار شكل الإعلانات المهمة.", "high", today.minusDays(1).toString()),
                AnnouncementItem("demo-a2", "إعلان تجريبي عادي", "هذا نص إعلان اصطناعي أطول لاختبار توزيع النص على عدة أسطر في الشاشة ومراجعة المسافات وارتفاع السطر في النص العربي.", "normal", today.minusDays(6).toString())
            ),
            events = listOf(
                CalendarEventItem("demo-e1", "فعالية تجريبية قادمة", "وصف اصطناعي للفعالية.", "event", today.plusDays(5).toString(), null),
                CalendarEventItem("demo-e2", "فترة امتحانات تجريبية", null, "exam", today.plusDays(14).toString(), today.plusDays(18).toString())
            )
        )
    }
}
