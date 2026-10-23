import { schoolPageHead } from "@/lib/pageHead";
import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { useMemo, useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import {
  GraduationCap,
  Calendar,
  ClipboardCheck,
  Banknote,
  Bell,
  Clock,
  ShieldCheck,
  User,
  BookOpen,
  CalendarDays,
  CheckCircle2,
  AlertTriangle,
  Receipt,
  Phone,
  School,
  Lock,
  LogOut,
  AlertCircle,
  FileText,
  ChevronLeft,
} from "lucide-react";

export const Route = createFileRoute("/parent")({
  ssr: false,
  head: () => schoolPageHead("بوابة أولياء الأمور — مدرسة العمرابي الثانوية", "بوابة ولي الأمر الإلكترونية المعتمدة لمتابعة الأبناء والنتائج المنشورة والحضور والرسوم."),
  component: ParentPortalPage,
});

type TabKey = "overview" | "grades" | "attendance" | "timetable" | "fees" | "announcements";

interface GuardianSession {
  guardianId: string;
  accountCode: string;
  fullName: string;
  phone: string;
  status: string;
}

interface LinkedChild {
  id: string;
  studentNumber: string;
  fullName: string;
  gradeName: string;
  sectionName: string;
  sectionId: string;
  status: string;
  canViewFees: boolean;
}

const SESSION_STORAGE_KEY = "alumrabi_guardian_session";

function ParentPortalPage() {
  const [activeTab, setActiveTab] = useState<TabKey>("overview");
  const [selectedChildIndex, setSelectedChildIndex] = useState(0);

  // Authentication State (Session-backed, OWASP-compliant, Anti-Enumeration)
  const [session, setSession] = useState<GuardianSession | null>(() => {
    if (typeof window === "undefined") return null;
    try {
      const stored = window.sessionStorage.getItem(SESSION_STORAGE_KEY);
      return stored ? JSON.parse(stored) : null;
    } catch {
      return null;
    }
  });

  // Login Form State
  const [loginAccountCode, setLoginAccountCode] = useState("");
  const [loginPin, setLoginPin] = useState("");
  const [loginLoading, setLoginLoading] = useState(false);
  const [loginError, setLoginError] = useState<string | null>(null);

  // Handle Login via parent_app_login RPC
  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setLoginError(null);

    const code = loginAccountCode.trim().toUpperCase();
    const pin = loginPin.trim();

    if (!code || !pin) {
      setLoginError("يرجى إدخال معرّف الحساب ورمز المرور");
      return;
    }

    setLoginLoading(true);
    try {
      const { data, error } = await supabase.rpc("parent_app_login", {
        _account_code: code,
        _code_or_pin: pin,
      });

      if (error) {
        console.error("Login RPC error:", error);
        setLoginError("بيانات الدخول غير صحيحة. يرجى التأكد من المعرّف أو مراجعة إدارة المدرسة.");
        return;
      }

      if (data && data.success) {
        const guardianSession: GuardianSession = {
          guardianId: data.guardian_id,
          accountCode: data.account_code,
          fullName: data.full_name,
          phone: data.phone,
          status: data.status,
        };
        setSession(guardianSession);
        try {
          window.sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(guardianSession));
        } catch {}
      } else {
        setLoginError(data?.message || "بيانات الدخول غير صحيحة. يرجى التأكد من المعرّف أو مراجعة إدارة المدرسة.");
      }
    } catch (err: any) {
      console.error("Login exception:", err);
      setLoginError("تعذر الاتصال بالخادم حالياً. يرجى المحاولة لاحقاً.");
    } finally {
      setLoginLoading(false);
    }
  }

  // Handle Logout
  function handleLogout() {
    try {
      window.sessionStorage.removeItem(SESSION_STORAGE_KEY);
    } catch {}
    setSession(null);
    setSelectedChildIndex(0);
    setActiveTab("overview");
  }

  // 1. Fetch current academic year and guardian's linked children
  const { data: portalData, isLoading: portalLoading } = useQuery({
    queryKey: ["parent-portal-data", session?.guardianId],
    enabled: !!session?.guardianId,
    queryFn: async () => {
      // Fetch current academic year
      let currentYear: any = null;
      try {
        const { data: y } = await supabase.from("academic_years").select("*").eq("is_current", true).maybeSingle();
        if (y) currentYear = y;
        else {
          const { data: latest } = await supabase.from("academic_years").select("*").order("starts_on", { ascending: false }).limit(1).maybeSingle();
          currentYear = latest ?? null;
        }
      } catch (err) {
        console.warn("Academic year query:", err);
      }

      // Fetch linked children strictly for authenticated guardian
      let linkedStudents: LinkedChild[] = [];
      try {
        const { data: links } = await supabase
          .from("guardian_students")
          .select("can_view_fees, student:students(id, full_name, student_number, status)")
          .eq("guardian_id", session!.guardianId);

        if (links && links.length > 0) {
          const studentIds = links.map((l: any) => l.student?.id).filter(Boolean);
          const { data: enrollments } = currentYear?.id
            ? await supabase
                .from("enrollments")
                .select("student_id, section:sections(id, name, grade:grades(name))")
                .eq("academic_year_id", currentYear.id)
                .in("student_id", studentIds)
            : { data: [] };

          const enrMap = new Map((enrollments ?? []).map((e: any) => [e.student_id, e.section]));

          linkedStudents = links.map((l: any) => {
            const sec = enrMap.get(l.student?.id);
            return {
              id: l.student?.id ?? "",
              studentNumber: l.student?.student_number ?? "—",
              fullName: l.student?.full_name ?? "بدون اسم",
              gradeName: sec?.grade?.name ?? "غير مقيد",
              sectionName: sec?.name ?? "—",
              sectionId: sec?.id ?? "",
              status: l.student?.status ?? "active",
              canViewFees: l.can_view_fees ?? true,
            };
          });
        }
      } catch (err) {
        console.warn("Linked children query error:", err);
      }

      // Fetch school announcements
      let announcements: any[] = [];
      try {
        const { data: ann } = await supabase
          .from("school_announcements")
          .select("*")
          .eq("is_published", true)
          .order("created_at", { ascending: false })
          .limit(10);
        announcements = ann ?? [];
      } catch {}

      // Fetch school events
      let events: any[] = [];
      try {
        const { data: ev } = await supabase
          .from("school_events")
          .select("*")
          .eq("is_published", true)
          .order("starts_on", { ascending: true })
          .limit(8);
        events = ev ?? [];
      } catch {}

      return {
        year: currentYear,
        children: linkedStudents,
        announcements,
        events,
      };
    },
  });

  const activeChild = useMemo(() => {
    const list = portalData?.children ?? [];
    if (list.length === 0) return null;
    return list[selectedChildIndex] ?? list[0];
  }, [portalData?.children, selectedChildIndex]);

  // 2. Fetch authenticated grades (strictly published assessments only, no fake fallbacks)
  const { data: childGrades, isLoading: gradesLoading } = useQuery({
    queryKey: ["parent-grades", activeChild?.id],
    enabled: !!activeChild?.id,
    queryFn: async () => {
      try {
        const { data: gradesData } = await supabase
          .from("student_grades")
          .select("score, status, notes, assessment:assessments(name, max_score, weight, is_published, subject:subjects(name))")
          .eq("student_id", activeChild!.id);

        // Strict filter: only published assessments
        const publishedOnly = (gradesData ?? []).filter((g: any) => g.assessment?.is_published);
        return publishedOnly;
      } catch {
        return [];
      }
    },
  });

  // 3. Fetch attendance records (authentic database counts, no hardcoded 98%)
  const { data: childAttendance, isLoading: attendanceLoading } = useQuery({
    queryKey: ["parent-attendance", activeChild?.id],
    enabled: !!activeChild?.id,
    queryFn: async () => {
      try {
        const { data: att } = await supabase
          .from("attendance_records")
          .select("id, status, reason, created_at, session:attendance_sessions(attendance_date)")
          .eq("student_id", activeChild!.id)
          .order("created_at", { ascending: false })
          .limit(50);

        const records = att ?? [];
        const absentCount = records.filter((r: any) => r.status === "absent").length;
        const totalSessions = records.length;
        const rate = totalSessions > 0 ? Math.max(0, Math.round(((totalSessions - absentCount) / totalSessions) * 100)) : null;

        return {
          records,
          absentCount,
          totalSessions,
          rate,
        };
      } catch {
        return { records: [], absentCount: 0, totalSessions: 0, rate: null };
      }
    },
  });

  // 4. Fetch fee statement (only fired if guardian has can_view_fees privilege)
  const { data: childFees, isLoading: feesLoading } = useQuery({
    queryKey: ["parent-fees", activeChild?.id],
    enabled: !!activeChild?.id && !!activeChild?.canViewFees,
    queryFn: async () => {
      try {
        const [paymentsRes, discountsRes] = await Promise.all([
          supabase.from("student_payments").select("*").eq("student_id", activeChild!.id).order("created_at", { ascending: false }),
          supabase.from("student_fee_discounts").select("*").eq("student_id", activeChild!.id),
        ]);

        let baseAnnualFee = 0;
        if (portalData?.year?.id && activeChild?.sectionId) {
          const { data: sec } = await supabase.from("sections").select("grade_id").eq("id", activeChild.sectionId).maybeSingle();
          if (sec?.grade_id) {
            const { data: fs } = await supabase
              .from("fee_structures")
              .select("amount")
              .eq("academic_year_id", portalData.year.id)
              .eq("grade_id", sec.grade_id);
            baseAnnualFee = (fs ?? []).reduce((sum, f) => sum + (Number(f.amount) || 0), 0);
          }
        }

        const discountTotal = (discountsRes.data ?? []).reduce((sum, d) => sum + (Number(d.amount) || 0), 0);
        const netDue = Math.max(0, baseAnnualFee - discountTotal);
        const paidTotal = (paymentsRes.data ?? []).reduce((sum, p) => sum + (Number(p.amount) || 0), 0);
        const balance = Math.max(0, netDue - paidTotal);

        return {
          baseAnnualFee,
          discountTotal,
          netDue,
          paidTotal,
          balance,
          payments: paymentsRes.data ?? [],
        };
      } catch {
        return {
          baseAnnualFee: 0,
          discountTotal: 0,
          netDue: 0,
          paidTotal: 0,
          balance: 0,
          payments: [],
        };
      }
    },
  });

  // 5. Fetch section timetable
  const { data: timetable } = useQuery({
    queryKey: ["parent-timetable", activeChild?.sectionId],
    enabled: !!activeChild?.sectionId,
    queryFn: async () => {
      try {
        const { data: entries } = await supabase
          .from("timetable_entries")
          .select("weekday, room, subject:subjects(name), teacher:teachers(full_name), period:periods(name, start_time, end_time, period_order)")
          .eq("section_id", activeChild!.sectionId);
        return entries ?? [];
      } catch {
        return [];
      }
    },
  });

  // -------------------------------------------------------------
  // VIEW A: AUTHENTICATION FORM (When not logged in)
  // -------------------------------------------------------------
  if (!session) {
    return (
      <div className="min-h-screen bg-muted/30 flex flex-col justify-between text-foreground font-sans" dir="rtl">
        {/* Top Header */}
        <header className="bg-brand-header text-brand-header-foreground shadow-header py-4 px-6">
          <div className="max-w-4xl mx-auto flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="grid size-9 place-items-center rounded-lg bg-white/10 text-white font-bold border border-white/20">
                <School className="size-5" />
              </div>
              <div>
                <h1 className="text-sm sm:text-base font-bold text-white leading-tight">مدرسة العمرابي الثانوية بنين</h1>
                <p className="text-[11px] text-brand-header-muted">بوابة أولياء الأمور المعتمدة</p>
              </div>
            </div>
            <Link
              to="/auth"
              className="text-xs text-white/80 hover:text-white px-3 py-1.5 rounded-lg border border-white/20 hover:bg-white/10 transition-colors"
            >
              دخول الموظفين
            </Link>
          </div>
        </header>

        {/* Login Container */}
        <main className="flex-1 flex items-center justify-center p-4 sm:p-6">
          <div className="w-full max-w-md bg-card border border-border rounded-xl shadow-lg p-6 sm:p-8 space-y-6">
            <div className="text-center space-y-2">
              <div className="mx-auto size-12 rounded-full bg-primary/10 text-primary grid place-items-center mb-3">
                <ShieldCheck className="size-6" />
              </div>
              <h2 className="text-lg font-bold text-foreground">تسجيل دخول ولي الأمر</h2>
              <p className="text-xs text-muted-foreground leading-relaxed">
                أدخل معرّف الحساب المعتمد (المسلّم من إدارة المدرسة) ورمز المرور الخاص بك.
              </p>
            </div>

            {loginError && (
              <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/20 text-destructive text-xs flex items-start gap-2">
                <AlertCircle className="size-4 shrink-0 mt-0.5" />
                <span>{loginError}</span>
              </div>
            )}

            <form onSubmit={handleLogin} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-foreground">معرّف الحساب (Account Code)</label>
                <div className="relative">
                  <Input
                    placeholder="PAR-XXXXXX"
                    value={loginAccountCode}
                    onChange={(e) => setLoginAccountCode(e.target.value.toUpperCase())}
                    className="h-10 text-xs font-mono ps-9 tracking-wider"
                    dir="ltr"
                    required
                    autoComplete="username"
                  />
                  <User className="size-4 text-muted-foreground absolute start-3 top-3" />
                </div>
                <p className="text-[10px] text-muted-foreground">كود فريد مكوّن من أحرف وأرقام معتمد لدى الإدارة.</p>
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-foreground">رمز المرور / PIN</label>
                <div className="relative">
                  <Input
                    type="password"
                    placeholder="••••••••"
                    value={loginPin}
                    onChange={(e) => setLoginPin(e.target.value)}
                    className="h-10 text-xs font-mono ps-9"
                    dir="ltr"
                    required
                    autoComplete="current-password"
                  />
                  <Lock className="size-4 text-muted-foreground absolute start-3 top-3" />
                </div>
                <p className="text-[10px] text-muted-foreground">رمز التفعيل أو كلمة المرور المستلمة حضورياً.</p>
              </div>

              <Button
                type="submit"
                disabled={loginLoading}
                className="w-full h-10 text-xs font-semibold bg-primary text-primary-foreground hover:bg-primary/90 mt-2"
              >
                {loginLoading ? "جاري التحقق والمصادقة..." : "دخول إلى البوابة"}
              </Button>
            </form>

            <div className="pt-4 border-t border-border text-center space-y-1.5">
              <p className="text-[11px] text-muted-foreground">
                لم تستلم بيانات حسابك بعد أو فقدت رمز المرور؟
              </p>
              <p className="text-[11px] font-medium text-foreground">
                يرجى مراجعة إدارة شؤون الطلاب بالمدرسة للتحقق الحضوري واستلام رمز التفعيل.
              </p>
            </div>
          </div>
        </main>

        {/* Footer */}
        <footer className="py-4 text-center text-[11px] text-muted-foreground border-t border-border">
          نظام مدرسة العمرابي الثانوية بنين — جميع الحقوق محفوظة
        </footer>
      </div>
    );
  }

  // -------------------------------------------------------------
  // VIEW B: AUTHENTICATED PORTAL DASHBOARD
  // -------------------------------------------------------------
  return (
    <div className="min-h-screen bg-background text-foreground font-sans" dir="rtl">
      {/* 1. Header — Institutional Burgundy Topbar */}
      <header className="sticky top-0 z-30 bg-brand-header text-brand-header-foreground shadow-header">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 h-14 sm:h-16 flex items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <Link to="/parent" className="flex items-center gap-2.5">
              <div className="grid size-9 place-items-center rounded-lg bg-white/10 text-white font-bold border border-white/20">
                <School className="size-5" />
              </div>
              <div>
                <h1 className="text-sm sm:text-base font-bold text-white leading-tight">مدرسة العمرابي الثانوية بنين</h1>
                <p className="text-[11px] text-brand-header-muted">بوابة ولي الأمر المعتمدة</p>
              </div>
            </Link>
          </div>

          <div className="flex items-center gap-2.5">
            <div className="hidden sm:flex flex-col text-end">
              <span className="text-xs font-semibold text-white">{session.fullName}</span>
              <span className="text-[10px] text-white/70 font-mono" dir="ltr">{session.accountCode}</span>
            </div>
            <Button
              variant="ghost"
              size="sm"
              onClick={handleLogout}
              className="text-xs text-brand-header-foreground hover:bg-white/10 gap-1.5 h-8 px-2.5"
              title="تسجيل الخروج"
            >
              <LogOut className="size-3.5" />
              <span className="hidden sm:inline">تسجيل الخروج</span>
            </Button>
          </div>
        </div>
      </header>

      {/* Main Container */}
      <main className="max-w-5xl mx-auto px-4 sm:px-6 py-5 sm:py-7 space-y-6">
        {/* Child Selector Switcher (Support for multi-child families) */}
        {portalData?.children && portalData.children.length > 0 ? (
          <div className="card-surface p-3 sm:p-4 border-s-4 border-s-primary">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <GraduationCap className="size-5 text-primary" />
                <div>
                  <h2 className="text-xs font-semibold text-foreground">الأبناء المقيدون بالمدرسة</h2>
                  <p className="text-[11px] text-muted-foreground">اختر الابن لمتابعة نتائجه وحضوره وجدوله</p>
                </div>
              </div>

              {/* Segmented children pills */}
              <div className="flex flex-wrap items-center gap-2">
                {portalData.children.map((child, idx) => (
                  <button
                    key={child.id}
                    onClick={() => setSelectedChildIndex(idx)}
                    className={`flex items-center gap-2 px-3.5 py-2 rounded-lg text-xs font-medium transition-all ${
                      selectedChildIndex === idx
                        ? "bg-primary text-primary-foreground shadow-xs"
                        : "bg-muted text-muted-foreground hover:bg-muted/80 hover:text-foreground"
                    }`}
                  >
                    <span>{child.fullName}</span>
                    <span className="text-[10px] font-mono opacity-80" dir="ltr">
                      {child.studentNumber}
                    </span>
                  </button>
                ))}
              </div>
            </div>

            {/* Current child banner info */}
            {activeChild && (
              <div className="mt-3 pt-3 border-t border-border flex flex-wrap items-center justify-between gap-2 text-xs">
                <div className="flex items-center gap-3">
                  <span className="text-muted-foreground">الصف والقيد:</span>
                  <span className="font-semibold text-foreground">
                    {activeChild.gradeName} · {activeChild.sectionName}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-[11px] text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                    طالب منتظم في الدراسة
                  </span>
                </div>
              </div>
            )}
          </div>
        ) : (
          <div className="card-surface p-6 text-center space-y-2 border-dashed border-2">
            <AlertCircle className="size-8 text-amber-600 mx-auto" />
            <h3 className="text-sm font-bold text-foreground">لا يوجد طلاب مسجلون مرتبطون بهذا الحساب حالياً</h3>
            <p className="text-xs text-muted-foreground max-w-md mx-auto leading-relaxed">
              وفقاً لقواعد النظام، يجب على إدارة المدرسة ربط الطالب بملف ولي أمره عبر رقم الحساب المعتمد. يرجى مراجعة إدارة المدرسة لإتمام عملية الربط الأسري.
            </p>
          </div>
        )}

        {/* Tab Navigation */}
        <div className="flex overflow-x-auto gap-2 pb-1 border-b border-border text-xs scrollbar-none">
          <button
            onClick={() => setActiveTab("overview")}
            className={`pb-2 px-3 font-semibold transition-colors relative whitespace-nowrap flex items-center gap-1.5 ${
              activeTab === "overview" ? "text-primary border-b-2 border-primary" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            <Clock className="size-3.5" />
            <span>نظرة عامة</span>
          </button>
          <button
            onClick={() => setActiveTab("grades")}
            className={`pb-2 px-3 font-semibold transition-colors relative whitespace-nowrap flex items-center gap-1.5 ${
              activeTab === "grades" ? "text-primary border-b-2 border-primary" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            <BookOpen className="size-3.5" />
            <span>النتائج والدرجات المنشورة</span>
          </button>
          <button
            onClick={() => setActiveTab("attendance")}
            className={`pb-2 px-3 font-semibold transition-colors relative whitespace-nowrap flex items-center gap-1.5 ${
              activeTab === "attendance" ? "text-primary border-b-2 border-primary" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            <ClipboardCheck className="size-3.5" />
            <span>الحضور والغياب</span>
          </button>
          <button
            onClick={() => setActiveTab("timetable")}
            className={`pb-2 px-3 font-semibold transition-colors relative whitespace-nowrap flex items-center gap-1.5 ${
              activeTab === "timetable" ? "text-primary border-b-2 border-primary" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            <CalendarDays className="size-3.5" />
            <span>الجدول الأسبوعي</span>
          </button>
          {activeChild?.canViewFees && (
            <button
              onClick={() => setActiveTab("fees")}
              className={`pb-2 px-3 font-semibold transition-colors relative whitespace-nowrap flex items-center gap-1.5 ${
                activeTab === "fees" ? "text-primary border-b-2 border-primary" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              <Banknote className="size-3.5" />
              <span>الرسوم وسندات السداد</span>
            </button>
          )}
          <button
            onClick={() => setActiveTab("announcements")}
            className={`pb-2 px-3 font-semibold transition-colors relative whitespace-nowrap flex items-center gap-1.5 ${
              activeTab === "announcements" ? "text-primary border-b-2 border-primary" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            <Bell className="size-3.5" />
            <span>الإعلانات والتقويم</span>
          </button>
        </div>

        {/* TAB 1: OVERVIEW */}
        {activeTab === "overview" && (
          <div className="space-y-6">
            {/* Quick Metrics Cards */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3.5">
              <div className="card-surface p-4">
                <div className="text-muted-foreground text-[11px] mb-1">نسبة الحضور المرصودة</div>
                <div className="text-xl sm:text-2xl font-bold font-mono text-emerald-600">
                  {childAttendance?.rate !== null && childAttendance?.rate !== undefined
                    ? `${childAttendance.rate}%`
                    : "—"}
                </div>
                <div className="text-[10px] text-muted-foreground mt-1">
                  {childAttendance?.totalSessions ? `${childAttendance.absentCount} غيابات من ${childAttendance.totalSessions} جلسة` : "لا توجد جلسات مسجلة"}
                </div>
              </div>

              <div className="card-surface p-4">
                <div className="text-muted-foreground text-[11px] mb-1">التقييمات المعتمدة</div>
                <div className="text-xl sm:text-2xl font-bold font-mono text-primary">
                  {childGrades?.length ?? 0} <span className="text-xs font-normal">مواد</span>
                </div>
                <div className="text-[10px] text-muted-foreground mt-1">نتائج معتمدة من الإدارة</div>
              </div>

              {activeChild?.canViewFees && (
                <div className="card-surface p-4">
                  <div className="text-muted-foreground text-[11px] mb-1">المتبقي من الرسوم</div>
                  <div className="text-xl sm:text-2xl font-bold font-mono text-foreground">
                    {(childFees?.balance ?? 0).toLocaleString()} <span className="text-xs font-normal">ج.س</span>
                  </div>
                  <div className="text-[10px] text-muted-foreground mt-1">
                    {(childFees?.balance ?? 0) > 0 ? "يستحق السداد" : "لا توجد رسوم مستحقة"}
                  </div>
                </div>
              )}

              <div className="card-surface p-4">
                <div className="text-muted-foreground text-[11px] mb-1">الأحداث والفعاليات</div>
                <div className="text-xl sm:text-2xl font-bold font-mono text-indigo-600">
                  {portalData?.events?.length ?? 0} <span className="text-xs font-normal">أحداث</span>
                </div>
                <div className="text-[10px] text-muted-foreground mt-1">تقويم الأنشطة والامتحانات</div>
              </div>
            </div>

            {/* Quick Two Columns: Recent Grades & School Announcements */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              {/* Recent Grades Summary */}
              <div className="card-surface p-5">
                <div className="flex items-center justify-between pb-3 border-b border-border mb-3">
                  <div className="flex items-center gap-2">
                    <BookOpen className="size-4 text-primary" />
                    <h3 className="text-xs font-bold text-foreground">النتائج والدرجات المعتمدة</h3>
                  </div>
                  {childGrades && childGrades.length > 0 && (
                    <button
                      onClick={() => setActiveTab("grades")}
                      className="text-xs text-primary hover:underline"
                    >
                      عرض الشهادة الكاملة
                    </button>
                  )}
                </div>

                {childGrades && childGrades.length > 0 ? (
                  <div className="space-y-2.5">
                    {childGrades.slice(0, 4).map((g: any, i: number) => (
                      <div key={i} className="flex items-center justify-between p-2 rounded-lg bg-muted/40 text-xs">
                        <div>
                          <div className="font-semibold text-foreground">{g.assessment?.subject?.name ?? "مادة دراسية"}</div>
                          <div className="text-[11px] text-muted-foreground">{g.assessment?.name}</div>
                        </div>
                        <div className="text-end">
                          <div className="font-mono font-bold text-emerald-700">
                            {g.score} / {g.assessment?.max_score}
                          </div>
                          <span className="text-[10px] text-emerald-600 bg-emerald-50 px-1.5 py-0.2 rounded font-medium">
                            معتمد
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="p-6 text-center text-xs text-muted-foreground">
                    لا توجد نتائج معتمدة منشورة رسمياً لهذا الطالب حتى الآن.
                  </div>
                )}
              </div>

              {/* Active Announcements */}
              <div className="card-surface p-5">
                <div className="flex items-center justify-between pb-3 border-b border-border mb-3">
                  <div className="flex items-center gap-2">
                    <Bell className="size-4 text-primary" />
                    <h3 className="text-xs font-bold text-foreground">إعلانات الإدارة المدرسية</h3>
                  </div>
                  {portalData?.announcements && portalData.announcements.length > 0 && (
                    <button
                      onClick={() => setActiveTab("announcements")}
                      className="text-xs text-primary hover:underline"
                    >
                      جميع الإعلانات
                    </button>
                  )}
                </div>

                {portalData?.announcements && portalData.announcements.length > 0 ? (
                  <div className="space-y-3">
                    {portalData.announcements.slice(0, 3).map((ann: any, idx: number) => (
                      <div key={idx} className="p-3 rounded-lg border border-border bg-card">
                        <div className="text-xs font-semibold text-foreground mb-1">{ann.title}</div>
                        <p className="text-[11px] text-muted-foreground line-clamp-2 leading-relaxed">
                          {ann.content}
                        </p>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="p-6 text-center text-xs text-muted-foreground">
                    لا توجد إعلانات منشورة حالياً من إدارة المدرسة.
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: GRADES & RESULTS */}
        {activeTab === "grades" && (
          <div className="space-y-5">
            <div className="card-surface p-5 border-s-4 border-s-emerald-600">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <BookOpen className="size-4 text-emerald-600" />
                  <h3 className="text-xs font-bold text-foreground">كشف النتائج والتقييمات المعتمدة</h3>
                </div>
                <span className="text-[11px] text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                  معتمدة ومصدقة من إدارة مدرسة العمرابي
                </span>
              </div>
              <p className="text-[11px] text-muted-foreground">
                وفقاً لسياسة الخصوصية بالمدرسة، تُعرض هنا النتائج التي تم اعتمادها ونشرها رسمياً فقط. النتائج قيد التدقيق لا تظهر في هذه الصفحة.
              </p>
            </div>

            {childGrades && childGrades.length > 0 ? (
              <div className="card-surface overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="modern-table">
                    <thead>
                      <tr>
                        <th className="w-12">#</th>
                        <th>المادة الدراسية</th>
                        <th>عنوان التقييم / الامتحان</th>
                        <th>الدرجة المحرزة</th>
                        <th>الدرجة الكاملة</th>
                        <th>النسبة المئوية</th>
                        <th>التقدير والتقييم</th>
                      </tr>
                    </thead>
                    <tbody>
                      {childGrades.map((row: any, i: number) => {
                        const max = Number(row.assessment?.max_score) || 100;
                        const sc = Number(row.score) || 0;
                        const pct = Math.round((sc / max) * 100);
                        return (
                          <tr key={i} className="hover:bg-muted/30 transition-colors">
                            <td className="num text-muted-foreground text-xs">{i + 1}</td>
                            <td className="font-semibold text-foreground text-xs">
                              {row.assessment?.subject?.name ?? "مادة دراسية"}
                            </td>
                            <td className="text-xs text-muted-foreground">{row.assessment?.name}</td>
                            <td className="num font-mono text-xs font-bold text-emerald-700">{sc}</td>
                            <td className="num font-mono text-xs text-muted-foreground">{max}</td>
                            <td>
                              <div className="flex items-center gap-2">
                                <div className="w-16 bg-muted rounded-full h-1.5 overflow-hidden">
                                  <div className="bg-emerald-600 h-1.5 rounded-full" style={{ width: `${pct}%` }} />
                                </div>
                                <span className="font-mono text-xs font-semibold text-foreground">{pct}%</span>
                              </div>
                            </td>
                            <td>
                              <span className="text-[11px] font-medium text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                                {pct >= 90 ? "ممتاز" : pct >= 80 ? "جيد جداً" : pct >= 70 ? "جيد" : pct >= 50 ? "مقبول" : "يحتاج متابعة"}
                              </span>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            ) : (
              <div className="card-surface p-8 text-center text-xs text-muted-foreground">
                <BookOpen className="size-8 text-muted-foreground/40 mx-auto mb-2" />
                <p>لا توجد نتائج أو درجات معتمدة منشورة لهذا الطالب حتى الآن.</p>
              </div>
            )}
          </div>
        )}

        {/* TAB 3: ATTENDANCE */}
        {activeTab === "attendance" && (
          <div className="space-y-5">
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="card-surface p-4">
                <div className="text-xs text-muted-foreground mb-1">نسبة الحضور الإجمالية</div>
                <div className="text-2xl font-bold font-mono text-emerald-600">
                  {childAttendance?.rate !== null && childAttendance?.rate !== undefined
                    ? `${childAttendance.rate}%`
                    : "—"}
                </div>
                <div className="text-[11px] text-muted-foreground mt-1">
                  {childAttendance?.totalSessions ? "حضور محسوب من الجلسات المعتمدة" : "لا توجد جلسات معتمدة بعد"}
                </div>
              </div>

              <div className="card-surface p-4">
                <div className="text-xs text-muted-foreground mb-1">أيام الغياب المرصودة</div>
                <div className="text-2xl font-bold font-mono text-rose-600">
                  {childAttendance?.absentCount ?? 0} <span className="text-xs font-normal">أيام</span>
                </div>
                <div className="text-[11px] text-muted-foreground mt-1">إجمالي الغياب المسجل</div>
              </div>

              <div className="card-surface p-4">
                <div className="text-xs text-muted-foreground mb-1">إجمالي الجلسات المرصودة</div>
                <div className="text-2xl font-bold font-mono text-foreground">
                  {childAttendance?.totalSessions ?? 0} <span className="text-xs font-normal">جلسة</span>
                </div>
                <div className="text-[11px] text-muted-foreground mt-1">خلال الفصل الدراسي الحالي</div>
              </div>
            </div>

            <div className="card-surface p-5">
              <h3 className="text-xs font-bold text-foreground mb-3 flex items-center gap-2">
                <ClipboardCheck className="size-4 text-primary" />
                <span>سجل الغياب والحضور التفصيلي</span>
              </h3>

              {childAttendance?.records && childAttendance.records.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="modern-table">
                    <thead>
                      <tr>
                        <th>التاريخ</th>
                        <th>الحالة</th>
                        <th>السبب والملاحظات</th>
                      </tr>
                    </thead>
                    <tbody>
                      {childAttendance.records.map((r: any, idx: number) => (
                        <tr key={idx}>
                          <td className="font-mono text-xs">
                            {r.session?.attendance_date ?? new Date(r.created_at).toLocaleDateString("ar-EG")}
                          </td>
                          <td>
                            <span
                              className={`text-[11px] px-2 py-0.5 rounded-full font-medium ${
                                r.status === "present"
                                  ? "bg-emerald-50 text-emerald-700 border border-emerald-200"
                                  : r.status === "absent"
                                  ? "bg-rose-50 text-rose-700 border border-rose-200"
                                  : "bg-amber-50 text-amber-700 border border-amber-200"
                              }`}
                            >
                              {r.status === "present" ? "حاضر" : r.status === "absent" ? "غائب" : "متأخر / إذن"}
                            </span>
                          </td>
                          <td className="text-xs text-muted-foreground">{r.reason ?? "—"}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="p-6 text-center text-xs text-muted-foreground">
                  لا توجد سجلات غياب مرصودة للطالب في قاعدة البيانات.
                </div>
              )}
            </div>
          </div>
        )}

        {/* TAB 4: TIMETABLE */}
        {activeTab === "timetable" && (
          <div className="space-y-5">
            <div className="card-surface p-5">
              <h3 className="text-xs font-bold text-foreground mb-3 flex items-center gap-2">
                <CalendarDays className="size-4 text-primary" />
                <span>الجدول الدراسي الأسبوعي للفصل ({activeChild?.sectionName})</span>
              </h3>

              {timetable && timetable.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="modern-table">
                    <thead>
                      <tr>
                        <th>اليوم</th>
                        <th>الحصة</th>
                        <th>المادة</th>
                        <th>المعلم</th>
                        <th>القاعة</th>
                      </tr>
                    </thead>
                    <tbody>
                      {timetable.map((t: any, i: number) => (
                        <tr key={i}>
                          <td className="text-xs font-semibold">{t.weekday}</td>
                          <td className="text-xs">{t.period?.name ?? "—"}</td>
                          <td className="text-xs font-semibold text-primary">{t.subject?.name ?? "—"}</td>
                          <td className="text-xs text-muted-foreground">{t.teacher?.full_name ?? "—"}</td>
                          <td className="text-xs font-mono">{t.room ?? "—"}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="p-6 text-center text-xs text-muted-foreground">
                  لم يتم اعتماد الجدول الدراسي لهذا الفصل حتى الآن.
                </div>
              )}
            </div>
          </div>
        )}

        {/* TAB 5: FEES & STATEMENTS (Strictly respecting can_view_fees privilege) */}
        {activeTab === "fees" && activeChild?.canViewFees && (
          <div className="space-y-5">
            <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
              <div className="card-surface p-4">
                <div className="text-xs text-muted-foreground mb-1">الرسوم الدراسية المقررة</div>
                <div className="text-xl font-bold font-mono text-foreground">
                  {(childFees?.baseAnnualFee ?? 0).toLocaleString()} ج.س
                </div>
                <div className="text-[10px] text-muted-foreground mt-1">الرسوم السنوية المعتمدة</div>
              </div>

              <div className="card-surface p-4">
                <div className="text-xs text-muted-foreground mb-1">التخفيضات والإعفاءات</div>
                <div className="text-xl font-bold font-mono text-indigo-600">
                  {(childFees?.discountTotal ?? 0).toLocaleString()} ج.س
                </div>
                <div className="text-[10px] text-muted-foreground mt-1">تخفيض معتمد من الإدارة</div>
              </div>

              <div className="card-surface p-4">
                <div className="text-xs text-muted-foreground mb-1">المبلغ المسدد</div>
                <div className="text-xl font-bold font-mono text-emerald-600">
                  {(childFees?.paidTotal ?? 0).toLocaleString()} ج.س
                </div>
                <div className="text-[10px] text-muted-foreground mt-1">إجمالي السندات الصادرة</div>
              </div>

              <div className="card-surface p-4">
                <div className="text-xs text-muted-foreground mb-1">المتبقي المطلوب</div>
                <div className="text-xl font-bold font-mono text-rose-600">
                  {(childFees?.balance ?? 0).toLocaleString()} ج.س
                </div>
                <div className="text-[10px] text-muted-foreground mt-1">
                  {(childFees?.balance ?? 0) === 0 ? "مسدد بالكامل" : "يستحق السداد بالخزينة"}
                </div>
              </div>
            </div>

            {/* Payments List */}
            <div className="card-surface p-5">
              <h3 className="text-xs font-bold text-foreground mb-3 flex items-center gap-2">
                <Receipt className="size-4 text-primary" />
                <span>سندات الدفع والتحصيل المعتمدة</span>
              </h3>

              {childFees?.payments && childFees.payments.length > 0 ? (
                <div className="space-y-2.5">
                  {childFees.payments.map((p: any, idx: number) => (
                    <div key={idx} className="flex items-center justify-between p-3 rounded-lg border border-border bg-card text-xs">
                      <div className="space-y-0.5">
                        <div className="font-semibold text-foreground flex items-center gap-2">
                          <CheckCircle2 className="size-3.5 text-emerald-600" />
                          <span>سند رقم: {p.receipt_number}</span>
                        </div>
                        <div className="text-[11px] text-muted-foreground">
                          تاريخ: {new Date(p.created_at).toLocaleDateString("ar-EG")} · طريقة الدفع: {p.payment_method}
                        </div>
                      </div>
                      <div className="text-end font-mono">
                        <div className="font-bold text-emerald-700 text-sm">
                          {Number(p.amount).toLocaleString()} ج.س
                        </div>
                        <span className="text-[10px] text-muted-foreground">معتمد بالخزينة</span>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="p-6 text-center text-xs text-muted-foreground">
                  لا توجد سندات سداد مسجلة لهذا الطالب حتى الآن.
                </div>
              )}
            </div>
          </div>
        )}

        {/* TAB 6: ANNOUNCEMENTS & EVENTS */}
        {activeTab === "announcements" && (
          <div className="space-y-5">
            <div className="card-surface p-5">
              <h3 className="text-xs font-bold text-foreground mb-3 flex items-center gap-2">
                <Bell className="size-4 text-primary" />
                <span>إعلانات وتعاميم المدرسة لأولياء الأمور</span>
              </h3>

              {portalData?.announcements && portalData.announcements.length > 0 ? (
                <div className="space-y-3">
                  {portalData.announcements.map((ann: any, idx: number) => (
                    <div key={idx} className="p-4 rounded-lg border border-border bg-card space-y-1.5">
                      <div className="flex items-center justify-between">
                        <h4 className="text-xs font-bold text-foreground">{ann.title}</h4>
                        <span className="text-[10px] text-muted-foreground font-mono">
                          {new Date(ann.created_at).toLocaleDateString("ar-EG")}
                        </span>
                      </div>
                      <p className="text-xs text-muted-foreground leading-relaxed">{ann.content}</p>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="p-6 text-center text-xs text-muted-foreground">
                  لا توجد إعلانات منشورة حالياً من إدارة المدرسة.
                </div>
              )}
            </div>

            {/* Upcoming School Events */}
            <div className="card-surface p-5">
              <h3 className="text-xs font-bold text-foreground mb-3 flex items-center gap-2">
                <Calendar className="size-4 text-primary" />
                <span>الأحداث والمواعيد الهامة في التقويم</span>
              </h3>

              {portalData?.events && portalData.events.length > 0 ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {portalData.events.map((ev: any, idx: number) => (
                    <div key={idx} className="p-3 rounded-lg border border-border bg-card flex items-start gap-3">
                      <div className="p-2 rounded bg-primary/10 text-primary font-bold text-xs shrink-0">
                        <CalendarDays className="size-5" />
                      </div>
                      <div>
                        <div className="font-semibold text-xs text-foreground">{ev.title}</div>
                        <div className="text-[11px] text-muted-foreground mt-0.5">{ev.description}</div>
                        <div className="text-[10px] font-mono text-primary mt-1">تاريخ: {ev.starts_on ?? ev.starts_at}</div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="p-6 text-center text-xs text-muted-foreground">
                  لا توجد فعاليات مجدولة في التقويم حالياً.
                </div>
              )}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
