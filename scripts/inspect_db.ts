import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = "https://c--8b91830b-7424-4960-81c7-67e94cdfd28d-prod.lovable.cloud";
const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_Cfv0pugkUHNlXrkWNX45JQ_ebr24viE";

const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);

async function inspect() {
  console.log("Checking current Supabase data...");
  const tables = [
    "schools",
    "academic_years",
    "grades",
    "sections",
    "students",
    "guardians",
    "guardian_students",
    "fee_structures",
    "student_payments",
    "assessments",
    "student_grades",
    "attendance_sessions",
    "attendance_records",
    "school_events",
    "announcements",
  ];

  for (const t of tables) {
    try {
      const { data, error, count } = await supabase.from(t).select("*", { count: "exact", head: true });
      if (error) {
        console.log(`Table [${t}]: Error -> ${error.message} (${error.code})`);
      } else {
        console.log(`Table [${t}]: Count = ${count}`);
      }
    } catch (e: any) {
      console.log(`Table [${t}]: Exception -> ${e.message}`);
    }
  }
}

inspect();
