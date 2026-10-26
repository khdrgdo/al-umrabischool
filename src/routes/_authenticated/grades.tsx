import { schoolPageHead } from "@/lib/pageHead";
import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useMe, canManage, errMsg } from "@/lib/staff";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { PageHead, StatCard, FilterPanel, Field, Empty } from "@/components/app/kit";
import {
  GraduationCap,
  Award,
  CheckCircle2,
  AlertTriangle,
  Save,
  Printer,
  FileSpreadsheet,
  Send,
  Lock,
  Layers,
  BookOpen,
} from "lucide-react";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/_authenticated/grades")({
  ssr: false,
  head: () => schoolPageHead("الدرجات والتقييمات — مدرسة العمرابي", "الدرجات والتقييمات في نظام إدارة مدرسة العمرابي الثانوية."),
  component: GradesPage,
});

type TermType = "term_1" | "term_2" | "midterm" | "final";

const TERM_LABELS: Record<TermType, string> = {
  term_1: "الفصل الدراسي الأول",
  term_2: "الفصل الدراسي الثاني",
  midterm: "اختبارات منتصف العام",
  final: "الامتحانات النهائية",
};

interface GradeEntry {
  studentId: string;
  studentNumber: string;
  fullName: string;
  score: number | null;
  isAbsent: boolean;
  absenceReason: string;
  notes: string;
}

async function safeFetch<T>(promise: PromiseLike<{ data: T | null; error: any }>): Promise<T | null> {
  const res = await promise;
  if (res.error) {
    if (res.error.code === "42P01" || res.error.message?.includes("does not exist")) {
      return null;
    }
    throw res.error;
  }
  return res.data;
}

