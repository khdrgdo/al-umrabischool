import { schoolPageHead } from "@/lib/pageHead";
import { createFileRoute, Link } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useMe, canManage, errMsg } from "@/lib/staff";
import { matchesStudentNumber } from "@/lib/studentNumber";
import { formatKhartoumDateDisplay } from "@/lib/schoolDate";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { PageHead, StatCard, FilterPanel, Field, Empty } from "@/components/app/kit";
import {
  Banknote,
  CheckCircle2,
  AlertCircle,
  Clock,
  Printer,
  PlusCircle,
  FileSpreadsheet,
  Receipt,
  School,
  TrendingUp,
  BarChart3,
  PieChart,
} from "lucide-react";

export const Route = createFileRoute("/_authenticated/fees")({
  ssr: false,
  head: () => schoolPageHead("التقارير / الرسوم المحصّلة — مدرسة العمرابي", "التقارير والرسوم المحصلة في نظام إدارة مدرسة العمرابي الثانوية."),
  component: FeesPage,
});

type PaymentMethod = "cash" | "bank_transfer" | "cheque" | "pos";

const METHOD_LABELS: Record<PaymentMethod, string> = {
  cash: "نقداً (خزينة المدرسة)",
  bank_transfer: "تحويل بنكي (بنكك / تطبيق)",
  cheque: "شيك مصرفي",
  pos: "نقطة بيع (بطاقة)",
};

interface StudentFeeRow {
  studentId: string;
  studentNumber: string;
  fullName: string;
  guardianName: string | null;
  guardianPhone: string | null;
  gradeId: string | null;
  gradeName: string;
  sectionId: string | null;
  sectionName: string;
  baseAmount: number;
  discountAmount: number;
  netDue: number;
  paidAmount: number;
  balance: number;
  status: "paid" | "partial" | "unpaid" | "exempt" | "none";
  payments: Array<{
    id: string;
    amount: number;
    receiptNumber: string;
    paymentMethod: string;
    createdAt: string;
    notes: string | null;
  }>;
}

async function safeFetchList<T>(promise: PromiseLike<{ data: T[] | null; error: any }>): Promise<T[]> {
  const res = await promise;
  if (res.error) {
    if (res.error.code === "42P01" || res.error.message?.includes("does not exist")) {
      return [];
    }
    throw res.error;
  }
  return res.data ?? [];
}

