# School audit and safe repairs
- [x] Admin additions implemented: school WhatsApp, targeted announcements/read counts, optional fees/assignments, parent reports/new-count badge. Frontend only; live integration checks tracked separately.
- [x] Finish admin additions validation: strict TypeScript/build OK; 92 unit tests passed, 33 database integration tests skipped. Protected files and database unchanged.
- [x] Fix preview code errors (27 type errors in admin pages) — 0 errors, 49/49 tests pass.
- [x] Read-only audit: live DB has only migrations 0000–0004; fees, guardians, grades/assessments, calendar, rollover, parent-app tables are missing.
- [ ] Remove "first user becomes owner" from handle_new_user (blocked: backup must be confirmed by user first; currently 1 owner exists so new signups get no role).
- [ ] Review and apply 0005–0011 in order (blocked: backup confirmation; 0010 seed file must NOT be applied to production).
- [ ] Decide fate of web parent page src/routes/parent.tsx (user said no web parent portal).
- [ ] Live authenticated UI/RLS checks of admin additions (blocked: separate permission required for live database reads/writes; not performed in this task).

- [ ] Replace test data with ~200 students + guardians (migrations 0005–0013 now live; seed script not yet written/run)
