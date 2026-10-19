import { createFileRoute, Link, Outlet, redirect, useNavigate } from "@tanstack/react-router";
import { useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { useMe, ROLE_LABELS, canManage } from "@/lib/staff";
import { Button } from "@/components/ui/button";

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

  if (isLoading) return <div className="p-10 text-center text-muted-foreground">جارٍ التحميل…</div>;

  if (!me?.roles.length) {
    return (
      <main className="min-h-screen flex items-center justify-center p-6 text-center">
        <div className="max-w-sm">
          <h1 className="text-3xl">بانتظار منح الصلاحية</h1>
          <p className="mt-3 text-muted-foreground">
            حسابك ({me?.user.email}) لم يُمنح أي دور بعد. اطلب من مالك المدرسة منحك الصلاحية.
          </p>
          <Button variant="outline" className="mt-6" onClick={signOut}>تسجيل الخروج</Button>
        </div>
      </main>
    );
  }

  const manager = canManage(me.roles);
  const links = [
    { to: "/dashboard", label: "الملخص" },
    { to: "/students", label: "سجل الطلاب" },
    { to: "/timetable", label: "الجدول الدراسي" },
    { to: "/structure", label: "الصفوف والشعب" },
    { to: "/teachers", label: "المعلمون" },
    { to: "/subjects", label: "المواد" },
    ...(manager ? [{ to: "/audit", label: "سجل التعديلات" } as const] : []),
    ...(me.roles.includes("owner") ? [{ to: "/users", label: "المستخدمون" } as const] : []),
  ] as const;

  return (
    <div className="min-h-screen">
      <header className="bg-ink text-paper">
        <div className="max-w-7xl mx-auto px-4 md:px-8 pt-4 flex items-start justify-between gap-4">
          <div>
            <div className="font-display text-2xl leading-none">مدرسة العمرابي الثانوية</div>
            <div className="text-xs opacity-60 mt-1">سجل الإدارة المدرسية</div>
          </div>
          <div className="text-xs text-end">
            <div className="opacity-90">{me.user.email}</div>
            <div className="opacity-60">{me.roles.map((r) => ROLE_LABELS[r]).join("، ")}</div>
            <button onClick={signOut} className="mt-1 underline underline-offset-4 opacity-80 hover:opacity-100">خروج</button>
          </div>
        </div>
        <nav className="max-w-7xl mx-auto px-2 md:px-6 mt-3 flex overflow-x-auto">
          {links.map((l) => (
            <Link key={l.to} to={l.to} className="tab-link" activeProps={{ className: "active" }}>
              {l.label}
            </Link>
          ))}
        </nav>
      </header>
      <main className="max-w-7xl mx-auto px-4 md:px-8 py-6 md:py-8">
        <Outlet />
      </main>
    </div>
  );
}
