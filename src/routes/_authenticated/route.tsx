import { createFileRoute, Link, Outlet, redirect, useNavigate } from "@tanstack/react-router";
import { useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { useMe, ROLE_LABELS } from "@/lib/staff";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/_authenticated")({
  ssr: false,
  beforeLoad: async () => {
    const { data } = await supabase.auth.getUser();
    if (!data.user) throw redirect({ to: "/auth" });
  },
  component: Layout,
});

const NAV = [
  { to: "/dashboard", label: "الرئيسية" },
  { to: "/structure", label: "الهيكل الدراسي" },
  { to: "/students", label: "الطلاب" },
  { to: "/teachers", label: "المعلمون" },
  { to: "/subjects", label: "المواد" },
  { to: "/users", label: "المستخدمون" },
] as const;

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
          <h1 className="text-2xl font-bold text-primary">بانتظار منح الصلاحية</h1>
          <p className="mt-3 text-muted-foreground">
            حسابك ({me?.user.email}) لم يُمنح أي دور بعد. اطلب من مالك المدرسة منحك الصلاحية.
          </p>
          <Button variant="outline" className="mt-6" onClick={signOut}>تسجيل الخروج</Button>
        </div>
      </main>
    );
  }

  return (
    <div className="min-h-screen md:flex">
      <aside className="bg-sidebar text-sidebar-foreground md:w-60 md:min-h-screen flex md:flex-col">
        <div className="hidden md:block p-5 border-b border-sidebar-border">
          <div className="font-display text-xl text-gold">مدرسة العمرابي</div>
          <div className="text-xs opacity-70 mt-1">{me.roles.map((r) => ROLE_LABELS[r]).join("، ")}</div>
        </div>
        <nav className="flex md:flex-col gap-1 p-2 overflow-x-auto flex-1">
          {NAV.map((n) => (
            <Link
              key={n.to}
              to={n.to}
              className="whitespace-nowrap rounded-md px-3 py-2 text-sm hover:bg-sidebar-accent"
              activeProps={{ className: "bg-sidebar-accent text-gold" }}
            >
              {n.label}
            </Link>
          ))}
        </nav>
        <button onClick={signOut} className="px-4 py-3 text-sm opacity-80 hover:opacity-100 whitespace-nowrap">
          خروج
        </button>
      </aside>
      <main className="flex-1 p-4 md:p-8 max-w-6xl">
        <Outlet />
      </main>
    </div>
  );
}
