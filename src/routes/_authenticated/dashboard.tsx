import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { PageHead, StatCard, WEEKDAYS } from "@/components/app/kit";
import { Users, Layers, GraduationCap, BookOpen, Clock, CheckCircle2 } from "lucide-react";

export const Route = createFileRoute("/_authenticated/dashboard")({
  head: () => ({ meta: [{ title: "لوحة التحكم — مدرسة العمرابي" }] }),
  component: Dashboard,
});

function Dashboard() {
  const { data, isLoading } = useQuery({
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
    <div className="space-y-6">
      <PageHead
        title="لوحة التحكم والملخص العام"
        sub={
          <>
            <span>العام الدراسي: <strong className="text-foreground">{data?.year?.name ?? "—"}</strong></span>
            <span>·</span>
            <span>اليوم {WEEKDAYS[today]} {new Date().toLocaleDateString("ar-SD", { day: "numeric", month: "long", year: "numeric" })}</span>
          </>
        }
      />

      {/* KPI Cards (4 columns) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="الطلاب المنتظمون"
          value={isLoading ? "…" : active.length}
          note={`${active.length - girls} بنين · ${girls} بنات`}
          icon={<Users className="h-4 w-4" />}
          variant="primary"
        />
        <StatCard
          label="الشعب المفتوحة"
          value={isLoading ? "…" : sections.length}
          note="موزعة على كافة الصفوف"
          icon={<Layers className="h-4 w-4" />}
        />
        <StatCard
          label="الكادر التعليمي"
          value={isLoading ? "…" : (data?.teachers ?? "—")}
          note="معلم نشط في الخدمة"
          icon={<GraduationCap className="h-4 w-4" />}
          variant="success"
        />
        <StatCard
          label="المواد الدراسية"
          value={isLoading ? "…" : (data?.subjects ?? "—")}
          note="مادة معتمدة بالمنهج"
          icon={<BookOpen className="h-4 w-4" />}
        />
      </div>

      {/* Class distribution Table Panel */}
      <div className="card-surface overflow-hidden">
        <div className="p-4 md:p-5 border-b border-border flex items-center justify-between">
          <div>
            <h2 className="text-sm font-semibold text-foreground">توزيع الطلاب والإشغال حسب الشعب</h2>
            <p className="text-xs text-muted-foreground mt-0.5">متابعة السعة الاستيعابية وحالة الجدول المدرسي لكل شعبة</p>
          </div>
          <span className="text-xs font-medium px-2.5 py-1 rounded-full bg-muted text-muted-foreground">
            {sections.length} شعبة
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="modern-table">
            <thead>
              <tr>
                <th>الصف الدراسي</th>
                <th>الشعبة</th>
                <th>عدد الطلاب</th>
                <th>السعة الاستيعابية</th>
                <th>نسبة الإشغال</th>
                <th>الجدول المدرسي</th>
              </tr>
            </thead>
            <tbody>
              {sections.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center py-10 text-muted-foreground text-xs">
                    لا توجد شعب مسجلة لهذا العام الدراسي حتى الآن.
                  </td>
                </tr>
              ) : (
                sections.map((s) => {
                  const n = data!.enr.filter((e) => e.section_id === s.id && e.status === "active").length;
                  const tt = data!.tts.find((t) => t.section_id === s.id)?.status;
                  const pct = s.capacity ? Math.round((n / s.capacity) * 100) : null;
                  return (
                    <tr key={s.id}>
                      <td className="font-medium text-foreground">{s.grade?.name}</td>
                      <td>
                        <span className="inline-flex items-center px-2 py-0.5 rounded-md bg-muted text-xs font-semibold text-foreground">
                          {s.name}
                        </span>
                      </td>
                      <td className="num">{n} طالب</td>
                      <td className="num text-muted-foreground">{s.capacity ?? "—"}</td>
                      <td>
                        {pct !== null ? (
                          <div className="flex items-center gap-2 max-w-[160px]">
                            <div className="h-2 flex-1 rounded-full bg-muted overflow-hidden">
                              <div
                                className={`h-full rounded-full transition-all ${
                                  pct > 95 ? "bg-rose-500" : pct > 80 ? "bg-amber-500" : "bg-primary"
                                }`}
                                style={{ width: `${Math.min(pct, 100)}%` }}
                              />
                            </div>
                            <span className="num text-xs font-semibold">{pct}%</span>
                          </div>
                        ) : (
                          <span className="text-xs text-muted-foreground">—</span>
                        )}
                      </td>
                      <td>
                        <Link
                          to="/timetable"
                          search={{ section: s.id }}
                          className="inline-flex items-center gap-1.5 text-xs font-medium text-primary hover:underline"
                        >
                          {tt === "approved" ? (
                            <span className="inline-flex items-center gap-1 text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200/80">
                              <CheckCircle2 className="h-3 w-3" />
                              <span>معتمد</span>
                            </span>
                          ) : tt === "draft" ? (
                            <span className="inline-flex items-center gap-1 text-amber-700 bg-amber-50 px-2 py-0.5 rounded-full border border-amber-200/80">
                              <Clock className="h-3 w-3" />
                              <span>مسودة</span>
                            </span>
                          ) : (
                            <span className="text-muted-foreground hover:text-foreground">إعداد الجدول ←</span>
                          )}
                        </Link>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

