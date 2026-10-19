import { createFileRoute, Link } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useMe, canManage, errMsg } from "@/lib/staff";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { PageHead, Field, StatusMark, ENROLL_TYPE, STATUS_LABEL, Empty } from "@/components/app/kit";
import { StudentForm, type StudentInput } from "@/components/app/StudentForm";

export const Route = createFileRoute("/_authenticated/students/$id")({
  head: () => ({ meta: [{ title: "ملف الطالب — مدرسة العمرابي" }] }),
  component: StudentPage,
});

const ENR_STATUS: Record<string, string> = { active: "جارٍ", promoted: "نُقل للصف التالي", repeated: "أعاد العام", transferred_out: "انتقل", withdrawn: "انسحب", graduated: "تخرج" };

function StudentPage() {
  const { id } = Route.useParams();
  const qc = useQueryClient();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);
  const [editing, setEditing] = useState(false);
  const [newStatus, setNewStatus] = useState("");
  const [reason, setReason] = useState("");
  const [moveTo, setMoveTo] = useState("");
  const [enrollSec, setEnrollSec] = useState("");
  const [enrollType, setEnrollType] = useState("continuing");

  const { data, isLoading } = useQuery({
    queryKey: ["student", id],
    queryFn: async () => {
      const { data: year } = await supabase.from("academic_years").select("*").eq("is_current", true).maybeSingle();
      const [s, enr, hist, secs] = await Promise.all([
        supabase.from("students").select("*").eq("id", id).single(),
        supabase.from("enrollments").select("*, year:academic_years(name,is_current), section:sections(name, grade:grades(name), track:tracks(name), spec:specializations(name))").eq("student_id", id).order("created_at", { ascending: false }),
        supabase.from("student_status_history").select("*").eq("student_id", id).order("changed_at", { ascending: false }),
        year ? supabase.from("sections").select("id,name,grade:grades(name,level_order)").eq("academic_year_id", year.id) : Promise.resolve({ data: [] }),
      ]);
      if (s.error) throw s.error;
      return { year, s: s.data, enr: enr.data ?? [], hist: hist.data ?? [], secs: (secs.data ?? []) as { id: string; name: string; grade: { name: string; level_order: number } | null }[] };
    },
  });
  const refresh = () => qc.invalidateQueries();

  const save = useMutation({
    mutationFn: async (v: StudentInput) => { const { error } = await supabase.from("students").update(v).eq("id", id); if (error) throw error; },
    onSuccess: () => { setEditing(false); refresh(); toast.success("حُفظت التعديلات"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const changeStatus = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.rpc("change_student_status", { _student: id, _status: newStatus as "active", _reason: reason });
      if (error) throw error;
      const cur = data?.enr.find((e) => e.year?.is_current);
      const map: Record<string, string> = { transferred_out: "transferred_out", withdrawn: "withdrawn", graduated: "graduated" };
      if (cur && map[newStatus]) {
        const { error: e2 } = await supabase.from("enrollments").update({ status: map[newStatus] as "withdrawn" }).eq("id", cur.id);
        if (e2) throw e2;
      }
    },
    onSuccess: () => { setNewStatus(""); setReason(""); refresh(); toast.success("تم تغيير الحالة وتسجيل السبب"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const move = useMutation({
    mutationFn: async (enrId: string) => { const { error } = await supabase.from("enrollments").update({ section_id: moveTo }).eq("id", enrId); if (error) throw error; },
    onSuccess: () => { setMoveTo(""); refresh(); toast.success("نُقل الطالب إلى الشعبة الجديدة"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const enroll = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.from("enrollments").insert({ student_id: id, section_id: enrollSec, academic_year_id: data!.year!.id, enrollment_type: enrollType as "new" });
      if (error) throw error;
    },
    onSuccess: () => { setEnrollSec(""); refresh(); toast.success("تم القيد"); },
    onError: (e) => toast.error(errMsg(e)),
  });

  if (isLoading || !data) return <Empty>جارٍ التحميل…</Empty>;
  const s = data.s;
  const current = data.enr.find((e) => e.year?.is_current);
  const secLabel = (x: { id: string; name: string; grade: { name: string } | null }) => `${x.grade?.name} / ${x.name}`;
  const age = s.birth_date ? Math.floor((Date.now() - new Date(s.birth_date).getTime()) / 3.15576e10) : null;

  return (
    <div>
      <Link to="/students" className="text-sm text-muted-foreground hover:underline">← سجل الطلاب</Link>
      <PageHead
        title={s.full_name}
        sub={<span dir="ltr" className="num">#{s.student_number}</span>}
        actions={<><StatusMark status={s.status} />{manager && !editing && <Button variant="outline" onClick={() => setEditing(true)}>تعديل البيانات</Button>}</>}
      />

      <div className="grid lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 space-y-8">
          {editing ? (
            <div className="sheet p-5">
              <StudentForm
                initial={{ student_number: s.student_number, full_name: s.full_name, gender: s.gender, birth_date: s.birth_date, national_id: s.national_id, address: s.address, guardian_name: s.guardian_name, guardian_relation: s.guardian_relation, guardian_phone: s.guardian_phone, previous_school: s.previous_school, notes: s.notes }}
                busy={save.isPending} submitLabel="حفظ التعديلات" onSubmit={(v) => save.mutate(v)}
              />
              <Button variant="ghost" className="mt-2" onClick={() => setEditing(false)}>إلغاء</Button>
            </div>
          ) : (
            <section>
              <h2 className="section-title">البيانات الأساسية</h2>
              <dl className="grid sm:grid-cols-2 gap-x-8 text-sm">
                {[
                  ["النوع", s.gender === "female" ? "أنثى" : s.gender === "male" ? "ذكر" : "—"],
                  ["تاريخ الميلاد", s.birth_date ? `${s.birth_date} (${age} سنة)` : "—"],
                  ["الرقم الوطني", s.national_id ?? "—"],
                  ["السكن", s.address ?? "—"],
                  ["المدرسة السابقة", s.previous_school ?? "—"],
                  ["ولي الأمر", s.guardian_name ? `${s.guardian_name}${s.guardian_relation ? ` (${s.guardian_relation})` : ""}` : "—"],
                  ["هاتف ولي الأمر", s.guardian_phone ?? "—"],
                  ["ملاحظات", s.notes ?? "—"],
                ].map(([k, v]) => (
                  <div key={k} className="flex justify-between gap-4 border-b border-rule py-2">
                    <dt className="text-muted-foreground">{k}</dt><dd className="text-end">{v}</dd>
                  </div>
                ))}
              </dl>
            </section>
          )}

          <section>
            <h2 className="section-title">السجل الدراسي</h2>
            <div className="sheet overflow-x-auto">
              <table className="ledger">
                <thead><tr><th>العام</th><th>الصف</th><th>الشعبة</th><th>نوع القيد</th><th>النتيجة / الحالة</th></tr></thead>
                <tbody>
                  {data.enr.map((e) => (
                    <tr key={e.id}>
                      <td>{e.year?.name}{e.year?.is_current && <span className="text-xs text-ok ms-2">(الحالي)</span>}</td>
                      <td>{e.section?.grade?.name}</td>
                      <td>{e.section?.name}</td>
                      <td>{ENROLL_TYPE[e.enrollment_type]}</td>
                      <td>{ENR_STATUS[e.status]}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {data.enr.length === 0 && <Empty>لا يوجد قيد دراسي</Empty>}
            </div>
          </section>

          <section>
            <h2 className="section-title">تاريخ تغيير الحالة</h2>
            {data.hist.length === 0 ? <p className="text-sm text-muted-foreground">لم تتغير حالة الطالب منذ فتح الملف.</p> : (
              <ul className="space-y-2 text-sm">
                {data.hist.map((h) => (
                  <li key={h.id} className="border-s-2 border-stamp ps-3">
                    <b>{STATUS_LABEL[h.old_status ?? ""] ?? "—"} ← {STATUS_LABEL[h.new_status]}</b>
                    <span className="text-muted-foreground"> · {new Date(h.changed_at).toLocaleDateString("ar-SD")}</span>
                    <div>{h.reason}</div>
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>

        {manager && (
          <aside className="space-y-6">
            <div className="sheet p-4 space-y-3">
              <h3 className="text-lg">القيد في العام الحالي</h3>
              {!data.year ? <p className="text-sm text-muted-foreground">لم يُحدَّد عام دراسي حالي.</p> : current ? (
                <>
                  <p className="text-sm">{current.section?.grade?.name} / {current.section?.name}</p>
                  <Field label="النقل إلى شعبة أخرى">
                    <select className="field-select w-full" value={moveTo} onChange={(e) => setMoveTo(e.target.value)}>
                      <option value="">اختر الشعبة</option>
                      {data.secs.filter((x) => x.id !== current.section_id).map((x) => <option key={x.id} value={x.id}>{secLabel(x)}</option>)}
                    </select>
                  </Field>
                  <Button size="sm" disabled={!moveTo || move.isPending} onClick={() => move.mutate(current.id)}>نقل</Button>
                </>
              ) : (
                <>
                  <p className="text-sm text-stamp">غير مقيّد في {data.year.name}</p>
                  <select className="field-select w-full" value={enrollSec} onChange={(e) => setEnrollSec(e.target.value)}>
                    <option value="">اختر الشعبة</option>
                    {data.secs.map((x) => <option key={x.id} value={x.id}>{secLabel(x)}</option>)}
                  </select>
                  <select className="field-select w-full" value={enrollType} onChange={(e) => setEnrollType(e.target.value)}>
                    {Object.entries(ENROLL_TYPE).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                  </select>
                  <Button size="sm" disabled={!enrollSec || enroll.isPending} onClick={() => enroll.mutate()}>قيد</Button>
                </>
              )}
            </div>

            <div className="sheet p-4 space-y-3">
              <h3 className="text-lg">تغيير حالة الطالب</h3>
              <select className="field-select w-full" value={newStatus} onChange={(e) => setNewStatus(e.target.value)}>
                <option value="">اختر الحالة الجديدة</option>
                {Object.entries(STATUS_LABEL).filter(([k]) => k !== s.status).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
              </select>
              <Input placeholder="السبب (إلزامي) — مثال: انتقل إلى مدرسة الدامر" value={reason} onChange={(e) => setReason(e.target.value)} />
              <Button size="sm" variant="destructive" disabled={!newStatus || !reason.trim() || changeStatus.isPending} onClick={() => changeStatus.mutate()}>تأكيد التغيير</Button>
              <p className="text-xs text-muted-foreground">لا يُحذف ملف الطالب أبدًا؛ يُحفظ السبب في السجل.</p>
            </div>
          </aside>
        )}
      </div>
    </div>
  );
}
