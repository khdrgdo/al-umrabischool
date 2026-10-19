import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { PageHead, Stat, WEEKDAYS } from "@/components/app/kit";

export const Route = createFileRoute("/_authenticated/dashboard")({
  head: () => ({ meta: [{ title: "الملخص — مدرسة العمرابي" }] }),
  component: Dashboard,
});

function Dashboard() {
  const { data } = useQuery({
    queryKey: ["dash"],
    queryFn: async () => {
      const { data: year } = await supabase.from("academic_years").select("*").eq("is_current", true).maybeSingle();
      const [students, teachers, subjects, sections, enr, tts] = await Promise.all([
        supabase.from("students").select("id,gender,status"),
        supabase.from("teachers").select("id", { count: "exact", head: true }).eq("is_active", true),
        supabase.from("subjects").select("id", { count: "exact", head: true }).eq("is_active", true),
        year ? supabase.from("sections").select("id,name,capacity,grade:grades(name,level_order)").eq("academic_year_id", year.id) : Promise.resolve({ data: [] as never[] }),
        year ? supabase.from("enrollments").select("section_id,status").eq("academic_year_id", year.id) : Promise.resolve({ data: [] as never[] }),
        supabase.from("section_timetables").select("section_id,status"),
      ]);
      return { year, students: students.data ?? [], teachers: teachers.count ?? 0, subjects: subjects.count ?? 0, sections: (sections.data ?? []) as { id: string; name: string; capacity: number | null; grade: { name: string; level_order: number } | null }[], enr: enr.data ?? [], tts: tts.data ?? [] };
    },
  });

  const active = data?.students.filter((s) => s.status === "active") ?? [];
  const girls = active.filter((s) => s.gender === "female").length;
  const sections = [...(data?.sections ?? [])].sort((a, b) => (a.grade?.level_order ?? 0) - (b.grade?.level_order ?? 0) || a.name.localeCompare(b.name));
  const today = new Date().getDay();

  return (
    <div>
      <PageHead
        title="ملخص المدرسة"
        sub={<>العام الدراسي {data?.year?.name ?? "—"} · اليوم {WEEKDAYS[today]} {new Date().toLocaleDateString("ar-SD", { day: "numeric", month: "long", year: "numeric" })}</>}
      />
      <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-10">
        <Stat label="الطلاب المنتظمون" value={active.length} note={`${active.length - girls} بنين · ${girls} بنات`} />
        <Stat label="الشعب هذا العام" value={sections.length} />
        <Stat label="المعلمون العاملون" value={data?.teachers ?? "—"} />
        <Stat label="المواد المفعّلة" value={data?.subjects ?? "—"} />
      </div>

      <h2 className="section-title">توزيع الطلاب على الشعب</h2>
      <div className="sheet overflow-x-auto">
        <table className="ledger">
          <thead>
            <tr><th>الصف</th><th>الشعبة</th><th>عدد الطلاب</th><th>السعة</th><th>الإشغال</th><th>الجدول</th></tr>
          </thead>
          <tbody>
            {sections.map((s) => {
              const n = data!.enr.filter((e) => e.section_id === s.id && e.status === "active").length;
              const tt = data!.tts.find((t) => t.section_id === s.id)?.status;
              const pct = s.capacity ? Math.round((n / s.capacity) * 100) : null;
              return (
                <tr key={s.id}>
                  <td>{s.grade?.name}</td>
                  <td className="font-medium">{s.name}</td>
                  <td className="num">{n}</td>
                  <td className="num">{s.capacity ?? "—"}</td>
                  <td>
                    {pct !== null && (
                      <div className="flex items-center gap-2">
                        <div className="h-1.5 w-24 bg-muted"><div className="h-full bg-primary" style={{ width: `${Math.min(pct, 100)}%` }} /></div>
                        <span className="num text-xs">{pct}%</span>
                      </div>
                    )}
                  </td>
                  <td>
                    <Link to="/timetable" search={{ section: s.id }} className="underline underline-offset-4">
                      {tt === "approved" ? "معتمد" : tt === "draft" ? "مسودة" : "غير مُعد"}
                    </Link>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
