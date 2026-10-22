import { schoolPageHead } from "@/lib/pageHead";
import { createFileRoute, Link } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useMe, canManage, errMsg } from "@/lib/staff";
import { matchesStudentNumber } from "@/lib/studentNumber";
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
} from "lucide-react";

export const Route = createFileRoute("/_authenticated/fees")({
  ssr: false,
  head: () => schoolPageHead("الرسوم والمالية — مدرسة العمرابي", "الرسوم والمالية في نظام إدارة مدرسة العمرابي الثانوية."),
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
  try {
    const res = await promise;
    if (res.error) {
      console.warn("Financial query notice (table may not be populated yet):", res.error.message);
      return [];
    }
    return res.data ?? [];
  } catch (err) {
    console.warn("Financial query exception caught safely:", err);
    return [];
  }
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
  const { data, isLoading } = useQuery({
    queryKey: ["fees-overview"],
    queryFn: async () => {
      const { data: year } = await supabase
        .from("academic_years")
        .select("*")
        .eq("is_current", true)
        .maybeSingle();

      const [studentsRes, sectionsRes, enrRes, gradesRes, feeStructures, payments, discounts] = await Promise.all([
        supabase.from("students").select("*").order("full_name"),
        year
          ? supabase
              .from("sections")
              .select("id,name,grade_id,grade:grades(name,level_order),track:tracks(name)")
              .eq("academic_year_id", year.id)
          : Promise.resolve({ data: [] }),
        year
          ? supabase
              .from("enrollments")
              .select("student_id,section_id,enrollment_type")
              .eq("academic_year_id", year.id)
          : Promise.resolve({ data: [] }),
        supabase.from("grades").select("*").order("level_order"),
        year ? safeFetchList(supabase.from("fee_structures").select("*").eq("academic_year_id", year.id)) : Promise.resolve([]),
        year ? safeFetchList(supabase.from("student_payments").select("*").eq("academic_year_id", year.id).order("created_at", { ascending: false })) : Promise.resolve([]),
        year ? safeFetchList(supabase.from("student_fee_discounts").select("*").eq("academic_year_id", year.id)) : Promise.resolve([]),
      ]);

      return {
        year,
        students: studentsRes.data ?? [],
        sections: (sectionsRes.data ?? []) as Array<{
          id: string;
          name: string;
          grade_id: string;
          grade: { name: string; level_order: number } | null;
          track: { name: string } | null;
        }>,
        enrollments: (enrRes.data ?? []) as Array<{ student_id: string; section_id: string }>,
        grades: gradesRes.data ?? [],
        feeStructures,
        payments,
        discounts,
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

  // Build rows for each enrolled student
  const rows = useMemo(() => {
    const list: StudentFeeRow[] = [];
    const defaultAnnualFee = 150000; // Benchmark fee in SDG if custom grade fee not set

    for (const s of data?.students ?? []) {
      const enr = enrBy.get(s.id);
      const sec = enr ? secById.get(enr.section_id) : undefined;
      const gradeId = sec?.grade_id ?? null;
      const gradeName = sec?.grade?.name ?? (sec ? "الصف المقيد" : "غير مسجل");
      const sectionName = sec?.name ?? "—";

      // Base fee
      let baseAmount = 0;
      if (gradeId && structureByGrade.has(gradeId)) {
        baseAmount = structureByGrade.get(gradeId) ?? defaultAnnualFee;
      } else if (sec) {
        baseAmount = defaultAnnualFee;
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

  // KPI Calculations
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

  // Submit payment mutation
  const payMutation = useMutation({
    mutationFn: async () => {
      if (!selectedStudent) throw new Error("اختر الطالب أولاً");
      if (!payAmount || Number(payAmount) <= 0) throw new Error("أدخل مبلغاً صحيحاً");
      if (!data?.year) throw new Error("لا يوجد عام دراسي حالي");

      const receiptNumber = `REC-${new Date().getFullYear()}-${Math.floor(100000 + Math.random() * 900000)}`;

      let feeTypeId = "00000000-0000-0000-0000-000000000000";
      const { data: ft } = await supabase.from("fee_types").select("id").limit(1).maybeSingle();
      if (ft?.id) {
        feeTypeId = ft.id;
      } else {
        const { data: school } = await supabase.from("schools").select("id").limit(1).single();
        if (school?.id) {
          const { data: newFt } = await supabase
            .from("fee_types")
            .insert({ school_id: school.id, name: "رسوم دراسية" })
            .select()
            .single();
          if (newFt?.id) feeTypeId = newFt.id;
        }
      }

      const { data: inserted, error } = await supabase
        .from("student_payments")
        .insert({
          student_id: selectedStudent.studentId,
          academic_year_id: data.year.id,
          fee_type_id: feeTypeId,
          amount: Number(payAmount),
          payment_method: payMethod,
          receipt_number: receiptNumber,
          notes: payNotes || null,
        })
        .select()
        .single();

      if (error) throw error;
      return { inserted, receiptNumber };
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
          date: new Date().toLocaleDateString("ar-EG"),
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

      const csv = "\uFEFF" + [head, ...lines].map((row) => row.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(",")).join("\n");
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
      {/* Header */}
      <PageHead
        title="الرسوم والمالية"
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

      {/* 4 Notion KPI Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="إجمالي الرسوم المقررة"
          value={`${stats.totalExpected.toLocaleString()} ج.س`}
          note="الصافي بعد المنح والخصومات"
          icon={<Banknote className="h-4 w-4" />}
        />
        <StatCard
          label="إجمالي المحصّل الفعلي"
          value={`${stats.totalCollected.toLocaleString()} ج.س`}
          note="الوارد في خزينة المدرسة"
          icon={<CheckCircle2 className="h-4 w-4" />}
          variant="success"
        />
        <StatCard
          label="الرصيد المتبقي (المتأخرات)"
          value={`${stats.totalOutstanding.toLocaleString()} ج.س`}
          note="مستحقات غير مسددة"
          icon={<AlertCircle className="h-4 w-4" />}
          variant="warning"
        />
        <StatCard
          label="نسبة التحصيل الإجمالية"
          value={`${stats.rate}%`}
          note="معدل استيفاء الرسوم السنوية"
          icon={<Clock className="h-4 w-4" />}
          variant="primary"
        />
      </div>

      {/* Filter Panel */}
      <FilterPanel
        title="خيارات تصفية الطلاب والرسوم"
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
            {data?.grades.map((g) => (
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

      {/* Main Financial Data Table */}
      <div className="card-surface overflow-hidden">
        <div className="p-4 border-b border-border flex items-center justify-between">
          <div className="text-xs font-semibold text-foreground">قائمة كشوفات الطلاب والرسوم المالية</div>
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
                <th>المقرر</th>
                <th>الخصم / المنحة</th>
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
                          className="h-8 px-2 text-xs text-primary border-primary/30 hover:bg-primary/5"
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
            {/* Student selection if not pre-selected */}
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
