import { schoolPageHead } from "@/lib/pageHead";
import { createFileRoute, Link } from "@tanstack/react-router";
import { Button } from "@/components/ui/button";
import { GraduationCap, Smartphone, ShieldCheck } from "lucide-react";

// بوابة الويب القديمة لأولياء الأمور كانت تعتمد على رقم حساب + PIN عبر دالة عامة (anon)،
// وقد أُزيل هذا المسار نهائياً لأسباب أمنية. الدخول الآن عبر تطبيق Android بكلمة مرور في Supabase Auth.
export const Route = createFileRoute("/parent")({
  ssr: false,
  head: () => schoolPageHead("بوابة أولياء الأمور — مدرسة العمرابي الثانوية", "بوابة ولي الأمر الإلكترونية المعتمدة لمتابعة الأبناء والنتائج المنشورة والحضور والرسوم."),
  component: ParentPortalNotice,
});

function ParentPortalNotice() {
  return (
    <main dir="rtl" className="min-h-screen flex items-center justify-center bg-background p-4">
      <div className="max-w-md w-full rounded-xl border bg-card p-6 text-center space-y-4">
        <div className="mx-auto h-12 w-12 rounded-full bg-primary/10 flex items-center justify-center">
          <GraduationCap className="h-6 w-6 text-primary" />
        </div>
        <h1 className="text-lg font-bold">بوابة أولياء الأمور</h1>
        <div className="flex items-start gap-2 text-sm text-muted-foreground text-right">
          <Smartphone className="h-5 w-5 shrink-0 mt-0.5" />
          <p>الاطلاع على درجات الأبناء وحضورهم والرسوم يتم حصراً من خلال تطبيق «العمرابي» لأولياء الأمور على هواتف Android.</p>
        </div>
        <div className="flex items-start gap-2 text-sm text-muted-foreground text-right">
          <ShieldCheck className="h-5 w-5 shrink-0 mt-0.5" />
          <p>لتفعيل حسابك أو إعادة تعيين كلمة المرور، راجع إدارة المدرسة لاستلام رمز تفعيل شخصي مؤقت.</p>
        </div>
        <Button asChild variant="outline">
          <Link to="/">العودة إلى الصفحة الرئيسية</Link>
        </Button>
      </div>
    </main>
  );
}
