import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { canManage, errMsg, useMe, useSchool } from "@/lib/staff";
import { whatsappSchema } from "@/lib/adminFeatures";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/app/kit";

export function SchoolWhatsapp() {
  const { data: school, isError } = useSchool();
  const { data: me } = useMe();
  const manager = canManage(me?.roles ?? []);
  const [draft, setDraft] = useState<string | null>(null);
  const qc = useQueryClient();
  const save = useMutation({
    mutationFn: async () => {
      if (!manager || !school) throw new Error("ليست لديك صلاحية لهذه العملية");
      const whatsapp_number = whatsappSchema.parse(draft ?? school.whatsapp_number ?? "");
      const { data, error } = await supabase.from("schools").update({ whatsapp_number }).eq("id", school.id).select("id").single();
      if (error) throw error;
      if (!data) throw new Error("لم يُحفظ الرقم");
    },
    onSuccess: async () => { await qc.invalidateQueries({ queryKey: ["school"] }); setDraft(null); toast.success("حُفظ رقم واتساب المدرسة"); },
    onError: (error) => toast.error(errMsg(error)),
  });
  return <section className="sheet p-4 max-w-lg space-y-3">
    <h2 className="font-semibold">رقم واتساب المدرسة</h2>
    {isError ? <p className="text-destructive text-sm">تعذر تحميل رقم المدرسة</p> : <form className="space-y-3" onSubmit={(e) => { e.preventDefault(); save.mutate(); }}>
      <Field label="الرقم الدولي دون +"><Input aria-label="رقم واتساب المدرسة" dir="ltr" inputMode="numeric" pattern="[0-9]{8,15}" minLength={8} maxLength={15} placeholder="249912345678" value={draft ?? school?.whatsapp_number ?? ""} onChange={(e) => setDraft(e.target.value)} disabled={!manager || !school || save.isPending} required /></Field>
      <p className="text-xs text-muted-foreground">يفتح تطبيق أولياء الأمور محادثة واتساب مع هذا الرقم.</p>
      {manager && <Button disabled={!school || save.isPending}>حفظ الرقم</Button>}
    </form>}
  </section>;
}