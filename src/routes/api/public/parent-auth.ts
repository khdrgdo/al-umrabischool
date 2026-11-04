import { createFileRoute } from "@tanstack/react-router";

// نقطة عامة (بلا جلسة) لتفعيل حساب ولي الأمر أو إعادة تعيين كلمة مروره برمز تفعيل لمرة واحدة.
// المنطق في src/lib/parentAuth.server.ts؛ الاستيراد ديناميكي كي لا تدخل مفاتيح الخادم حزمة المتصفح.
let limiter: import("@/lib/parentAuth.server").RateLimiter | undefined;

export const Route = createFileRoute("/api/public/parent-auth")({
  server: {
    handlers: {
      POST: async ({ request }: { request: Request }) => {
        const { handleParentActivation, RateLimiter } = await import("@/lib/parentAuth.server");
        limiter ??= new RateLimiter(10, 10 * 60 * 1000);
        const ip = request.headers.get("cf-connecting-ip") ?? request.headers.get("x-forwarded-for") ?? "unknown";
        if (!limiter.allow(ip)) {
          return Response.json({ ok: false, error: "rate_limited", message: "محاولات كثيرة. حاول لاحقاً." }, { status: 429 });
        }
        let body: Record<string, unknown> = {};
        try {
          body = (await request.json()) as Record<string, unknown>;
        } catch {
          return Response.json({ ok: false, error: "bad_request", message: "بيانات غير صالحة." }, { status: 400 });
        }
        const { createAdminDeps } = await import("@/lib/parentAuth.admin.server");
        const result = await handleParentActivation(body, createAdminDeps());
        return Response.json(result.body, { status: result.status, headers: { "Cache-Control": "no-store" } });
      },
    },
  },
});
