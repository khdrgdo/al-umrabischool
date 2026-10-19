import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { PageHead, Empty } from "@/components/app/kit";

export const Route = createFileRoute("/_authenticated/audit")({
  head: () => ({ meta: [{ title: "سجل التعديلات — مدرسة العمرابي" }] }),
  component: Audit,
});

const TABLES: Record<string, string> = {
  students: "الطلاب", enrollments: "القيد", teachers: "المعلمون", subjects: "المواد", sections: "الشعب",
  academic_years: "الأعوام", grades: "الصفوف", tracks: "المسارات", specializations: "التخصصات", user_roles: "الصلاحيات",
  timetable_entries: "الجدول", teaching_assignments: "الإسناد", periods: "الحصص", school_days: "أيام الدراسة", section_timetables: "اعتماد الجدول", schools: "المدرسة",
};
const ACT: Record<string, string> = { INSERT: "إضافة", UPDATE: "تعديل", DELETE: "حذف" };

function diff(o: Record<string, unknown> | null, n: Record<string, unknown> | null) {
  if (!o || !n) return "";
  return Object.keys(n).filter((k) => k !== "updated_at" && JSON.stringify(o[k]) !== JSON.stringify(n[k]))
    .map((k) => `${k}: ${o[k] ?? "—"} ← ${n[k] ?? "—"}`).join(" · ");
}
const label = (d: Record<string, unknown> | null) => (d ? String(d["full_name"] ?? d["name"] ?? d["label"] ?? d["role"] ?? "") : "");

function Audit() {
  const [table, setTable] = useState("");
  const { data, error } = useQuery({
    queryKey: ["audit", table],
    queryFn: async () => {
      let q = supabase.from("audit_log").select("*").order("created_at", { ascending: false }).limit(200);
      if (table) q = q.eq("table_name", table);
      const [{ data: rows, error }, { data: people }] = await Promise.all([q, supabase.from("profiles").select("id,full_name,email")]);
      if (error) throw error;
      return { rows: rows ?? [], people: people ?? [] };
    },
  });
  return (
    <div>
      <PageHead title="سجل التعديلات" sub="آخر 200 عملية — يُسجَّل تلقائيًا ولا يمكن تعديله" />
      <select className="field-select mb-4" value={table} onChange={(e) => setTable(e.target.value)}>
        <option value="">كل الأقسام</option>
        {Object.entries(TABLES).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
      </select>
      {error ? <Empty>ليست لديك صلاحية لعرض السجل</Empty> : (
        <div className="sheet overflow-x-auto">
          <table className="ledger">
            <thead><tr><th>الوقت</th><th>المستخدم</th><th>القسم</th><th>العملية</th><th>السجل</th><th>التغيير</th></tr></thead>
            <tbody>
              {data?.rows.map((r) => {
                const p = data.people.find((x) => x.id === r.actor_id);
                const o = r.old_data as Record<string, unknown> | null, n = r.new_data as Record<string, unknown> | null;
                return (
                  <tr key={r.id}>
                    <td className="num text-xs whitespace-nowrap">{new Date(r.created_at).toLocaleString("ar-SD", { dateStyle: "short", timeStyle: "short" })}</td>
                    <td className="text-xs">{p?.full_name || p?.email || (r.actor_id ? "—" : "النظام")}</td>
                    <td>{TABLES[r.table_name] ?? r.table_name}</td>
                    <td className={r.action === "DELETE" ? "text-stamp" : ""}>{ACT[r.action]}</td>
                    <td className="text-xs">{label(n ?? o)}</td>
                    <td className="text-xs text-muted-foreground max-w-md truncate" title={diff(o, n)}>{diff(o, n)}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          {data?.rows.length === 0 && <Empty>لا توجد عمليات</Empty>}
        </div>
      )}
    </div>
  );
}
