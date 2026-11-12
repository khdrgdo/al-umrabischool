import { useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { z } from "zod";
import { supabase } from "@/integrations/supabase/client";
import { schoolPageHead } from "@/lib/pageHead";
import { canManage, errMsg, useMe } from "@/lib/staff";
import { khartoumReportTime, readAll, reportStatusSchema } from "@/lib/adminFeatures";
import { PageHead, Field, Empty } from "@/components/app/kit";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/_authenticated/parent-reports")({
  head: () => schoolPageHead("بلاغات أولياء الأمور — مدرسة العمرابي", "مراجعة بلاغات أولياء الأمور ومتابعة حالتها."),
  component: ParentReports,
});
const categories: Record<string, string> = { bug: "مشكلة", question: "سؤال", suggestion: "اقتراح", other: "أخرى" };
const statuses = { new: "جديد", seen: "تمت المشاهدة", resolved: "تم الحل" };
function ParentReports() {
  const [status, setStatus] = useState("");
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);
  const qc = useQueryClient();
  const query = useQuery({
    queryKey: ["parent-reports", status], refetchInterval: 60_000,
    queryFn: () => readAll((a, b) => {
      let request = supabase.from("parent_reports").select("*,guardians(full_name),students(full_name)").order("created_at", { ascending: false }).order("id");
      if (status) request = request.eq("status", reportStatusSchema.parse(status));
      return request.range(a, b);
    }),
  });
  const update = useMutation({
    mutationFn: async (value: { id: string; status: string }) => {
      if (!manager) throw new Error("ليست لديك صلاحية لهذه العملية");
      const input = z.object({ id: z.string().uuid(), status: reportStatusSchema }).parse(value);
      const { error } = await supabase.from("parent_reports").update({ status: input.status }).eq("id", input.id).select("id").single();
      if (error) throw error;
    },
    onSuccess: async () => { await Promise.all([qc.invalidateQueries({ queryKey: ["parent-reports"] }), qc.invalidateQueries({ queryKey: ["parent-reports-new-count"] })]); toast.success("حُدّثت حالة البلاغ"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  return <div className="space-y-5">
    <PageHead title="بلاغات أولياء الأمور" />
    <Field label="حالة البلاغ"><select aria-label="حالة البلاغ" className="field-select w-full sm:w-56" value={status} onChange={(e) => setStatus(e.target.value)}><option value="">جميع الحالات</option>{Object.entries(statuses).map(([key, name]) => <option key={key} value={key}>{name}</option>)}</select></Field>
    {query.isError ? <div role="alert" className="text-destructive">{errMsg(query.error)} <Button variant="outline" onClick={() => query.refetch()}>إعادة المحاولة</Button></div> : query.isLoading ? <p>جارٍ تحميل البلاغات…</p> : <div className="sheet overflow-x-auto"><table className="ledger"><thead><tr><th>الوقت — الخرطوم</th><th>ولي الأمر</th><th>الطالب</th><th>التصنيف</th><th>البلاغ</th><th>التطبيق / الجهاز</th><th>الحالة</th></tr></thead><tbody>
      {query.data?.map((report) => <tr key={report.id}><td>{khartoumReportTime(report.created_at)}</td><td>{report.guardians?.full_name ?? "—"}</td><td>{report.students?.full_name ?? "—"}</td><td>{categories[report.category] ?? report.category}</td><td className="min-w-64 max-w-lg whitespace-pre-wrap break-words">{report.body}</td><td className="text-xs"><div dir="ltr">{report.app_version ?? "—"}</div><div className="break-words">{report.device ?? "—"}</div></td><td><select aria-label={`حالة بلاغ ${report.guardians?.full_name ?? report.id}`} className="field-select" disabled={!manager || update.isPending} value={report.status} onChange={(e) => update.mutate({ id: report.id, status: e.target.value })}>{Object.entries(statuses).map(([key, name]) => <option key={key} value={key}>{name}</option>)}</select></td></tr>)}
    </tbody></table>{!query.data?.length && <Empty title="لا توجد بلاغات تطابق التصفية" />}</div>}
  </div>;
}