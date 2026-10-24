# Fix Env


# TASK: Restore the deleted `.env` file (Supabase public config)

Read this whole page before touching anything. Do ONLY what is written here. If something does not match what this page says, STOP and report. Do not guess and do not invent values.


## 1. The problem (verified from git history)

The app shows this error in the browser:

```javascript
Missing Supabase environment variable(s): SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY. Connect Supabase in Lovable Cloud.
```

The error is thrown by `src/integrations/supabase/client.ts` when `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` are empty in the browser bundle.

Likely cause (evidence): commit `fe80274c5bfc9b10c63965ebaa1bb59fcb99bab5` (message: "fix(compliance): ... secure git env ...") did two things:

- It DELETED the file `.env` from the repository.
- It added `.env` to `.gitignore`.
So the Lovable build no longer receives the `VITE_*` values. The build is the only place Vite fills them in.


## 2. Verified values (taken from the deleted `.env` in commit fe80274)

These are PUBLIC values (a publishable key is designed to be public). The original file had exactly these 6 lines:

```javascript
SUPABASE_PROJECT_ID="ywlcrvqioyzliiaikpwd"
SUPABASE_PUBLISHABLE_KEY="sb_publishable_Cfv0pugkUHNlXrkWNX45JQ_ebr24viE"
SUPABASE_URL="https://c--8b91830b-7424-4960-81c7-67e94cdfd28d-prod.lovable.cloud"
VITE_SUPABASE_PROJECT_ID="ywlcrvqioyzliiaikpwd"
VITE_SUPABASE_PUBLISHABLE_KEY="sb_publishable_Cfv0pugkUHNlXrkWNX45JQ_ebr24viE"
VITE_SUPABASE_URL="https://c--8b91830b-7424-4960-81c7-67e94cdfd28d-prod.lovable.cloud"
```

`supabase/config.toml` also contains `project_id = "ywlcrvqioyzliiaikpwd"`, which matches.


## 3. Hard rules (read carefully)

1. Do NOT change any other file except `.env` (create) and `.gitignore` (one line). Nothing else.
1. Do NOT edit these files at all: `src/integrations/supabase/client.ts`, `src/integrations/supabase/client.server.ts`, `src/server.ts`, `vite.config.ts`. They are generated or already working.
1. Do NOT invent, change, or "improve" any value. Use only the values in section 2.
1. NEVER put a secret in any file. Forbidden: `SUPABASE_SERVICE_ROLE_KEY`, any value starting with `sb_secret_`, any `service_role` key. Only the 6 public lines above go into `.env`.
1. Do NOT create a new Supabase project or database. Do NOT run SQL. Do NOT touch `supabase/migrations/` or `drizzle/`.
1. Do NOT add try/catch, placeholders, mock data, or fallback hardcoded values to hide the error.
1. Do NOT say "fixed" for anything you did not actually run and see the output of.

## 4. Steps (do them in this order)


### Step 1 - Check the current state

Run these and keep the output:

```javascript
ls -la .env
git ls-files .env
git check-ignore -v .env
git show fe80274c5bfc9b10c63965ebaa1bb59fcb99bab5^:.env
```

Expected: `.env` does not exist or is untracked, `git check-ignore` points to `.gitignore`, and the last command prints the 6 lines from section 2.

If the last command prints DIFFERENT values from section 2: STOP. Report the exact output. Do not continue.


### Step 2 - Create `.env` in the repository root

Create the file `.env` with exactly the 6 lines from section 2. No extra lines, no comments, no spaces around `=`, keep the double quotes.


### Step 3 - Stop ignoring `.env`

Open `.gitignore`. Find the block:

```javascript
# Environment variables
.env
.env.local
.env.*.local
!.env.example
```

Delete ONLY the single line `.env`. Keep the other lines.

Then run:

```javascript
git check-ignore -v .env
```

Expected: no output (the file is no longer ignored). If it still prints a rule, find that rule and report it. Do not use `git add -f` as a shortcut.


### Step 4 - Commit

```javascript
git add .env .gitignore
git status
```

`git status` must show exactly two changes: new file `.env` and modified `.gitignore`. If other files appear, unstage them. Then:

```javascript
git commit -m "fix(env): restore public Supabase .env removed in fe80274"
```

Do NOT push unless the user told you to push. If you cannot push, tell the user to push.


### Step 5 - Local verification (run and show real output)

```javascript
npx tsc --noEmit
npm test
npm run build
```

After the build, search the build output folder (for example `.output`) for the string `lovable.cloud`. It should appear in the client bundle. If you cannot find it, report that. Do not claim success.

If a command fails for a reason unrelated to this task, report the first real error line. Do not fix unrelated errors.


## 5. What you CANNOT verify (say this honestly in your report)

Only the user can confirm the real result: after the push, Lovable must rebuild, the user must press Publish, then open the preview and the published site. Until then the status is "changed, not verified in Lovable".


## 6. Out of scope - REPORT ONLY, DO NOT FIX in this task

These were found during review of commit `704df22e399c4477d917b7ec00c6077fad065ad2` and `51e3338b48f9dff2897731da881dca9b8069c247`. They are separate tasks. Do not change them now:

- `supabase/migrations/20261023000011_parent_portal_rpc.sql` ends with `GRANT EXECUTE ON FUNCTION public.parent_app_login`. Migration 0009 says that function was removed, and no migration defines it.
- Migration 0009 admin functions insert into `audit_log` columns `school_id, user_id, details`. The table (created in the foundation migration) has `table_name, record_id, action, old_data, new_data, actor_id, created_at`.
- `parent_get_portal_data` is granted to `anon` and checks only `guardian_id` + `account_code`, with no PIN or password.
- `src/routes/parent.tsx` (as of commit 51e3338) calls `supabase.rpc("parent_app_login")`.
- `drizzle/migrations/` and `supabase/migrations/` hold duplicated migration sets.

## 7. Final report format

Send a short report with these items:

1. Output of the Step 1 commands (exact text).
1. The exact diff of `.gitignore` and the content of `.env`.
1. Output of `git status` before the commit.
1. Results of `npx tsc --noEmit`, `npm test`, `npm run build` (pass or fail + first error line if fail).
1. Status for each item, using ONLY one of: "verified", "changed but not verified", "not done", "blocked because ...".
1. A line saying: "Not verified in Lovable preview/publish - user must check."
