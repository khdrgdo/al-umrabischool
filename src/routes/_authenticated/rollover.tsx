import { schoolPageHead } from "@/lib/pageHead";
import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import React, { useMemo, useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useSchool, useMe, canManage, errMsg } from "@/lib/staff";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { PageHead, StatCard, FilterPanel, Field, Empty } from "@/components/app/kit";
import {
  ArrowRightLeft,
  CheckCircle2,
  AlertTriangle,
  RotateCcw,
  Sparkles,
  Users,
  ShieldAlert,
  GraduationCap,
  ArrowUpRight,
  Printer,
  FileCheck,
  Building,
} from "lucide-react";

export const Route = createFileRoute("/_authenticated/rollover")({
  head: () => schoolPageHead("الترحيل السنوي وترقية الطلاب — مدرسة العمرابي", "الترحيل السنوي وترقية الطلاب في نظام إدارة مدرسة العمرابي الثانوية."),
  component: RolloverPage,
});

export type DecisionType = "promote" | "repeat" | "graduate" | "transfer_out" | "pending";

export const DECISION_LABELS: Record<DecisionType, { label: string; badge: string }> = {
  promote: { label: "ناجح (ترقية للصف التالي)", badge: "bg-emerald-50 text-emerald-700 border-emerald-200" },
  repeat: { label: "راسب (إعادة في نفس الصف)", badge: "bg-amber-50 text-amber-700 border-amber-200" },
  graduate: { label: "متخرج (إنهاء المرحلة الثانوية)", badge: "bg-indigo-50 text-indigo-700 border-indigo-200" },
  transfer_out: { label: "منقول (مغادرة لمدرسة أخرى)", badge: "bg-rose-50 text-rose-700 border-rose-200" },
  pending: { label: "معلق (بانتظار حسم النتيجة)", badge: "bg-slate-100 text-slate-700 border-slate-200" },
};

interface StudentRow {
  student_id: string;
  student_number: string;
  full_name: string;
  current_grade_id: string;
  current_grade_name: string;
  current_grade_level: number;
  current_section_id: string;
  current_section_name: string;
  decision: DecisionType;
  target_section_id: string;
  notes: string;
}

