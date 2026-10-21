import { createFileRoute, Link, Outlet, redirect, useNavigate, useLocation } from "@tanstack/react-router";
import { useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
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
} from "lucide-react";
import { cn } from "@/lib/utils";

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
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);

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

  const currentRole = me.roles[0];
  const roleName = ROLE_LABELS[currentRole] ?? currentRole;

  return (
    <div className="min-h-screen flex bg-background text-foreground">
      {/* Mobile Backdrop */}
      {mobileOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/40 backdrop-blur-xs md:hidden"
          onClick={() => setMobileOpen(false)}
        />
      )}

      {/* Desktop & Mobile Sidebar (Right side in RTL) */}
      <aside
        className={cn(
          "fixed top-0 bottom-0 z-50 flex flex-col w-64 bg-sidebar border-s border-sidebar-border transition-transform duration-200 ease-in-out md:static md:translate-x-0 shadow-xs",
          mobileOpen ? "translate-x-0" : "translate-x-full md:translate-x-0"
        )}
      >
        {/* Sidebar Header / Brand */}
        <div className="h-16 px-5 flex items-center justify-between border-b border-sidebar-border">
          <div className="flex items-center gap-3">
            <div className="h-9 w-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center border border-primary/20">
              <School className="h-5 w-5" />
            </div>
            <div>
              <div className="font-semibold text-sm leading-tight text-foreground">مدرسة العمرابي</div>
              <div className="text-[11px] text-muted-foreground flex items-center gap-1 mt-0.5">
                <span>الثانوية بنين</span>
                <span className="inline-block h-1 w-1 rounded-full bg-emerald-500" />
              </div>
            </div>
          </div>
          <button
            onClick={() => setMobileOpen(false)}
            className="md:hidden text-muted-foreground hover:text-foreground p-1"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* User Card */}
        <div className="p-3 mx-3 mt-3 rounded-lg bg-muted/60 border border-border/70">
          <div className="flex items-center gap-2.5">
            <div className="h-8 w-8 rounded-full bg-primary text-primary-foreground font-semibold text-xs flex items-center justify-center shrink-0">
              {me.user.email?.[0].toUpperCase()}
            </div>
            <div className="min-w-0 flex-1">
              <div className="text-xs font-semibold truncate text-foreground">{me.user.email?.split("@")[0]}</div>
              <div className="text-[11px] text-muted-foreground truncate">{me.user.email}</div>
            </div>
          </div>
          <div className="mt-2 pt-2 border-t border-border/50 flex items-center justify-between">
            <span className="text-[11px] font-medium px-2 py-0.5 rounded-full bg-primary/10 text-primary">
              {roleName}
            </span>
            <span className="text-[10px] text-muted-foreground">صلاحية نشطة</span>
          </div>
        </div>

        {/* Navigation Links */}
        <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
          <div className="px-3 pb-1 text-[11px] font-medium text-muted-foreground">التنقل الرئيسي</div>
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.to || location.pathname.startsWith(item.to + "/");
            return (
              <Link
                key={item.to}
                to={item.to}
                onClick={() => setMobileOpen(false)}
                className={cn(
                  "flex items-center gap-3 px-3 py-2.5 text-xs font-medium rounded-lg transition-colors",
                  isActive
                    ? "bg-accent text-accent-foreground font-semibold shadow-xs"
                    : "text-muted-foreground hover:bg-muted/70 hover:text-foreground"
                )}
              >
                <Icon className={cn("h-4 w-4 shrink-0", isActive ? "text-primary" : "text-muted-foreground")} />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>

        {/* Sidebar Footer / Logout */}
        <div className="p-3 border-t border-sidebar-border">
          <button
            onClick={signOut}
            className="w-full flex items-center gap-2 px-3 py-2 text-xs font-medium text-destructive hover:bg-destructive/10 rounded-lg transition-colors"
          >
            <LogOut className="h-4 w-4 shrink-0" />
            <span>تسجيل الخروج</span>
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Topbar */}
        <header className="sticky top-0 z-30 h-16 bg-panel border-b border-line flex items-center justify-between px-4 md:px-8 shadow-xs">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setMobileOpen(true)}
              className="md:hidden p-2 text-muted-foreground hover:text-foreground hover:bg-muted rounded-lg"
              aria-label="القائمة"
            >
              <Menu className="h-5 w-5" />
            </button>
            <div className="hidden sm:flex items-center gap-2 text-xs text-muted-foreground">
              <span className="font-medium text-foreground">نظام إدارة المدرسة</span>
              <span>/</span>
              <span>العام الحالي 2026/2027</span>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="hidden md:flex items-center gap-1.5 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-medium">
              <Sparkles className="h-3.5 w-3.5" />
              <span>مدرسة العمرابي الثانوية بنين</span>
            </div>
            <div className="h-4 w-px bg-border hidden md:block" />
            <div className="text-xs text-muted-foreground hidden sm:block">
              {new Date().toLocaleDateString("ar-SD", { weekday: "long", day: "numeric", month: "long" })}
            </div>
          </div>
        </header>

        {/* Content View */}
        <main className="flex-1 p-4 md:p-8 max-w-7xl w-full mx-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

