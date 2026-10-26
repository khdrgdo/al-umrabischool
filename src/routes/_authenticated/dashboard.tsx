import { schoolPageHead } from "@/lib/pageHead";
import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { PageHead, StatCard, WEEKDAYS, Empty } from "@/components/app/kit";
import {
  Users,
  Layers,
  GraduationCap,
  BookOpen,
  Clock,
  CheckCircle2,
  Banknote,
  ClipboardCheck,
  CalendarDays,
  Award,
  Megaphone,
  ArrowRightLeft,
  ChevronLeft,
  CalendarCheck2,
  ShieldCheck,
  UserCheck,
} from "lucide-react";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/_authenticated/dashboard")({
  head: () => schoolPageHead("لوحة القيادة المدرسية — مدرسة العمرابي", "لوحة القيادة الشاملة لنظام إدارة مدرسة العمرابي الثانوية بنين."),
  component: Dashboard,
});

function Dashboard() {
  const { data, isLoading } = useQuery({
    queryKey: ["executive_dashboard_data"],
    queryFn: async () => {
      const { data: year } = await supabase.from("academic_years").select("*").eq("is_current", true).maybeSingle();

      const [students, teachers, subjects, sections, enr, tts, payments, events, announcements] = await Promise.all([
        supabase.from("students").select("id, gender, status"),
        supabase.from("teachers").select("id", { count: "exact", head: true }).eq("is_active", true),
        supabase.from("subjects").select("id", { count: "exact", head: true }).eq("is_active", true),
        year
          ? supabase.from("sections").select("id, name, capacity, grade:grades(name, level_order)").eq("academic_year_id", year.id)
          : Promise.resolve({ data: [] as never[] }),
        year
          ? supabase.from("enrollments").select("section_id, status").eq("academic_year_id", year.id)
          : Promise.resolve({ data: [] as never[] }),
        supabase.from("section_timetables").select("section_id, status"),
        supabase.from("student_payments").select("amount"),
        supabase.from("school_events").select("*").order("starts_on").limit(4).then((r) => r, () => ({ data: [] })),
        supabase.from("announcements").select("*").eq("is_published", true).order("published_at", { ascending: false }).limit(3).then((r) => r, () => ({ data: [] })),
      ]);

      const totalPaymentsSum = (payments.data ?? []).reduce((acc: number, curr: any) => acc + (Number(curr.amount) || 0), 0);

      return {
        year,
        students: students.data ?? [],
        teachers: teachers.count ?? 0,
        subjects: subjects.count ?? 0,
        sections: (sections.data ?? []) as unknown as { id: string; name: string; capacity: number | null; grade: { name: string; level_order: number } | null }[],
        enr: enr.data ?? [],
        tts: tts.data ?? [],
        totalPaymentsSum,
        upcomingEvents: (events as any).data ?? [],
        recentAnnouncements: (announcements as any).data ?? [],
      };
    },
  });

  const active = data?.students.filter((s) => s.status === "active") ?? [];
  const boys = active.filter((s) => s.gender === "male").length;
  const girls = active.filter((s) => s.gender === "female").length;
  const sections = [...(data?.sections ?? [])].sort(
    (a, b) => (a.grade?.level_order ?? 0) - (b.grade?.level_order ?? 0) || a.name.localeCompare(b.name)
  );
  const today = new Date().getDay();

  // Capacity calculations
  const totalCapacity = sections.reduce((acc, s) => acc + (s.capacity ?? 45), 0);
  const totalEnrolled = data?.enr.filter((e) => e.status === "active").length ?? 0;
  const schoolOccupancyRate = totalCapacity > 0 ? Math.round((totalEnrolled / totalCapacity) * 100) : 0;

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHead
        title="لوحة القيادة المدرسية والملخص التنفيذي"
        sub={
          <>
            <span>العام الدراسي الحالي: <strong className="text-foreground">{data?.year?.name ?? "2026 / 2027"}</strong></span>
            <span>·</span>
            <span>اليوم {WEEKDAYS[today]} {new Date().toLocaleDateString("ar-SD", { day: "numeric", month: "long", year: "numeric" })}</span>
          </>
        }
        actions={
          <div className="flex flex-wrap items-center gap-2">
            <Link to="/attendance">
              <Button size="sm" variant="outline" className="h-9 gap-1.5 text-xs">
                <ClipboardCheck className="h-3.5 w-3.5 text-primary" />
                <span>رصد الحضور</span>
              </Button>
            </Link>
            <Link to="/fees">
              <Button size="sm" variant="outline" className="h-9 gap-1.5 text-xs">
                <Banknote className="h-3.5 w-3.5 text-emerald-600" />
                <span>تحصيل الرسوم</span>
              </Button>
            </Link>
            <Link to="/grades">
              <Button size="sm" variant="outline" className="h-9 gap-1.5 text-xs">
                <Award className="h-3.5 w-3.5 text-amber-600" />
                <span>الدرجات والنتائج</span>
              </Button>
            </Link>
          </div>
        }
      />

      {/* 4 Main Operational KPIs */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="الطلاب المنتظمون"
          value={isLoading ? "…" : active.length}
          note={`${boys} بنين · ${girls} بنات`}
          icon={<Users className="h-4 w-4" />}
          variant="primary"
        />
        <StatCard
          label="نسبة إشغال الفصول"
          value={isLoading ? "…" : `${schoolOccupancyRate}%`}
          note={`${totalEnrolled} طالب من أصل ${totalCapacity} مقعد`}
          icon={<Layers className="h-4 w-4" />}
          variant={schoolOccupancyRate > 90 ? "warning" : "default"}
        />
        <StatCard
          label="إجمالي التحصيل المالي"
          value={isLoading ? "…" : `${(data?.totalPaymentsSum ?? 0).toLocaleString()} ج.س`}
          note="إيرادات الرسوم المسددة"
          icon={<Banknote className="h-4 w-4" />}
          variant="success"
        />
        <StatCard
          label="الكادر التعليمي والمواد"
          value={isLoading ? "…" : `${data?.teachers ?? 0} معلم`}
          note={`${data?.subjects ?? 0} مادة دراسية معتمدة`}
          icon={<GraduationCap className="h-4 w-4" />}
        />
      </div>

      {/* Quick Access Matrix (Notion-style Action Pill Grid) */}
      <div className="card-surface p-4 border border-border">
        <h2 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">
          الوصول السريع لوحدات الإدارة
        </h2>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-6 gap-2">
          <Link
            to="/students"
            className="p-3 rounded-lg border border-border bg-card hover:border-primary/50 transition-colors text-center group"
          >
            <Users className="h-4 w-4 mx-auto mb-1 text-primary group-hover:scale-110 transition-transform" />
            <span className="text-xs font-semibold text-foreground block">سجل الطلاب</span>
            <span className="text-[10px] text-muted-foreground">الملفات والقيد</span>
          </Link>

          <Link
            to="/guardians"
            className="p-3 rounded-lg border border-border bg-card hover:border-primary/50 transition-colors text-center group"
          >
            <UserCheck className="h-4 w-4 mx-auto mb-1 text-emerald-600 group-hover:scale-110 transition-transform" />
            <span className="text-xs font-semibold text-foreground block">أولياء الأمور</span>
            <span className="text-[10px] text-muted-foreground">الربط والتوثيق</span>
          </Link>

          <Link
            to="/attendance"
            className="p-3 rounded-lg border border-border bg-card hover:border-primary/50 transition-colors text-center group"
          >
            <ClipboardCheck className="h-4 w-4 mx-auto mb-1 text-indigo-600 group-hover:scale-110 transition-transform" />
            <span className="text-xs font-semibold text-foreground block">الحضور والغياب</span>
            <span className="text-[10px] text-muted-foreground">الرصد اليومي</span>
          </Link>

          <Link
            to="/fees"
            className="p-3 rounded-lg border border-border bg-card hover:border-primary/50 transition-colors text-center group"
          >
            <Banknote className="h-4 w-4 mx-auto mb-1 text-emerald-600 group-hover:scale-110 transition-transform" />
            <span className="text-xs font-semibold text-foreground block">الرسوم والمالية</span>
            <span className="text-[10px] text-muted-foreground">الإيصالات والمنح</span>
          </Link>

          <Link
            to="/grades"
            className="p-3 rounded-lg border border-border bg-card hover:border-primary/50 transition-colors text-center group"
          >
            <Award className="h-4 w-4 mx-auto mb-1 text-amber-600 group-hover:scale-110 transition-transform" />
            <span className="text-xs font-semibold text-foreground block">الدرجات والنتائج</span>
            <span className="text-[10px] text-muted-foreground">المسيرات والاعتماد</span>
          </Link>

          <Link
            to="/rollover"
            className="p-3 rounded-lg border border-border bg-card hover:border-primary/50 transition-colors text-center group"
          >
            <ArrowRightLeft className="h-4 w-4 mx-auto mb-1 text-purple-600 group-hover:scale-110 transition-transform" />
            <span className="text-xs font-semibold text-foreground block">الترحيل السنوي</span>
            <span className="text-[10px] text-muted-foreground">ترقية الصفوف</span>
          </Link>
        </div>
      </div>

      {/* Events & Announcements 2-column Grid */}
      <div className="grid md:grid-cols-2 gap-4">
        {/* Upcoming School Events */}
        <div className="card-surface p-5 space-y-3">
          <div className="flex items-center justify-between pb-3 border-b border-border">
            <div className="flex items-center gap-2">
              <CalendarDays className="h-4 w-4 text-primary" />
              <h3 className="text-sm font-bold text-foreground">الفعاليات والمحطات القادمة</h3>
            </div>
            <Link to="/calendar" className="text-xs text-primary hover:underline flex items-center gap-1 font-medium">
              <span>التقويم كاملاً</span>
              <ChevronLeft className="h-3.5 w-3.5" />
            </Link>
          </div>

          {(data?.upcomingEvents ?? []).length === 0 ? (
            <p className="text-xs text-muted-foreground py-4 text-center">لا توجد مواعيد مسجلة قريباً.</p>
          ) : (
            <div className="space-y-2.5">
              {(data?.upcomingEvents ?? []).map((ev: any) => (
                <div key={ev.id} className="p-2.5 rounded-lg border border-border bg-card flex items-center justify-between text-xs">
                  <div>
                    <h4 className="font-semibold text-foreground">{ev.title}</h4>
                    {ev.description && <p className="text-[11px] text-muted-foreground mt-0.5 line-clamp-1">{ev.description}</p>}
                  </div>
                  <span className="font-mono text-[11px] px-2 py-0.5 rounded bg-muted text-foreground font-medium shrink-0 ms-2" dir="ltr">
                    {ev.starts_on}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Recent Announcements */}
        <div className="card-surface p-5 space-y-3">
          <div className="flex items-center justify-between pb-3 border-b border-border">
            <div className="flex items-center gap-2">
              <Megaphone className="h-4 w-4 text-amber-600" />
              <h3 className="text-sm font-bold text-foreground">آخر التعاميم والإعلانات المدرسية</h3>
            </div>
            <Link to="/calendar" className="text-xs text-primary hover:underline flex items-center gap-1 font-medium">
              <span>لوحة الإعلانات</span>
              <ChevronLeft className="h-3.5 w-3.5" />
            </Link>
          </div>

          {(data?.recentAnnouncements ?? []).length === 0 ? (
            <p className="text-xs text-muted-foreground py-4 text-center">لا توجد إعلانات نشطة منشورة حالياً.</p>
          ) : (
            <div className="space-y-2.5">
              {(data?.recentAnnouncements ?? []).map((ann: any) => (
                <div key={ann.id} className="p-2.5 rounded-lg border border-border bg-card space-y-1 text-xs">
                  <div className="flex items-center justify-between">
                    <h4 className="font-semibold text-foreground">{ann.title}</h4>
                    <span className="text-[10px] text-muted-foreground">
                      {new Date(ann.published_at).toLocaleDateString("ar-SD", { month: "short", day: "numeric" })}
                    </span>
                  </div>
                  <p className="text-[11px] text-muted-foreground line-clamp-2 leading-relaxed">{ann.body}</p>
                </div>
              ))}
            </div>
          )}
        </div>
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
          <table className="modern-table text-xs">
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
                      <td className="num font-semibold">{n} طالب</td>
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
