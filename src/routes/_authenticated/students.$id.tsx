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
    <div className="space-y-6">
      <div>
        <Link to="/students" className="inline-flex items-center gap-1 text-xs text-primary font-medium hover:underline mb-2">
          <span>← العودة إلى سجل الطلاب</span>
        </Link>
        <PageHead
          title={s.full_name}
          sub={
            <div className="flex items-center gap-2">
              <span className="font-mono text-xs px-2 py-0.5 rounded-md bg-muted text-foreground font-semibold" dir="ltr">
                {s.student_number}
              </span>
              <span>·</span>
              <span className="text-xs text-muted-foreground">ملف أكاديمي مسجل</span>
            </div>
          }
          actions={
            <div className="flex items-center gap-2">
              <StatusMark status={s.status} />
              {manager && !editing && (
                <Button variant="outline" size="sm" onClick={() => setEditing(true)} className="h-9 text-xs">
                  تعديل البيانات
                </Button>
              )}
            </div>
          }
        />
      </div>

      <div className="grid lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          {editing ? (
            <div className="card-surface p-6">
              <h2 className="text-sm font-semibold text-foreground mb-4">تعديل بيانات الطالب</h2>
              <StudentForm
                studentNumber={s.student_number}
                initial={{
                  full_name: s.full_name,
                  gender: s.gender,
                  birth_date: s.birth_date,
                  national_id: s.national_id,
                  address: s.address,
                  guardian_name: s.guardian_name,
                  guardian_relation: s.guardian_relation,
                  guardian_phone: s.guardian_phone,
                  previous_school: s.previous_school,
                  notes: s.notes,
                }}
                busy={save.isPending}
                submitLabel="حفظ التعديلات"
                onSubmit={(v) => save.mutate(v)}
              />
              <Button variant="ghost" size="sm" className="mt-3 text-xs" onClick={() => setEditing(false)}>
                إلغاء التعديل
              </Button>
            </div>
          ) : (
            <div className="card-surface p-6">
              <h2 className="text-sm font-semibold text-foreground pb-3 mb-4 border-b border-border flex items-center justify-between">
                <span>البيانات الشخصية والأساسية</span>
                <span className="text-xs text-muted-foreground font-normal">الملف العام</span>
              </h2>
              <dl className="grid sm:grid-cols-2 gap-x-8 gap-y-1 text-xs">
                {[
                  ["النوع", s.gender === "female" ? "أنثى" : s.gender === "male" ? "ذكر" : "—"],
                  ["تاريخ الميلاد", s.birth_date ? `${s.birth_date} (${age} سنة)` : "—"],
                  ["الرقم الوطني", s.national_id ?? "—"],
                  ["السكن والعنوان", s.address ?? "—"],
                  ["المدرسة السابقة", s.previous_school ?? "—"],
                  ["ولي الأمر", s.guardian_name ? `${s.guardian_name}${s.guardian_relation ? ` (${s.guardian_relation})` : ""}` : "—"],
                  ["هاتف ولي الأمر", s.guardian_phone ?? "—"],
                  ["ملاحظات إضافية", s.notes ?? "—"],
                ].map(([k, v]) => (
                  <div key={k} className="flex justify-between items-center gap-4 border-b border-border/50 py-2.5">
                    <dt className="text-muted-foreground font-medium">{k}</dt>
                    <dd className="text-foreground font-medium text-end">{v}</dd>
                  </div>
                ))}
              </dl>
            </div>
          )}

          <div className="card-surface overflow-hidden">
            <div className="p-4 border-b border-border flex items-center justify-between">
              <h2 className="text-sm font-semibold text-foreground">السجل الأكاديمي والتسجيل السنوي</h2>
              <span className="text-xs text-muted-foreground">{data.enr.length} تسجيل</span>
            </div>
            <div className="overflow-x-auto">
              <table className="modern-table">
                <thead>
                  <tr>
                    <th>العام الدراسي</th>
                    <th>الصف</th>
                    <th>الشعبة</th>
                    <th>نوع القيد</th>
                    <th>النتيجة / الحالة</th>
                  </tr>
                </thead>
                <tbody>
                  {data.enr.map((e) => (
                    <tr key={e.id}>
                      <td className="font-medium">
                        {e.year?.name}
                        {e.year?.is_current && (
                          <span className="text-[11px] text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200 ms-2">
                            العام الحالي
                          </span>
                        )}
                      </td>
                      <td>{e.section?.grade?.name ?? "—"}</td>
                      <td>
                        <span className="inline-flex px-2 py-0.5 bg-muted rounded text-xs font-semibold">
                          {e.section?.name ?? "—"}
                        </span>
                      </td>
                      <td className="text-xs text-muted-foreground">{ENROLL_TYPE[e.enrollment_type] ?? e.enrollment_type}</td>
                      <td>
                        <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-muted text-foreground">
                          {ENR_STATUS[e.status] ?? e.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {data.enr.length === 0 && (
                <Empty title="لا يوجد قيد دراسي مسجل لهذا الطالب" />
              )}
            </div>
          </div>

          <div className="card-surface p-6">
            <h2 className="text-sm font-semibold text-foreground pb-3 mb-4 border-b border-border flex items-center justify-between">
              <span>سجل التدقيق وتاريخ الحالات</span>
              <span className="text-xs text-muted-foreground font-normal">حركات موثقة</span>
            </h2>
            {data.hist.length === 0 ? (
              <p className="text-xs text-muted-foreground">لم تتغير حالة الطالب منذ فتح ملفه المدرسي.</p>
            ) : (
              <ul className="space-y-3">
                {data.hist.map((h) => (
                  <li key={h.id} className="border-s-2 border-primary ps-3 py-1">
                    <div className="text-xs font-semibold text-foreground">
                      <span>{STATUS_LABEL[h.old_status ?? ""] ?? "—"}</span>
                      <span className="mx-1 text-muted-foreground">←</span>
                      <span className="text-primary">{STATUS_LABEL[h.new_status]}</span>
                      <span className="text-muted-foreground font-normal ms-2">
                        · {new Date(h.changed_at).toLocaleDateString("ar-SD", { day: "numeric", month: "short", year: "numeric" })}
                      </span>
                    </div>
                    {h.reason && <div className="text-xs text-muted-foreground mt-1">{h.reason}</div>}
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>

        {manager && (
          <aside className="space-y-6">
            <div className="card-surface p-5 space-y-4">
              <div>
                <h3 className="text-sm font-semibold text-foreground">القيد في العام الحالي</h3>
                <p className="text-xs text-muted-foreground mt-0.5">الشعبة والصف الدراسي المقيد به</p>
              </div>
              {!data.year ? (
                <p className="text-xs text-muted-foreground">لم يُحدَّد عام دراسي حالي بعد.</p>
              ) : current ? (
                <div className="space-y-3">
                  <div className="p-3 bg-muted/50 rounded-lg border border-border/60">
                    <span className="text-xs text-muted-foreground block mb-1">الشعبة الحالية:</span>
                    <span className="text-sm font-bold text-foreground">
                      {current.section?.grade?.name} / {current.section?.name}
                    </span>
                  </div>
                  <Field label="النقل إلى شعبة أخرى في نفس العام">
                    <select
                      className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                      value={moveTo}
                      onChange={(e) => setMoveTo(e.target.value)}
                    >
                      <option value="">اختر الشعبة الجديدة…</option>
                      {data.secs
                        .filter((x) => x.id !== current.section_id)
                        .map((x) => (
                          <option key={x.id} value={x.id}>
                            {secLabel(x)}
                          </option>
                        ))}
                    </select>
                  </Field>
                  <Button
                    size="sm"
                    className="w-full h-9 text-xs"
                    disabled={!moveTo || move.isPending}
                    onClick={() => move.mutate(current.id)}
                  >
                    تأكيد نقل الشعبة
                  </Button>
                </div>
              ) : (
                <div className="space-y-3">
                  <p className="text-xs text-rose-600 bg-rose-50 p-2.5 rounded-lg border border-rose-200">
                    الطالب غير مقيّد في العام الحالي ({data?.year?.name})
                  </p>
                  <Field label="اختر الشعبة للقيد">
                    <select
                      className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                      value={enrollSec}
                      onChange={(e) => setEnrollSec(e.target.value)}
                    >
                      <option value="">اختر الشعبة…</option>
                      {data.secs.map((x) => (
                        <option key={x.id} value={x.id}>
                          {secLabel(x)}
                        </option>
                      ))}
                    </select>
                  </Field>
                  <Field label="نوع القيد">
                    <select
                      className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                      value={enrollType}
                      onChange={(e) => setEnrollType(e.target.value)}
                    >
                      {Object.entries(ENROLL_TYPE).map(([k, v]) => (
                        <option key={k} value={k}>
                          {v}
                        </option>
                      ))}
                    </select>
                  </Field>
                  <Button
                    size="sm"
                    className="w-full h-9 text-xs"
                    disabled={!enrollSec || enroll.isPending}
                    onClick={() => enroll.mutate()}
                  >
                    تسجيل وقيد الطالب
                  </Button>
                </div>
              )}
            </div>

            <div className="card-surface p-5 space-y-4">
              <div>
                <h3 className="text-sm font-semibold text-foreground">تغيير حالة الطالب</h3>
                <p className="text-xs text-muted-foreground mt-0.5">نقل، انسحاب، تخرج، أو إيقاف</p>
              </div>
              <Field label="الحالة الجديدة">
                <select
                  className="w-full h-9 px-3 rounded-lg border border-input bg-card text-xs focus:ring-1 focus:ring-primary focus:outline-hidden"
                  value={newStatus}
                  onChange={(e) => setNewStatus(e.target.value)}
                >
                  <option value="">اختر الحالة الجديدة…</option>
                  {Object.entries(STATUS_LABEL)
                    .filter(([k]) => k !== s.status)
                    .map(([k, v]) => (
                      <option key={k} value={k}>
                        {v}
                      </option>
                    ))}
                </select>
              </Field>
              <Field label="سبب التغيير (إلزامي للتدقيق)">
                <Input
                  placeholder="مثال: انتقال ولي الأمر لولاية أخرى…"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  className="h-9 text-xs"
                />
              </Field>
              <Button
                size="sm"
                variant="destructive"
                className="w-full h-9 text-xs"
                disabled={!newStatus || !reason.trim() || changeStatus.isPending}
                onClick={() => changeStatus.mutate()}
              >
                تأكيد تغيير الحالة
              </Button>
              <p className="text-[11px] text-muted-foreground text-center">
                وفق سياسة المدرسة، لا يُحذف سجل أي طالب، بل يُحفظ السبب والمستخدم في سجل التدقيق.
              </p>
            </div>
          </aside>
        )}
      </div>
    </div>
  );
}
