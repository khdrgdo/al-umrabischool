import { schoolPageHead } from "@/lib/pageHead";
import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useSchool, useMe, canManage, errMsg } from "@/lib/staff";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { PageHead, Empty } from "@/components/app/kit";

export const Route = createFileRoute("/_authenticated/subjects")({
  head: () => schoolPageHead("المواد — مدرسة العمرابي", "المواد في نظام إدارة مدرسة العمرابي الثانوية."),
  component: Subjects,
});

function Subjects() {
  const qc = useQueryClient();
  const { data: school } = useSchool();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);
  const [name, setName] = useState("");
  const [code, setCode] = useState("");
  const { data } = useQuery({
    queryKey: ["subjects"],
    queryFn: async () => {
      const [s, a] = await Promise.all([
        supabase.from("subjects").select("*").order("name"),
        supabase.from("teaching_assignments").select("subject_id,section_id"),
      ]);
      return { rows: s.data ?? [], assigns: a.data ?? [] };
    },
  });
  const refresh = () => qc.invalidateQueries({ queryKey: ["subjects"] });
  const add = useMutation({
    mutationFn: async () => { const { error } = await supabase.from("subjects").insert({ school_id: school!.id, name, code: code || null }); if (error) throw error; },
    onSuccess: () => { setName(""); setCode(""); refresh(); toast.success("أُضيفت المادة"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const upd = useMutation({
    mutationFn: async (v: { id: string; name?: string; code?: string | null; is_active?: boolean }) => {
      const { id, ...rest } = v; const { error } = await supabase.from("subjects").update(rest).eq("id", id); if (error) throw error;
    },
    onSuccess: () => { refresh(); toast.success("حُفظ"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  return (
    <div>
      <PageHead title="المواد الدراسية" sub="عدّل الاسم أو الرمز مباشرة في الجدول، ثم انقر خارج الخانة للحفظ" />
      {manager && (
        <form className="flex flex-wrap gap-2 mb-5" onSubmit={(e) => { e.preventDefault(); add.mutate(); }}>
          <Input className="w-64" placeholder="اسم المادة" value={name} onChange={(e) => setName(e.target.value)} required />
          <Input className="w-28" placeholder="الرمز" dir="ltr" value={code} onChange={(e) => setCode(e.target.value)} />
          <Button disabled={add.isPending || !school}>إضافة مادة</Button>
        </form>
      )}
      <div className="sheet overflow-x-auto">
        <table className="ledger">
          <thead><tr><th>المادة</th><th>الرمز</th><th>تُدرَّس في</th><th>الحالة</th></tr></thead>
          <tbody>
            {data?.rows.map((r) => (
              <tr key={r.id} className={r.is_active ? "" : "opacity-50"}>
                <td><Input className="h-8 border-transparent bg-transparent hover:border-input" disabled={!manager} defaultValue={r.name} onBlur={(e) => e.target.value !== r.name && upd.mutate({ id: r.id, name: e.target.value })} /></td>
                <td><Input className="h-8 w-24 border-transparent bg-transparent hover:border-input" dir="ltr" disabled={!manager} defaultValue={r.code ?? ""} onBlur={(e) => e.target.value !== (r.code ?? "") && upd.mutate({ id: r.id, code: e.target.value || null })} /></td>
                <td className="num">{data.assigns.filter((a) => a.subject_id === r.id).length} شعبة</td>
                <td>
                  <button disabled={!manager} onClick={() => upd.mutate({ id: r.id, is_active: !r.is_active })} className={r.is_active ? "stamp text-ok" : "stamp text-stamp"}>
                    {r.is_active ? "مفعّلة" : "موقوفة"}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {data?.rows.length === 0 && <Empty>لا توجد مواد</Empty>}
      </div>
    </div>
  );
}
