import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card } from "@/components/ui/card";

export const Route = createFileRoute("/auth")({
  head: () => ({
    meta: [
      { title: "تسجيل الدخول — مدرسة العمرابي" },
      { name: "description", content: "تسجيل الدخول إلى نظام إدارة مدرسة العمرابي." },
      { property: "og:title", content: "تسجيل الدخول — مدرسة العمرابي" },
      { property: "og:description", content: "تسجيل الدخول إلى نظام إدارة المدرسة." },
    ],
  }),
  component: AuthPage,
});

// Sign-in only: accounts are created by the owner, never by public sign-up.
function AuthPage() {
  const nav = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      nav({ to: "/dashboard" });
    } catch {
      toast.error("بيانات الدخول غير صحيحة");
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="min-h-screen flex items-center justify-center bg-background px-4">
      <Card className="w-full max-w-sm p-8">
        <h1 className="text-2xl font-bold text-primary mb-1">مدرسة العمرابي</h1>
        <p className="text-sm text-muted-foreground mb-6">تسجيل الدخول</p>
        <form onSubmit={submit} className="space-y-4">
          <div className="space-y-1.5">
            <Label>البريد الإلكتروني</Label>
            <Input type="email" dir="ltr" value={email} onChange={(e) => setEmail(e.target.value)} required />
          </div>
          <div className="space-y-1.5">
            <Label>كلمة المرور</Label>
            <Input type="password" dir="ltr" value={password} onChange={(e) => setPassword(e.target.value)} required />
          </div>
          <Button type="submit" className="w-full" disabled={busy}>
            دخول
          </Button>
        </form>
        <p className="mt-4 text-xs text-muted-foreground">
          لا يوجد تسجيل عام. يُنشئ المالك حسابات العاملين ويمنحهم الصلاحيات.
        </p>
      </Card>
    </main>
  );
}
