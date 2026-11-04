package sd.alumrabi.parent.data

import sd.alumrabi.parent.data.model.*

/**
 * بيانات محلية اصطناعية للاختبار فقط.
 * لا تتصل هذه البيانات بالخادم ولا تُحفظ في جلسة الإنتاج.
 */
object DemoData {
    const val FAMILY_ACCOUNT = "DEMO-FAMILY-01"
    const val SINGLE_ACCOUNT = "DEMO-SINGLE-01"
    const val PASSWORD = "demo2026"

    fun authenticate(accountCode: String, password: String): DashboardPayload? {
        if (password != PASSWORD) return null
        return when (accountCode.trim().uppercase()) {
            FAMILY_ACCOUNT -> familyPayload()
            SINGLE_ACCOUNT -> singlePayload()
            else -> null
        }
    }

    private fun scheduleFor(stage: String): List<ScheduleEntry> {
        val subjects = when (stage) {
            "kindergarten" -> listOf("اللغة العربية", "الأرقام", "الأنشطة", "التربية الإسلامية")
            "basic" -> listOf("اللغة العربية", "الرياضيات", "العلوم", "اللغة الإنجليزية")
            "intermediate" -> listOf("اللغة العربية", "الرياضيات", "العلوم", "اللغة الإنجليزية", "الحاسوب")
            else -> listOf("الرياضيات", "الفيزياء", "الكيمياء", "اللغة العربية", "اللغة الإنجليزية")
        }
        val days = listOf("sunday", "monday", "tuesday", "wednesday", "thursday")
        return days.flatMapIndexed { dayIndex, day ->
            listOf(
                ScheduleEntry(day, 1, "08:00", "08:45", subjects[dayIndex % subjects.size], "معلم تجريبي", "قاعة تجريبية"),
                ScheduleEntry(day, 2, "09:00", "09:45", subjects[(dayIndex + 1) % subjects.size], "معلم تجريبي", "قاعة تجريبية"),
                ScheduleEntry(day, 3, "10:00", "10:45", subjects[(dayIndex + 2) % subjects.size], "معلم تجريبي", "قاعة تجريبية")
            )
        }
    }

