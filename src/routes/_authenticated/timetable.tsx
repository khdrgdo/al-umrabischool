import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useMe, useSchool, canManage, errMsg } from "@/lib/staff";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { PageHead, Field, Empty, WEEKDAYS } from "@/components/app/kit";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/_authenticated/timetable")({
  validateSearch: (s: Record<string, unknown>) => ({ section: typeof s.section === "string" ? s.section : undefined }),
  head: () => ({ meta: [{ title: "الجدول الدراسي — مدرسة العمرابي" }] }),
  component: Timetable,
});

type Tab = "section" | "teacher" | "assign" | "settings";

function useTT() {
  return useQuery({
    queryKey: ["tt"],
    queryFn: async () => {
      const { data: year } = await supabase.from("academic_years").select("*").eq("is_current", true).maybeSingle();
      const y = year?.id ?? "00000000-0000-0000-0000-000000000000";
      const [periods, days, sections, subjects, teachers, assigns, entries, status] = await Promise.all([
        supabase.from("periods").select("*").order("period_order"),
        supabase.from("school_days").select("*").order("weekday"),
        supabase.from("sections").select("id,name,grade:grades(name,level_order)").eq("academic_year_id", y),
        supabase.from("subjects").select("id,name,code").order("name"),
        supabase.from("teachers").select("id,full_name,is_active").order("full_name"),
        supabase.from("teaching_assignments").select("*").eq("academic_year_id", y),
        supabase.from("timetable_entries").select("*").eq("academic_year_id", y),
        supabase.from("section_timetables").select("*"),
      ]);
      const secs = ((sections.data ?? []) as { id: string; name: string; grade: { name: string; level_order: number } | null }[])
        .sort((a, b) => (a.grade?.level_order ?? 0) - (b.grade?.level_order ?? 0) || a.name.localeCompare(b.name));
      return { year, periods: periods.data ?? [], days: (days.data ?? []).map((d) => d.weekday), sections: secs, subjects: subjects.data ?? [], teachers: teachers.data ?? [], assigns: assigns.data ?? [], entries: entries.data ?? [], status: status.data ?? [] };
    },
  });
}
type TT = NonNullable<ReturnType<typeof useTT>["data"]>;

function Timetable() {
  const { data } = useTT();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);
  const [tab, setTab] = useState<Tab>("section");
  const tabs: [Tab, string][] = [["section", "جدول الشعبة"], ["teacher", "جدول المعلم"], ["assign", "إسناد المواد"], ["settings", "الحصص وأيام الدراسة"]];
  return (
    <div>
      <PageHead title="الجدول الدراسي" sub={`العام ${data?.year?.name ?? "—"}`} />
      <div className="flex gap-1 border-b mb-6 overflow-x-auto">
        {tabs.map(([k, l]) => (
          <button key={k} onClick={() => setTab(k)} className={cn("px-4 py-2 text-sm -mb-px border-b-2 whitespace-nowrap", tab === k ? "border-stamp" : "border-transparent text-muted-foreground")}>{l}</button>
        ))}
      </div>
      {!data ? <Empty>جارٍ التحميل…</Empty> : !data.year ? <Empty>حدد العام الدراسي الحالي أولًا من صفحة الصفوف والشعب.</Empty> : (
        <>
          {tab === "section" && <SectionGrid d={data} manager={manager} />}
          {tab === "teacher" && <TeacherGrid d={data} />}
          {tab === "assign" && <Assignments d={data} manager={manager} />}
          {tab === "settings" && <Settings d={data} manager={manager} />}
        </>
      )}
    </div>
  );
}

const secLabel = (s?: { name: string; grade: { name: string } | null }) => (s ? `${s.grade?.name.replace("الصف ", "")} / ${s.name}` : "");

