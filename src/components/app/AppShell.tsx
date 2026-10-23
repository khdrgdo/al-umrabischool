import { useEffect, useState, type ReactNode } from "react";
import { Link, useLocation } from "@tanstack/react-router";
import { Menu, LogOut, ChevronDown, UserRound, type LucideIcon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTitle, SheetDescription } from "@/components/ui/sheet";
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuItem } from "@/components/ui/dropdown-menu";
import { cn } from "@/lib/utils";

type NavDestination = "/dashboard" | "/students" | "/guardians" | "/attendance" | "/fees" | "/grades" | "/calendar" | "/timetable" | "/structure" | "/teachers" | "/subjects" | "/rollover" | "/audit" | "/users" | "/parent";
export type SchoolNavItem = { to: NavDestination; label: string; icon: LucideIcon };

export function AppShell({ email, roleName, navItems, onSignOut, children }: {
  email?: string | undefined; roleName: string; navItems: readonly SchoolNavItem[]; onSignOut: () => void; children: ReactNode;
}) {
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);
  const userName = email?.split("@")[0] ?? roleName;
  useEffect(() => {
    const media = window.matchMedia("(min-width: 1024px)");
    const closeOnDesktop = () => { if (media.matches) setMobileOpen(false); };
    media.addEventListener("change", closeOnDesktop);
    return () => media.removeEventListener("change", closeOnDesktop);
  }, []);

  const navigation = (
    <>
      <div className="px-5 py-5 border-b border-sidebar-border">
        <div className="flex min-w-0 items-center gap-3">
          <div className="grid size-10 shrink-0 place-items-center rounded-full bg-accent text-primary"><UserRound className="size-5" /></div>
          <div className="min-w-0">
            <div className="truncate text-sm font-semibold">{userName}</div>
            <div className="truncate text-xs text-muted-foreground" dir="ltr">{email}</div>
          </div>
        </div>
        <div className="mt-3 text-xs font-medium text-primary">{roleName}</div>
      </div>
      <nav aria-label="التنقل الرئيسي" className="min-h-0 flex-1 overflow-y-auto px-3 py-4 space-y-1">
        {navItems.map(({ to, label, icon: Icon }) => {
          const active = location.pathname === to || location.pathname.startsWith(to + "/");
          return <Link key={to} to={to} onClick={() => setMobileOpen(false)} aria-current={active ? "page" : undefined}
            className={cn("flex min-w-0 items-center gap-3 rounded-md border-s-2 px-3 py-3 text-sm transition-colors focus-visible:outline-2 focus-visible:outline-ring",
              active ? "border-primary bg-sidebar-accent text-sidebar-accent-foreground font-semibold" : "border-transparent text-sidebar-foreground hover:bg-muted hover:text-foreground")}>
            <Icon className="size-4 shrink-0" /><span className="min-w-0">{label}</span>
          </Link>;
        })}
      </nav>
      <div className="border-t border-sidebar-border p-3">
        <Button variant="ghost" onClick={onSignOut} className="w-full justify-start gap-3 text-destructive hover:bg-destructive/10 hover:text-destructive"><LogOut className="size-4" />تسجيل الخروج</Button>
      </div>
    </>
  );

  return <div className="school-shell min-h-dvh bg-background text-foreground" dir="rtl">
    <header className="school-topbar sticky top-0 z-30 grid h-[52px] grid-cols-[minmax(0,1fr)_auto] items-center gap-3 bg-brand-header px-3 text-brand-header-foreground shadow-header sm:px-5 lg:h-[72px] lg:px-7">
      <div className="flex min-w-0 items-center gap-3">
        <Button variant="ghost" size="icon" aria-label="فتح القائمة" aria-expanded={mobileOpen} onClick={() => setMobileOpen(true)} className="size-10 shrink-0 text-brand-header-foreground hover:bg-brand-header-hover hover:text-brand-header-foreground lg:hidden"><Menu className="size-5" /></Button>
        {/* No authentic logo file is available. Text identity only: never substitute a generic school icon. */}
        <Link to="/dashboard" className="min-w-0 text-brand-header-foreground">
          <div className="truncate text-base font-semibold lg:text-xl">مدرسة العمرابي<span className="hidden lg:inline"> الثانوية</span></div>
          <div className="hidden text-xs text-brand-header-muted lg:block">نظام إدارة المدرسة</div>
        </Link>
      </div>
      <div className="flex shrink-0 items-center gap-5">
        <time className="hidden text-xs text-brand-header-muted xl:block">{new Date().toLocaleDateString("ar-SD", { weekday: "long", day: "numeric", month: "long" })}</time>
        <DropdownMenu dir="rtl">
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" aria-label="قائمة المستخدم" className="h-10 gap-2 px-2 text-brand-header-foreground hover:bg-brand-header-hover hover:text-brand-header-foreground">
              <UserRound className="size-5 shrink-0" /><span className="hidden max-w-40 truncate text-xs lg:block">{userName}</span><ChevronDown className="hidden size-3 lg:block" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="max-w-[calc(100vw-24px)] w-64">
            <DropdownMenuLabel className="break-words"><span className="block">{roleName}</span><span className="block text-xs font-normal text-muted-foreground" dir="ltr">{email}</span></DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem onSelect={onSignOut} className="gap-2 text-destructive"><LogOut />تسجيل الخروج</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
    <div className="grid min-w-0 lg:grid-cols-[256px_minmax(0,1fr)]">
      <aside aria-label="القائمة الجانبية" className="sticky top-[72px] hidden h-[calc(100dvh-72px)] min-h-0 flex-col border-e border-sidebar-border bg-sidebar lg:flex">{navigation}</aside>
      <main className="admin-content min-w-0 w-full max-w-7xl mx-auto p-3 sm:p-5 lg:p-8">{children}</main>
    </div>
    <Sheet open={mobileOpen} onOpenChange={setMobileOpen}>
      <SheetContent side="right" dir="rtl" className="school-nav-drawer flex w-[min(288px,calc(100vw-32px))] flex-col gap-0 bg-sidebar p-0">
        <div className="border-b border-sidebar-border px-5 py-4 pe-12"><SheetTitle className="text-base">مدرسة العمرابي</SheetTitle><SheetDescription className="text-xs">القائمة الرئيسية</SheetDescription></div>
        {navigation}
      </SheetContent>
    </Sheet>
  </div>;
}