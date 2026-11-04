// ربط منطق التفعيل بعميل Supabase الإداري (service_role). يُستورد من الخادم فقط.
import { supabaseAdmin } from "@/integrations/supabase/client.server";
import type { ParentAuthDeps } from "./parentAuth.server";

export function createAdminDeps(): ParentAuthDeps {
  const admin = supabaseAdmin;
  return {
    async checkActivation(accountCode, code) {
      const { data, error } = await (admin as any).rpc("parent_check_activation", { _account_code: accountCode, _code: code });
      if (error || !data) return null;
      return data as { guardian_id: string; user_id: string | null; purpose: "activate" | "reset" };
    },
    async completeActivation(guardianId, userId) {
      const { data, error } = await (admin as any).rpc("parent_complete_activation", { _guardian_id: guardianId, _user_id: userId });
      return !error && data === true;
    },
    async createAuthUser(email, password) {
      const { data, error } = await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        app_metadata: { guardian: true },
      });
      if (error || !data.user) {
        const msg = (error?.message ?? "").toLowerCase();
        if (msg.includes("already") || msg.includes("exists") || msg.includes("registered")) return { error: "exists" as const };
        if (msg.includes("password")) return { error: "weak_password" as const };
        return { error: "other" as const };
      }
      return { id: data.user.id };
    },
    async findAuthUserByEmail(email) {
      for (let page = 1; page <= 20; page++) {
        const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 1000 });
        if (error) return null;
        const hit = data.users.find((u) => (u.email ?? "").toLowerCase() === email.toLowerCase());
        if (hit) return { id: hit.id, isGuardian: (hit.app_metadata as Record<string, unknown> | undefined)?.["guardian"] === true };
        if (data.users.length < 1000) return null;
      }
      return null;
    },
    async deleteAuthUser(id) {
      await admin.auth.admin.deleteUser(id);
    },
    async updateAuthPassword(id, password) {
      const { error } = await admin.auth.admin.updateUserById(id, { password });
      return !error;
    },
  };
}
