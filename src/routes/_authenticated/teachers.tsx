import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useSchool, useMe, canManage, errMsg } from "@/lib/staff";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { PageHead, Field, Empty } from "@/components/app/kit";

export const Route = createFileRoute("/_authenticated/teachers")({
  head: () => ({ meta: [{ title: "المعلمون — مدرسة العمرابي" }] }),
  component: Teachers,
});

type TF = { id?: string; full_name: string; phone: string; qualification: string; hired_on: string; notes: string; is_active: boolean };

function Teachers() {
  const qc = useQueryClient();
  const { data: school } = useSchool();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);
  const [f, setF] = useState<TF | null>(null);
  const [q, setQ] = useState("");
  const { data } = useQuery({
    queryKey: ["teachers"],
    queryFn: async () => {
      const { data: year } = await supabase.from("academic_years").select("id").eq("is_current", true).maybeSingle();
      const [t, a] = await Promise.all([
        supabase.from("teachers").select("*").order("full_name"),
        supabase.from("teaching_assignments").select("teacher_id,weekly_periods,subject:subjects(name),section:sections(name,grade:grades(name))").eq("academic_year_id", year?.id ?? "00000000-0000-0000-0000-000000000000"),
      ]);
      return { teachers: t.data ?? [], assigns: (a.data ?? []) as { teacher_id: string; weekly_periods: number | null; subject: { name: string } | null; section: { name: string; grade: { name: string } | null } | null }[] };
    },
  });
  const save = useMutation({
    mutationFn: async () => {
      const row = { full_name: f!.full_name, phone: f!.phone || null, qualification: f!.qualification || null, hired_on: f!.hired_on || null, notes: f!.notes || null, is_active: f!.is_active };
      const { error } = f!.id ? await supabase.from("teachers").update(row).eq("id", f!.id) : await supabase.from("teachers").insert({ ...row, school_id: school!.id });
      if (error) throw error;
    },
    onSuccess: () => { setF(null); qc.invalidateQueries(); toast.success("حُفظت بيانات المعلم"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const rows = (data?.teachers ?? []).filter((t) => !q || t.full_name.includes(q));
  return (
    <div>
      <PageHead title="المعلمون" sub={`${data?.teachers.filter((t) => t.is_active).length ?? 0} معلم عامل`}
        actions={manager && <Button onClick={() => setF({ full_name: "", phone: "", qualification: "", hired_on: "", notes: "", is_active: true })}>إضافة معلم</Button>} />
      <Input className="w-64 mb-4" placeholder="بحث بالاسم" value={q} onChange={(e) => setQ(e.target.value)} />
      <div className="sheet overflow-x-auto">
        <table className="ledger">
          <thead><tr><th>الاسم</th><th>المؤهل</th><th>الهاتف</th><th>المواد والشعب هذا العام</th><th>النصاب</th><th>الحالة</th>{manager && <th />}</tr></thead>
          <tbody>
            {rows.map((t) => {
              const as = data!.assigns.filter((a) => a.teacher_id === t.id);
              const load = as.reduce((s, a) => s + (a.weekly_periods ?? 0), 0);
              return (
                <tr key={t.id} className={t.is_active ? "" : "opacity-50"}>
                  <td className="font-medium">{t.full_name}</td>
                  <td className="text-xs">{t.qualification ?? "—"}</td>
                  <td className="num" dir="ltr">{t.phone}</td>
                  <td className="text-xs max-w-xs">{as.map((a) => `${a.subject?.name ?? "—"} (${(a.section?.grade?.name ? a.section.grade.name.replace("الصف ", "") : "")}/${a.section?.name ?? "—"})`).join("، ") || "—"}</td>
                  <td className="num">{load || "—"}</td>
                  <td>{t.is_active ? <span className="stamp text-ok">على رأس العمل</span> : <span className="stamp text-stamp">موقوف</span>}</td>
                  {manager && <td><Button size="sm" variant="ghost" onClick={() => setF({ id: t.id, full_name: t.full_name, phone: t.phone ?? "", qualification: t.qualification ?? "", hired_on: t.hired_on ?? "", notes: t.notes ?? "", is_active: t.is_active })}>تعديل</Button></td>}
                </tr>
              );
            })}
          </tbody>
        </table>
        {rows.length === 0 && <Empty>لا يوجد معلمون</Empty>}
      </div>
      <Dialog open={!!f} onOpenChange={(o) => !o && setF(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle className="font-display text-xl">{f?.id ? "تعديل بيانات المعلم" : "إضافة معلم"}</DialogTitle></DialogHeader>
          {f && (
            <form className="grid grid-cols-2 gap-3" onSubmit={(e) => { e.preventDefault(); save.mutate(); }}>
              <Field label="الاسم الكامل *" className="col-span-2"><Input value={f.full_name} onChange={(e) => setF({ ...f, full_name: e.target.value })} required /></Field>
              <Field label="المؤهل" className="col-span-2"><Input value={f.qualification} onChange={(e) => setF({ ...f, qualification: e.target.value })} /></Field>
              <Field label="الهاتف"><Input dir="ltr" value={f.phone} onChange={(e) => setF({ ...f, phone: e.target.value })} /></Field>
              <Field label="تاريخ التعيين"><Input type="date" value={f.hired_on} onChange={(e) => setF({ ...f, hired_on: e.target.value })} /></Field>
              <Field label="ملاحظات" className="col-span-2"><Textarea rows={2} value={f.notes} onChange={(e) => setF({ ...f, notes: e.target.value })} /></Field>
              <label className="col-span-2 flex items-center gap-2 text-sm"><input type="checkbox" checked={f.is_active} onChange={(e) => setF({ ...f, is_active: e.target.checked })} />على رأس العمل</label>
              <Button className="col-span-2" disabled={save.isPending}>حفظ</Button>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