    private fun familyPayload() = DashboardPayload(
        guardian = GuardianInfo(
            id = "demo-guardian-family",
            accountCode = FAMILY_ACCOUNT,
            fullName = "أحمد محمد عبد الرحمن",
            phone = "+249900000001",
            status = "active"
        ),
        children = listOf(
            LinkedChild(
                id = "demo-child-001",
                studentNumber = "DEMO-0001",
                fullName = "سارة أحمد محمد",
                status = "active",
                relation = "ابنة",
                gradeName = "روضة المستوى الثاني",
                sectionName = "المجموعة (أ)",
                schedule = scheduleFor("kindergarten"),
                attendance = listOf(
                    AttendanceRecord("2026-11-04", "present"),
                    AttendanceRecord("2026-11-03", "present"),
                    AttendanceRecord("2026-11-02", "absent", "غياب تجريبي")
                ),
                fees = FeeStatement(
                    totalDue = 180000.0,
                    totalDiscounts = 20000.0,
                    totalPaid = 100000.0,
                    payments = listOf(
                        PaymentRecord(100000.0, "cash", "DEMO-REC-001", "2026-10-20 09:00:00")
                    )
                )
            ),
            LinkedChild(
                id = "demo-child-002",
                studentNumber = "DEMO-0002",
                fullName = "عبد الرحمن أحمد محمد",
                status = "active",
                relation = "ابن",
                gradeName = "الصف السادس — المرحلة الأساسية",
                sectionName = "الشعبة (ب)",
                schedule = scheduleFor("basic"),
                grades = listOf(
                    PublishedGrade("اللغة العربية", "اختبار شهري", "الفصل الأول", 87.0),
                    PublishedGrade("الرياضيات", "اختبار شهري", "الفصل الأول", 91.0),
                    PublishedGrade("العلوم", "أعمال السنة", "الفصل الأول", 84.0)
                ),
                attendance = listOf(
                    AttendanceRecord("2026-11-04", "present"),
                    AttendanceRecord("2026-11-03", "late", "تأخر صباحي"),
                    AttendanceRecord("2026-11-02", "present")
                ),
                fees = FeeStatement(
                    totalDue = 240000.0,
                    totalDiscounts = 0.0,
                    totalPaid = 160000.0,
                    payments = listOf(
                        PaymentRecord(160000.0, "bank_transfer", "DEMO-REC-002", "2026-10-18 10:30:00")
                    )
                )
            ),
            LinkedChild(
                id = "demo-child-003",
                studentNumber = "DEMO-0003",
                fullName = "مريم أحمد محمد",
                status = "active",
                relation = "ابنة",
                gradeName = "الصف الثاني — المرحلة المتوسطة",
                sectionName = "الشعبة (أ)",
                schedule = scheduleFor("intermediate"),
                grades = listOf(
                    PublishedGrade("اللغة العربية", "امتحان قصير", "الفصل الأول", 94.0),
                    PublishedGrade("الرياضيات", "امتحان قصير", "الفصل الأول", 88.0),
                    PublishedGrade("اللغة الإنجليزية", "أعمال السنة", "الفصل الأول", 92.0)
                ),
                attendance = listOf(
                    AttendanceRecord("2026-11-04", "present"),
                    AttendanceRecord("2026-11-03", "present"),
                    AttendanceRecord("2026-11-02", "present")
                ),
                fees = FeeStatement(
                    totalDue = 260000.0,
                    totalDiscounts = 10000.0,
                    totalPaid = 250000.0,
                    payments = listOf(
                        PaymentRecord(150000.0, "cash", "DEMO-REC-003", "2026-09-15 08:45:00"),
                        PaymentRecord(100000.0, "cash", "DEMO-REC-004", "2026-10-15 08:45:00")
                    )
                )
            ),
            LinkedChild(
                id = "demo-child-004",
                studentNumber = "DEMO-0004",
                fullName = "يوسف أحمد محمد",
                status = "active",
                relation = "ابن",
                gradeName = "الصف الأول الثانوي",
                sectionName = "علمي — شعبة (أ)",
                schedule = scheduleFor("secondary"),
                grades = listOf(
                    PublishedGrade("الفيزياء", "اختبار شهري", "الفصل الأول", 82.0),
                    PublishedGrade("الكيمياء", "اختبار شهري", "الفصل الأول", 89.0),
                    PublishedGrade("الرياضيات", "أعمال السنة", "الفصل الأول", 93.0)
                ),
                attendance = listOf(
                    AttendanceRecord("2026-11-04", "present"),
                    AttendanceRecord("2026-11-03", "absent", "غياب تجريبي"),
                    AttendanceRecord("2026-11-02", "present")
                ),
                fees = FeeStatement(
                    totalDue = 320000.0,
                    totalDiscounts = 20000.0,
                    totalPaid = 200000.0,
                    payments = listOf(
                        PaymentRecord(200000.0, "bank_transfer", "DEMO-REC-005", "2026-10-10 12:00:00")
                    )
                )
            )
        ),
        announcements = listOf(
            AnnouncementItem(
                id = "demo-ann-001",
                title = "تنبيه تجريبي لأولياء الأمور",
                body = "هذه رسالة تجريبية لعرض طريقة ظهور إعلانات المؤسسة. لا تمثل إعلاناً مدرسياً حقيقياً.",
                priority = "high",
                publishedAt = "2026-11-04"
            ),
            AnnouncementItem(
                id = "demo-ann-002",
                title = "متابعة التقييمات الدورية",
                body = "يمكن لولي الأمر مراجعة التقييمات المنشورة لكل ابن من صفحة النتائج.",
                priority = "normal",
                publishedAt = "2026-11-02"
            )
        ),
        events = listOf(
            CalendarEventItem(
                id = "demo-event-001",
                title = "موعد تجريبي لاجتماع أولياء الأمور",
                description = "حدث توضيحي لاختبار عرض التقويم.",
                eventType = "general",
                startsOn = "2026-11-12",
                endsOn = "2026-11-12"
            )
        )
    )

    private fun singlePayload() = DashboardPayload(
        guardian = GuardianInfo(
            id = "demo-guardian-single",
            accountCode = SINGLE_ACCOUNT,
            fullName = "محمود عبد الرحمن حسن",
            phone = "+249900000002",
            status = "active"
        ),
        children = listOf(
            LinkedChild(
                id = "demo-child-single",
                studentNumber = "DEMO-0101",
                fullName = "آمنة محمود عبد الرحمن",
                status = "active",
                relation = "ابنة",
                gradeName = "الصف الثالث الثانوي",
                sectionName = "أدبي — شعبة (ب)",
                schedule = scheduleFor("secondary"),
                grades = listOf(
                    PublishedGrade("اللغة العربية", "اختبار شهري", "الفصل الأول", 95.0),
                    PublishedGrade("التاريخ", "اختبار شهري", "الفصل الأول", 90.0),
                    PublishedGrade("الجغرافيا", "أعمال السنة", "الفصل الأول", 88.0)
                ),
                attendance = listOf(
                    AttendanceRecord("2026-11-04", "present"),
                    AttendanceRecord("2026-11-03", "present"),
                    AttendanceRecord("2026-11-02", "present")
                ),
                fees = FeeStatement(
                    totalDue = 300000.0,
                    totalDiscounts = 0.0,
                    totalPaid = 300000.0,
                    payments = listOf(
                        PaymentRecord(150000.0, "cash", "DEMO-REC-101", "2026-09-10 09:00:00"),
                        PaymentRecord(150000.0, "cash", "DEMO-REC-102", "2026-10-10 09:00:00")
                    )
                )
            )
        ),
        announcements = familyPayload().announcements,
        events = familyPayload().events
    )
}
