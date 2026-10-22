import { schoolPageHead } from "@/lib/pageHead";
import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState, useMemo } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useMe, canManage, errMsg } from "@/lib/staff";
import { PageHead, StatCard, Empty } from "@/components/app/kit";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Users, UserCheck, UserX, Percent, Calendar, CheckCheck, Save } from "lucide-react";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/_authenticated/attendance")({
  head: () => schoolPageHead("سجل الحضور والغياب — مدرسة العمرابي", "سجل الحضور والغياب في نظام إدارة مدرسة العمرابي الثانوية."),
  component: AttendancePage,
});

type EnrolledStudent = {
  id: string;
  student_number: string;
  full_name: string;
  gender: string | null;
  guardian_phone: string | null;
};

function todayIso() {
  const d = new Date();
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function AttendancePage() {
  const qc = useQueryClient();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);

  const [date, setDate] = useState<string>(todayIso());
  const [selectedSection, setSelectedSection] = useState<string>("");

  // Local state for absences: Map of studentId -> reason string
  const [absences, setAbsences] = useState<Map<string, string>>(new Map());
  const [isDirty, setIsDirty] = useState(false);

  // Load sections and active year
  const { data: meta, isLoading: metaLoading } = useQuery({
    queryKey: ["attendance-meta"],
    queryFn: async () => {
      const { data: year } = await supabase.from("academic_years").select("*").eq("is_current", true).maybeSingle();
      if (!year) return { year: null, sections: [] };

      const { data: sections } = await supabase
        .from("sections")
        .select("id, name, capacity, grade:grades(name, level_order)")
        .eq("academic_year_id", year.id);

      const sorted = (sections ?? []).sort(
        (a, b) => ((a.grade as { level_order?: number })?.level_order ?? 0) - ((b.grade as { level_order?: number })?.level_order ?? 0) || a.name.localeCompare(b.name)
      );

      return { year, sections: sorted };
    },
  });

  // Automatically select first section when loaded
  useMemo(() => {
    if (!selectedSection && meta?.sections?.length) {
      setSelectedSection(meta.sections[0].id);
    }
  }, [meta, selectedSection]);

  // Load section roster and attendance session for the selected (section, date)
  const { data: rosterData, isLoading: rosterLoading } = useQuery({
    queryKey: ["attendance-roster", selectedSection, date],
    enabled: !!selectedSection && !!date,
    queryFn: async () => {
      // 1. Fetch active enrollments in this section
      const { data: enrollments, error: enrErr } = await supabase
        .from("enrollments")
        .select("student_id, student:students(id, student_number, full_name, gender, guardian_phone)")
        .eq("section_id", selectedSection)
        .eq("status", "active");

      if (enrErr) throw enrErr;

      const students: EnrolledStudent[] = (enrollments ?? [])
        .map((e) => e.student as EnrolledStudent)
        .filter(Boolean)
        .sort((a, b) => a.full_name.localeCompare(b.full_name));

      // 2. Fetch existing session & records
      const { data: session } = await supabase
        .from("attendance_sessions")
        .select("id")
        .eq("section_id", selectedSection)
        .eq("attendance_date", date)
        .maybeSingle();

      let initialAbsences = new Map<string, string>();

      if (session) {
        const { data: records } = await supabase
          .from("attendance_records")
          .select("student_id, status, reason")
          .eq("session_id", session.id);

        for (const r of records ?? []) {
          if (r.status === "absent") {
            initialAbsences.set(r.student_id, r.reason ?? "");
          }
        }
      }

      setAbsences(initialAbsences);
      setIsDirty(false);

      return { students, sessionExists: !!session };
    },
  });

  // Save Mutation
  const saveMutation = useMutation({
    mutationFn: async () => {
      if (!selectedSection || !date) throw new Error("حدد الشعبة والتاريخ أولاً");

      const absencePayload = Array.from(absences.entries()).map(([student_id, reason]) => ({
        student_id,
        reason: reason.trim() || null,
      }));

      const { data: sessionId, error } = await supabase.rpc("save_daily_attendance", {
        _section: selectedSection,
        _date: date,
        _absences: absencePayload,
      });

      if (error) throw error;
      return sessionId;
    },
    onSuccess: () => {
      setIsDirty(false);
      qc.invalidateQueries({ queryKey: ["attendance-roster", selectedSection, date] });
      toast.success("تم حفظ وتوثيق سجل الحضور اليومي بنجاح");
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  const students = rosterData?.students ?? [];
  const totalCount = students.length;
  const absentCount = absences.size;
  const presentCount = Math.max(0, totalCount - absentCount);
  const attendanceRate = totalCount > 0 ? Math.round((presentCount / totalCount) * 100) : 100;

  function toggleStatus(studentId: string) {
    if (!manager) return;
    const next = new Map(absences);
    if (next.has(studentId)) {
      next.delete(studentId);
    } else {
      next.set(studentId, "");
    }
    setAbsences(next);
    setIsDirty(true);
  }

  function updateReason(studentId: string, reason: string) {
    if (!manager) return;
    const next = new Map(absences);
    next.set(studentId, reason);
    setAbsences(next);
    setIsDirty(true);
  }

  function markAllPresent() {
    if (!manager) return;
    setAbsences(new Map());
    setIsDirty(true);
    toast.info("تم تعيين جميع الطلاب كحاضرين (الوضع الافتراضي)");
  }

  return (
    <div className="space-y-6">
      <PageHead
        title="سجل الحضور والغياب اليومي"
        sub={
          <span>
            العام الدراسي: <strong className="text-foreground">{meta?.year?.name ?? "—"}</strong>
            {" · "}
            وفق قاعدة العمل: <strong className="text-foreground">الافتراضي حاضر ويُسجل الغياب كاستثناء</strong>
          </span>
        }
        actions={
          manager && (
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={markAllPresent}
                disabled={absences.size === 0 || rosterLoading}
                className="h-9 text-xs gap-1.5"
              >
                <CheckCheck className="h-3.5 w-3.5" />
                <span>الكل حاضر</span>
              </Button>
              <Button
                size="sm"
                onClick={() => saveMutation.mutate()}
                disabled={saveMutation.isPending || rosterLoading}
                className="h-9 text-xs gap-1.5 bg-primary text-primary-foreground"
              >
                <Save className="h-3.5 w-3.5" />
                <span>{saveMutation.isPending ? "جارٍ الحفظ…" : "حفظ سجل الحضور"}</span>
              </Button>
            </div>
          )
        }
      />

      {/* KPI Stats Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard
          label="إجمالي طلاب الشعبة"
          value={rosterLoading ? "…" : totalCount}
          note="مسجلون نشطون"
          icon={<Users className="h-4 w-4" />}
        />
        <StatCard
          label="الحاضرون اليوم"
          value={rosterLoading ? "…" : presentCount}
          note="في الفصل الدراسي"
          icon={<UserCheck className="h-4 w-4" />}
          variant="success"
        />
        <StatCard
          label="الغياب المسجل"
          value={rosterLoading ? "…" : absentCount}
          note={absentCount > 0 ? "يتطلب مراجعة العذر" : "لا يوجد غياب"}
          icon={<UserX className="h-4 w-4" />}
          variant={absentCount > 0 ? "warning" : "default"}
        />
        <StatCard
          label="نسبة الحضور"
          value={rosterLoading ? "…" : `${attendanceRate}%`}
          note={attendanceRate >= 90 ? "ممتازة" : "منخفضة"}
          icon={<Percent className="h-4 w-4" />}
          variant={attendanceRate >= 90 ? "primary" : "warning"}
        />
      </div>

      {/* Selector / Filter Box */}
      <div className="card-surface p-4 md:p-5">
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 items-end">
          <div>
            <label className="text-xs font-medium text-muted-foreground block mb-1.5">تاريخ التحضير</label>
            <div className="relative">
              <Input
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                className="h-9 text-xs ps-9"
              />
              <Calendar className="h-4 w-4 text-muted-foreground absolute start-3 top-2.5 pointer-events-none" />
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground block mb-1.5">الشعبة الدراسية</label>
            <select
              className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
              value={selectedSection}
              onChange={(e) => setSelectedSection(e.target.value)}
              disabled={metaLoading}
            >
              <option value="">اختر الشعبة…</option>
              {(meta?.sections ?? []).map((s) => (
                <option key={s.id} value={s.id}>
                  {(s.grade as { name?: string })?.name} / {s.name}
                </option>
              ))}
            </select>
          </div>

          <div className="flex items-center gap-2">
            {isDirty && (
              <span className="text-xs text-amber-600 bg-amber-50 px-2.5 py-1.5 rounded-lg border border-amber-200">
                توجد تعديلات غير محفوظة
              </span>
            )}
            {rosterData?.sessionExists && !isDirty && (
              <span className="text-xs text-emerald-700 bg-emerald-50 px-2.5 py-1.5 rounded-lg border border-emerald-200">
                تم رصد وتحضير هذا اليوم مسبقاً
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Student Roster Table */}
      <div className="card-surface overflow-hidden">
        <div className="p-4 border-b border-border flex items-center justify-between">
          <div className="text-xs font-semibold text-foreground">
            كشف طلاب الشعبة — انقر على حالة الطالب للتبديل بين الحضور والغياب
          </div>
          <span className="text-xs text-muted-foreground">{totalCount} طالب مقيد</span>
        </div>

        <div className="overflow-x-auto">
          <table className="modern-table">
            <thead>
              <tr>
                <th className="w-12">#</th>
                <th>الرقم المدرسي</th>
                <th>اسم الطالب</th>
                <th>الحالة اليومية</th>
                <th>سبب الغياب / الملاحظات</th>
                <th>هاتف ولي الأمر</th>
              </tr>
            </thead>
            <tbody>
              {rosterLoading ? (
                <tr>
                  <td colSpan={6} className="text-center py-12 text-muted-foreground text-xs">
                    <div className="flex flex-col items-center gap-2">
                      <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
                      <span>جارٍ تحميل كشف الحضور للشعبة…</span>
                    </div>
                  </td>
                </tr>
              ) : students.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center py-12">
                    <Empty title="لا يوجد طلاب مسجلين في هذه الشعبة">
                      تأكد من اختيار شعبة تحتوي على تسجيلات طلاب نشطة لهذا العام.
                    </Empty>
                  </td>
                </tr>
              ) : (
                students.map((student, i) => {
                  const isAbsent = absences.has(student.id);
                  const reason = absences.get(student.id) ?? "";

                  return (
                    <tr
                      key={student.id}
                      className={cn(
                        "transition-colors",
                        isAbsent ? "bg-rose-50/40 hover:bg-rose-50/70" : "hover:bg-muted/40"
                      )}
                    >
                      <td className="num text-xs text-muted-foreground">{i + 1}</td>
                      <td>
                        <span className="font-mono text-xs px-2 py-0.5 rounded-md bg-muted text-foreground font-medium" dir="ltr">
                          {student.student_number}
                        </span>
                      </td>
                      <td className="font-medium text-foreground">{student.full_name}</td>
                      <td>
                        <button
                          type="button"
                          onClick={() => toggleStatus(student.id)}
                          disabled={!manager}
                          className={cn(
                            "inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold transition-all cursor-pointer",
                            isAbsent
                              ? "bg-rose-100 text-rose-800 border border-rose-300 shadow-xs"
                              : "bg-emerald-100 text-emerald-800 border border-emerald-300"
                          )}
                        >
                          {isAbsent ? (
                            <>
                              <UserX className="h-3.5 w-3.5 text-rose-600" />
                              <span>غائب</span>
                            </>
                          ) : (
                            <>
                              <UserCheck className="h-3.5 w-3.5 text-emerald-600" />
                              <span>حاضر</span>
                            </>
                          )}
                        </button>
                      </td>
                      <td>
                        {isAbsent ? (
                          <Input
                            placeholder="اذكر سبب الغياب (مرض، إذن مسبق…)"
                            value={reason}
                            disabled={!manager}
                            onChange={(e) => updateReason(student.id, e.target.value)}
                            className="h-8 text-xs max-w-xs bg-white"
                          />
                        ) : (
                          <span className="text-xs text-muted-foreground">—</span>
                        )}
                      </td>
                      <td className="num text-xs text-muted-foreground" dir="ltr">
                        {student.guardian_phone ?? "—"}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
