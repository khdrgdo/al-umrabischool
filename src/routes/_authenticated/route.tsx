import { createFileRoute, Outlet, redirect, useNavigate } from "@tanstack/react-router";
import { useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { useMe, ROLE_LABELS, canManage } from "@/lib/staff";
import { Button } from "@/components/ui/button";
import {
  LayoutDashboard,
  Users,
  ClipboardCheck,
  CalendarDays,
  Layers,
  GraduationCap,
  BookOpen,
  ShieldCheck,
  UserCog,
  LogOut,
  Menu,
  X,
  School,
  Sparkles,
  Banknote,
  Award,
  Calendar,
  ArrowRightLeft,
  UserCheck,
} from "lucide-react";
import { AppShell } from "@/components/app/AppShell";

export const Route = createFileRoute("/_authenticated")({
  ssr: false,
  beforeLoad: async () => {
    const { data } = await supabase.auth.getUser();
    if (!data.user) throw redirect({ to: "/auth" });
  },
  component: Layout,
});

function Layout() {
  const { data: me, isLoading } = useMe();
  const qc = useQueryClient();
  const nav = useNavigate();

  async function signOut() {
    await qc.cancelQueries();
    qc.clear();
    await supabase.auth.signOut();
    nav({ to: "/auth", replace: true });
  }

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background text-muted-foreground text-sm">
        <div className="flex flex-col items-center gap-3">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
          <span>جارٍ التحميل…</span>
        </div>
      </div>
    );
  }

  if (!me?.roles.length) {
    return (
      <main className="min-h-screen flex items-center justify-center p-6 text-center bg-background">
        <div className="card-surface max-w-md p-8">
          <div className="h-12 w-12 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center mx-auto mb-4 border border-amber-200">
            <ShieldCheck className="h-6 w-6" />
          </div>
          <h1 className="text-2xl font-bold text-foreground">بانتظار منح الصلاحية</h1>
          <p className="mt-3 text-sm text-muted-foreground leading-relaxed">
            حسابك (<span className="font-mono text-xs text-foreground font-medium">{me?.user.email}</span>) لم يُمنح أي دور بعد. اطلب من مالك المدرسة تفعيل حسابك.
          </p>
          <Button variant="outline" className="mt-6 w-full" onClick={signOut}>
            تسجيل الخروج
          </Button>
        </div>
      </main>
    );
  }

  const manager = canManage(me.roles);

  const navItems = [
    { to: "/dashboard", label: "لوحة التحكم", icon: LayoutDashboard },
    { to: "/students", label: "سجل الطلاب", icon: Users },
    { to: "/guardians", label: "أولياء الأمور", icon: UserCheck },
    { to: "/attendance", label: "الحضور والغياب", icon: ClipboardCheck },
    { to: "/fees", label: "الرسوم والمالية", icon: Banknote },
    { to: "/grades", label: "الدرجات والتقييمات", icon: Award },
    { to: "/calendar", label: "التقويم والإعلانات", icon: Calendar },
    { to: "/timetable", label: "الجدول المدرسي", icon: CalendarDays },
    { to: "/structure", label: "الصفوف والشعب", icon: Layers },
    { to: "/teachers", label: "المعلمون", icon: GraduationCap },
    { to: "/subjects", label: "المواد الدراسية", icon: BookOpen },
    ...(manager ? [{ to: "/rollover", label: "الترحيل السنوي", icon: ArrowRightLeft } as const] : []),
    ...(manager ? [{ to: "/audit", label: "سجل التعديلات", icon: ShieldCheck } as const] : []),
    ...(me.roles.includes("owner") ? [{ to: "/users", label: "إدارة المستخدمين", icon: UserCog } as const] : []),
  ] as const;

  const currentRole = me.roles[0] ?? "supervisor";
  const roleName = ROLE_LABELS[currentRole] ?? currentRole;

  return <AppShell email={me.user.email} roleName={roleName} navItems={navItems} onSignOut={signOut}>
    <Outlet />
  </AppShell>;
}
