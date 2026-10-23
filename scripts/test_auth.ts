import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = "https://c--8b91830b-7424-4960-81c7-67e94cdfd28d-prod.lovable.cloud";
const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_Cfv0pugkUHNlXrkWNX45JQ_ebr24viE";

const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);

async function testAuth() {
  const email = "principal@alumrabi.sd";
  const password = "Password123!";

  console.log("Attempting signIn...");
  const { data: signInData, error: signInErr } = await supabase.auth.signInWithPassword({ email, password });
  if (signInErr) {
    console.log("Sign in failed:", signInErr.message);
    console.log("Attempting signUp to see if signups are open or first owner setup...");
    const { data: signUpData, error: signUpErr } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: "الأستاذ مصطفى العمرابي - مدير المدرسة",
        }
      }
    });
    if (signUpErr) {
      console.log("SignUp error:", signUpErr.message);
    } else {
      console.log("SignUp success, user id:", signUpData.user?.id);
    }
  } else {
    console.log("Sign in success, user id:", signInData.user.id);
  }
}

testAuth();
