import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useSchool, errMsg } from "@/lib/staff";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";

export const Route = createFileRoute("/_authenticated/teachers")({
  head: () => ({ meta: [{ title: "المعلمون — مدرسة العمرابي" }] }),
  component: Teachers,
});

function Teachers() {
  const qc = useQueryClient();
  const { data: school } = useSchool();
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const { data: rows } = useQuery({
    queryKey: ["teachers"],
    queryFn: async () => (await supabase.from("teachers").select("*").order("full_name")).data ?? [],
  });
  const add = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.from("teachers").insert({ school_id: school!.id, full_name: name, phone: phone || null });
      if (error) throw error;
    },
    onSuccess: () => { setName(""); setPhone(""); qc.invalidateQueries({ queryKey: ["teachers"] }); toast.success("أضيف المعلم"); },
    onError: (e) => toast.error(errMsg(e)),
  });
  const toggle = useMutation({
    mutationFn: async (r: { id: string; is_active: boolean }) => {
      const { error } = await supabase.from("teachers").update({ is_active: !r.is_active }).eq("id", r.id);
      if (error) throw error;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["teachers"] }),
    onError: (e) => toast.error(errMsg(e)),
  });
  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-primary">المعلمون</h1>
      <Card className="p-4">
        <form className="flex flex-wrap gap-2" onSubmit={(e) => { e.preventDefault(); add.mutate(); }}>
          <Input className="flex-1 min-w-40" placeholder="الاسم الكامل" value={name} onChange={(e) => setName(e.target.value)} required />
          <Input className="w-40" dir="ltr" placeholder="الهاتف" value={phone} onChange={(e) => setPhone(e.target.value)} />
          <Button disabled={add.isPending || !school}>إضافة</Button>
        </form>
      </Card>
      <Card className="divide-y">
        {rows?.length === 0 && <p className="p-6 text-center text-muted-foreground">لا يوجد معلمون بعد</p>}
        {rows?.map((r) => (
          <div key={r.id} className="flex items-center justify-between p-3">
            <div>
              <div className={r.is_active ? "" : "line-through text-muted-foreground"}>{r.full_name}</div>
              {r.phone && <div className="text-xs text-muted-foreground" dir="ltr">{r.phone}</div>}
            </div>
            <Button size="sm" variant="ghost" onClick={() => toggle.mutate(r)}>{r.is_active ? "إيقاف" : "تفعيل"}</Button>
          </div>
        ))}
      </Card>
    </div>
  );
}
