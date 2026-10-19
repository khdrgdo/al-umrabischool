# ANTIGRAVITY HANDOFF — Al-Omarabi School System

## Purpose
Admin web app (this repo) + future **parent mobile app** (to be built in Google Antigravity) sharing one PostgreSQL database and auth.
Do NOT rewrite the system. Do NOT duplicate business rules in the mobile app.

## Stack
- TanStack Start (React 19, Vite), Tailwind v4, deployed to an edge runtime.
- Backend: Postgres + Auth (Supabase-compatible), Row Level Security on every table.
- Schema source of truth: `drizzle/migrations/*.sql` (apply in order to a fresh database).

## Data model (current)
schools → academic_years, grades → tracks → specializations
sections (academic_year, grade, optional track/specialization)
students (stable identity) → enrollments (one per student per academic year)
subjects, teachers, profiles, user_roles, audit_log

## Security model
- Roles in `user_roles` (`owner`, `principal`, `supervisor`). Checked via SQL functions `has_role`, `is_staff`, `can_manage`.
- Students/enrollments have no DELETE policy — history is never deleted; use `status`.
- Every write on core tables is recorded in `audit_log`.

## Parent app — required before building
1. Add role/table `guardians` + `guardian_students` (verified link created by staff, not by the parent).
2. Add RLS policies: a guardian may read only students linked to `auth.uid()`; only **published** results.
3. Expose read endpoints server-side (TanStack server routes under `src/routes/api/`) with documented auth, inputs, outputs, errors. Never give the app broad table access or filter on the device.
4. Results need a status lifecycle (draft → review → approved → published) before any parent can see them.

## Open business questions
See `docs/PROJECT_STATUS.md`.