function FeesPage() {
  const qc = useQueryClient();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);

  // Filters
  const [q, setQ] = useState("");
  const [grade, setGrade] = useState("");
  const [section, setSection] = useState("");
  const [statusFilter, setStatusFilter] = useState("");

  // Modals
  const [payModalOpen, setPayModalOpen] = useState(false);
  const [selectedStudent, setSelectedStudent] = useState<StudentFeeRow | null>(null);
  const [payAmount, setPayAmount] = useState<number | "">("");
  const [payMethod, setPayMethod] = useState<PaymentMethod>("cash");
  const [payNotes, setPayNotes] = useState("");

  // Receipt Modal
  const [receiptModalOpen, setReceiptModalOpen] = useState(false);
  const [activeReceipt, setActiveReceipt] = useState<{
    receiptNumber: string;
    studentName: string;
    studentNumber: string;
    gradeSection: string;
    amount: number;
    method: string;
    date: string;
    notes: string | null;
  } | null>(null);

  // Fetch all necessary financial data defensively
  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["fees-overview"],
    queryFn: async () => {
      let year: any = null;
      const { data: curYear, error: curYearErr } = await supabase
        .from("academic_years")
        .select("*")
        .eq("is_current", true)
        .maybeSingle();
      if (curYearErr) throw curYearErr;
      if (curYear) {
        year = curYear;
      } else {
        const { data: latestYear, error: latErr } = await supabase
          .from("academic_years")
          .select("*")
          .order("starts_on", { ascending: false })
          .limit(1)
          .maybeSingle();
        if (latErr) throw latErr;
        year = latestYear ?? null;
      }

      const [
        students,
        sectionsRes,
        enrRes,
        grades,
        feeStructures,
        payments,
        discounts,
        feeTypes,
      ] = await Promise.all([
        safeFetchList(supabase.from("students").select("*").order("full_name")),
        year
          ? safeFetchList(
              supabase
                .from("sections")
                .select("id,name,grade_id,grade:grades(name,level_order),track:tracks(name)")
                .eq("academic_year_id", year.id)
            )
          : Promise.resolve([]),
        year
          ? safeFetchList(
              supabase
                .from("enrollments")
                .select("student_id,section_id,enrollment_type")
                .eq("academic_year_id", year.id)
            )
          : Promise.resolve([]),
        safeFetchList(supabase.from("grades").select("*").order("level_order")),
        year
          ? safeFetchList(supabase.from("fee_structures").select("*").eq("academic_year_id", year.id))
          : Promise.resolve([]),
        year
          ? safeFetchList(
              supabase
                .from("student_payments")
                .select("*")
                .eq("academic_year_id", year.id)
                .order("created_at", { ascending: false })
            )
          : Promise.resolve([]),
        year
          ? safeFetchList(
              supabase.from("student_fee_discounts").select("*").eq("academic_year_id", year.id)
            )
          : Promise.resolve([]),
        safeFetchList(supabase.from("fee_types").select("*").order("name")),
      ]);

      return {
        year,
        students,
        sections: sectionsRes as unknown as Array<{
          id: string;
          name: string;
          grade_id: string;
          grade: { name: string; level_order: number } | null;
          track: { name: string } | null;
        }>,
        enrollments: enrRes as Array<{ student_id: string; section_id: string }>,
        grades,
        feeStructures,
        payments,
        discounts,
        feeTypes,
      };
    },
  });

  const secById = useMemo(() => new Map((data?.sections ?? []).map((s) => [s.id, s])), [data]);
  const enrBy = useMemo(() => new Map((data?.enrollments ?? []).map((e) => [e.student_id, e])), [data]);

  // Aggregate fee structure by grade
  const structureByGrade = useMemo(() => {
    const map = new Map<string, number>();
    for (const fs of data?.feeStructures ?? []) {
      if (!fs?.grade_id) continue;
      const current = map.get(fs.grade_id) ?? 0;
      map.set(fs.grade_id, current + (Number(fs.amount) || 0));
    }
    return map;
  }, [data?.feeStructures]);

  // Payments and discounts per student
  const paymentsByStudent = useMemo(() => {
    const map = new Map<string, NonNullable<typeof data>["payments"]>();
    for (const p of data?.payments ?? []) {
      if (!p?.student_id) continue;
      const arr = map.get(p.student_id) ?? [];
      arr.push(p);
      map.set(p.student_id, arr);
    }
    return map;
  }, [data?.payments]);

  const discountsByStudent = useMemo(() => {
    const map = new Map<string, number>();
    for (const d of data?.discounts ?? []) {
      if (!d?.student_id) continue;
      const cur = map.get(d.student_id) ?? 0;
      map.set(d.student_id, cur + (Number(d.amount) || 0));
    }
    return map;
  }, [data?.discounts]);

  // Build rows for each enrolled student strictly from verified DB fee structures
  const rows = useMemo(() => {
    const list: StudentFeeRow[] = [];

    for (const s of data?.students ?? []) {
      const enr = enrBy.get(s.id);
      const sec = enr ? secById.get(enr.section_id) : undefined;
      const gradeId = sec?.grade_id ?? null;
      const gradeName = sec?.grade?.name ?? (sec ? "الصف المقيد" : "غير مسجل");
      const sectionName = sec?.name ?? "—";

      // Base fee comes strictly from approved fee structure for the grade (or 0 if unconfigured)
      let baseAmount = 0;
      if (gradeId && structureByGrade.has(gradeId)) {
        baseAmount = structureByGrade.get(gradeId) ?? 0;
      }

      // Discounts
      const discountAmount = discountsByStudent.get(s.id) ?? 0;
      const netDue = Math.max(0, baseAmount - discountAmount);

      // Payments
      const studentPays = paymentsByStudent.get(s.id) ?? [];
      const paidAmount = studentPays.reduce((sum, p) => sum + (Number(p.amount) || 0), 0);
      const balance = Math.max(0, netDue - paidAmount);

      // Status
      let status: StudentFeeRow["status"] = "none";
      if (baseAmount > 0) {
        if (discountAmount >= baseAmount) {
          status = "exempt";
        } else if (balance === 0 && netDue > 0) {
          status = "paid";
        } else if (paidAmount > 0 && balance > 0) {
          status = "partial";
        } else {
          status = "unpaid";
        }
      }

      list.push({
        studentId: s.id,
        studentNumber: s.student_number,
        fullName: s.full_name,
        guardianName: s.guardian_name,
        guardianPhone: s.guardian_phone,
        gradeId,
        gradeName,
        sectionId: sec?.id ?? null,
        sectionName,
        baseAmount,
        discountAmount,
        netDue,
        paidAmount,
        balance,
        status,
        payments: studentPays.map((p) => ({
          id: p.id,
          amount: Number(p.amount) || 0,
          receiptNumber: p.receipt_number,
          paymentMethod: p.payment_method,
          createdAt: p.created_at,
          notes: p.notes,
        })),
      });
    }

    return list;
  }, [data, enrBy, secById, structureByGrade, discountsByStudent, paymentsByStudent]);

  // Filtered rows
  const filteredRows = useMemo(() => {
    return rows.filter((r) => {
      if (grade && r.gradeId !== grade) return false;
      if (section && r.sectionId !== section) return false;
      if (statusFilter && r.status !== statusFilter) return false;
      if (q) {
        const query = q.trim().toLowerCase();
        const nameMatches = (r.fullName || "").toLowerCase().includes(query);
        const numMatches = matchesStudentNumber(r.studentNumber, query);
        const phoneMatches = (r.guardianPhone || "").includes(query);
        if (!nameMatches && !numMatches && !phoneMatches) return false;
      }
      return true;
    });
  }, [rows, grade, section, statusFilter, q]);

  // KPI Calculations (Total Dues, Collected, Remaining, Rate)
  const stats = useMemo(() => {
    const totalExpected = filteredRows.reduce((sum, r) => sum + r.netDue, 0);
    const totalCollected = filteredRows.reduce((sum, r) => sum + r.paidAmount, 0);
    const totalOutstanding = filteredRows.reduce((sum, r) => sum + r.balance, 0);
    const rate = totalExpected > 0 ? Math.round((totalCollected / totalExpected) * 100) : 0;
    return {
      totalExpected,
      totalCollected,
      totalOutstanding,
      rate,
    };
  }, [filteredRows]);

  // Class breakdown table: «الرسوم حسب الفصل» (Notion Section 10)
  const gradeBreakdown = useMemo(() => {
    const map = new Map<string, { gradeName: string; levelOrder: number; total: number; collected: number; balance: number; count: number }>();

    for (const g of data?.grades ?? []) {
      map.set(g.id, {
        gradeName: g.name,
        levelOrder: g.level_order ?? 0,
        total: 0,
        collected: 0,
        balance: 0,
        count: 0,
      });
    }

    for (const r of filteredRows) {
      if (!r.gradeId) continue;
      const cur = map.get(r.gradeId) ?? {
        gradeName: r.gradeName,
        levelOrder: 99,
        total: 0,
        collected: 0,
        balance: 0,
        count: 0,
      };
      cur.total += r.netDue;
      cur.collected += r.paidAmount;
      cur.balance += r.balance;
      cur.count += 1;
      map.set(r.gradeId, cur);
    }

    return Array.from(map.values())
      .filter((g) => g.count > 0 || !grade)
      .sort((a, b) => a.levelOrder - b.levelOrder)
      .map((g) => ({
        ...g,
        rate: g.total > 0 ? Math.round((g.collected / g.total) * 100) : 0,
      }));
  }, [data?.grades, filteredRows, grade]);

  // Monthly collection timeline: «التحصيل الشهري» (Notion Section 9)
  const monthlyStats = useMemo(() => {
    const arabicMonths = ["يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"];
    const filteredStudentIds = new Set(filteredRows.map((r) => r.studentId));
    const relevantPayments = (data?.payments ?? []).filter((p) => filteredStudentIds.has(p.student_id));

    const monthTotals = new Map<number, number>();
    for (let m = 0; m < 12; m++) monthTotals.set(m, 0);

    for (const p of relevantPayments) {
      const d = new Date(p.created_at);
      const m = d.getMonth();
      const cur = monthTotals.get(m) ?? 0;
      monthTotals.set(m, cur + (Number(p.amount) || 0));
    }

    // Sequence for academic year: Aug, Sep, Oct, Nov, Dec, Jan, Feb, Mar, Apr, May
    const academicMonths = [7, 8, 9, 10, 11, 0, 1, 2, 3, 4].map((m) => ({
      index: m,
      name: arabicMonths[m],
      amount: monthTotals.get(m) ?? 0,
    }));

    const maxVal = Math.max(...academicMonths.map((m) => m.amount), 50000);
    return { academicMonths, maxVal };
  }, [filteredRows, data?.payments]);

  // Fees by type distribution: «الرسوم حسب النوع» (Notion Section 9)
  const feeTypeStats = useMemo(() => {
    const rawTypes = (data?.feeTypes ?? []).length > 0
      ? data!.feeTypes
      : [
          { id: "1", name: "الرسوم الدراسية" },
          { id: "2", name: "الكتب والمقررات" },
          { id: "3", name: "الزي المدرسي" },
          { id: "4", name: "أنشطة وخدمات" },
        ];

    const items = rawTypes.map((t) => {
      const typePayments = (data?.payments ?? []).filter((p) => p.fee_type_id === t.id);
      const amount = typePayments.reduce((sum, p) => sum + (Number(p.amount) || 0), 0);
      return {
        id: t.id,
        name: t.name,
        amount,
      };
    });

    const maxAmount = Math.max(...items.map((i) => i.amount), 10000);
    return { items, maxAmount };
  }, [data?.feeTypes, data?.payments]);

  // Submit payment mutation
  const payMutation = useMutation({
    mutationFn: async () => {
      if (!selectedStudent) throw new Error("اختر الطالب أولاً");
      if (!payAmount || Number(payAmount) <= 0) throw new Error("أدخل مبلغاً صحيحاً");
      if (!data?.year) throw new Error("لا يوجد عام دراسي حالي معتمد");

      let feeTypeId: string | null = null;
      const { data: ft } = await supabase.from("fee_types").select("id").limit(1).maybeSingle();
      if (ft?.id) {
        feeTypeId = ft.id;
      } else {
        const { data: school } = await supabase.from("schools").select("id").limit(1).maybeSingle();
        if (school?.id) {
          const { data: newFt } = await supabase
            .from("fee_types")
            .insert({ school_id: school.id, name: "رسوم دراسية" })
            .select("id")
            .maybeSingle();
          if (newFt?.id) feeTypeId = newFt.id;
        }
      }

      if (!feeTypeId) {
        throw new Error("تعذر تحديد نوع الرسم. يرجى تهيئة أنواع الرسوم المعتمدة أولاً في لوحة التحكم.");
      }

      // F-014: Server-side atomic payment recording with client idempotency key
      const idempotencyKey = typeof crypto !== "undefined" && crypto.randomUUID ? crypto.randomUUID() : `idemp-${Date.now()}-${Math.random()}`;

      try {
        const { data: rpcRes, error: rpcErr } = await (supabase.rpc as any)("record_student_payment", {
          p_student_id: selectedStudent.studentId,
          p_academic_year_id: data.year.id,
          p_fee_type_id: feeTypeId,
          p_amount: Number(payAmount),
          p_payment_method: payMethod,
          p_notes: payNotes || null,
          p_idempotency_key: idempotencyKey,
        });

        if (!rpcErr && rpcRes?.success && rpcRes?.receipt_number) {
          return { inserted: rpcRes, receiptNumber: rpcRes.receipt_number };
        }
      } catch (err) {
        console.warn("record_student_payment RPC fallback:", err);
      }

      // Fallback if RPC is not yet created in active schema
      const fallbackReceiptNumber = `REC-${new Date().getFullYear()}-${Date.now().toString().slice(-6)}`;
      const { data: inserted, error } = await supabase
        .from("student_payments")
        .insert({
          student_id: selectedStudent.studentId,
          academic_year_id: data.year.id,
          fee_type_id: feeTypeId,
          amount: Number(payAmount),
          payment_method: payMethod,
          receipt_number: fallbackReceiptNumber,
          notes: payNotes || null,
        })
        .select()
        .single();

      if (error) throw error;
      return { inserted, receiptNumber: fallbackReceiptNumber };
    },
    onSuccess: (res) => {
      qc.invalidateQueries({ queryKey: ["fees-overview"] });
      toast.success(`تم تسجيل الدفعة بنجاح برقم إيصال: ${res.receiptNumber}`);

      if (selectedStudent) {
        setActiveReceipt({
          receiptNumber: res.receiptNumber,
          studentName: selectedStudent.fullName,
          studentNumber: selectedStudent.studentNumber,
          gradeSection: `${selectedStudent.gradeName} / ${selectedStudent.sectionName}`,
          amount: Number(payAmount) || 0,
          method: METHOD_LABELS[payMethod] ?? payMethod,
          date: formatKhartoumDateDisplay(new Date()),
          notes: payNotes || null,
        });
        setReceiptModalOpen(true);
      }

      setPayModalOpen(false);
      setPayAmount("");
      setPayNotes("");
      setSelectedStudent(null);
    },
    onError: (e) => toast.error(errMsg(e)),
  });

  // Export CSV
  function exportCsv() {
    try {
      const head = [
        "الرقم المدرسي",
        "اسم الطالب",
        "الصف",
        "الشعبة",
        "الرسوم المقررة",
        "المنح والخصم",
        "الصافي المستحق",
        "المدفوع فعلياً",
        "المتبقي",
        "حالة السداد",
        "هاتف ولي الأمر",
      ];
      const statusMap = {
        paid: "مسدد بالكامل",
        partial: "مسدد جزئياً",
        unpaid: "غير مسدد",
        exempt: "معفى / منحة",
        none: "غير محدد",
      };
      const sanitizeCsv = (val: any) => {
        let str = String(val ?? "").replace(/"/g, '""');
        if (/^[=+\-@\t\r]/.test(str)) {
          str = "'" + str;
        }
        return `"${str}"`;
      };

      const lines = filteredRows.map((r) => [
        r.studentNumber,
        r.fullName,
        r.gradeName,
        r.sectionName,
        r.baseAmount,
        r.discountAmount,
        r.netDue,
        r.paidAmount,
        r.balance,
        statusMap[r.status] ?? "—",
        r.guardianPhone ?? "—",
      ]);

      const csv = "\uFEFF" + [head, ...lines].map((row) => row.map(sanitizeCsv).join(",")).join("\n");
      const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = `تقرير_الرسوم_${data?.year?.name ?? "المدرسة"}.csv`;
      link.click();
      URL.revokeObjectURL(url);
    } catch {
      toast.error("فشل تصدير التقرير المالي");
    }
  }

  const sectionsForGrade = (data?.sections ?? []).filter((s) => !grade || s.grade_id === grade);

  if (isError) {
    return (
      <div className="py-20 flex flex-col items-center justify-center text-center p-6 card-surface">
        <p className="text-sm text-destructive font-medium mb-3">حدث خطأ أثناء تحميل التقارير والرسوم المالية.</p>
        <Button variant="outline" size="sm" onClick={() => refetch()} className="text-xs">
          إعادة المحاولة
        </Button>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="py-24 flex flex-col items-center justify-center text-muted-foreground text-sm">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent mb-3" />
        <span>جارٍ تحميل البيانات المالية وسجل الرسوم…</span>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* 1. Page Header (Notion Section 6: «التقارير / الرسوم المحصّلة») */}
      <PageHead
        title="التقارير / الرسوم المحصّلة"
        sub={
          <span>
            العام الدراسي: <strong className="text-foreground">{data?.year?.name ?? "—"}</strong>
            {" · "}
            عدد الطلاب الخاضعين للرسوم: <strong className="text-foreground">{filteredRows.length} طالب</strong>
          </span>
        }
        actions={
          <>
            <Button variant="outline" size="sm" onClick={exportCsv} className="h-9 gap-1.5 text-xs">
              <FileSpreadsheet className="h-4 w-4" />
              <span>تصدير كشف المبالغ (CSV)</span>
            </Button>
            {manager && (
              <Button
                size="sm"
                onClick={() => {
                  setSelectedStudent(null);
                  setPayModalOpen(true);
                }}
                className="h-9 gap-1.5 text-xs bg-primary text-primary-foreground"
              >
                <PlusCircle className="h-4 w-4" />
                <span>تسجيل دفعة مالية</span>
              </Button>
            )}
          </>
        }
      />

      {/* Unconfigured Fee Structures Guidance (per Notion anti-guessing rules) */}
      {(data?.feeStructures ?? []).length === 0 && (
        <div className="p-4 rounded-lg bg-amber-50/90 border border-amber-200 text-amber-900 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 text-xs">
          <div>
            <strong className="font-semibold block mb-0.5">تنبيه إداري: لم يتم اعتماد هيكل رسوم لهذا العام بعد</strong>
            <span>وفقاً للسياسة المالية المعتمدة في النظام، لا يتم فرض مبالغ تخمينية أو تقديرية على الطلاب دون اعتماد رسمي من المدير. تظهر المبالغ المستحقة كـ (0) حتى يتم إدخال الرسوم المقررة لكل صف.</span>
          </div>
        </div>
      )}

      {/* 2. Filter Panel (Notion Section 7) */}
      <FilterPanel
        title="خيارات التصفية"
        onReset={() => {
          setQ("");
          setGrade("");
          setSection("");
          setStatusFilter("");
        }}
      >
        <Field label="بحث بالاسم / الرقم المدرسي / الهاتف">
          <Input
            placeholder="ابحث باسم الطالب أو الرقم أو الهاتف…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            className="h-9 text-xs"
          />
        </Field>

        <Field label="الصف الدراسي">
          <select
            className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
            value={grade}
            onChange={(e) => {
              setGrade(e.target.value);
              setSection("");
            }}
          >
            <option value="">كافة الصفوف</option>
            {(data?.grades ?? []).map((g) => (
              <option key={g.id} value={g.id}>
                {g.name}
              </option>
            ))}
          </select>
        </Field>

        <Field label="الشعبة الدراسية">
          <select
            className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
            value={section}
            onChange={(e) => setSection(e.target.value)}
          >
            <option value="">كافة الشعب</option>
            {sectionsForGrade.map((s) => (
              <option key={s.id} value={s.id}>
                {s.grade?.name ? s.grade.name.replace("الصف ", "") : ""} / {s.name ?? ""}
              </option>
            ))}
          </select>
        </Field>

        <Field label="حالة السداد">
          <select
            className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="">كافة الحالات</option>
            <option value="paid">مسدد بالكامل</option>
            <option value="partial">مسدد جزئياً</option>
            <option value="unpaid">غير مسدد (متأخر)</option>
            <option value="exempt">معفى / حاصل على منحة</option>
          </select>
        </Field>
      </FilterPanel>

      {/* 3. KPI Cards with Notion Semantic Colors (Section 8) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Total Dues (بنفسجي/أزرق) */}
        <div className="card-surface p-5 border-s-4 border-s-indigo-500">
          <div className="flex items-center justify-between text-muted-foreground text-xs mb-2">
            <span>إجمالي الرسوم المستحقة</span>
            <Banknote className="h-4 w-4 text-indigo-600" />
          </div>
          <div className="text-xl sm:text-2xl font-bold font-mono text-foreground">
            {stats.totalExpected.toLocaleString()} <span className="text-xs font-normal">ج.س</span>
          </div>
          <div className="text-[11px] text-muted-foreground mt-1">الصافي بعد المنح والخصومات المعتمدة</div>
        </div>

        {/* Collected (أخضر) */}
        <div className="card-surface p-5 border-s-4 border-s-emerald-500">
          <div className="flex items-center justify-between text-muted-foreground text-xs mb-2">
            <span>المبلغ المحصّل فعلياً</span>
            <CheckCircle2 className="h-4 w-4 text-emerald-600" />
          </div>
          <div className="text-xl sm:text-2xl font-bold font-mono text-emerald-700">
            {stats.totalCollected.toLocaleString()} <span className="text-xs font-normal">ج.س</span>
          </div>
          <div className="text-[11px] text-emerald-600 mt-1 font-medium">الوارد في خزينة وحسابات المدرسة</div>
        </div>

        {/* Remaining (مرجاني/أحمر) */}
        <div className="card-surface p-5 border-s-4 border-s-rose-500">
          <div className="flex items-center justify-between text-muted-foreground text-xs mb-2">
            <span>المبلغ المتبقي (المتأخرات)</span>
            <AlertCircle className="h-4 w-4 text-rose-600" />
          </div>
          <div className="text-xl sm:text-2xl font-bold font-mono text-rose-700">
            {stats.totalOutstanding.toLocaleString()} <span className="text-xs font-normal">ج.س</span>
          </div>
          <div className="text-[11px] text-rose-600 mt-1 font-medium">مستحقات واجبة التحصيل</div>
        </div>

        {/* Rate (نسبة التحصيل) */}
        <div className="card-surface p-5 border-s-4 border-s-primary">
          <div className="flex items-center justify-between text-muted-foreground text-xs mb-2">
            <span>نسبة التحصيل العامة</span>
            <Clock className="h-4 w-4 text-primary" />
          </div>
          <div className="text-xl sm:text-2xl font-bold font-mono text-primary">
            {stats.rate}%
          </div>
          <div className="w-full bg-muted rounded-full h-1.5 mt-2.5 overflow-hidden">
            <div className="bg-primary h-1.5 rounded-full transition-all" style={{ width: `${Math.min(stats.rate, 100)}%` }} />
          </div>
        </div>
      </div>

      {/* 4. Two Notion Charts Side-by-Side (Section 9) */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        {/* Panel 1: Monthly Collection (التحصيل الشهري) */}
        <div className="card-surface p-5">
          <div className="flex items-center justify-between pb-3 border-b border-border mb-4">
            <div className="flex items-center gap-2">
              <BarChart3 className="h-4 w-4 text-primary" />
              <h3 className="text-xs font-bold text-foreground">التحصيل الشهري</h3>
            </div>
            <span className="text-[11px] text-muted-foreground">توزيع الإيرادات حسب الأشهر</span>
          </div>

          <div className="h-56 flex items-end gap-2 pt-6 pb-2 px-2">
            {monthlyStats.academicMonths.map((m) => {
              const heightPercent = monthlyStats.maxVal > 0 ? Math.round((m.amount / monthlyStats.maxVal) * 100) : 0;
              return (
                <div key={m.index} className="flex-1 flex flex-col items-center gap-2 h-full justify-end group">
                  <div className="text-[10px] font-mono text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity">
                    {m.amount > 0 ? `${(m.amount / 1000).toFixed(0)}k` : "0"}
                  </div>
                  <div
                    className="w-full max-w-[28px] rounded-t-sm bg-primary/80 group-hover:bg-primary transition-all relative"
                    style={{ height: `${Math.max(heightPercent, 6)}%` }}
                    title={`${m.name}: ${m.amount.toLocaleString()} ج.س`}
                  />
                  <span className="text-[10px] text-muted-foreground whitespace-nowrap">{m.name}</span>
                </div>
              );
            })}
          </div>
        </div>

        {/* Panel 2: Fees by Type (الرسوم حسب النوع) */}
        <div className="card-surface p-5">
          <div className="flex items-center justify-between pb-3 border-b border-border mb-4">
            <div className="flex items-center gap-2">
              <PieChart className="h-4 w-4 text-primary" />
              <h3 className="text-xs font-bold text-foreground">الرسوم حسب النوع</h3>
            </div>
            <span className="text-[11px] text-muted-foreground">مقارنة فئات الرسوم المقررة</span>
          </div>

          <div className="space-y-4 pt-2">
            {feeTypeStats.items.map((item) => {
              const pct = feeTypeStats.maxAmount > 0 ? Math.round((item.amount / feeTypeStats.maxAmount) * 100) : 0;
              return (
                <div key={item.id} className="space-y-1.5">
                  <div className="flex justify-between items-center text-xs">
                    <span className="font-medium text-foreground">{item.name}</span>
                    <span className="font-mono text-muted-foreground">{item.amount.toLocaleString()} ج.س</span>
                  </div>
                  <div className="w-full bg-muted rounded-full h-2 overflow-hidden">
                    <div
                      className="h-2 rounded-full bg-indigo-600 transition-all"
                      style={{ width: `${Math.min(pct, 100)}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* 5. Class Details Table: «الرسوم حسب الفصل» (Notion Section 10) */}
      <div className="card-surface overflow-hidden">
        <div className="p-4 border-b border-border flex items-center justify-between">
          <div className="text-xs font-semibold text-foreground">الرسوم حسب الفصل</div>
          <span className="text-xs text-muted-foreground">ملخص استيفاء الرسوم لكل صف دراسي</span>
        </div>

        <div className="overflow-x-auto">
          <table className="modern-table">
            <thead>
              <tr>
                <th className="w-12">#</th>
                <th>الصف الدراسي</th>
                <th>إجمالي الرسوم المقررة</th>
                <th>المحصّل فعلياً</th>
                <th>المبلغ المتبقي</th>
                <th className="w-48">نسبة التحصيل</th>
              </tr>
            </thead>
            <tbody>
              {gradeBreakdown.map((row, idx) => (
                <tr key={row.gradeName} className="hover:bg-muted/40 transition-colors">
                  <td className="num text-muted-foreground text-xs">{idx + 1}</td>
                  <td className="font-semibold text-foreground text-xs">{row.gradeName}</td>
                  <td className="num font-mono text-xs">{row.total.toLocaleString()} ج.س</td>
                  <td className="num font-mono text-xs text-emerald-600 font-semibold">{row.collected.toLocaleString()} ج.س</td>
                  <td className="num font-mono text-xs text-rose-600 font-semibold">{row.balance.toLocaleString()} ج.س</td>
                  <td>
                    <div className="flex items-center gap-3">
                      <div className="flex-1 bg-muted rounded-full h-2 overflow-hidden">
                        <div
                          className="bg-amber-500 h-2 rounded-full transition-all"
                          style={{ width: `${Math.min(row.rate, 100)}%` }}
                        />
                      </div>
                      <span className="text-xs font-mono font-bold text-foreground w-9 text-end">{row.rate}%</span>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {gradeBreakdown.length === 0 && (
            <div className="p-8 text-center text-xs text-muted-foreground">
              لا توجد صفوف دراسية مسجلة حالياً
            </div>
          )}
        </div>
      </div>

      {/* 6. Detailed Student Ledger Table */}
      <div className="card-surface overflow-hidden">
        <div className="p-4 border-b border-border flex items-center justify-between">
          <div className="text-xs font-semibold text-foreground">كشوفات حسابات الطلاب والرسوم</div>
          <span className="text-xs text-muted-foreground">{filteredRows.length} طالب معروض</span>
        </div>

        <div className="overflow-x-auto">
          <table className="modern-table">
            <thead>
              <tr>
                <th className="w-12">#</th>
                <th>الرقم المدرسي</th>
                <th>اسم الطالب</th>
                <th>الصف / الشعبة</th>
                <th>الرسوم المقررة</th>
                <th>المنحة / الخصم</th>
                <th>الصافي المستحق</th>
                <th>المدفوع</th>
                <th>المتبقي</th>
                <th>الحالة</th>
                <th className="text-end">الإجراءات</th>
              </tr>
            </thead>
            <tbody>
              {filteredRows.map((row, idx) => (
                <tr key={row.studentId} className="hover:bg-muted/40 transition-colors">
                  <td className="num text-muted-foreground text-xs">{idx + 1}</td>
                  <td>
                    <span className="font-mono text-xs px-2 py-0.5 rounded-md bg-muted text-foreground font-medium" dir="ltr">
                      {row.studentNumber}
                    </span>
                  </td>
                  <td>
                    <Link
                      to="/students/$id"
                      params={{ id: row.studentId }}
                      className="font-medium text-foreground hover:text-primary transition-colors block"
                    >
                      {row.fullName}
                    </Link>
                    {row.guardianPhone && (
                      <span className="text-[11px] text-muted-foreground block mt-0.5 font-mono" dir="ltr">
                        {row.guardianPhone}
                      </span>
                    )}
                  </td>
                  <td className="text-xs text-foreground font-medium">
                    {row.gradeName} / {row.sectionName}
                  </td>
                  <td className="text-xs font-mono text-muted-foreground">{row.baseAmount.toLocaleString()}</td>
                  <td className="text-xs font-mono text-amber-600">
                    {row.discountAmount > 0 ? `-${row.discountAmount.toLocaleString()}` : "—"}
                  </td>
                  <td className="text-xs font-mono font-semibold text-foreground">{row.netDue.toLocaleString()}</td>
                  <td className="text-xs font-mono font-semibold text-emerald-600">
                    {row.paidAmount.toLocaleString()}
                  </td>
                  <td className="text-xs font-mono font-bold text-rose-600">
                    {row.balance > 0 ? row.balance.toLocaleString() : "0"}
                  </td>
                  <td>
                    {row.status === "paid" && (
                      <span className="status-pill status-pill-active">مسدد بالكامل</span>
                    )}
                    {row.status === "partial" && (
                      <span className="status-pill bg-amber-50 text-amber-700 border-amber-200">مسدد جزئياً</span>
                    )}
                    {row.status === "unpaid" && (
                      <span className="status-pill status-pill-withdrawn">غير مسدد</span>
                    )}
                    {row.status === "exempt" && (
                      <span className="status-pill bg-indigo-50 text-indigo-700 border-indigo-200">منحة كاملة</span>
                    )}
                    {row.status === "none" && (
                      <span className="status-pill bg-slate-100 text-slate-600 border-slate-200">غير محدد</span>
                    )}
                  </td>
                  <td className="text-end">
                    <div className="flex items-center justify-end gap-1.5">
                      {manager && row.balance > 0 && (
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => {
                            setSelectedStudent(row);
                            setPayAmount(row.balance);
                            setPayModalOpen(true);
                          }}
                          className="h-8 px-2.5 text-xs text-primary border-primary/30 hover:bg-primary/5"
                        >
                          <span>سداد</span>
                        </Button>
                      )}
                      {row.payments.length > 0 && (
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => {
                            const lastP = row.payments[0];
                            if (!lastP) return;
                            setActiveReceipt({
                              receiptNumber: lastP.receiptNumber,
                              studentName: row.fullName,
                              studentNumber: row.studentNumber,
                              gradeSection: `${row.gradeName} / ${row.sectionName}`,
                              amount: lastP.amount,
                              method: METHOD_LABELS[lastP.paymentMethod as PaymentMethod] ?? lastP.paymentMethod,
                              date: new Date(lastP.createdAt).toLocaleDateString("ar-EG"),
                              notes: lastP.notes,
                            });
                            setReceiptModalOpen(true);
                          }}
                          className="h-8 w-8 p-0 text-muted-foreground hover:text-foreground"
                          title="عرض آخر إيصال"
                        >
                          <Receipt className="h-4 w-4" />
                        </Button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {filteredRows.length === 0 && (
            <Empty title="لا توجد سجلات مالية مطابقة">
              جرّب تغيير كلمات البحث أو إعادة ضبط خيارات التصفية لعرض نتائج الرسوم.
            </Empty>
          )}
        </div>
      </div>

      {/* Record Payment Dialog */}
      <Dialog open={payModalOpen} onOpenChange={setPayModalOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="text-lg font-bold text-foreground flex items-center gap-2">
              <Banknote className="h-5 w-5 text-primary" />
              <span>تسجيل دفعة مالية جديدة</span>
            </DialogTitle>
          </DialogHeader>

          <form
            onSubmit={(e) => {
              e.preventDefault();
              payMutation.mutate();
            }}
            className="space-y-4 pt-2"
          >
            {/* Student selection */}
            <Field label="الطالب المسدد *">
              {selectedStudent ? (
                <div className="p-3 rounded-lg bg-muted/60 border border-border flex items-center justify-between">
                  <div>
                    <div className="text-xs font-semibold text-foreground">{selectedStudent.fullName}</div>
                    <div className="text-[11px] text-muted-foreground mt-0.5">
                      {selectedStudent.gradeName} / {selectedStudent.sectionName} · متبقي:{" "}
                      <span className="text-rose-600 font-bold font-mono">
                        {selectedStudent.balance.toLocaleString()} ج.س
                      </span>
                    </div>
                  </div>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => setSelectedStudent(null)}
                    className="h-7 text-xs text-muted-foreground"
                  >
                    تغيير
                  </Button>
                </div>
              ) : (
                <select
                  className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                  onChange={(e) => {
                    const st = rows.find((r) => r.studentId === e.target.value);
                    if (st) {
                      setSelectedStudent(st);
                      setPayAmount(st.balance > 0 ? st.balance : "");
                    }
                  }}
                  required
                >
                  <option value="">اختر الطالب من القائمة…</option>
                  {rows
                    .filter((r) => r.balance > 0)
                    .map((r) => (
                      <option key={r.studentId} value={r.studentId}>
                        {r.fullName} ({r.gradeName}) — متبقي: {r.balance.toLocaleString()}
                      </option>
                    ))}
                </select>
              )}
            </Field>

            <Field label="المبلغ المدفوع (بالجنيه السوداني) *">
              <Input
                type="number"
                min="1"
                step="any"
                placeholder="أدخل المبلغ المدفوع…"
                value={payAmount}
                onChange={(e) => setPayAmount(e.target.value ? Number(e.target.value) : "")}
                className="h-9 text-xs font-mono"
                required
              />
            </Field>

            <Field label="طريقة الدفع *">
              <select
                className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                value={payMethod}
                onChange={(e) => setPayMethod(e.target.value as PaymentMethod)}
                required
              >
                <option value="cash">نقداً (خزينة المدرسة)</option>
                <option value="bank_transfer">تحويل بنكي (تطبيق بنكك / إشعار)</option>
                <option value="cheque">شيك مصرفي</option>
                <option value="pos">نقطة بيع إلكترونية (POS)</option>
              </select>
            </Field>

            <Field label="ملاحظات أو رقم المعاملة البنكية (اختياري)">
              <Input
                placeholder="مثال: رقم العملية 847291 أو اسم المحوّل…"
                value={payNotes}
                onChange={(e) => setPayNotes(e.target.value)}
                className="h-9 text-xs"
              />
            </Field>

            <div className="pt-3 border-t border-border flex items-center justify-end gap-2">
              <Button
                type="button"
                variant="ghost"
                size="sm"
                onClick={() => setPayModalOpen(false)}
                className="h-9 text-xs"
              >
                إلغاء
              </Button>
              <Button
                type="submit"
                size="sm"
                disabled={payMutation.isPending}
                className="h-9 text-xs bg-primary text-primary-foreground gap-1.5"
              >
                {payMutation.isPending ? "جارٍ الحفظ…" : "اعتماد الدفعة وإصدار الإيصال"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Printable Receipt Dialog */}
      <Dialog open={receiptModalOpen} onOpenChange={setReceiptModalOpen}>
        <DialogContent className="max-w-md p-6">
          <div id="school-receipt-print" className="space-y-4">
            {/* School Header */}
            <div className="text-center pb-4 border-b border-border">
              <div className="flex items-center justify-center gap-2 mb-1">
                <School className="h-6 w-6 text-primary" />
                <h3 className="font-bold text-base text-foreground">مدرسة العمرابي الثانوية بنين</h3>
              </div>
              <div className="text-xs text-muted-foreground">إيصال سداد رسوم دراسية معتمد</div>
              <div className="text-[11px] font-mono text-muted-foreground mt-1">
                رقم الإيصال: <strong className="text-foreground">{activeReceipt?.receiptNumber}</strong>
              </div>
            </div>

            {/* Receipt Details */}
            <div className="space-y-2.5 text-xs py-2">
              <div className="flex justify-between items-center py-1 border-b border-border/50">
                <span className="text-muted-foreground font-medium">اسم الطالب:</span>
                <span className="text-foreground font-semibold">{activeReceipt?.studentName}</span>
              </div>
              <div className="flex justify-between items-center py-1 border-b border-border/50">
                <span className="text-muted-foreground font-medium">الرقم المدرسي:</span>
                <span className="text-foreground font-mono font-medium">{activeReceipt?.studentNumber}</span>
              </div>
              <div className="flex justify-between items-center py-1 border-b border-border/50">
                <span className="text-muted-foreground font-medium">الصف / الشعبة:</span>
                <span className="text-foreground">{activeReceipt?.gradeSection}</span>
              </div>
              <div className="flex justify-between items-center py-1 border-b border-border/50">
                <span className="text-muted-foreground font-medium">طريقة السداد:</span>
                <span className="text-foreground">{activeReceipt?.method}</span>
              </div>
              <div className="flex justify-between items-center py-1 border-b border-border/50">
                <span className="text-muted-foreground font-medium">تاريخ المعاملة:</span>
                <span className="text-foreground">{activeReceipt?.date}</span>
              </div>
              {activeReceipt?.notes && (
                <div className="flex justify-between items-center py-1 border-b border-border/50">
                  <span className="text-muted-foreground font-medium">ملاحظات:</span>
                  <span className="text-foreground">{activeReceipt.notes}</span>
                </div>
              )}
              <div className="flex justify-between items-center py-2.5 bg-muted/60 px-3 rounded-lg font-bold text-sm text-foreground mt-3">
                <span>المبلغ المستلم:</span>
                <span className="font-mono text-primary">
                  {activeReceipt?.amount ? activeReceipt.amount.toLocaleString() : "0"} ج.س
                </span>
              </div>
            </div>

            {/* Footer / Signatures */}
            <div className="pt-4 border-t border-border flex items-center justify-between text-[11px] text-muted-foreground">
              <div>ختم المدرسة والاعتماد</div>
              <div>توقيع أمين الخزينة</div>
            </div>
          </div>

          <div className="pt-4 border-t border-border flex items-center justify-end gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => window.print()}
              className="h-8 gap-1.5 text-xs text-foreground"
            >
              <Printer className="h-3.5 w-3.5" />
              <span>طباعة الإيصال</span>
            </Button>
            <Button
              size="sm"
              onClick={() => setReceiptModalOpen(false)}
              className="h-8 text-xs"
            >
              إغلاق
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
