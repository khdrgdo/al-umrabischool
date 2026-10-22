import { createFileRoute, Link } from "@tanstack/react-router";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "نظام إدارة مدرسة العمرابي" },
      { name: "description", content: "بوابة إدارة مدرسة العمرابي الثانوية: الطلاب، الصفوف، المعلمون والمواد." },
      { property: "og:title", content: "نظام إدارة مدرسة العمرابي" },
      { property: "og:description", content: "بوابة إدارة مدرسة العمرابي الثانوية." },
    ],
  }),
  component: Index,
});

function Index() {
  return (
    <main className="min-h-screen bg-sidebar text-sidebar-foreground flex flex-col">
      <div className="flex-1 flex flex-col items-center justify-center px-6 text-center">
        <div className="mb-6 h-16 w-16 rounded-full border-2 border-gold flex items-center justify-center font-display text-3xl text-gold">ع</div>
        <h1 className="text-4xl md:text-6xl font-bold leading-tight">مدرسة العمرابي</h1>
        <p className="mt-4 max-w-md text-sidebar-foreground/75">
          نظام إدارة المدرسة — للمالك ومدير المدرسة والمشرفين.
        </p>
        <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
          <Button asChild size="lg" className="bg-primary text-primary-foreground hover:bg-primary/90">
            <Link to="/auth">دخول الإدارة المدرسية</Link>
          </Button>
          <Button asChild size="lg" variant="outline" className="border-sidebar-border bg-card text-foreground hover:bg-muted">
            <Link to="/parent">بوابة أولياء الأمور</Link>
          </Button>
        </div>
      </div>
      <p className="pb-6 text-center text-xs text-sidebar-foreground/50">مدرسة العمرابي الثانوية</p>
    </main>
  );
}
