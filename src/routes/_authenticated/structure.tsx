import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useSchool, errMsg } from "@/lib/staff";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

export const Route = createFileRoute("/_authenticated/structure")({
  head: () => ({ meta: [{ title: "الهيكل الدراسي — مدرسة العمرابي" }] }),
  component: Structure,
});

const sel = "h-9 rounded-md border border-input bg-card px-2 text-sm";

function Structure() {
  const qc = useQueryClient();
  const { data: school } = useSchool();
  const { data } = useQuery({
    queryKey: ["structure"],
    queryFn: async () => {
      const [years, grades, tracks, specs, sections] = await Promise.all([
        supabase.from("academic_years").select("*").order("name", { ascending: false }),
        supabase.from("grades").select("*").order("level_order"),
        supabase.from("tracks").select("*"),
        supabase.from("specializations").select("*"),
        supabase.from("sections").select("*").order("name"),
      ]);
      return { years: years.data ?? [], grades: grades.data ?? [], tracks: tracks.data ?? [], specs: specs.data ?? [], sections: sections.data ?? [] };
    },
  });
  const refresh = () => qc.invalidateQueries();

  const [yearName, setYearName] = useState("");
  const addYear = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.from("academic_years").insert({ school_id: school!.id, name: yearName });
      if (error) throw error;
    },
    onSuccess: () => { setYearName(""); refresh(); toast.success("أضيفت السنة الدراسية"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const setCurrent = useMutation({
    mutationFn: async (id: string) => {
      const cur = data?.years.find((y) => y.is_current);
      if (cur) {
        const { error } = await supabase.from("academic_years").update({ is_current: false }).eq("id", cur.id);
        if (error) throw error;
      }
      const { error } = await supabase.from("academic_years").update({ is_current: true }).eq("id", id);
      if (error) throw error;
    },
    onSuccess: refresh,
    onError: (e) => toast.error(errMsg(e)),
  });

  const [sec, setSec] = useState({ year: "", grade: "", track: "", spec: "", name: "" });
  const addSection = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.from("sections").insert({
        academic_year_id: sec.year, grade_id: sec.grade,
        track_id: sec.track || null, specialization_id: sec.spec || null, name: sec.name,
      });
      if (error) throw error;
    },
    onSuccess: () => { setSec({ ...sec, name: "" }); refresh(); toast.success("أضيفت الشعبة"); },
    onError: (e) => toast.error(errMsg(e)),
  });

  const name = (arr: { id: string; name: string }[] | undefined, id: string | null) => arr?.find((x) => x.id === id)?.name;
  const tracksFor = data?.tracks.filter((t) => t.grade_id === sec.grade) ?? [];
  const specsFor = data?.specs.filter((s) => s.track_id === sec.track) ?? [];

  return (
    <div className="space-y-8">
      <h1 className="text-3xl font-bold text-primary">الهيكل الدراسي</h1>

      <section className="space-y-3">
        <h2 className="text-xl font-bold">السنوات الدراسية</h2>
        <Card className="p-4">
          <form className="flex gap-2" onSubmit={(e) => { e.preventDefault(); addYear.mutate(); }}>
            <Input placeholder="مثال: 2026/2027" value={yearName} onChange={(e) => setYearName(e.target.value)} required />
            <Button disabled={!school}>إضافة</Button>
          </form>
        </Card>
        <div className="flex flex-wrap gap-2">
          {data?.years.map((y) => (
            <Card key={y.id} className="px-4 py-2 flex items-center gap-3">
              <span>{y.name}</span>
              {y.is_current ? <Badge>الحالية</Badge> : (
                <Button size="sm" variant="ghost" onClick={() => setCurrent.mutate(y.id)}>اجعلها الحالية</Button>
              )}
            </Card>
          ))}
        </div>
      </section>

      <section className="space-y-3">
        <h2 className="text-xl font-bold">الصفوف والمسارات والتخصصات</h2>
        <div className="grid md:grid-cols-3 gap-3">
          {data?.grades.map((g) => (
            <Card key={g.id} className="p-4">
              <div className="font-bold text-primary">{g.name}</div>
              {data.tracks.filter((t) => t.grade_id === g.id).map((t) => (
                <div key={t.id} className="mt-2 text-sm">
                  {t.name}
                  <div className="flex flex-wrap gap-1 mt-1">
                    {data.specs.filter((s) => s.track_id === t.id).map((s) => <Badge key={s.id} variant="secondary">{s.name}</Badge>)}
                  </div>
                </div>
              ))}
            </Card>
          ))}
        </div>
      </section>

      <section className="space-y-3">
        <h2 className="text-xl font-bold">الشعب (الفصول)</h2>
        <Card className="p-4">
          <form className="flex flex-wrap gap-2" onSubmit={(e) => { e.preventDefault(); addSection.mutate(); }}>
            <select className={sel} value={sec.year} onChange={(e) => setSec({ ...sec, year: e.target.value })} required>
              <option value="">السنة</option>
              {data?.years.map((y) => <option key={y.id} value={y.id}>{y.name}</option>)}
            </select>
            <select className={sel} value={sec.grade} onChange={(e) => setSec({ ...sec, grade: e.target.value, track: "", spec: "" })} required>
              <option value="">الصف</option>
              {data?.grades.map((g) => <option key={g.id} value={g.id}>{g.name}</option>)}
            </select>
            {tracksFor.length > 0 && (
              <select className={sel} value={sec.track} onChange={(e) => setSec({ ...sec, track: e.target.value, spec: "" })}>
                <option value="">المسار</option>
                {tracksFor.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
              </select>
            )}
            {specsFor.length > 0 && (
              <select className={sel} value={sec.spec} onChange={(e) => setSec({ ...sec, spec: e.target.value })}>
                <option value="">التخصص</option>
                {specsFor.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
            )}
            <Input className="w-32" placeholder="اسم الشعبة" value={sec.name} onChange={(e) => setSec({ ...sec, name: e.target.value })} required />
            <Button>إضافة</Button>
          </form>
        </Card>
        <Card className="divide-y">
          {data?.sections.length === 0 && <p className="p-6 text-center text-muted-foreground">لا توجد شعب بعد</p>}
          {data?.sections.map((s) => (
            <div key={s.id} className="p-3 text-sm flex flex-wrap gap-2">
              <b>{s.name}</b>
              <span>{name(data.grades, s.grade_id)}</span>
              {s.track_id && <span>· {name(data.tracks, s.track_id)}</span>}
              {s.specialization_id && <span>· {name(data.specs, s.specialization_id)}</span>}
              <span className="text-muted-foreground">· {name(data.years, s.academic_year_id)}</span>
            </div>
          ))}
        </Card>
      </section>
    </div>
  );
}
