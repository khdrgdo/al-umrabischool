import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useSchool, useMe, canManage, errMsg } from "@/lib/staff";
import { matchesStudentNumber } from "@/lib/studentNumber";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { PageHead, Empty, StatusMark, ENROLL_TYPE, Field } from "@/components/app/kit";
import { StudentForm, emptyStudent } from "@/components/app/StudentForm";

export const Route = createFileRoute("/_authenticated/students/")({
  head: () => ({ meta: [{ title: "سجل الطلاب — مدرسة العمرابي" }] }),
  component: Students,
});

type Sec = { id: string; name: string; grade_id: string; grade: { name: string; level_order: number } | null; track: { name: string } | null; spec: { name: string } | null };

function Students() {
  const qc = useQueryClient();
  const navigate = useNavigate();
  const { data: school } = useSchool();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);
  const [q, setQ] = useState("");
  const [grade, setGrade] = useState("");
  const [section, setSection] = useState("");
  const [status, setStatus] = useState("active");
  const [open, setOpen] = useState(false);
  const [newSec, setNewSec] = useState("");
  const [newType, setNewType] = useState("new");

  const { data } = useQuery({
    queryKey: ["students"],
    queryFn: async () => {
      const { data: year } = await supabase.from("academic_years").select("*").eq("is_current", true).maybeSingle();
      const [students, sections, enr, grades] = await Promise.all([
        supabase.from("students").select("*").order("full_name"),
        year ? supabase.from("sections").select("id,name,grade_id,grade:grades(name,level_order),track:tracks(name),spec:specializations(name)").eq("academic_year_id", year.id) : Promise.resolve({ data: [] }),
        year ? supabase.from("enrollments").select("student_id,section_id,enrollment_type").eq("academic_year_id", year.id) : Promise.resolve({ data: [] }),
        supabase.from("grades").select("*").order("level_order"),
      ]);
      return { year, students: students.data ?? [], sections: (sections.data ?? []) as Sec[], enr: (enr.data ?? []) as { student_id: string; section_id: string; enrollment_type: string }[], grades: grades.data ?? [] };
    },
  });

  const secById = useMemo(() => new Map((data?.sections ?? []).map((s) => [s.id, s])), [data]);
  const enrBy = useMemo(() => new Map((data?.enr ?? []).map((e) => [e.student_id, e])), [data]);

  const rows = (data?.students ?? []).filter((s) => {
    const e = enrBy.get(s.id); const sec = e ? secById.get(e.section_id) : undefined;
    if (status && s.status !== status) return false;
    if (grade && sec?.grade_id !== grade) return false;
    if (section === "none" ? !!e : section && e?.section_id !== section) return false;
    if (q && !s.full_name.includes(q) && !matchesStudentNumber(s.student_number, q) && !(s.guardian_phone ?? "").includes(q)) return false;
    return true;
  });

  const create = useMutation({
    mutationFn: async (v: typeof emptyStudent) => {
      if (!data?.year) throw new Error("لا يوجد عام دراسي حالي. حدّد العام الحالي في الهيكل أولًا.");
      if (!newSec) throw new Error("اختر الشعبة التي يُقيَّد فيها الطالب");
      if (newType === "transfer_in" && !v.previous_school?.trim()) throw new Error("اذكر المدرسة السابقة للطالب المنقول");
      // One transaction in the database: the file and the yearly enrollment are created together or not at all.
      const { data: id, error } = await supabase.rpc("create_student_with_enrollment", {
        _student: { ...v, school_id: school!.id },
        _academic_year: data.year.id,
        _section: newSec,
        _enrollment_type: newType as "new" | "transfer_in",
      });
      if (error) throw error;
      return id as string;
    },
    onSuccess: (id) => { setOpen(false); setNewSec(""); setNewType("new"); qc.invalidateQueries(); toast.success("تم فتح ملف الطالب وقيده"); navigate({ to: "/students/$id", params: { id } }); },
    onError: (e) => toast.error(errMsg(e)),
  });

  const sections = (data?.sections ?? []).filter((s) => !grade || s.grade_id === grade).sort((a, b) => (a.grade?.level_order ?? 0) - (b.grade?.level_order ?? 0));
  const secFull = (s: Sec) => [s.grade?.name, s.track?.name, s.spec?.name, s.name].filter(Boolean).join(" / ");
  const label = (s?: Sec) => (s ? `${s.grade?.name.replace("الصف ", "")} / ${s.name}` : "");

  function exportCsv() {
    const head = ["الرقم", "الاسم", "النوع", "الصف/الشعبة", "ولي الأمر", "الهاتف", "الحالة"];
    const lines = rows.map((s) => [s.student_number, s.full_name, s.gender === "female" ? "أنثى" : "ذكر", label(secById.get(enrBy.get(s.id)?.section_id ?? "")), s.guardian_name ?? "", s.guardian_phone ?? "", s.status]);
    const csv = "\uFEFF" + [head, ...lines].map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(",")).join("\n");
    const a = document.createElement("a");
    a.href = URL.createObjectURL(new Blob([csv], { type: "text/csv" }));
    a.download = "students.csv"; a.click();
  }

  return (
    <div>
      <PageHead
        title="سجل الطلاب"
        sub={`${rows.length} من أصل ${data?.students.length ?? 0} طالب · العام ${data?.year?.name ?? "—"}`}
        actions={<>
          <Button variant="outline" onClick={exportCsv}>تصدير القائمة</Button>
          {manager && <Button onClick={() => setOpen(true)}>فتح ملف طالب</Button>}
        </>}
      />
      <div className="flex flex-wrap gap-2 mb-4">
        <Input className="w-64" placeholder="بحث بالاسم أو الرقم المدرسي أو هاتف ولي الأمر" value={q} onChange={(e) => setQ(e.target.value)} />
        <select className="field-select" value={grade} onChange={(e) => { setGrade(e.target.value); setSection(""); }}>
          <option value="">كل الصفوف</option>
          {data?.grades.map((g) => <option key={g.id} value={g.id}>{g.name}</option>)}
        </select>
        <select className="field-select" value={section} onChange={(e) => setSection(e.target.value)}>
          <option value="">كل الشعب</option>
          {sections.map((s) => <option key={s.id} value={s.id}>{label(s)}</option>)}
          <option value="none">غير مسجلين هذا العام</option>
        </select>
        <select className="field-select" value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="">كل الحالات</option>
          <option value="active">منتظم</option><option value="transferred_out">منقول</option>
          <option value="withdrawn">منسحب</option><option value="graduated">متخرج</option><option value="suspended">موقوف</option>
        </select>
      </div>
      <div className="sheet overflow-x-auto">
        <table className="ledger">
          <thead>
            <tr><th>#</th><th>الرقم المدرسي</th><th>الاسم</th><th>الصف / الشعبة</th><th>نوع القيد</th><th>ولي الأمر</th><th>الهاتف</th><th>الحالة</th></tr>
          </thead>
          <tbody>
            {rows.map((s, i) => {
              const e = enrBy.get(s.id);
              return (
                <tr key={s.id} className="cursor-pointer" onClick={() => navigate({ to: "/students/$id", params: { id: s.id } })}>
                  <td className="num">{i + 1}</td>
                  <td className="num" dir="ltr">{s.student_number}</td>
                  <td><Link to="/students/$id" params={{ id: s.id }} className="font-medium hover:underline">{s.full_name}</Link></td>
                  <td>{e ? label(secById.get(e.section_id)) : <span className="text-stamp text-xs">غير مسجل</span>}</td>
                  <td className="text-xs text-muted-foreground">{e ? ENROLL_TYPE[e.enrollment_type] : ""}</td>
                  <td>{s.guardian_name}</td>
                  <td className="num" dir="ltr">{s.guardian_phone}</td>
                  <td><StatusMark status={s.status} /></td>
                </tr>
              );
            })}
          </tbody>
        </table>
        {rows.length === 0 && <Empty>لا توجد نتائج مطابقة</Empty>}
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader><DialogTitle className="font-display text-2xl">فتح ملف طالب جديد</DialogTitle></DialogHeader>
          <StudentForm
            initial={emptyStudent}
            busy={create.isPending}
            submitLabel="حفظ الملف"
            onSubmit={(v) => create.mutate(v)}
            extra={!data?.year ? (
              <p className="text-sm text-stamp border-t pt-4">لا يوجد عام دراسي حالي، لذلك لا يمكن فتح ملف الآن.</p>
            ) : (
              <fieldset className="grid sm:grid-cols-2 gap-3 border-t pt-4">
                <legend className="text-sm font-medium mb-2">القيد في العام {data.year.name}</legend>
                <Field label="تصنيف التسجيل *" className="sm:col-span-2">
                  <div className="flex gap-4 text-sm">
                    <label className="flex items-center gap-2"><input type="radio" name="etype" checked={newType === "new"} onChange={() => setNewType("new")} /> مستجد — أول مرة في المدرسة</label>
                    <label className="flex items-center gap-2"><input type="radio" name="etype" checked={newType === "transfer_in"} onChange={() => setNewType("transfer_in")} /> منقول من مدرسة أخرى</label>
                  </div>
                  {newType === "transfer_in" && <p className="text-xs text-muted-foreground mt-1">املأ حقل «المدرسة السابقة» أعلاه.</p>}
                </Field>
                <Field label="الصف / المسار / التخصص / الشعبة *" className="sm:col-span-2">
                  <select className="field-select w-full" value={newSec} onChange={(e) => setNewSec(e.target.value)} required>
                    <option value="">اختر الشعبة…</option>
                    {[...data.sections].sort((a, b) => (a.grade?.level_order ?? 0) - (b.grade?.level_order ?? 0)).map((s) => <option key={s.id} value={s.id}>{secFull(s)}</option>)}
                  </select>
                </Field>
              </fieldset>
            )}
          />
        </DialogContent>
      </Dialog>
    </div>
  );
}