function GradesPage() {
  const qc = useQueryClient();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);

  // Selection Filters
  const [selectedGrade, setSelectedGrade] = useState("");
  const [selectedSection, setSelectedSection] = useState("");
  const [selectedSubject, setSelectedSubject] = useState("");
  const [selectedTerm, setSelectedTerm] = useState<TermType>("term_1");
  const [assessmentTitle, setAssessmentTitle] = useState("الاختبار التحريري الأول");
  const [maxScore, setMaxScore] = useState<number>(100);
  const [passScore, setPassScore] = useState<number>(50);

  // In-memory score edits: studentId -> GradeEntry
  const [entries, setEntries] = useState<Record<string, GradeEntry>>({});
  const [isDirty, setIsDirty] = useState(false);

  // Fetch structural data: Current Year, Sections, Subjects
  const { data: meta, isLoading: metaLoading } = useQuery({
    queryKey: ["grades-meta"],
    queryFn: async () => {
      const { data: year } = await supabase
        .from("academic_years")
        .select("*")
        .eq("is_current", true)
        .maybeSingle();

      const [gradesRes, sectionsRes, subjectsRes] = await Promise.all([
        supabase.from("grades").select("*").order("level_order"),
        year
          ? supabase
              .from("sections")
              .select("id, name, grade_id, grade:grades(name, level_order)")
              .eq("academic_year_id", year.id)
          : Promise.resolve({ data: [] }),
        supabase.from("subjects").select("*").order("name"),
      ]);

      return {
        year,
        grades: gradesRes.data ?? [],
        sections: (sectionsRes.data ?? []) as unknown as Array<{
          id: string;
          name: string;
          grade_id: string;
          grade: { name: string; level_order: number } | null;
        }>,
        subjects: subjectsRes.data ?? [],
      };
    },
  });

  // Automatically select first section and subject when meta loads
  useMemo(() => {
    if (meta?.sections.length && !selectedSection) {
      setSelectedSection(meta.sections[0]?.id ?? "");
      if (meta.sections[0]?.grade_id) {
        setSelectedGrade(meta.sections[0].grade_id);
      }
    }
    if (meta?.subjects.length && !selectedSubject) {
      setSelectedSubject(meta.subjects[0]?.id ?? "");
    }
  }, [meta, selectedSection, selectedSubject]);

  // Fetch Roster & Existing Assessment for the selected Section + Subject + Term
  const { data: assessmentData, isLoading: assessmentLoading } = useQuery({
    queryKey: ["assessment-sheet", meta?.year?.id, selectedSection, selectedSubject, selectedTerm, assessmentTitle],
    enabled: !!meta?.year && !!selectedSection && !!selectedSubject,
    queryFn: async () => {
      if (!meta?.year || !selectedSection || !selectedSubject) return null;

      // 1. Get enrolled students in this section
      const { data: enrollments } = await supabase
        .from("enrollments")
        .select("student_id, student:students(id, student_number, full_name, status)")
        .eq("section_id", selectedSection)
        .eq("academic_year_id", meta.year.id)
        .eq("status", "active");

      const students = (enrollments ?? [])
        .map((e) => e.student)
        .filter(Boolean) as Array<{ id: string; student_number: string; full_name: string; status: string }>;

      // 2. Look for existing assessment
      const existing = await safeFetch(
        supabase
          .from("assessments")
          .select("*")
          .eq("academic_year_id", meta.year.id)
          .eq("section_id", selectedSection)
          .eq("subject_id", selectedSubject)
          .eq("term", selectedTerm)
          .eq("title", assessmentTitle)
          .maybeSingle()
      );

      // 3. If exists, load student_grades
      let gradesMap: Record<string, { score: number | null; is_absent: boolean; absence_reason: string | null; notes: string | null }> = {};
      if (existing?.id) {
        const { data: savedGrades } = await supabase
          .from("student_grades")
          .select("*")
          .eq("assessment_id", existing.id);

        for (const g of savedGrades ?? []) {
          gradesMap[g.student_id] = {
            score: g.score !== null ? Number(g.score) : null,
            is_absent: !!g.is_absent,
            absence_reason: g.absence_reason ?? "",
            notes: g.notes ?? "",
          };
        }
      }

      // Initialize entries state
      const initialMap: Record<string, GradeEntry> = {};
      for (const s of students) {
        const existingGrade = gradesMap[s.id];
        initialMap[s.id] = {
          studentId: s.id,
          studentNumber: s.student_number,
          fullName: s.full_name,
          score: existingGrade?.score ?? null,
          isAbsent: existingGrade?.is_absent ?? false,
          absenceReason: existingGrade?.absence_reason ?? "",
          notes: existingGrade?.notes ?? "",
        };
      }
      setEntries(initialMap);
      setIsDirty(false);

      if (existing) {
        setMaxScore(Number(existing.max_score) || 100);
        setPassScore(Number(existing.pass_score) || 50);
      }

      return {
        assessment: existing,
        students,
      };
    },
  });

  const studentsList = assessmentData?.students ?? [];
  const currentStatus = assessmentData?.assessment?.status ?? "draft";

  // Score Calculations
  const stats = useMemo(() => {
    const list = Object.values(entries);
    const total = list.length;
    const scoredList = list.filter((e) => !e.isAbsent && e.score !== null && e.score !== undefined);
    const absentCount = list.filter((e) => e.isAbsent).length;
    const scoredCount = scoredList.length;

    let passedCount = 0;
    let failedCount = 0;
    let sumScore = 0;

    for (const item of scoredList) {
      const val = item.score ?? 0;
      sumScore += val;
      if (val >= passScore) {
        passedCount++;
      } else {
        failedCount++;
      }
    }

    const passRate = scoredCount > 0 ? Math.round((passedCount / scoredCount) * 100) : 0;
    const avgScore = scoredCount > 0 ? (sumScore / scoredCount).toFixed(1) : "0";

    return {
      total,
      scoredCount,
      absentCount,
      passedCount,
      failedCount,
      passRate,
      avgScore,
    };
  }, [entries, passScore]);

  // Handle Score Input
  const updateScore = (studentId: string, val: string) => {
    if (currentStatus === "published") {
      toast.warning("كشف الدرجات منشور ومعتمد حالياً. يُرجى إلغاء النشر أولاً لتعديل الرصد.");
      return;
    }
    setIsDirty(true);
    setEntries((prev) => {
      const cur = prev[studentId];
      if (!cur) return prev;
      if (val === "") {
        return { ...prev, [studentId]: { ...cur, score: null, isAbsent: false } };
      }
      let num = parseFloat(val);
      if (isNaN(num)) num = 0;
      if (num < 0) num = 0;
      if (num > maxScore) num = maxScore;
      return { ...prev, [studentId]: { ...cur, score: num, isAbsent: false } };
    });
  };

  // Handle Absent Toggle
  const toggleAbsent = (studentId: string) => {
    if (currentStatus === "published") {
      toast.warning("كشف الدرجات منشور ومعتمد حالياً. يُرجى إلغاء النشر أولاً لتعديل الرصد.");
      return;
    }
    setIsDirty(true);
    setEntries((prev) => {
      const cur = prev[studentId];
      if (!cur) return prev;
      const nextAbsent = !cur.isAbsent;
      return {
        ...prev,
        [studentId]: {
          ...cur,
          isAbsent: nextAbsent,
          score: nextAbsent ? null : cur.score,
        },
      };
    });
  };

  // Save Mutation
  const saveMutation = useMutation({
    mutationFn: async (targetStatus?: "draft" | "review" | "approved" | "published") => {
      if (!meta?.year) throw new Error("لا يوجد عام دراسي حالي");
      if (!selectedSection) throw new Error("اختر الشعبة");
      if (!selectedSubject) throw new Error("اختر المادة الدراسية");

      // Rule 10 Enforcement: Do not publish unapproved grades
      if (targetStatus === "published") {
        if (!manager) {
          throw new Error("نشر النتائج مخصص للمدير المشرف فقط");
        }
        if (currentStatus !== "approved" && currentStatus !== "published") {
          throw new Error("لا يمكن نشر درجات غير معتمدة. يجب اعتماد كشف الدرجات أولاً قبل النشر.");
        }
      }
      if (targetStatus === "approved" && !manager) {
        throw new Error("اعتماد كشف الدرجات يتطلب صلاحية الإدارة");
      }

      // 1. Ensure assessment record exists or create it
      let assessmentId = assessmentData?.assessment?.id;

      if (!assessmentId) {
        const { data: newAssessment, error: createErr } = await supabase
          .from("assessments")
          .insert({
            academic_year_id: meta.year.id,
            section_id: selectedSection,
            subject_id: selectedSubject,
            title: assessmentTitle,
            term: selectedTerm,
            max_score: maxScore,
            pass_score: passScore,
            status: targetStatus ?? "draft",
          })
          .select()
          .single();

        if (createErr) throw createErr;
        assessmentId = newAssessment.id;
      } else if (targetStatus) {
        // Update status and limits if modified
        const { error: updateErr } = await supabase
          .from("assessments")
          .update({
            status: targetStatus,
            max_score: maxScore,
            pass_score: passScore,
            updated_at: new Date().toISOString(),
          })
          .eq("id", assessmentId);

        if (updateErr) throw updateErr;
      }

      // 2. Batch upsert student_grades
      if (!assessmentId) throw new Error("تعذر تحديد كشف الدرجات");
      const gradeRows = Object.values(entries).map((item) => ({
        assessment_id: assessmentId,
        student_id: item.studentId,
        score: item.isAbsent ? null : item.score,
        is_absent: item.isAbsent,
        absence_reason: item.isAbsent ? item.absenceReason || "غائب عن الاختبار" : null,
        notes: item.notes || null,
        updated_at: new Date().toISOString(),
      }));

      if (gradeRows.length > 0) {
        const { error: upsertErr } = await supabase
          .from("student_grades")
          .upsert(gradeRows, { onConflict: "assessment_id,student_id" });

        if (upsertErr) throw upsertErr;
      }

      return { status: targetStatus ?? currentStatus };
    },
    onSuccess: (res) => {
      qc.invalidateQueries({ queryKey: ["assessment-sheet"] });
      setIsDirty(false);
      const labelMap = {
        draft: "حُفظت المسودة بنجاح",
        review: "تم إرسال الكشف للمراجعة والتدقيق",
        approved: "تم اعتماد كشف الدرجات رسمياً",
        published: "تم نشر النتائج للطلاب والشهادات",
      };
      toast.success(labelMap[res.status] ?? "تم حفظ الدرجات");
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  // Export CSV
  const exportCsv = () => {
    try {
      const head = ["الرقم المدرسي", "اسم الطالب", "الدرجة المستحقة", "الدرجة العظمى", "النتيجة", "حالة الغياب", "ملاحظات"];
      const lines = studentsList.map((s) => {
        const e = entries[s.id];
        const resLabel = e?.isAbsent ? "غائب" : e?.score !== null && e?.score !== undefined ? (e.score >= passScore ? "ناجح" : "راسب") : "لم ترصد";
        return [
          s.student_number,
          s.full_name,
          e?.isAbsent ? "غائب" : e?.score ?? "—",
          maxScore,
          resLabel,
          e?.isAbsent ? "نعم" : "لا",
          e?.notes ?? "",
        ];
      });

      const csv = "\uFEFF" + [head, ...lines].map((row) => row.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(",")).join("\n");
      const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = `كشف_درجات_${assessmentTitle}.csv`;
      link.click();
      URL.revokeObjectURL(url);
    } catch {
      toast.error("فشل تصدير كشف الدرجات");
    }
  };

  const sectionsForGrade = (meta?.sections ?? []).filter((s) => !selectedGrade || s.grade_id === selectedGrade);
  const currentSectionName = meta?.sections.find((s) => s.id === selectedSection)?.name ?? "الشعبة";
  const currentSubjectName = meta?.subjects.find((s) => s.id === selectedSubject)?.name ?? "المادة";

  if (metaLoading) {
    return (
      <div className="py-24 flex flex-col items-center justify-center text-muted-foreground text-sm">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent mb-3" />
        <span>جارٍ تحميل نظام الدرجات والتقييمات…</span>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHead
        title="الدرجات والتقييمات الأكاديمية"
        sub={
          <span>
            العام الدراسي: <strong className="text-foreground">{meta?.year?.name ?? "—"}</strong>
            {" · "}
            المادة: <strong className="text-foreground">{currentSubjectName}</strong>
            {" · "}
            {TERM_LABELS[selectedTerm]}
          </span>
        }
        actions={
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" onClick={exportCsv} className="h-9 gap-1.5 text-xs">
              <FileSpreadsheet className="h-4 w-4" />
              <span>تصدير الكشف (CSV)</span>
            </Button>
            <Button variant="outline" size="sm" onClick={() => window.print()} className="h-9 gap-1.5 text-xs">
              <Printer className="h-4 w-4" />
              <span>طباعة المسيرة</span>
            </Button>
            {manager && (
              <>
                <Button
                  size="sm"
                  onClick={() => saveMutation.mutate("draft")}
                  disabled={saveMutation.isPending || currentStatus === "published"}
                  className="h-9 gap-1.5 text-xs bg-muted text-foreground hover:bg-muted/80 border border-border"
                >
                  <Save className="h-3.5 w-3.5" />
                  <span>حفظ المسودة</span>
                </Button>
                {currentStatus !== "approved" && currentStatus !== "published" && (
                  <Button
                    size="sm"
                    onClick={() => saveMutation.mutate("approved")}
                    disabled={saveMutation.isPending}
                    className="h-9 gap-1.5 text-xs bg-emerald-700 text-white hover:bg-emerald-800"
                  >
                    <CheckCircle2 className="h-3.5 w-3.5" />
                    <span>اعتماد الكشف</span>
                  </Button>
                )}
                {currentStatus === "approved" && (
                  <Button
                    size="sm"
                    onClick={() => saveMutation.mutate("published")}
                    disabled={saveMutation.isPending}
                    className="h-9 gap-1.5 text-xs bg-primary text-primary-foreground"
                  >
                    <Send className="h-3.5 w-3.5" />
                    <span>نشر النتائج رسمياً</span>
                  </Button>
                )}
                {currentStatus === "published" && (
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => saveMutation.mutate("draft")}
                    disabled={saveMutation.isPending}
                    className="h-9 gap-1.5 text-xs text-amber-700 border-amber-300 hover:bg-amber-50"
                  >
                    <Lock className="h-3.5 w-3.5" />
                    <span>إلغاء النشر وإعادة للمسودة</span>
                  </Button>
                )}
              </>
            )}
          </div>
        }
      />

      {/* KPI Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="إجمالي طلاب الشعبة"
          value={stats.total}
          note="مسجلون نشطون في الكشف"
          icon={<Layers className="h-4 w-4" />}
        />
        <StatCard
          label="الدرجات المرصودة"
          value={`${stats.scoredCount} / ${stats.total}`}
          note={`${stats.absentCount} غائب مسجل`}
          icon={<CheckCircle2 className="h-4 w-4" />}
          variant="primary"
        />
        <StatCard
          label="نسبة النجاح العامة"
          value={`${stats.passRate}%`}
          note={`${stats.passedCount} ناجح · ${stats.failedCount} دون درجة النجاح`}
          icon={<Award className="h-4 w-4" />}
          variant={stats.passRate >= 70 ? "success" : "warning"}
        />
        <StatCard
          label="حالة كشف الدرجات"
          value={
            currentStatus === "published"
              ? "معتمد ومنشور"
              : currentStatus === "approved"
              ? "معتمد"
              : currentStatus === "review"
              ? "قيد المراجعة"
              : "مسودة للمعلم"
          }
          note={`الدرجة العظمى: ${maxScore} · النجاح: ${passScore}`}
          icon={<Lock className="h-4 w-4" />}
        />
      </div>

      {/* Filter & Selector Panel */}
      <FilterPanel title="اختيار المادة والصف الدراسي ونوع الاختبار">
        <Field label="الصف الدراسي">
          <select
            className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
            value={selectedGrade}
            onChange={(e) => {
              setSelectedGrade(e.target.value);
              const matchingSec = meta?.sections.find((s) => s.grade_id === e.target.value);
              if (matchingSec) setSelectedSection(matchingSec.id);
            }}
          >
            <option value="">كافة الصفوف</option>
            {(meta?.grades ?? []).map((g) => (
              <option key={g.id} value={g.id}>
                {g.name}
              </option>
            ))}
          </select>
        </Field>

        <Field label="الشعبة الدراسية *">
          <select
            className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
            value={selectedSection}
            onChange={(e) => setSelectedSection(e.target.value)}
          >
            {sectionsForGrade.map((s) => (
              <option key={s.id} value={s.id}>
                {s.grade?.name ? s.grade.name.replace("الصف ", "") : ""} / {s.name ?? ""}
              </option>
            ))}
          </select>
        </Field>

        <Field label="المادة الدراسية *">
          <select
            className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
            value={selectedSubject}
            onChange={(e) => setSelectedSubject(e.target.value)}
          >
            {meta?.subjects.map((sub) => (
              <option key={sub.id} value={sub.id}>
                {sub.name}
              </option>
            ))}
          </select>
        </Field>

        <Field label="الفصل الدراسي ونوع التقييم">
          <select
            className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
            value={selectedTerm}
            onChange={(e) => setSelectedTerm(e.target.value as TermType)}
          >
            <option value="term_1">الفصل الأول (اختبار أعمال سنة)</option>
            <option value="midterm">امتحان منتصف العام</option>
            <option value="term_2">الفصل الثاني</option>
            <option value="final">الامتحان النهائي (نهاية العام)</option>
          </select>
        </Field>
      </FilterPanel>

      {/* Grade Matrix Table */}
      <div className="card-surface overflow-hidden">
        <div className="p-4 border-b border-border flex flex-wrap items-center justify-between gap-3 bg-muted/20">
          <div className="flex items-center gap-3">
            <GraduationCap className="h-5 w-5 text-primary" />
            <div>
              <h3 className="text-xs font-bold text-foreground">
                كشف درجات: {currentSubjectName} — شعبة {currentSectionName}
              </h3>
              <p className="text-[11px] text-muted-foreground mt-0.5">
                الدرجة العظمى ({maxScore}) · حد النجاح الأدنى ({passScore})
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {isDirty && (
              <span className="text-xs text-amber-600 bg-amber-50 px-2 py-0.5 rounded-full border border-amber-200 animate-pulse">
                توجد تعديلات غير محفوظة
              </span>
            )}
            <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
              <span>العظمى:</span>
              <Input
                type="number"
                min="10"
                max="200"
                value={maxScore}
                onChange={(e) => setMaxScore(Number(e.target.value) || 100)}
                className="w-16 h-7 text-xs font-mono text-center"
              />
            </div>
          </div>
        </div>

        {assessmentLoading ? (
          <div className="py-20 text-center text-muted-foreground text-xs">
            <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent mx-auto mb-2" />
            <span>جارٍ تحميل قوائم الطلاب والدرجات…</span>
          </div>
        ) : studentsList.length === 0 ? (
          <Empty title="لا يوجد طلاب مسجلون في هذه الشعبة">
            تأكد من اختيار شعبة تحتوي على طلاب مقيدين في العام الدراسي الحالي.
          </Empty>
        ) : (
          <div className="overflow-x-auto">
            <table className="modern-table">
              <thead>
                <tr>
                  <th className="w-12">#</th>
                  <th>الرقم المدرسي</th>
                  <th>اسم الطالب</th>
                  <th className="w-36 text-center">الدرجة المستحقة (من {maxScore})</th>
                  <th className="w-24 text-center">غائب؟</th>
                  <th>النتيجة</th>
                  <th>ملاحظات المعلم</th>
                </tr>
              </thead>
              <tbody>
                {studentsList.map((student, idx) => {
                  const entry = entries[student.id] ?? {
                    studentId: student.id,
                    studentNumber: student.student_number,
                    fullName: student.full_name,
                    score: null,
                    isAbsent: false,
                    absenceReason: "",
                    notes: "",
                  };

                  const isPassed = !entry.isAbsent && entry.score !== null && entry.score >= passScore;
                  const isFailed = !entry.isAbsent && entry.score !== null && entry.score < passScore;

                  return (
                    <tr key={student.id} className="hover:bg-muted/40 transition-colors">
                      <td className="num text-muted-foreground text-xs">{idx + 1}</td>
                      <td>
                        <span className="font-mono text-xs px-2 py-0.5 rounded-md bg-muted text-foreground font-medium" dir="ltr">
                          {student.student_number}
                        </span>
                      </td>
                      <td className="font-medium text-foreground text-xs">{student.full_name}</td>
                      <td className="text-center">
                        <Input
                          type="number"
                          min="0"
                          max={maxScore}
                          step="0.5"
                          disabled={entry.isAbsent || currentStatus === "published" && !manager}
                          placeholder={entry.isAbsent ? "غائب" : "—"}
                          value={entry.isAbsent ? "" : entry.score ?? ""}
                          onChange={(e) => updateScore(student.id, e.target.value)}
                          className={cn(
                            "w-24 h-8 text-xs font-mono text-center mx-auto transition-colors",
                            isPassed && "border-emerald-500 bg-emerald-50/40 font-bold text-emerald-800",
                            isFailed && "border-rose-500 bg-rose-50/40 font-bold text-rose-800",
                            entry.isAbsent && "bg-muted text-muted-foreground opacity-60"
                          )}
                        />
                      </td>
                      <td className="text-center">
                        <label className="inline-flex items-center gap-1.5 text-xs cursor-pointer select-none">
                          <input
                            type="checkbox"
                            checked={entry.isAbsent}
                            onChange={() => toggleAbsent(student.id)}
                            className="rounded border-input text-primary focus:ring-primary h-4 w-4"
                          />
                          <span className={entry.isAbsent ? "text-amber-700 font-bold" : "text-muted-foreground"}>
                            غياب
                          </span>
                        </label>
                      </td>
                      <td>
                        {entry.isAbsent ? (
                          <span className="status-pill bg-amber-50 text-amber-700 border-amber-200">غائب عن الامتحان</span>
                        ) : entry.score === null || entry.score === undefined ? (
                          <span className="status-pill bg-slate-100 text-slate-500 border-slate-200">لم تُرصد</span>
                        ) : isPassed ? (
                          <span className="status-pill status-pill-active">ناجح ({entry.score})</span>
                        ) : (
                          <span className="status-pill status-pill-withdrawn">راسب ({entry.score})</span>
                        )}
                      </td>
                      <td>
                        <Input
                          placeholder="ملاحظات المعلم أو عذر الغياب…"
                          value={entry.notes}
                          onChange={(e) => {
                            setIsDirty(true);
                            const val = e.target.value;
                            setEntries((prev) => {
                              const current = prev[student.id];
                              if (!current) return prev;
                              return { ...prev, [student.id]: { ...current, notes: val } };
                            });
                          }}
                          className="h-8 text-xs"
                        />
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* Footer actions bar */}
        <div className="p-4 border-t border-border flex flex-wrap items-center justify-between gap-3 bg-muted/10">
          <div className="text-xs text-muted-foreground">
            إجمالي الطلاب: <strong className="text-foreground">{stats.total}</strong> · المرصود:{" "}
            <strong className="text-emerald-700">{stats.scoredCount}</strong> · الغياب:{" "}
            <strong className="text-amber-700">{stats.absentCount}</strong> · متوسط الشعبة:{" "}
            <strong className="text-foreground">{stats.avgScore}</strong>
          </div>

          <div className="flex items-center gap-2">
            <Button
              size="sm"
              variant="outline"
              onClick={() => saveMutation.mutate("draft")}
              disabled={saveMutation.isPending || !isDirty}
              className="h-9 gap-1.5 text-xs"
            >
              <Save className="h-3.5 w-3.5" />
              <span>حفظ التعديلات كمسودة</span>
            </Button>
            <Button
              size="sm"
              onClick={() => saveMutation.mutate("published")}
              disabled={saveMutation.isPending}
              className="h-9 gap-1.5 text-xs bg-primary text-primary-foreground"
            >
              <CheckCircle2 className="h-3.5 w-3.5" />
              <span>اعتماد كشف الدرجات</span>
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
