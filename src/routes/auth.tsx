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

function AuthPage() {
  const nav = useNavigate();
  const [mode, setMode] = useState<"in" | "up">("in");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      if (mode === "in") {
        const { error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) throw error;
        nav({ to: "/dashboard" });
      } else {
        const { data, error } = await supabase.auth.signUp({
          email,
          password,
          options: { emailRedirectTo: window.location.origin + "/dashboard", data: { full_name: name } },
        });
        if (error) throw error;
        if (data.session) nav({ to: "/dashboard" });
        else toast.success("تم إنشاء الحساب. تحقق من بريدك الإلكتروني لتأكيده.");
      }
    } catch (err) {
      toast.error(mode === "in" ? "بيانات الدخول غير صحيحة" : (err as Error).message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="min-h-screen flex items-center justify-center bg-background px-4">
      <Card className="w-full max-w-sm p-8">
        <h1 className="text-2xl font-bold text-primary mb-1">مدرسة العمرابي</h1>
        <p className="text-sm text-muted-foreground mb-6">{mode === "in" ? "تسجيل الدخول" : "إنشاء حساب جديد"}</p>
        <form onSubmit={submit} className="space-y-4">
          {mode === "up" && (
            <div className="space-y-1.5">
              <Label>الاسم الكامل</Label>
              <Input value={name} onChange={(e) => setName(e.target.value)} required />
            </div>
          )}
          <div className="space-y-1.5">
            <Label>البريد الإلكتروني</Label>
            <Input type="email" dir="ltr" value={email} onChange={(e) => setEmail(e.target.value)} required />
          </div>
          <div className="space-y-1.5">
            <Label>كلمة المرور</Label>
            <Input type="password" dir="ltr" minLength={8} value={password} onChange={(e) => setPassword(e.target.value)} required />
          </div>
          <Button type="submit" className="w-full" disabled={busy}>
            {mode === "in" ? "دخول" : "إنشاء الحساب"}
          </Button>
        </form>
        <button className="mt-4 text-sm text-primary underline" onClick={() => setMode(mode === "in" ? "up" : "in")}>
          {mode === "in" ? "ليس لديك حساب؟ أنشئ حسابًا" : "لديك حساب؟ سجّل الدخول"}
        </button>
        {mode === "up" && (
          <p className="mt-3 text-xs text-muted-foreground">
            الحساب الجديد لا يملك صلاحيات حتى يمنحها المالك.
          </p>
        )}
      </Card>
    </main>
  );
}
