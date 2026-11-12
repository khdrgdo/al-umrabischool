import { useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { schoolPageHead } from "@/lib/pageHead";
import { canManage, errMsg, useMe, useSchool } from "@/lib/staff";
import { useAdminRoster } from "@/lib/adminFeatureQueries";
import { assignmentChanges, expectedOptionalTotal, optionalFeeSchema, paidUnassignments, readAll } from "@/lib/adminFeatures";
import { PageHead, Field, Empty } from "@/components/app/kit";
import { SearchChecklist } from "@/components/app/SearchChecklist";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";

export const Route = createFileRoute("/_authenticated/optional-fees")({
  head: () => schoolPageHead("رسوم اختيارية — مدرسة العمرابي", "إدارة الرسوم الاختيارية وإسنادها إلى الطلاب في العام الدراسي الحالي."),
  component: OptionalFees,
});

const initialForm = { grade_id: "", fee_type_id: "", new_type: "", amount: "", due_date: "", description: "" };

function OptionalFees() {
  const qc = useQueryClient();
  const { data: school } = useSchool();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);
  const roster = useAdminRoster(school?.id);
  const year = roster.data?.year;
  const [form, setForm] = useState(initialForm);
  const [createOpen, setCreateOpen] = useState(false);
  const [assignId, setAssignId] = useState<string | null>(null);
  const [selection, setSelection] = useState<string[]>([]);
  const [warning, setWarning] = useState<string[]>([]);
  const [confirmRemoval, setConfirmRemoval] = useState(false);
  const query = useQuery({
    queryKey: ["optional-fees", school?.id, year?.id], enabled: !!school && !!year,
    queryFn: async () => {
      if (!school || !year) throw new Error("لا يوجد عام دراسي حالي");
      const [structures, types, assignments] = await Promise.all([
        readAll((a, b) => supabase.from("fee_structures").select("*").eq("academic_year_id", year.id).eq("is_optional", true).order("created_at", { ascending: false }).order("id").range(a, b)),
        readAll((a, b) => supabase.from("fee_types").select("id,name,is_active").eq("school_id", school.id).order("name").order("id").range(a, b)),
        readAll((a, b) => supabase.from("fee_structure_assignments").select("id,fee_structure_id,student_id").order("id").range(a, b)),
      ]);
      return { structures, types, assignments };
    },
  });
  const refresh = async () => { await qc.invalidateQueries({ queryKey: ["optional-fees"] }); };
  const create = useMutation({
    mutationFn: async () => {
      if (!manager || !school || !year) throw new Error("ليست لديك صلاحية أو لا يوجد عام دراسي حالي");
      const value = optionalFeeSchema.parse(form);
      if (!roster.data?.grades.some((g) => g.id === value.grade_id)) throw new Error("الصف غير صالح");
      let feeTypeId = value.fee_type_id;
      if (!feeTypeId) {
        feeTypeId = query.data?.types.find((t) => t.name.trim() === value.new_type)?.id ?? "";
        if (!feeTypeId) {
          const { data, error } = await supabase.from("fee_types").insert({ school_id: school.id, name: value.new_type }).select("id").single();
          if (error) throw error;
          feeTypeId = data.id;
        }
      } else if (!query.data?.types.some((t) => t.id === feeTypeId)) throw new Error("نوع الرسم غير صالح");
      const { error } = await supabase.from("fee_structures").insert({ academic_year_id: year.id, grade_id: value.grade_id, fee_type_id: feeTypeId, amount: value.amount, due_date: value.due_date || null, description: value.description || null, is_optional: true });
      if (error) throw error;
    },
    onSuccess: async () => { setCreateOpen(false); setForm(initialForm); await refresh(); toast.success("أُضيف الرسم الاختياري"); },
    onError: async (e) => { await refresh(); toast.error(errMsg(e)); },
  });
  const structure = query.data?.structures.find((f) => f.id === assignId);
  const eligible = roster.data?.students.filter((student) => roster.data?.enrollments.some((e) => e.student_id === student.id && roster.data?.sections.some((s) => s.id === e.section_id && s.grade_id === structure?.grade_id))) ?? [];
  const saveAssignments = useMutation({
    mutationFn: async () => {
      if (!manager || !structure || !year) throw new Error("ليست لديك صلاحية لهذه العملية");
      // Re-read before saving: do not diff against a stale list or delete unrelated assignments.
      const existingRows = await readAll((a, b) => supabase.from("fee_structure_assignments").select("id,student_id").eq("fee_structure_id", structure.id).order("id").range(a, b));
      const changes = assignmentChanges(existingRows.map((r) => r.student_id), selection);
      if (changes.add.some((id) => !eligible.some((student) => student.id === id))) throw new Error("يمكن إسناد الرسم لطلاب الصف المسجلين في العام الحالي فقط");
      if (changes.remove.length) {
        const payments = await readAll((a, b) => supabase.from("student_payments").select("student_id").eq("fee_type_id", structure.fee_type_id).eq("academic_year_id", year.id).order("id").range(a, b));
        const paid = paidUnassignments(changes.remove, payments);
        if (paid.length && !confirmRemoval) { setWarning(paid); return false; }
      }
      // Add first, delete only explicit removed IDs. Each request is checked by RLS.
      if (changes.add.length) {
        const { error } = await supabase.from("fee_structure_assignments").upsert(changes.add.map((student_id) => ({ student_id, fee_structure_id: structure.id, assigned_by: me?.user.id })), { onConflict: "fee_structure_id,student_id", ignoreDuplicates: true });
        if (error) throw error;
      }
      for (let i = 0; i < changes.remove.length; i += 100) {
        const { error } = await supabase.from("fee_structure_assignments").delete().eq("fee_structure_id", structure.id).in("student_id", changes.remove.slice(i, i + 100));
        if (error) throw error;
      }
      return true;
    },
    onSuccess: async (saved) => { if (!saved) return; setAssignId(null); setWarning([]); setConfirmRemoval(false); await refresh(); toast.success("حُفظ إسناد الطلاب"); },
    onError: async (e) => { await refresh(); toast.error(`تعذر إكمال الحفظ؛ راجع الإسنادات قبل إعادة المحاولة. ${errMsg(e)}`); },
  });
  const error = roster.error || query.error;
  return <div className="space-y-5">
    <PageHead title="رسوم اختيارية" sub={year?.name ?? "لا يوجد عام دراسي حالي"} actions={manager && <Button disabled={!year || !query.data} onClick={() => setCreateOpen(true)}>إضافة رسم اختياري</Button>} />
    <p className="text-sm text-muted-foreground border-s-2 border-primary ps-3">لا يُحاسَب بالرسم الاختياري إلا الطلاب المُسنَد إليهم</p>
    {error ? <div role="alert" className="text-destructive">{errMsg(error)} <Button variant="outline" onClick={() => { roster.refetch(); query.refetch(); }}>إعادة المحاولة</Button></div> : roster.isLoading || query.isLoading ? <p>جارٍ التحميل…</p> : <div className="sheet overflow-x-auto">
      <table className="ledger"><thead><tr><th>الصف</th><th>الرسم</th><th>المبلغ</th><th>الاستحقاق</th><th>الوصف</th><th>الطلاب المسندون</th><th>الإجمالي المتوقع</th><th>الإسناد</th></tr></thead>
        <tbody>{query.data?.structures.map((fee) => {
          const ids = query.data.assignments.filter((a) => a.fee_structure_id === fee.id).map((a) => a.student_id);
          return <tr key={fee.id}><td>{roster.data?.grades.find((g) => g.id === fee.grade_id)?.name}</td><td>{query.data.types.find((t) => t.id === fee.fee_type_id)?.name}</td><td className="num">{fee.amount.toLocaleString("ar-SD")}</td><td dir="ltr">{fee.due_date ?? "—"}</td><td className="whitespace-pre-wrap">{fee.description ?? "—"}</td><td className="num">{ids.length}</td><td className="num">{expectedOptionalTotal(fee.amount, ids.length).toLocaleString("ar-SD")}</td><td><Button variant="outline" size="sm" onClick={() => { setAssignId(fee.id); setSelection(ids); setWarning([]); setConfirmRemoval(false); }}>{manager ? "إسناد الطلاب" : "عرض الطلاب"}</Button></td></tr>;
        })}</tbody></table>
      {!query.data?.structures.length && <Empty title="لا توجد رسوم اختيارية في العام الحالي" />}
    </div>}
    <Dialog open={createOpen} onOpenChange={(open) => !create.isPending && setCreateOpen(open)}><DialogContent dir="rtl"><DialogHeader><DialogTitle>رسم اختياري جديد</DialogTitle></DialogHeader>
      <form className="space-y-3" onSubmit={(e) => { e.preventDefault(); create.mutate(); }}>
        <Field label="الصف"><select aria-label="الصف" className="field-select w-full" required value={form.grade_id} onChange={(e) => setForm({ ...form, grade_id: e.target.value })}><option value="">اختر الصف</option>{roster.data?.grades.map((g) => <option value={g.id} key={g.id}>{g.name}</option>)}</select></Field>
        <Field label="نوع الرسم"><select aria-label="نوع الرسم" className="field-select w-full" value={form.fee_type_id} onChange={(e) => setForm({ ...form, fee_type_id: e.target.value })}><option value="">نوع جديد</option>{query.data?.types.filter((t) => t.is_active).map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}</select></Field>
        {!form.fee_type_id && <Field label="اسم النوع الجديد"><Input aria-label="اسم النوع الجديد" maxLength={100} required value={form.new_type} onChange={(e) => setForm({ ...form, new_type: e.target.value })} /></Field>}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3"><Field label="المبلغ"><Input aria-label="المبلغ" type="number" min="0.01" step="0.01" required value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} /></Field><Field label="تاريخ الاستحقاق"><Input aria-label="تاريخ الاستحقاق" type="date" value={form.due_date} onChange={(e) => setForm({ ...form, due_date: e.target.value })} /></Field></div>
        <Field label="الوصف"><Textarea aria-label="الوصف" maxLength={1000} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></Field>
        <Button disabled={create.isPending}>حفظ</Button>
      </form>
    </DialogContent></Dialog>
    <Dialog open={!!assignId} onOpenChange={(open) => { if (!open && !saveAssignments.isPending) setAssignId(null); }}><DialogContent dir="rtl"><DialogHeader><DialogTitle>الطلاب المسندون للرسم</DialogTitle></DialogHeader>
      <SearchChecklist label="الطلاب" options={eligible.map((s) => ({ id: s.id, label: `${s.student_number} — ${s.full_name}` }))} selected={selection} disabled={!manager || saveAssignments.isPending} onChange={(ids) => { setSelection(ids); setWarning([]); setConfirmRemoval(false); }} />
      {selection.some((id) => !eligible.some((s) => s.id === id)) && <div className="space-y-2"><p className="text-xs text-muted-foreground">إسنادات سابقة خارج قائمة المسجلين الحالية</p>{selection.filter((id) => !eligible.some((s) => s.id === id)).map((id) => <div key={id} className="flex items-center justify-between gap-2 text-sm"><span>{roster.data?.students.find((s) => s.id === id)?.full_name ?? id}</span>{manager && <Button variant="ghost" size="sm" disabled={saveAssignments.isPending} onClick={() => { setSelection(selection.filter((s) => s !== id)); setWarning([]); setConfirmRemoval(false); }}>إلغاء الإسناد</Button>}</div>)}</div>}
      {!!warning.length && <div role="alert" className="border border-warning rounded-md p-3 text-sm space-y-2"><p>تنبيه: توجد مدفوعات لهذا النوع لدى {warning.length} من الطلاب الذين سيُلغى إسنادهم. الإلغاء لا يحذف المدفوعات.</p><label className="flex gap-2"><input type="checkbox" checked={confirmRemoval} onChange={(e) => setConfirmRemoval(e.target.checked)} />أؤكد إلغاء الإسناد مع بقاء المدفوعات</label></div>}
      {manager && <Button disabled={saveAssignments.isPending || (!!warning.length && !confirmRemoval)} onClick={() => saveAssignments.mutate()}>حفظ الإسنادات</Button>}
    </DialogContent></Dialog>
  </div>;
}