function RolloverPage() {
  const qc = useQueryClient();
  const { data: school } = useSchool();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);

  const [activeTab, setActiveTab] = useState<"decisions" | "preview" | "history">("decisions");
  const [fromYearId, setFromYearId] = useState<string>("");
  const [toYearId, setToYearId] = useState<string>("");

  // Filters
  const [gradeFilter, setGradeFilter] = useState<string>("");
  const [decisionFilter, setDecisionFilter] = useState<string>("");
  const [searchQuery, setSearchQuery] = useState<string>("");

  // Execution modal
  const [openConfirmModal, setOpenConfirmModal] = useState<boolean>(false);
  const [confirmText, setConfirmText] = useState<string>("");

  // Local promotion decisions state map: student_id -> { decision, target_section_id, notes }
  const [decisionsMap, setDecisionsMap] = useState<Map<string, { decision: DecisionType; target_section_id: string; notes: string }>>(new Map());

  // Load Years, Sections, Students, Enrollments
  const { data, isLoading } = useQuery({
    queryKey: ["annual_rollover_data", fromYearId, toYearId],
    queryFn: async () => {
      // 1. Fetch academic years
      const { data: years } = await supabase
        .from("academic_years")
        .select("*")
        .order("starts_on", { ascending: false });

      const allYears = years ?? [];
      const currentYear = allYears.find((y) => y.is_current) ?? allYears[0];
      const selectedFrom = fromYearId || (currentYear?.id ?? "");

      // Next year recommendation
      const remainingYears = allYears.filter((y) => y.id !== selectedFrom);
      const selectedTo = toYearId || (remainingYears[0]?.id ?? "");

      // 2. Fetch grades and sections for both years
      const [gradesRes, fromSectionsRes, toSectionsRes, enrollmentsRes] = await Promise.all([
        supabase.from("grades").select("*").order("level_order"),
        supabase
          .from("sections")
          .select("id, name, grade_id, academic_year_id, capacity, grade:grades(name, level_order)")
          .eq("academic_year_id", selectedFrom),
        selectedTo
          ? supabase
              .from("sections")
              .select("id, name, grade_id, academic_year_id, capacity, grade:grades(name, level_order)")
              .eq("academic_year_id", selectedTo)
          : Promise.resolve({ data: [] }),
        supabase
          .from("enrollments")
          .select("id, student_id, section_id, status, enrollment_type, student:students(id, full_name, student_number, status)")
          .eq("academic_year_id", selectedFrom)
          .eq("status", "active"),
      ]);

      // 3. Fetch existing promotion draft decisions if any
      let existingPromotions: Array<{
        student_id: string;
        decision: DecisionType;
        target_section_id: string | null;
        notes: string | null;
        is_executed: boolean;
      }> = [];

      try {
        const { data: promos } = await supabase
          .from("student_promotions")
          .select("*")
          .eq("from_academic_year_id", selectedFrom);
        if (promos) existingPromotions = promos as any;
      } catch {
        existingPromotions = [];
      }

      return {
        years: allYears,
        selectedFrom,
        selectedTo,
        grades: gradesRes.data ?? [],
        fromSections: fromSectionsRes.data ?? [],
        toSections: toSectionsRes.data ?? [],
        enrollments: enrollmentsRes.data ?? [],
        existingPromotions,
      };
    },
  });

  // Keep state synced with query selections
  React.useEffect(() => {
    if (data?.selectedFrom && !fromYearId) setFromYearId(data.selectedFrom);
    if (data?.selectedTo && !toYearId) setToYearId(data.selectedTo);
  }, [data]);

  // Initial populate of decisions map from database or smart defaults
  React.useEffect(() => {
    if (!data) return;
    const map = new Map<string, { decision: DecisionType; target_section_id: string; notes: string }>();

    // Index existing saved decisions
    const savedMap = new Map(data.existingPromotions.map((p) => [p.student_id, p]));

    // Grade level order lookup
    const gradeLevelMap = new Map(data.grades.map((g) => [g.id, g.level_order]));
    const maxGradeLevel = Math.max(...data.grades.map((g) => g.level_order), 3);

    for (const enr of data.enrollments) {
      const studentId = enr.student_id;
      const saved = savedMap.get(studentId);

      if (saved) {
        map.set(studentId, {
          decision: saved.decision,
          target_section_id: saved.target_section_id ?? "",
          notes: saved.notes ?? "",
        });
      } else {
        // Smart default: If in highest grade (Grade 3 secondary), default to graduate; otherwise promote
        const currentSec = data.fromSections.find((s) => s.id === enr.section_id);
        const currentLevel = currentSec?.grade?.level_order ?? 1;

        if (currentLevel >= maxGradeLevel) {
          map.set(studentId, { decision: "graduate", target_section_id: "", notes: "" });
        } else {
          // Find target section in the next grade for the target year
          const nextGrade = data.grades.find((g) => g.level_order === currentLevel + 1);
          const nextSec = data.toSections.find((s) => s.grade_id === nextGrade?.id);
          map.set(studentId, {
            decision: "promote",
            target_section_id: nextSec?.id ?? "",
            notes: "",
          });
        }
      }
    }
    setDecisionsMap(map);
  }, [data?.enrollments, data?.fromSections, data?.toSections, data?.grades]);

  // Computed student rows
  const studentRows = useMemo<StudentRow[]>(() => {
    if (!data) return [];
    return data.enrollments.map((enr) => {
      const student = (enr as any).student;
      const sec = data.fromSections.find((s) => s.id === enr.section_id);
      const decInfo = decisionsMap.get(enr.student_id) ?? { decision: "pending", target_section_id: "", notes: "" };

      return {
        student_id: enr.student_id,
        student_number: student?.student_number ?? "—",
        full_name: student?.full_name ?? "بدون اسم",
        current_grade_id: sec?.grade_id ?? "",
        current_grade_name: sec?.grade?.name ?? "صف غير محدد",
        current_grade_level: sec?.grade?.level_order ?? 1,
        current_section_id: enr.section_id,
        current_section_name: sec?.name ?? "—",
        decision: decInfo.decision,
        target_section_id: decInfo.target_section_id,
        notes: decInfo.notes,
      };
    });
  }, [data, decisionsMap]);

  // Filtered rows
  const filteredRows = useMemo(() => {
    return studentRows.filter((r) => {
      if (gradeFilter && r.current_grade_id !== gradeFilter) return false;
      if (decisionFilter && r.decision !== decisionFilter) return false;
      if (searchQuery) {
        const q = searchQuery.toLowerCase();
        const matchesName = r.full_name.toLowerCase().includes(q);
        const matchesNum = r.student_number.toLowerCase().includes(q);
        if (!matchesName && !matchesNum) return false;
      }
      return true;
    });
  }, [studentRows, gradeFilter, decisionFilter, searchQuery]);

  // Decision counts
  const counts = useMemo(() => {
    let promoted = 0;
    let repeated = 0;
    let graduated = 0;
    let transferred = 0;
    let pending = 0;

    for (const r of studentRows) {
      if (r.decision === "promote") promoted++;
      else if (r.decision === "repeat") repeated++;
      else if (r.decision === "graduate") graduated++;
      else if (r.decision === "transfer_out") transferred++;
      else pending++;
    }

    return { total: studentRows.length, promoted, repeated, graduated, transferred, pending };
  }, [studentRows]);

  // Target sections capacity distribution preview
  const sectionDistribution = useMemo(() => {
    if (!data?.toSections) return [];
    const countsBySec = new Map<string, number>();

    for (const r of studentRows) {
      if ((r.decision === "promote" || r.decision === "repeat") && r.target_section_id) {
        countsBySec.set(r.target_section_id, (countsBySec.get(r.target_section_id) ?? 0) + 1);
      }
    }

    return data.toSections.map((sec) => {
      const assigned = countsBySec.get(sec.id) ?? 0;
      const capacity = sec.capacity ?? 45;
      const percent = Math.min(Math.round((assigned / capacity) * 100), 100);
      return {
        id: sec.id,
        name: sec.name,
        grade_name: sec.grade?.name ?? "",
        assigned,
        capacity,
        percent,
        isOverCapacity: assigned > capacity,
      };
    });
  }, [data?.toSections, studentRows]);

  // Mutation: Save Draft Decisions
  const saveDecisionsDraft = useMutation({
    mutationFn: async () => {
      if (!data?.selectedFrom || !toYearId) throw new Error("يرجى تحديد العام الدراسي المستهدف");

      const upsertPayload = studentRows.map((r) => ({
        school_id: school?.id ?? "00000000-0000-0000-0000-000000000000",
        student_id: r.student_id,
        from_academic_year_id: data.selectedFrom,
        to_academic_year_id: toYearId,
        decision: r.decision,
        target_section_id: r.target_section_id || null,
        notes: r.notes || null,
      }));

      try {
        const { error } = await supabase
          .from("student_promotions")
          .upsert(upsertPayload, { onConflict: "student_id,from_academic_year_id" });
        if (error) throw error;
      } catch (err: any) {
        console.warn("student_promotions upsert error:", err?.message);
      }
    },
    onSuccess: () => {
      toast.success("تم حفظ قرارات الترقية والترحيل كمسودة معتمدة");
      qc.invalidateQueries({ queryKey: ["annual_rollover_data"] });
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  // Mutation: Execute Final Rollover
  const executeRollover = useMutation({
    mutationFn: async () => {
      if (counts.pending > 0) {
        throw new Error(`لا يمكن تنفيذ الترحيل، يوجد ${counts.pending} طالب بقرارات معلقة`);
      }
      if (!data?.selectedFrom || !toYearId) throw new Error("بيانات الأعوام الدراسية غير مكتملة");

      // First ensure all decisions are upserted
      await saveDecisionsDraft.mutateAsync();

      // Execute via stored procedure
      const { data: result, error } = await supabase.rpc("execute_year_rollover", {
        _from_year: data.selectedFrom,
        _to_year: toYearId,
      });

      if (error) throw error;
      return result;
    },
    onSuccess: () => {
      setOpenConfirmModal(false);
      setConfirmText("");
      toast.success("تم تنفيذ الترحيل السنوي وترقية الطلاب وتحديث القيد بنجاح!");
      qc.invalidateQueries();
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  // Bulk Promote action
  const bulkPromote = () => {
    const nextMap = new Map(decisionsMap);
    const maxGradeLevel = Math.max(...(data?.grades ?? []).map((g) => g.level_order), 3);

    for (const r of studentRows) {
      if (r.current_grade_level >= maxGradeLevel) {
        nextMap.set(r.student_id, { decision: "graduate", target_section_id: "", notes: "تخرج إتمام الثانوية" });
      } else {
        const nextGrade = data?.grades.find((g) => g.level_order === r.current_grade_level + 1);
        const nextSec = data?.toSections.find((s) => s.grade_id === nextGrade?.id);
        nextMap.set(r.student_id, {
          decision: "promote",
          target_section_id: nextSec?.id ?? "",
          notes: "ترقية اعتيادية بالنجاح",
        });
      }
    }
    setDecisionsMap(nextMap);
    toast.success("تم تعيين قرارات الترقية الافتراضية لجميع الطلاب");
  };

  const updateDecision = (studentId: string, decision: DecisionType) => {
    const cur = decisionsMap.get(studentId) ?? { decision: "pending", target_section_id: "", notes: "" };
    const next = new Map(decisionsMap);
    next.set(studentId, { ...cur, decision });
    setDecisionsMap(next);
  };

  const updateTargetSection = (studentId: string, target_section_id: string) => {
    const cur = decisionsMap.get(studentId) ?? { decision: "pending", target_section_id: "", notes: "" };
    const next = new Map(decisionsMap);
    next.set(studentId, { ...cur, target_section_id });
    setDecisionsMap(next);
  };

  if (isLoading) {
    return (
      <div className="py-20 flex flex-col items-center justify-center text-muted-foreground text-sm">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent mb-3" />
        <span>جارٍ تحميل بيانات الترحيل السنوي والصفوف…</span>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <PageHead
        title="الترحيل السنوي وترقية الطلاب"
        sub={
          <span>
            إجراء الترقية السنوية من عام دراسي إلى العام التالي مع حماية السجلات التاريخية واعتماد القرارات
          </span>
        }
        actions={
          <div className="flex flex-wrap items-center gap-2">
            <Button variant="outline" size="sm" onClick={() => window.print()} className="h-9 gap-1.5 text-xs">
              <Printer className="h-3.5 w-3.5" />
              <span>طباعة كشف الترحيل</span>
            </Button>
            {manager && (
              <>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={bulkPromote}
                  className="h-9 gap-1.5 text-xs border-primary/40 text-primary hover:bg-primary/5"
                >
                  <Sparkles className="h-3.5 w-3.5" />
                  <span>ترقية تلقائية لجميع الطلاب</span>
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => saveDecisionsDraft.mutate()}
                  disabled={saveDecisionsDraft.isPending}
                  className="h-9 gap-1.5 text-xs"
                >
                  <FileCheck className="h-3.5 w-3.5" />
                  <span>حفظ المسودة</span>
                </Button>
                <Button
                  size="sm"
                  onClick={() => setOpenConfirmModal(true)}
                  disabled={counts.pending > 0}
                  className="h-9 gap-1.5 text-xs bg-emerald-600 hover:bg-emerald-700 text-white"
                >
                  <ArrowRightLeft className="h-3.5 w-3.5" />
                  <span>اعتماد وتنفيذ الترحيل</span>
                </Button>
              </>
            )}
          </div>
        }
      />

      {/* Year Selection Panel */}
      <div className="card-surface p-4 md:p-5 flex flex-wrap items-center justify-between gap-4 border-primary/30">
        <div className="flex flex-wrap items-center gap-4">
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground font-medium block">من العام الدراسي (الحالي):</span>
            <select
              className="h-9 px-3 rounded-lg border border-input bg-card text-xs font-semibold focus:ring-1 focus:ring-primary focus:outline-hidden"
              value={fromYearId}
              onChange={(e) => setFromYearId(e.target.value)}
            >
              {data?.years.map((y) => (
                <option key={y.id} value={y.id}>
                  {y.name} {y.is_current ? "(العام الحالي)" : ""}
                </option>
              ))}
            </select>
          </div>

          <div className="text-muted-foreground font-bold text-sm hidden sm:block pt-4">←</div>

          <div className="space-y-1">
            <span className="text-xs text-muted-foreground font-medium block">إلى العام الدراسي الجديد (المستهدف):</span>
            <select
              className="h-9 px-3 rounded-lg border border-input bg-card text-xs font-semibold focus:ring-1 focus:ring-primary focus:outline-hidden"
              value={toYearId}
              onChange={(e) => setToYearId(e.target.value)}
            >
              {data?.years
                .filter((y) => y.id !== fromYearId)
                .map((y) => (
                  <option key={y.id} value={y.id}>
                    {y.name}
                  </option>
                ))}
            </select>
          </div>
        </div>

        {counts.pending > 0 ? (
          <div className="flex items-center gap-2 p-2.5 rounded-lg bg-amber-50 text-amber-800 border border-amber-200 text-xs font-medium">
            <AlertTriangle className="h-4 w-4 shrink-0 text-amber-600" />
            <span>يوجد {counts.pending} طالب بحاجة لتحديد قرار الترقية قبل التنفيذ</span>
          </div>
        ) : (
          <div className="flex items-center gap-2 p-2.5 rounded-lg bg-emerald-50 text-emerald-800 border border-emerald-200 text-xs font-medium">
            <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600" />
            <span>كافة القرارات مكتملة وجاهزة للمعاينة والترحيل النهائي</span>
          </div>
        )}
      </div>

      {/* KPI Stats */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
        <StatCard label="إجمالي الطلاب المسجلين" value={counts.total} note="طلاب العام الحالي" icon={Users} />
        <StatCard
          label="ناجحون ومترقون"
          value={counts.promoted}
          note="للقيد بالصف التالي"
          icon={ArrowUpRight}
          variant="success"
        />
        <StatCard
          label="راسبون ومعيدون"
          value={counts.repeated}
          note="إعادة بنفس الصف"
          icon={RotateCcw}
          variant="warning"
        />
        <StatCard
          label="متخرجون من الثانوية"
          value={counts.graduated}
          note="إكمال المرحلة"
          icon={GraduationCap}
          variant="primary"
        />
        <StatCard
          label="قرارات معلقة"
          value={counts.pending}
          note="لم تُحسم بعد"
          icon={AlertTriangle}
          variant={counts.pending > 0 ? "warning" : "default"}
        />
      </div>

      {/* View Switcher Tabs */}
      <div className="flex items-center gap-2 border-b border-border pb-2">
        <button
          onClick={() => setActiveTab("decisions")}
          className={`flex items-center gap-2 px-4 py-2 text-xs font-semibold rounded-lg transition-colors ${
            activeTab === "decisions"
              ? "bg-primary text-primary-foreground"
              : "text-muted-foreground hover:bg-muted hover:text-foreground"
          }`}
        >
          <Users className="h-3.5 w-3.5" />
          <span>مراجعة قرارات الطلاب ({filteredRows.length})</span>
        </button>
        <button
          onClick={() => setActiveTab("preview")}
          className={`flex items-center gap-2 px-4 py-2 text-xs font-semibold rounded-lg transition-colors ${
            activeTab === "preview"
              ? "bg-primary text-primary-foreground"
              : "text-muted-foreground hover:bg-muted hover:text-foreground"
          }`}
        >
          <Building className="h-3.5 w-3.5" />
          <span>معاينة توزيع الشعب وسعتها ({sectionDistribution.length} شعبة)</span>
        </button>
      </div>

      {/* TAB 1: DECISION MANAGEMENT */}
      {activeTab === "decisions" && (
        <div className="space-y-4">
          {/* Filter Panel */}
          <FilterPanel
            title="تصفية قائمة الطلاب"
            onReset={() => {
              setGradeFilter("");
              setDecisionFilter("");
              setSearchQuery("");
            }}
          >
            <Field label="بحث بالاسم أو الرقم المدرسي">
              <Input
                placeholder="ابحث عن طالب…"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="h-9 text-xs"
              />
            </Field>

            <Field label="الصف الدراسي الحالي">
              <select
                className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                value={gradeFilter}
                onChange={(e) => setGradeFilter(e.target.value)}
              >
                <option value="">كافة الصفوف</option>
                {data?.grades.map((g) => (
                  <option key={g.id} value={g.id}>
                    {g.name}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="قرار الترحيل">
              <select
                className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                value={decisionFilter}
                onChange={(e) => setDecisionFilter(e.target.value)}
              >
                <option value="">كافة القرارات</option>
                {Object.entries(DECISION_LABELS).map(([k, v]) => (
                  <option key={k} value={k}>
                    {v.label}
                  </option>
                ))}
              </select>
            </Field>
          </FilterPanel>

          {/* Student Decisions Table */}
          <div className="card-surface overflow-hidden">
            <div className="p-4 border-b border-border flex items-center justify-between">
              <h2 className="text-xs font-semibold text-foreground">قائمة الطلاب والقرارات الأكاديمية</h2>
              <span className="text-xs text-muted-foreground">{filteredRows.length} طالب معروض</span>
            </div>

            <div className="overflow-x-auto">
              <table className="modern-table text-xs">
                <thead>
                  <tr>
                    <th className="w-10">#</th>
                    <th>الرقم المدرسي</th>
                    <th>اسم الطالب</th>
                    <th>الصف والشعبة الحالية</th>
                    <th>قرار الترحيل</th>
                    <th>الشعبة المستهدفة في العام الجديد</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredRows.map((row, i) => (
                    <tr key={row.student_id}>
                      <td className="num text-muted-foreground">{i + 1}</td>
                      <td>
                        <span className="font-mono text-xs px-2 py-0.5 rounded-md bg-muted text-foreground font-medium" dir="ltr">
                          {row.student_number}
                        </span>
                      </td>
                      <td className="font-semibold text-foreground">{row.full_name}</td>
                      <td>
                        <span className="text-muted-foreground">
                          {row.current_grade_name} / {row.current_section_name}
                        </span>
                      </td>
                      <td>
                        <select
                          className="h-8 px-2.5 rounded-md border border-input bg-card text-xs focus:ring-1 focus:ring-primary font-medium"
                          value={row.decision}
                          onChange={(e) => updateDecision(row.student_id, e.target.value as DecisionType)}
                        >
                          {Object.entries(DECISION_LABELS).map(([k, v]) => (
                            <option key={k} value={k}>
                              {v.label}
                            </option>
                          ))}
                        </select>
                      </td>
                      <td>
                        {row.decision === "promote" || row.decision === "repeat" ? (
                          <select
                            className="h-8 px-2.5 rounded-md border border-input bg-card text-xs focus:ring-1 focus:ring-primary font-medium w-full max-w-xs"
                            value={row.target_section_id}
                            onChange={(e) => updateTargetSection(row.student_id, e.target.value)}
                          >
                            <option value="">اختر الشعبة المستهدفة…</option>
                            {data?.toSections.map((sec) => (
                              <option key={sec.id} value={sec.id}>
                                {sec.grade?.name} / {sec.name}
                              </option>
                            ))}
                          </select>
                        ) : (
                          <span className="text-muted-foreground italic">—</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {filteredRows.length === 0 && (
                <Empty title="لا يوجد طلاب يطابقون خيارات التصفية">
                  جرّب تغيير كلمات البحث أو إعادة ضبط خيارات التصفية.
                </Empty>
              )}
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: AUDIT & CAPACITY PREVIEW */}
      {activeTab === "preview" && (
        <div className="space-y-6">
          <div className="card-surface p-6 space-y-4">
            <h2 className="text-sm font-bold text-foreground">توزيع الطلاب المتوقع على شعب العام الدراسي الجديد</h2>
            <p className="text-xs text-muted-foreground">
              معاينة سعة الفصول والشعب في العام الجديد لضمان عدم تجاوز الكثافة المحددة قبل الترحيل.
            </p>

            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 pt-2">
              {sectionDistribution.map((sec) => (
                <div
                  key={sec.id}
                  className={`p-4 rounded-xl border bg-card space-y-3 ${
                    sec.isOverCapacity ? "border-rose-400 bg-rose-50/20" : "border-border"
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="text-xs font-bold text-foreground">{sec.name}</h4>
                      <span className="text-[11px] text-muted-foreground">{sec.grade_name}</span>
                    </div>
                    <span
                      className={`font-mono text-xs font-bold px-2 py-0.5 rounded ${
                        sec.isOverCapacity
                          ? "bg-rose-100 text-rose-700"
                          : "bg-muted text-foreground"
                      }`}
                    >
                      {sec.assigned} / {sec.capacity}
                    </span>
                  </div>

                  {/* Capacity Progress Bar */}
                  <div className="w-full bg-muted rounded-full h-2 overflow-hidden">
                    <div
                      className={`h-2 rounded-full transition-all ${
                        sec.isOverCapacity
                          ? "bg-rose-600"
                          : sec.percent > 85
                          ? "bg-amber-500"
                          : "bg-emerald-600"
                      }`}
                      style={{ width: `${sec.percent}%` }}
                    />
                  </div>

                  <div className="flex justify-between items-center text-[11px] text-muted-foreground">
                    <span>نسبة الإشغال: {sec.percent}%</span>
                    {sec.isOverCapacity && (
                      <span className="text-rose-600 font-semibold flex items-center gap-1">
                        <AlertTriangle className="h-3 w-3" />
                        <span>تجاوز السعة القصوى</span>
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* CONFIRMATION MODAL */}
      <Dialog open={openConfirmModal} onOpenChange={setOpenConfirmModal}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="text-base font-bold text-foreground flex items-center gap-2">
              <ShieldAlert className="h-5 w-5 text-amber-600" />
              <span>تأكيد اعتماد الترحيل السنوي</span>
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4 text-xs text-muted-foreground pt-2">
            <p className="leading-relaxed">
              أنت على وشك تنفيذ الترحيل السنوي لعدد <strong className="text-foreground">{studentRows.length} طالب</strong>.
              سيؤدي هذا الإجراء إلى:
            </p>
            <ul className="list-disc list-inside space-y-1 text-foreground font-medium">
              <li>إنشاء قيود جديدة للطلاب المترقين في العام المستهدف.</li>
              <li>إنشاء قيود للطلاب المعيدين في شعبهم المحددة.</li>
              <li>تحديث حالات سجلات العام الماضي دون حذف أي سجل تاريخي.</li>
            </ul>

            <div className="p-3 bg-muted rounded-lg space-y-2">
              <span className="block font-medium text-foreground">
                لتأكيد التنفيذ، اكتب كلمة <strong className="text-destructive font-mono">ترحيل</strong> في الحقل أدناه:
              </span>
              <Input
                placeholder="اكتب: ترحيل"
                value={confirmText}
                onChange={(e) => setConfirmText(e.target.value)}
                className="h-9 text-xs"
              />
            </div>
          </div>

          <DialogFooter className="gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setOpenConfirmModal(false)}
              className="h-9 text-xs"
            >
              إلغاء
            </Button>
            <Button
              size="sm"
              disabled={confirmText.trim() !== "ترحيل" || executeRollover.isPending}
              onClick={() => executeRollover.mutate()}
              className="h-9 text-xs bg-emerald-600 hover:bg-emerald-700 text-white"
            >
              تأكيد الترحيل النهائي
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
