import { schoolPageHead } from "@/lib/pageHead";
import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useMe, ROLE_LABELS, errMsg, type AppRole } from "@/lib/staff";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/_authenticated/users")({
  head: () => schoolPageHead("المستخدمون — مدرسة العمرابي", "المستخدمون في نظام إدارة مدرسة العمرابي الثانوية."),
  component: Users,
});

const ROLES: AppRole[] = ["owner", "principal", "supervisor"];

function Users() {
  const qc = useQueryClient();
  const { data: me } = useMe();
  const isOwner = me?.roles.includes("owner");
  const { data } = useQuery({
    queryKey: ["users"],
    enabled: !!isOwner,
    queryFn: async () => {
      const [p, r] = await Promise.all([
        supabase.from("profiles").select("*").order("created_at"),
        supabase.from("user_roles").select("*"),
      ]);
      return { profiles: p.data ?? [], roles: r.data ?? [] };
    },
  });
  const toggle = useMutation({
    mutationFn: async ({ userId, role, has }: { userId: string; role: AppRole; has: boolean }) => {
      const { error } = has
        ? await supabase.from("user_roles").delete().eq("user_id", userId).eq("role", role)
        : await supabase.from("user_roles").insert({ user_id: userId, role });
      if (error) throw error;
    },
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["users"] }); toast.success("تم تحديث الصلاحيات"); },
    onError: (e) => toast.error(errMsg(e)),
  });

  if (!isOwner) return <p className="text-muted-foreground">إدارة المستخدمين متاحة للمالك فقط.</p>;

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-primary">المستخدمون والصلاحيات</h1>
      <p className="text-sm text-muted-foreground">ينشئ الموظف حسابه من صفحة الدخول، ثم تمنحه الدور هنا.</p>
      <Card className="divide-y">
        {data?.profiles.map((p) => (
          <div key={p.id} className="p-3 flex flex-wrap items-center justify-between gap-2">
            <div>
              <div className="font-medium">{p.full_name || "—"}</div>
              <div className="text-xs text-muted-foreground" dir="ltr">{p.email}</div>
            </div>
            <div className="flex gap-1">
              {ROLES.map((role) => {
                const has = data.roles.some((r) => r.user_id === p.id && r.role === role);
                const self = p.id === me?.user.id && role === "owner";
                return (
                  <Button key={role} size="sm" variant={has ? "default" : "outline"} disabled={self || toggle.isPending}
                    onClick={() => toggle.mutate({ userId: p.id, role, has })}>
                    {ROLE_LABELS[role]}
                  </Button>
                );
              })}
            </div>
          </div>
        ))}
      </Card>
    </div>
  );
}
