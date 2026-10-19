import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card } from "@/components/ui/card";

export const Route = createFileRoute("/_authenticated/dashboard")({
  head: () => ({ meta: [{ title: "الرئيسية — مدرسة العمرابي" }] }),
  component: Dashboard,
});

async function count(table: "students" | "teachers" | "subjects" | "sections") {
  const q = supabase.from(table).select("id", { count: "exact", head: true });
  const { count: c } = table === "students" ? await q.eq("status", "active") : await q;
  return c ?? 0;
}

function Dashboard() {
  const { data } = useQuery({
    queryKey: ["dash"],
    queryFn: async () => {
      const [students, teachers, subjects, sections] = await Promise.all([
        count("students"), count("teachers"), count("subjects"), count("sections"),
      ]);
      const { data: year } = await supabase.from("academic_years").select("name").eq("is_current", true).maybeSingle();
      return { students, teachers, subjects, sections, year: year?.name };
    },
  });
  const items = [
    ["طلاب نشطون", data?.students],
    ["معلمون", data?.teachers],
    ["مواد", data?.subjects],
    ["شعب", data?.sections],
  ] as const;
  return (
    <div>
      <h1 className="text-3xl font-bold text-primary">لوحة الإدارة</h1>
      <p className="text-muted-foreground mt-1">
        السنة الدراسية الحالية: {data?.year ?? "لم تُحدَّد بعد — أضفها من الهيكل الدراسي"}
      </p>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6">
        {items.map(([label, v]) => (
          <Card key={label} className="p-5">
            <div className="text-sm text-muted-foreground">{label}</div>
            <div className="text-3xl font-bold mt-2 text-primary">{v ?? "—"}</div>
          </Card>
        ))}
      </div>
    </div>
  );
}
