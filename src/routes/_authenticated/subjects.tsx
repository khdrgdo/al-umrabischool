import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useSchool, errMsg } from "@/lib/staff";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";

export const Route = createFileRoute("/_authenticated/subjects")({
  head: () => ({ meta: [{ title: "المواد — مدرسة العمرابي" }] }),
  component: Subjects,
});

function Subjects() {
  const qc = useQueryClient();
  const { data: school } = useSchool();
  const [name, setName] = useState("");
  const [code, setCode] = useState("");
  const { data: rows } = useQuery({
    queryKey: ["subjects"],
    queryFn: async () => (await supabase.from("subjects").select("*").order("name")).data ?? [],
  });
  const add = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.from("subjects").insert({ school_id: school!.id, name, code: code || null });
      if (error) throw error;
    },
    onSuccess: () => { setName(""); setCode(""); qc.invalidateQueries({ queryKey: ["subjects"] }); toast.success("أضيفت المادة"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const toggle = useMutation({
    mutationFn: async (r: { id: string; is_active: boolean }) => {
      const { error } = await supabase.from("subjects").update({ is_active: !r.is_active }).eq("id", r.id);
      if (error) throw error;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["subjects"] }),
    onError: (e) => toast.error(errMsg(e)),
  });
  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-primary">المواد الدراسية</h1>
      <Card className="p-4">
        <form className="flex flex-wrap gap-2" onSubmit={(e) => { e.preventDefault(); add.mutate(); }}>
          <Input className="flex-1 min-w-40" placeholder="اسم المادة" value={name} onChange={(e) => setName(e.target.value)} required />
          <Input className="w-32" placeholder="الرمز (اختياري)" value={code} onChange={(e) => setCode(e.target.value)} />
          <Button disabled={add.isPending || !school}>إضافة</Button>
        </form>
      </Card>
      <Card className="divide-y">
        {rows?.length === 0 && <p className="p-6 text-center text-muted-foreground">لا توجد مواد بعد</p>}
        {rows?.map((r) => (
          <div key={r.id} className="flex items-center justify-between p-3">
            <span className={r.is_active ? "" : "line-through text-muted-foreground"}>{r.name} {r.code && <span className="text-xs text-muted-foreground">({r.code})</span>}</span>
            <Button size="sm" variant="ghost" onClick={() => toggle.mutate(r)}>{r.is_active ? "إيقاف" : "تفعيل"}</Button>
          </div>
        ))}
      </Card>
    </div>
  );
}