function SectionGrid({ d, manager }: { d: TT; manager: boolean }) {
  const qc = useQueryClient();
  const search = Route.useSearch();
  const navigate = useNavigate({ from: "/timetable" });
  const sectionId = search.section ?? d.sections[0]?.id;
  const [cell, setCell] = useState<{ day: number; period: string } | null>(null);
  const [assignId, setAssignId] = useState("");
  const [room, setRoom] = useState("");
  const st = d.status.find((s) => s.section_id === sectionId);
  const entries = d.entries.filter((e) => e.section_id === sectionId);
  const assigns = d.assigns.filter((a) => a.section_id === sectionId);
  const subj = (id: string) => d.subjects.find((s) => s.id === id);
  const teacher = (id: string) => d.teachers.find((t) => t.id === id);
  const current = cell ? entries.find((e) => e.weekday === cell.day && e.period_id === cell.period) : undefined;

  const save = useMutation({
    mutationFn: async () => {
      const a = assigns.find((x) => x.id === assignId)!;
      const clash = d.entries.find((e) => e.teacher_id === a.teacher_id && e.weekday === cell!.day && e.period_id === cell!.period && e.section_id !== sectionId);
      if (clash) throw new Error(`المعلم ${teacher(a.teacher_id)?.full_name} مشغول في هذه الحصة مع ${secLabel(d.sections.find((s) => s.id === clash.section_id))}`);
      if (current) {
        const { error } = await supabase.from("timetable_entries").update({ subject_id: a.subject_id, teacher_id: a.teacher_id, room: room || null }).eq("id", current.id);
        if (error) throw error;
      } else {
        const { error } = await supabase.from("timetable_entries").insert({ academic_year_id: d.year!.id, section_id: sectionId!, weekday: cell!.day, period_id: cell!.period, subject_id: a.subject_id, teacher_id: a.teacher_id, room: room || null });
        if (error) throw error;
      }
      if (!st) await supabase.from("section_timetables").insert({ section_id: sectionId! });
    },
    onSuccess: () => { setCell(null); qc.invalidateQueries({ queryKey: ["tt"] }); toast.success("حُفظت الحصة — الجدول عاد إلى مسودة"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const clear = useMutation({
    mutationFn: async () => { const { error } = await supabase.from("timetable_entries").delete().eq("id", current!.id); if (error) throw error; },
    onSuccess: () => { setCell(null); qc.invalidateQueries({ queryKey: ["tt"] }); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const approve = useMutation({
    mutationFn: async () => {
      const row = { section_id: sectionId!, status: "approved" as const, approved_by: (await supabase.auth.getUser()).data.user?.id, approved_at: new Date().toISOString() };
      const { error } = await supabase.from("section_timetables").upsert(row);
      if (error) throw error;
    },
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["tt"] }); toast.success("اعتُمد الجدول رسميًا"); },
    onError: (e) => toast.error(errMsg(e)),
  });

  // weekly load check
  const loadRows = assigns.map((a) => ({ a, placed: entries.filter((e) => e.subject_id === a.subject_id).length }));

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center gap-3">
        <select className="field-select" value={sectionId ?? ""} onChange={(e) => navigate({ search: { section: e.target.value } })}>
          {d.sections.map((s) => <option key={s.id} value={s.id}>{secLabel(s)}</option>)}
        </select>
        <span className={cn("stamp", st?.status === "approved" ? "text-ok" : "text-stamp")}>{st?.status === "approved" ? "جدول معتمد" : "مسودة — غير رسمي"}</span>
        {manager && st?.status !== "approved" && entries.length > 0 && (
          <Button size="sm" onClick={() => approve.mutate()} disabled={approve.isPending}>اعتماد الجدول</Button>
        )}
        <Button size="sm" variant="outline" onClick={() => window.print()}>طباعة</Button>
      </div>

      <div className="sheet overflow-x-auto">
        <table className="w-full border-collapse text-sm min-w-[720px]">
          <thead>
            <tr>
              <th className="p-2 border-b-2 border-ink text-start w-20">اليوم</th>
              {d.periods.map((p) => (
                <th key={p.id} className={cn("p-2 border-b-2 border-ink font-normal", p.is_break && "bg-muted")}>
                  <div className="font-medium">{p.label}</div>
                  <div className="text-xs text-muted-foreground num" dir="ltr">{p.starts_at.slice(0, 5)}–{p.ends_at.slice(0, 5)}</div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {d.days.map((day) => (
              <tr key={day}>
                <td className="p-2 border-b border-rule font-medium">{WEEKDAYS[day]}</td>
                {d.periods.map((p) => {
                  if (p.is_break) return <td key={p.id} className="border-b border-s border-rule bg-muted" />;
                  const e = entries.find((x) => x.weekday === day && x.period_id === p.id);
                  return (
                    <td key={p.id} className="border-b border-s border-rule p-0 align-top">
                      <button
                        disabled={!manager}
                        onClick={() => { setCell({ day, period: p.id }); const a = e && assigns.find((x) => x.subject_id === e.subject_id); setAssignId(a?.id ?? ""); setRoom(e?.room ?? ""); }}
                        className="w-full min-h-14 p-2 text-start hover:bg-accent disabled:cursor-default"
                      >
                        {e ? (
                          <>
                            <div className="font-medium leading-tight">{subj(e.subject_id)?.name}</div>
                            <div className="text-xs text-muted-foreground leading-tight mt-0.5">{teacher(e.teacher_id)?.full_name.split(" ").slice(0, 2).join(" ")}</div>
                            {e.room && <div className="text-xs text-primary">{e.room}</div>}
                          </>
                        ) : manager ? <span className="text-xs text-muted-foreground/50">+</span> : null}
                      </button>
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div>
        <h3 className="section-title">مطابقة الحصص الأسبوعية</h3>
        <table className="ledger max-w-xl">
          <thead><tr><th>المادة</th><th>المعلم</th><th>المطلوب</th><th>الموزَّع</th></tr></thead>
          <tbody>
            {loadRows.map(({ a, placed }) => (
              <tr key={a.id}>
                <td>{subj(a.subject_id)?.name}</td><td>{teacher(a.teacher_id)?.full_name}</td>
                <td className="num">{a.weekly_periods ?? "—"}</td>
                <td className={cn("num", a.weekly_periods && placed !== a.weekly_periods && "text-stamp font-medium")}>{placed}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {loadRows.length === 0 && <p className="text-sm text-muted-foreground">لم تُسند مواد لهذه الشعبة. ابدأ من تبويب "إسناد المواد".</p>}
      </div>

      <Dialog open={!!cell} onOpenChange={(o) => !o && setCell(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle className="font-display text-xl">{cell && `${WEEKDAYS[cell.day]} — الحصة ${d.periods.find((p) => p.id === cell.period)?.label}`}</DialogTitle></DialogHeader>
          <Field label="المادة والمعلم">
            <select className="field-select w-full" value={assignId} onChange={(e) => setAssignId(e.target.value)}>
              <option value="">اختر</option>
              {assigns.map((a) => <option key={a.id} value={a.id}>{subj(a.subject_id)?.name} — {teacher(a.teacher_id)?.full_name}</option>)}
            </select>
          </Field>
          <Field label="القاعة (اختياري)"><Input value={room} onChange={(e) => setRoom(e.target.value)} placeholder="معمل الحاسوب، معمل الكيمياء…" /></Field>
          <div className="flex gap-2">
            <Button disabled={!assignId || save.isPending} onClick={() => save.mutate()}>حفظ</Button>
            {current && <Button variant="outline" onClick={() => clear.mutate()}>إفراغ الحصة</Button>}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function TeacherGrid({ d }: { d: TT }) {
  const [tid, setTid] = useState(d.teachers[0]?.id ?? "");
  const entries = d.entries.filter((e) => e.teacher_id === tid);
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <select className="field-select" value={tid} onChange={(e) => setTid(e.target.value)}>
          {d.teachers.map((t) => <option key={t.id} value={t.id}>{t.full_name}</option>)}
        </select>
        <span className="text-sm text-muted-foreground">{entries.length} حصة أسبوعيًا</span>
      </div>
      <div className="sheet overflow-x-auto">
        <table className="w-full border-collapse text-sm min-w-[720px]">
          <thead><tr><th className="p-2 border-b-2 border-ink text-start">اليوم</th>{d.periods.map((p) => <th key={p.id} className={cn("p-2 border-b-2 border-ink font-medium", p.is_break && "bg-muted")}>{p.label}</th>)}</tr></thead>
          <tbody>
            {d.days.map((day) => (
              <tr key={day}>
                <td className="p-2 border-b border-rule font-medium">{WEEKDAYS[day]}</td>
                {d.periods.map((p) => {
                  const e = entries.find((x) => x.weekday === day && x.period_id === p.id);
                  return (
                    <td key={p.id} className={cn("border-b border-s border-rule p-2 h-14 align-top", p.is_break && "bg-muted")}>
                      {e && <><div className="font-medium leading-tight">{secLabel(d.sections.find((s) => s.id === e.section_id))}</div><div className="text-xs text-muted-foreground">{d.subjects.find((s) => s.id === e.subject_id)?.name}</div></>}
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function Assignments({ d, manager }: { d: TT; manager: boolean }) {
  const qc = useQueryClient();
  const [sec, setSec] = useState(d.sections[0]?.id ?? "");
  const [subject, setSubject] = useState("");
  const [teacher, setTeacher] = useState("");
  const [n, setN] = useState("");
  const rows = d.assigns.filter((a) => a.section_id === sec);
  const refresh = () => qc.invalidateQueries({ queryKey: ["tt"] });
  const add = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.from("teaching_assignments").insert({ academic_year_id: d.year!.id, section_id: sec, subject_id: subject, teacher_id: teacher, weekly_periods: n ? Number(n) : null });
      if (error) throw error;
    },
    onSuccess: () => { setSubject(""); setTeacher(""); setN(""); refresh(); toast.success("أُسندت المادة"); },
    onError: (e) => toast.error(errMsg(e).includes("موجود") ? "هذه المادة مسندة لهذه الشعبة مسبقًا — عدّلها من الجدول" : errMsg(e)),
  });
  const update = useMutation({
    mutationFn: async (v: { id: string; teacher_id?: string; weekly_periods?: number | null }) => {
      const { id, ...rest } = v;
      const { error } = await supabase.from("teaching_assignments").update(rest).eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => { refresh(); toast.success("حُفظ التعديل"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const remove = useMutation({
    mutationFn: async (id: string) => { const { error } = await supabase.from("teaching_assignments").delete().eq("id", id); if (error) throw error; },
    onSuccess: refresh,
    onError: (e) => toast.error(errMsg(e)),
  });
  const total = rows.reduce((s, r) => s + (r.weekly_periods ?? 0), 0);
  const slots = d.days.length * d.periods.filter((p) => !p.is_break).length;
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <select className="field-select" value={sec} onChange={(e) => setSec(e.target.value)}>
          {d.sections.map((s) => <option key={s.id} value={s.id}>{secLabel(s)}</option>)}
        </select>
        <span className={cn("text-sm", total > slots ? "text-stamp" : "text-muted-foreground")}>{total} حصة مطلوبة من {slots} متاحة</span>
      </div>
      <div className="sheet overflow-x-auto">
        <table className="ledger">
          <thead><tr><th>المادة</th><th>المعلم</th><th>حصص أسبوعيًا</th>{manager && <th />}</tr></thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id}>
                <td>{d.subjects.find((s) => s.id === r.subject_id)?.name}</td>
                <td>
                  <select className="field-select" disabled={!manager} value={r.teacher_id} onChange={(e) => update.mutate({ id: r.id, teacher_id: e.target.value })}>
                    {d.teachers.filter((t) => t.is_active || t.id === r.teacher_id).map((t) => <option key={t.id} value={t.id}>{t.full_name}</option>)}
                  </select>
                </td>
                <td><Input type="number" min={1} className="w-20" disabled={!manager} defaultValue={r.weekly_periods ?? ""} onBlur={(e) => update.mutate({ id: r.id, weekly_periods: e.target.value ? Number(e.target.value) : null })} /></td>
                {manager && <td><Button size="sm" variant="ghost" onClick={() => remove.mutate(r.id)}>إلغاء الإسناد</Button></td>}
              </tr>
            ))}
          </tbody>
        </table>
        {rows.length === 0 && <Empty>لا توجد مواد مسندة</Empty>}
      </div>
      {manager && (
        <form className="flex flex-wrap gap-2 items-end" onSubmit={(e) => { e.preventDefault(); add.mutate(); }}>
          <Field label="المادة"><select className="field-select" value={subject} onChange={(e) => setSubject(e.target.value)} required><option value="">اختر</option>{d.subjects.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}</select></Field>
          <Field label="المعلم"><select className="field-select" value={teacher} onChange={(e) => setTeacher(e.target.value)} required><option value="">اختر</option>{d.teachers.filter((t) => t.is_active).map((t) => <option key={t.id} value={t.id}>{t.full_name}</option>)}</select></Field>
          <Field label="حصص/أسبوع"><Input type="number" min={1} className="w-24" value={n} onChange={(e) => setN(e.target.value)} /></Field>
          <Button disabled={add.isPending}>إسناد</Button>
        </form>
      )}
    </div>
  );
}

function Settings({ d, manager }: { d: TT; manager: boolean }) {
  const qc = useQueryClient();
  const { data: school } = useSchool();
  const refresh = () => qc.invalidateQueries({ queryKey: ["tt"] });
  const [np, setNp] = useState({ label: "", starts_at: "", ends_at: "", is_break: false });
  const toggleDay = useMutation({
    mutationFn: async (w: number) => {
      const { error } = d.days.includes(w)
        ? await supabase.from("school_days").delete().eq("weekday", w).eq("school_id", school!.id)
        : await supabase.from("school_days").insert({ weekday: w, school_id: school!.id });
      if (error) throw error;
    },
    onSuccess: refresh,
    onError: (e) => toast.error(errMsg(e)),
  });
  const updP = useMutation({
    mutationFn: async (v: { id: string; label?: string; starts_at?: string; ends_at?: string; is_break?: boolean }) => {
      const { id, ...rest } = v; const { error } = await supabase.from("periods").update(rest).eq("id", id); if (error) throw error;
    },
    onSuccess: () => { refresh(); toast.success("حُفظ"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const addP = useMutation({
    mutationFn: async () => {
      const order = Math.max(0, ...d.periods.map((p) => p.period_order)) + 1;
      const { error } = await supabase.from("periods").insert({ ...np, school_id: school!.id, period_order: order }); if (error) throw error;
    },
    onSuccess: () => { setNp({ label: "", starts_at: "", ends_at: "", is_break: false }); refresh(); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const delP = useMutation({
    mutationFn: async (id: string) => { const { error } = await supabase.from("periods").delete().eq("id", id); if (error) throw error; },
    onSuccess: refresh,
    onError: () => toast.error("لا يمكن حذف حصة مستخدمة في جدول — أفرغها أولًا"),
  });
  return (
    <div className="grid lg:grid-cols-3 gap-8">
      <section>
        <h3 className="section-title">أيام الدراسة</h3>
        <div className="flex flex-wrap gap-2">
          {WEEKDAYS.map((w, i) => (
            <button key={w} disabled={!manager} onClick={() => toggleDay.mutate(i)} className={cn("px-3 py-1.5 border text-sm", d.days.includes(i) ? "bg-ink text-paper border-ink" : "border-rule text-muted-foreground")}>{w}</button>
          ))}
        </div>
      </section>
      <section className="lg:col-span-2">
        <h3 className="section-title">الحصص والفسح</h3>
        <table className="ledger">
          <thead><tr><th>#</th><th>الاسم</th><th>من</th><th>إلى</th><th>فسحة</th>{manager && <th />}</tr></thead>
          <tbody>
            {d.periods.map((p) => (
              <tr key={p.id}>
                <td className="num">{p.period_order}</td>
                <td><Input className="w-28" disabled={!manager} defaultValue={p.label} onBlur={(e) => e.target.value !== p.label && updP.mutate({ id: p.id, label: e.target.value })} /></td>
                <td><Input type="time" className="w-28" disabled={!manager} defaultValue={p.starts_at.slice(0, 5)} onBlur={(e) => updP.mutate({ id: p.id, starts_at: e.target.value })} /></td>
                <td><Input type="time" className="w-28" disabled={!manager} defaultValue={p.ends_at.slice(0, 5)} onBlur={(e) => updP.mutate({ id: p.id, ends_at: e.target.value })} /></td>
                <td><input type="checkbox" disabled={!manager} checked={p.is_break} onChange={(e) => updP.mutate({ id: p.id, is_break: e.target.checked })} /></td>
                {manager && <td><Button size="sm" variant="ghost" onClick={() => delP.mutate(p.id)}>حذف</Button></td>}
              </tr>
            ))}
          </tbody>
        </table>
        {manager && (
          <form className="flex flex-wrap gap-2 items-end mt-4" onSubmit={(e) => { e.preventDefault(); addP.mutate(); }}>
            <Field label="الاسم"><Input className="w-28" value={np.label} onChange={(e) => setNp({ ...np, label: e.target.value })} required /></Field>
            <Field label="من"><Input type="time" value={np.starts_at} onChange={(e) => setNp({ ...np, starts_at: e.target.value })} required /></Field>
            <Field label="إلى"><Input type="time" value={np.ends_at} onChange={(e) => setNp({ ...np, ends_at: e.target.value })} required /></Field>
            <label className="flex items-center gap-1 text-sm h-9"><input type="checkbox" checked={np.is_break} onChange={(e) => setNp({ ...np, is_break: e.target.checked })} />فسحة</label>
            <Button>إضافة حصة</Button>
          </form>
        )}
      </section>
    </div>
  );
}
