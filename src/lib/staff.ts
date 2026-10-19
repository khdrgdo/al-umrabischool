import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";

export type AppRole = "owner" | "principal" | "supervisor";

export const ROLE_LABELS: Record<AppRole, string> = {
  owner: "المالك",
  principal: "مدير المدرسة",
  supervisor: "المشرف",
};

/** Mirrors the database can_manage() rule. UI hint only — the database enforces it. */
export function canManage(roles: AppRole[]) {
  return roles.includes("owner") || roles.includes("principal");
}

export function useMe() {
  return useQuery({
    queryKey: ["me"],
    queryFn: async () => {
      const { data: u } = await supabase.auth.getUser();
      if (!u.user) return null;
      const { data: roles } = await supabase
        .from("user_roles")
        .select("role")
        .eq("user_id", u.user.id);
      return { user: u.user, roles: (roles ?? []).map((r) => r.role as AppRole) };
    },
  });
}

export function useSchool() {
  return useQuery({
    queryKey: ["school"],
    queryFn: async () => {
      const { data, error } = await supabase.from("schools").select("*").order("created_at").limit(1).single();
      if (error) throw error;
      return data;
    },
  });
}

export function errMsg(e: unknown) {
  const m = (e as { message?: string })?.message ?? "حدث خطأ";
  if (m.includes("duplicate key")) return "هذا السجل موجود مسبقًا";
  if (m.includes("row-level security")) return "ليست لديك صلاحية لهذه العملية";
  return m;
}
