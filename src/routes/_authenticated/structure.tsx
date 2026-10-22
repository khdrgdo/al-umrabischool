import { schoolPageHead } from "@/lib/pageHead";
import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useSchool, useMe, canManage, errMsg } from "@/lib/staff";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { PageHead, Field, Empty } from "@/components/app/kit";

export const Route = createFileRoute("/_authenticated/structure")({
  head: () => schoolPageHead("الصفوف والشعب — مدرسة العمرابي", "الصفوف والشعب في نظام إدارة مدرسة العمرابي الثانوية."),
  component: Structure,
});

type SecForm = { id?: string; academic_year_id: string; grade_id: string; track_id: string; specialization_id: string; name: string; capacity: string };

function Structure() {
  const qc = useQueryClient();
  const { data: school } = useSchool();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);
  const { data } = useQuery({
    queryKey: ["structure"],
    queryFn: async () => {
      const [years, grades, tracks, specs, sections, enr] = await Promise.all([
        supabase.from("academic_years").select("*").order("name", { ascending: false }),
        supabase.from("grades").select("*").order("level_order"),
        supabase.from("tracks").select("*").order("name"),
        supabase.from("specializations").select("*").order("name"),
        supabase.from("sections").select("*").order("name"),
        supabase.from("enrollments").select("section_id").eq("status", "active"),
      ]);
      return { years: years.data ?? [], grades: grades.data ?? [], tracks: tracks.data ?? [], specs: specs.data ?? [], sections: sections.data ?? [], enr: enr.data ?? [] };
    },
  });
  const refresh = () => qc.invalidateQueries();
  const run = (fn: () => PromiseLike<{ error: unknown }>, ok?: string) => async () => {
    const { error } = await fn(); if (error) { toast.error(errMsg(error)); return false; } if (ok) toast.success(ok); refresh(); return true;
  };

  const [yearSel, setYearSel] = useState("");
  const viewYear = yearSel || data?.years.find((y) => y.is_current)?.id || data?.years[0]?.id || "";
  const [yf, setYf] = useState<{ id?: string; name: string; starts_on: string; ends_on: string } | null>(null);
  const [sf, setSf] = useState<SecForm | null>(null);
  const [newTrack, setNewTrack] = useState<{ grade: string; name: string }>({ grade: "", name: "" });
  const [newSpec, setNewSpec] = useState<{ track: string; name: string }>({ track: "", name: "" });

  const saveYear = useMutation({
    mutationFn: async () => {
      const row = { name: yf!.name, starts_on: yf!.starts_on || null, ends_on: yf!.ends_on || null };
      const { error } = yf!.id ? await supabase.from("academic_years").update(row).eq("id", yf!.id) : await supabase.from("academic_years").insert({ ...row, school_id: school!.id });
      if (error) throw error;
    },
    onSuccess: () => { setYf(null); refresh(); toast.success("حُفظ العام الدراسي"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const setCurrent = useMutation({
    mutationFn: async (id: string) => {
      const cur = data?.years.find((y) => y.is_current);
      if (cur) { const { error } = await supabase.from("academic_years").update({ is_current: false }).eq("id", cur.id); if (error) throw error; }
      const { error } = await supabase.from("academic_years").update({ is_current: true }).eq("id", id); if (error) throw error;
    },
    onSuccess: () => { refresh(); toast.success("تغيّر العام الحالي"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const saveSec = useMutation({
    mutationFn: async () => {
      const f = sf!;
      const row = { academic_year_id: f.academic_year_id, grade_id: f.grade_id, track_id: f.track_id || null, specialization_id: f.specialization_id || null, name: f.name, capacity: f.capacity ? Number(f.capacity) : null };
      const { error } = f.id ? await supabase.from("sections").update(row).eq("id", f.id) : await supabase.from("sections").insert(row);
      if (error) throw error;
    },
    onSuccess: () => { setSf(null); refresh(); toast.success("حُفظت الشعبة"); },
    onError: (e) => toast.error(errMsg(e)),
  });

  const nm = (arr: { id: string; name: string }[] | undefined, id: string | null) => arr?.find((x) => x.id === id)?.name ?? "";
  const secs = (data?.sections ?? []).filter((s) => s.academic_year_id === viewYear)
    .sort((a, b) => (data!.grades.find((g) => g.id === a.grade_id)?.level_order ?? 0) - (data!.grades.find((g) => g.id === b.grade_id)?.level_order ?? 0));

  return (
    <div className="space-y-10">
      <PageHead title="الصفوف والشعب" sub="الأعوام الدراسية، الصفوف، المسارات، التخصصات، والشعب" />

      <section>
        <div className="flex items-center justify-between mb-3">
          <h2 className="section-title mb-0 border-0">الأعوام الدراسية</h2>
          {manager && <Button size="sm" variant="outline" onClick={() => setYf({ name: "", starts_on: "", ends_on: "" })}>عام جديد</Button>}
        </div>
        <div className="sheet overflow-x-auto">
          <table className="ledger">
            <thead><tr><th>العام</th><th>البداية</th><th>النهاية</th><th>الشعب</th><th>الحالة</th>{manager && <th />}</tr></thead>
            <tbody>
              {data?.years.map((y) => (
                <tr key={y.id}>
                  <td className="font-medium">{y.name}</td>
                  <td className="num">{y.starts_on ?? "—"}</td>
                  <td className="num">{y.ends_on ?? "—"}</td>
                  <td className="num">{data.sections.filter((s) => s.academic_year_id === y.id).length}</td>
                  <td>{y.is_current ? <span className="stamp text-ok">العام الحالي</span> : manager ? <Button size="sm" variant="ghost" onClick={() => setCurrent.mutate(y.id)}>اجعله الحالي</Button> : null}</td>
                  {manager && <td><Button size="sm" variant="ghost" onClick={() => setYf({ id: y.id, name: y.name, starts_on: y.starts_on ?? "", ends_on: y.ends_on ?? "" })}>تعديل</Button></td>}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section>
        <div className="flex flex-wrap items-center justify-between gap-2 mb-3">
          <div className="flex items-center gap-3">
            <h2 className="font-display text-xl">الشعب في عام</h2>
            <select className="field-select" value={viewYear} onChange={(e) => setYearSel(e.target.value)}>
              {data?.years.map((y) => <option key={y.id} value={y.id}>{y.name}</option>)}
            </select>
          </div>
          {manager && <Button size="sm" onClick={() => setSf({ academic_year_id: viewYear, grade_id: "", track_id: "", specialization_id: "", name: "", capacity: "" })}>شعبة جديدة</Button>}
        </div>
        <div className="sheet overflow-x-auto">
          <table className="ledger">
            <thead><tr><th>الصف</th><th>الشعبة</th><th>المسار</th><th>التخصص</th><th>الطلاب</th><th>السعة</th>{manager && <th />}</tr></thead>
            <tbody>
              {secs.map((s) => (
                <tr key={s.id}>
                  <td>{nm(data!.grades, s.grade_id)}</td>
                  <td className="font-medium">{s.name}</td>
                  <td>{nm(data!.tracks, s.track_id) || "—"}</td>
                  <td>{nm(data!.specs, s.specialization_id) || "—"}</td>
                  <td className="num">{data!.enr.filter((e) => e.section_id === s.id).length}</td>
                  <td className="num">{s.capacity ?? "—"}</td>
                  {manager && <td><Button size="sm" variant="ghost" onClick={() => setSf({ id: s.id, academic_year_id: s.academic_year_id, grade_id: s.grade_id, track_id: s.track_id ?? "", specialization_id: s.specialization_id ?? "", name: s.name, capacity: s.capacity?.toString() ?? "" })}>تعديل</Button></td>}
                </tr>
              ))}
            </tbody>
          </table>
          {secs.length === 0 && <Empty>لا توجد شعب في هذا العام</Empty>}
        </div>
      </section>

      <section>
        <h2 className="section-title">الصفوف والمسارات والتخصصات</h2>
        <div className="grid md:grid-cols-3 gap-6">
          {data?.grades.map((g) => (
            <div key={g.id} className="sheet p-4">
              <EditableName value={g.name} disabled={!manager} onSave={(name) => run(() => supabase.from("grades").update({ name }).eq("id", g.id), "حُفظ")()} className="font-display text-lg" />
              {data.tracks.filter((t) => t.grade_id === g.id).map((t) => (
                <div key={t.id} className="mt-3 border-s-2 border-primary ps-3">
                  <EditableName value={t.name} disabled={!manager} onSave={(name) => run(() => supabase.from("tracks").update({ name }).eq("id", t.id), "حُفظ")()} className="text-sm font-medium" />
                  <ul className="text-sm text-muted-foreground mt-1 space-y-0.5">
                    {data.specs.filter((s) => s.track_id === t.id).map((s) => (
                      <li key={s.id}>— <EditableName value={s.name} disabled={!manager} onSave={(name) => run(() => supabase.from("specializations").update({ name }).eq("id", s.id), "حُفظ")()} /></li>
                    ))}
                  </ul>
                  {manager && (
                    <form className="flex gap-1 mt-2" onSubmit={async (e) => { e.preventDefault(); if (await run(() => supabase.from("specializations").insert({ track_id: t.id, name: newSpec.name }), "أُضيف التخصص")()) setNewSpec({ track: "", name: "" }); }}>
                      <Input className="h-8 text-xs" placeholder="تخصص جديد" value={newSpec.track === t.id ? newSpec.name : ""} onChange={(e) => setNewSpec({ track: t.id, name: e.target.value })} required />
                      <Button size="sm" variant="outline" className="h-8">+</Button>
                    </form>
                  )}
                </div>
              ))}
              {manager && (
                <form className="flex gap-1 mt-3" onSubmit={async (e) => { e.preventDefault(); if (await run(() => supabase.from("tracks").insert({ grade_id: g.id, name: newTrack.name }), "أُضيف المسار")()) setNewTrack({ grade: "", name: "" }); }}>
                  <Input className="h-8 text-xs" placeholder="مسار جديد" value={newTrack.grade === g.id ? newTrack.name : ""} onChange={(e) => setNewTrack({ grade: g.id, name: e.target.value })} required />
                  <Button size="sm" variant="outline" className="h-8">+</Button>
                </form>
              )}
            </div>
          ))}
        </div>
      </section>

      <Dialog open={!!yf} onOpenChange={(o) => !o && setYf(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle className="font-display text-xl">{yf?.id ? "تعديل العام الدراسي" : "عام دراسي جديد"}</DialogTitle></DialogHeader>
          {yf && (
            <form className="space-y-3" onSubmit={(e) => { e.preventDefault(); saveYear.mutate(); }}>
              <Field label="اسم العام"><Input value={yf.name} onChange={(e) => setYf({ ...yf, name: e.target.value })} placeholder="2027/2028" required /></Field>
              <div className="grid grid-cols-2 gap-3">
                <Field label="البداية"><Input type="date" value={yf.starts_on} onChange={(e) => setYf({ ...yf, starts_on: e.target.value })} /></Field>
                <Field label="النهاية"><Input type="date" value={yf.ends_on} onChange={(e) => setYf({ ...yf, ends_on: e.target.value })} /></Field>
              </div>
              <Button disabled={saveYear.isPending}>حفظ</Button>
            </form>
          )}
        </DialogContent>
      </Dialog>

      <Dialog open={!!sf} onOpenChange={(o) => !o && setSf(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle className="font-display text-xl">{sf?.id ? "تعديل الشعبة" : "شعبة جديدة"}</DialogTitle></DialogHeader>
          {sf && data && (
            <form className="grid grid-cols-2 gap-3" onSubmit={(e) => { e.preventDefault(); saveSec.mutate(); }}>
              <Field label="العام" className="col-span-2">
                <select className="field-select w-full" value={sf.academic_year_id} onChange={(e) => setSf({ ...sf, academic_year_id: e.target.value })} required>
                  {data.years.map((y) => <option key={y.id} value={y.id}>{y.name}</option>)}
                </select>
              </Field>
              <Field label="الصف" className="col-span-2">
                <select className="field-select w-full" value={sf.grade_id} onChange={(e) => setSf({ ...sf, grade_id: e.target.value, track_id: "", specialization_id: "" })} required>
                  <option value="">اختر</option>{data.grades.map((g) => <option key={g.id} value={g.id}>{g.name}</option>)}
                </select>
              </Field>
              <Field label="المسار">
                <select className="field-select w-full" value={sf.track_id} onChange={(e) => setSf({ ...sf, track_id: e.target.value, specialization_id: "" })}>
                  <option value="">—</option>{data.tracks.filter((t) => t.grade_id === sf.grade_id).map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
                </select>
              </Field>
              <Field label="التخصص">
                <select className="field-select w-full" value={sf.specialization_id} onChange={(e) => setSf({ ...sf, specialization_id: e.target.value })}>
                  <option value="">—</option>{data.specs.filter((s) => s.track_id === sf.track_id).map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
                </select>
              </Field>
              <Field label="اسم الشعبة"><Input value={sf.name} onChange={(e) => setSf({ ...sf, name: e.target.value })} placeholder="أ" required /></Field>
              <Field label="السعة"><Input type="number" min={1} value={sf.capacity} onChange={(e) => setSf({ ...sf, capacity: e.target.value })} /></Field>
              <Button className="col-span-2" disabled={saveSec.isPending}>حفظ</Button>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}

function EditableName({ value, onSave, disabled, className }: { value: string; onSave: (v: string) => void; disabled?: boolean; className?: string }) {
  const [edit, setEdit] = useState(false);
  const [v, setV] = useState(value);
  if (!edit) return <span className={className} onDoubleClick={() => !disabled && setEdit(true)} title={disabled ? undefined : "انقر مرتين للتعديل"}>{value}</span>;
  return (
    <form className="inline-flex gap-1" onSubmit={(e) => { e.preventDefault(); onSave(v); setEdit(false); }}>
      <Input autoFocus className="h-7 text-sm" value={v} onChange={(e) => setV(e.target.value)} onBlur={() => setEdit(false)} />
    </form>
  );
}
