import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { readAll } from "@/lib/adminFeatures";

export function useNewParentReports(enabled = true) {
  return useQuery({
    queryKey: ["parent-reports-new-count"], enabled, refetchInterval: 60_000,
    queryFn: async () => {
      const { count, error } = await supabase.from("parent_reports").select("id", { count: "exact", head: true }).eq("status", "new");
      if (error) throw error;
      return count ?? 0;
    },
  });
}

export function useAdminRoster(schoolId?: string) {
  return useQuery({
    queryKey: ["admin-roster", schoolId], enabled: !!schoolId,
    queryFn: async () => {
      if (!schoolId) throw new Error("تعذر تحديد المدرسة");
      const { data: year, error } = await supabase.from("academic_years").select("id,name").eq("school_id", schoolId).eq("is_current", true).maybeSingle();
      if (error) throw error;
      const [grades, students, sections, enrollments] = await Promise.all([
        readAll((a, b) => supabase.from("grades").select("id,name,level_order").eq("school_id", schoolId).order("level_order").order("id").range(a, b)),
        readAll((a, b) => supabase.from("students").select("id,full_name,student_number").eq("school_id", schoolId).order("full_name").order("id").range(a, b)),
        year ? readAll((a, b) => supabase.from("sections").select("id,name,grade_id").eq("academic_year_id", year.id).order("name").order("id").range(a, b)) : [],
        year ? readAll((a, b) => supabase.from("enrollments").select("student_id,section_id").eq("academic_year_id", year.id).eq("status", "active").order("id").range(a, b)) : [],
      ]);
      return { year, grades, students, sections, enrollments };
    },
  });
}