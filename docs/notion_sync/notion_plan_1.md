# plan1

You are Gemini 3.8 Flash acting as senior software architect, product engineer, database engineer, QA lead, and security reviewer for the existing Al Omrabi School Management System. This is an implementation brief for the existing project, not a generic proposal and not permission to invent requirements.

Repository: [https://github.com/khdrgdo/al-umrabischool.git](https://github.com/khdrgdo/al-umrabischool.git)
Lovable project: [https://lovable.dev/projects/8b91830b-7424-4960-81c7-67e94cdfd28d](https://lovable.dev/projects/8b91830b-7424-4960-81c7-67e94cdfd28d)
Preview: [https://id-preview--8b91830b-7424-4960-81c7-67e94cdfd28d.lovable.app](https://id-preview--8b91830b-7424-4960-81c7-67e94cdfd28d.lovable.app/)

The user confirms current records are test data and may be reset or altered if necessary. This does not authorize careless destructive operations: inspect the schema, identify the environment, and state exactly what will be reset before a broad reset. Never assume a project label proves that a database is a test environment.


## 1. Non-negotiable rules

1. Inspect the current repository, routes, components, SQL migrations, live database schema, authentication, RLS policies, roles, reports, and Android work before architectural changes. Read the existing Notion requirements and visual design guide when accessible. Old audit reports are not proof of current state.
1. Build an evidence matrix: requirement → implementation → database support → authorization → test → status (implemented / partial / missing / unverified). A screen or TypeScript type alone does not prove a feature works.
1. Prefer incremental, reviewable changes and reusable components. Preserve Arabic RTL, the existing visual identity, and school logo. Do not rewrite the whole app without evidence.
1. Separate confirmed school decisions from proposals and open questions. Do not invent official school policies, fees, grading thresholds, transfer rules, or certificate formats. Make unresolved policies configurable.
1. Never hide schema mismatch with broad casts, mock persistence presented as real, swallowed errors, fake success states, or unverified “fixed” claims.
1. Use the existing stack unless inspection proves it cannot meet requirements. Avoid unnecessary dependencies. Never expose secrets in client bundles, logs, or repository.
1. Enforce authorization on every sensitive server/database operation, not just by hiding UI buttons. Default-deny and least privilege. Test direct API/database access as well as UI behavior.
1. Audit consequential actions. Never silently overwrite financial records, approved grades, student identity, enrollment history, or issued documents.
1. After each stage run typecheck, configured lint, tests, build, and relevant integration checks. Report exact commands and outcomes. If credits, permissions, or tooling prevent execution, state the blocker rather than pretending work continued.
1. Do not create a parent web portal. The parent-facing product is intended to be a separate Android application/APK. The administrative website is for authorized school management users.

## 2. Product scope and school structure

The institution serves Kindergarten (Rawda), Primary/Basic (Asas), Intermediate (Mutawassita), and Secondary (Thanawiya). The current operational focus is the girls’ secondary school. Design architecture so other stages can be enabled later through configuration without pretending their workflows are already complete.

- Model institution, school/branch/building, stage, academic year, grade, section/class, track/specialization, subject, enrollment, and student status explicitly.
- Avoid hard-coding “secondary girls” into business logic. Configure the active school/stage. Keep the current interface focused on girls’ secondary; do not expose unfinished stage workflows as production-ready.
- Allow future stage-specific fees, calendars, documents, roles, and reports.
- Keep a permanent student number independent from annual enrollment. Never reuse a number or create duplicate student identities. Returning students retain the same number.
- Separate student identity from annual enrollment and transfer history. Preserve prior years, schools, grades, sections, status, results, attendance, obligations, and payments.
- For Grade 3 secondary, support Scientific and Literary tracks; the known scientific specializations are Biology, Computer, and Engineering. Keep configurable because exact school terminology may need confirmation.

## 3. Admission, registration, and transfers — highest priority

The school director confirmed that the Intermediate School Certificate (شهادة المرحلة المتوسطة) is very important for registration. Make required documents configurable by stage and admission type; require this certificate for relevant secondary admissions unless an authorized, documented policy waiver exists.

Support distinct workflows:
A. First-time/new student.
B. Transfer-in from another school.
C. Continuing/returning student.
D. Re-enrollment after withdrawal or interruption.
E. Transfer-out/withdrawal while preserving history.

Use a document checklist with statuses: missing, received/uploaded, under review, accepted, rejected, or waived with reason. Record who reviewed each item and when. Include at minimum:

- Intermediate School Certificate for secondary entry, where applicable.
- Previous school certificate/report for the prior term/semester when a student transfers into an in-progress grade. Example: a student transferring into Grade 2 from another school must be prompted for the previous school’s preceding term/semester report/certificate.
- Transfer/release certificate if school policy requires it.
- Birth/identity record and guardian identity/contact information if required by school policy.
- Other stage-specific documents configured by an authorized administrator.
Do not treat the intermediate certificate and prior-term report as interchangeable. Store separate document types. For transfers, capture previous school, stage/grade/section, academic year, completed term/semester, last attendance date if known, supporting report, incoming marks when relevant, and approval status. Documents must be private, validated, access-controlled, and not exposed through public storage URLs.

Prevent common errors:

- Duplicate checks using stable identifiers and cautious matching across name/date of birth/guardian; never auto-merge on name alone.
- Warn about missing documents, possible duplicate identity, invalid stage/grade transition, missing previous-term result, conflicting enrollment, and incomplete guardian details.
- Draft → review → approve/reject → enroll, with visible status and responsible person.
- Authorized overrides require a reason, actor, timestamp, and audit entry.
- Repeated submissions and retries must be idempotent.
- Use atomic transactions or equivalent so partial admissions cannot leave inconsistent records.
- Preserve an enrollment event/history. Correct important history through an auditable correction, not silent deletion.
- Clearly label requirements as school policy; do not invent undocumented rules.
Acceptance tests: a secondary admission with a missing required intermediate certificate cannot be approved without a documented authorized waiver; transfer-in to a later grade prompts for the previous school’s relevant prior-term report; documents remain linked to the right student/enrollment; returning students keep the same number; retries do not create duplicate students or enrollments.


## 4. Finance and accountant — critical priority

The user emphasized that the accountant/finance function is extremely important. Treat finance as a first-class module, not a few fields on the student page. Inspect whether a separate accountant role exists and add a configurable least-privilege role if needed. One person may hold multiple explicitly granted roles, but never grant financial access to all users by default.

Finance must support:

- Fee schedules by school/stage/academic year/grade/enrollment and fee category; do not assume one fee for all stages or grades.
- Configurable installments, due dates, one-time and recurring fees, and registration fees as applicable. Never invent amounts or schedules.
- Categories such as tuition, registration, uniform, books, meals, transport, and configurable others.
- Full/partial scholarships, exemptions, discounts, and approved family/sibling arrangements with scope, dates, approval, reason, and author.
- Freeze fee assessments for each student enrollment/year so future fee changes do not rewrite historical obligations.
- Receipts with unique numbers, payer, student(s), enrollment/year, timestamp, payment method, amount, allocation, status, issuing user, and print output.
- Partial payments, credits/overpayments only if policy permits, outstanding balances, arrears, due lists, and reconciliation.
- Corrections by reversal/void/correction entries with reason and audit history; never hard-delete posted transactions or silently alter issued receipts.
- Daily payment summaries, category/period/class/stage reports, exemption reports, arrears, and monthly owner/management overview.
- Duplicate-receipt prevention, idempotency, valid amount/currency rules, timezone-safe dates, and concurrency-safe balance calculations.
- Separate permissions for assessment, collection, adjustment approval, reversal/refund, exemptions, and reports. If staff separation is not possible, require reason and audit high-risk actions.
- Derive balances from assessments, adjustments, payments, allocations, and reversals; do not treat a manually editable balance as source of truth.
- Never expose one family’s finances to another. Parent app financial visibility must be separately authorized and only show approved data.
Map each finance screen to actual database tables, constraints, RLS, and tested operations. If tables are missing, add ordered migrations; do not fake persistence in local state.

Acceptance tests: concurrent/retried payments cannot duplicate receipts or over-allocate; reversal preserves original trace; fee schedule changes do not alter prior years; scholarships calculate correctly; non-finance users cannot access finance data through direct API calls; totals reconcile to ledger entries.


## 5. Academic records and annual progression

- Model assessments by school/stage, academic year, grade, subject, term/semester, and component. The director configures components, weights, pass thresholds, and excluded subjects according to school policy.
- Support draft entry, validation, review/approval, publication, and documented correction. Published results never change silently.
- Validate score ranges, required components, weights, missing marks, and absent-student handling. Do not invent pass thresholds.
- Preserve raw marks, computed totals, grading-rule version, approver, publication time, and correction history.
- Make promotion, repetition, graduation, conditional promotion, and exceptional transitions configurable and director-approved.
- Annual rollover is a protected operation, not an ordinary save. Require source/destination year, preview of every proposed change, counts and exception list, explicit confirmation, idempotent operation ID, and a correction/reversal process that preserves history.
- Do not delete graduating students; update enrollment/status and retain history.
- Historical reports must use the selected historical academic year, not current student status/grade.

## 6. Attendance and error prevention

- Daily attendance is entered once per class/section/session. If the school’s existing workflow is retained, default to present and record exceptions only.
- Support configurable excused/unexcused absence, late, early departure, and authorized leave.
- Prevent duplicate sessions and duplicate attendance records. Protect against double-clicks, retries, and conflicting edits.
- Provide a review/correction queue when a supervisor transcribes paper records and the director reviews them. Preserve before/after values, actor, time, reason, and reviewer.
- Parent absence notifications must follow the school’s approved validation policy. Never send mass notifications from draft/erroneous data. Track delivery, failures, retries, and deduplication.
- Provide weekly/monthly reports and student/class summaries.
- Offline attendance must show local/pending/synced/conflicted/failed states; retries must be idempotent. Do not claim offline support unless it survives refresh/restart and is tested under real network loss.

## 7. Editable document and certificate template studio

Create a dedicated “Document Templates / Print Studio” inside the admin system. Authorized users must be able to create, edit, preview, save, duplicate, version, activate, archive, and reuse official school templates without code changes.

Use a safe structured/rich-text editor appropriate to the existing stack. Do not permit arbitrary executable HTML/JavaScript. Support:

- Arabic RTL and mixed Arabic/Latin text; typography, alignment, font size/weight, spacing, paragraphs, lists, borders, tables, A4 and configured paper sizes, portrait/landscape, margins, headers/footers, page numbering, signature blocks, and controlled positioning.
- Upload/select official school logo with file validation, resize/placement controls, and optional stamp/signature image where authorized.
- Editable basmala/opening text, school name, stage/branch, configured contact details, document title/body/date/reference number, director/principal name/title, signature/stamp areas, and optional QR/verification code only if implemented securely.
- Save/reuse/duplicate templates and preview with test data. Track draft/approved/active/archived versions. Issued documents reference the exact template version; later template edits must not change previously issued documents.
- Permission controls for editing/approving templates, issuing, cancelling/reissuing, and viewing history.
- A documented, searchable allowlist of @ placeholders, with insert menu and validation. Never treat arbitrary @text as SQL or code. Escape inserted content and never evaluate templates as JavaScript or SQL.
- Single and batch generation with preview. Batch issue requires displaying count/selection and explicit confirmation.
- Every issued document has unique number, student/enrollment/year, template version, issuer, issue date, status, and cancellation/reissue reason.
- Document-specific print preview and PDF export with Arabic font embedding and correct RTL layout.
Initial placeholder registry candidates (validate exact names and source fields):

- @student.full_name
- @[student.school](http://student.school/)_number
- @[student.date](http://student.date/)_of_birth (only if stored and authorized)
- @student.stage
- @student.grade
- @student.section
- @student.academic_year
- @guardian.full_name
- @guardian.relationship
- @[school.name](http://school.name/)
- @school.stage
- @school.branch
- @school.logo
- @document.issue_date
- @document.number
- @[results.total](http://results.total/)
- @results.percentage
- @results.status
- @attendance.absence_count
- @finance.balance (only for permitted financial documents and authorized users)
If a field is missing, warn in preview and block issuance when required, or omit it only when explicitly optional. Never insert “undefined”, fabricated values, or another student’s data. Validate student/guardian association server-side before resolving placeholders. Keep rendering isolated and safe.


## 8. Fix target-only printing

Current bug: in some areas, clicking Print prints the whole page instead of the requested region. Find the root cause; do not patch only with arbitrary margins.

- Give each printable report/document a dedicated print root/component boundary.
- Print only the selected target, excluding navigation, sidebar, unrelated cards, dialogs, and app chrome.
- Use dedicated print styles and @media print; use @page for paper size/margins; hide controls/navigation; ensure readable colors, table borders/headers, and RTL typography.
- Avoid clipping, blank pages, and split critical rows/certificate sections; repeat table headers on multi-page reports where feasible.
- Ensure hidden UI is not accidentally exposed and print/PDF use the same authorization/data scope as the screen.
- If using browser print, verify in the actual target browser. If a PDF library is needed, first test Arabic shaping, font embedding, page breaks, and bundle size.
- Add browser tests for target-only print, multi-page tables, Arabic RTL, and no unrelated page content. Report browsers/devices actually tested.

## 9. Research and document catalog

Research document requirements, but do not claim a sample is an official Sudanese government format unless supported by authoritative current sources and confirmed with the school/education authority. Distinguish government requirements from common examples and school-specific forms. Do not copy an unofficial design and label it official.

Prepare editable template starting points for:

- Student admission/registration form.
- Student personal record/summary.
- Admission document checklist.
- Transfer-in form and previous-school/term-results attachment.
- Transfer-out/release certificate if required.
- Enrollment confirmation certificate.
- Attendance certificate/statement.
- Term/semester report card.
- Academic transcript/marks statement.
- Success/pass and completion/graduation certificates where applicable.
- Student list by stage/grade/section.
- Attendance/absence report.
- Fee statement, account statement, receipt, scholarship/exemption approval, and arrears notice.
- Teacher/class/subject assignment list.
- Official letters and guardian/meeting notices.
- Annual promotion/rollover report and student status history.
- Administrative summary and monthly financial overview for owner.
For each document specify purpose, required fields, source tables, authorized issuer, approval requirements, numbering, and whether it is internal or externally official. Keep all templates editable and versioned.


## 10. Roles, approvals, audit, and operational safety

Inspect and implement least-privilege permissions for owner, principal/director, supervisor, accountant/finance officer, and future teachers/guardians. A staff member may have multiple explicit roles, but never assume accountant = owner.

- Deny by default; enforce permissions on every request and via database RLS.
- Remove insecure “first registered user becomes owner” behavior. Bootstrap the owner through a secure, one-time, documented administrative procedure.
- Never expose service-role keys/secrets in client code.
- Audit admission decisions, document acceptance/waiver, identity edits, grade approval/publication/correction, attendance changes, fee schedule changes, payments, reversals/refunds, exemptions, role grants, exports, template edits, certificate issuance/cancellation, rollover, imports, and security failures.
- Audit entries include actor, action, target, timestamp, reason when required, and safe before/after diff. Never log passwords, tokens, secrets, or unnecessary sensitive student data.
- Use database constraints, transactions, idempotency, concurrency controls, and explicit state transitions.
- Archive/status records when deletion would damage history. Restrict hard deletion to approved test fixtures or an approved retention workflow.
- Warnings for irreversible actions, large batches, unusual discounts, post-publication grade edits, bulk notifications, exports, and rollover must explain scope and consequence.
- Prevent repeated clicks while pending. Provide clear success/failure and safe retry behavior.
- Store timestamps consistently and display the configured school timezone; avoid UTC shifts for date-only values.

## 11. Error handling, observability, backup, and recovery

- Private developer-facing diagnostics, not a public feedback form. Capture correlation/request ID, timestamp, route, safe error code, app version, and non-sensitive context. Redact secrets and student/guardian information.
- Show concise Arabic error messages with safe next steps; keep stack traces and sensitive details out of UI.
- Never swallow errors or report success if the transaction failed.
- Health checks for database connectivity, schema/migration version, auth, and critical dependencies.
- Define backup/restore expectations for actual hosting. A backup is not proven until restoration is tested. Browser storage is not a backup.
- Import/export validates structure, duplicates, foreign keys, year and row counts; show dry-run summary and rejected-row report before import.
- Structured logs for repeated failures, failed logins, authorization denials, migration errors, and notification failures.

## 12. UX and information architecture

Refactor the admin navigation around actual tasks:

- Dashboard with actionable pending work.
- Admissions & Students: registration, transfers, required documents, profile/history.
- Academic: stages, grades, sections, subjects, assessments, results, promotion/rollover.
- Attendance: sessions, exceptions, review queue, reports.
- Finance: fee schedules, student accounts, payments/receipts, exemptions, arrears, reports.
- Documents & Print Studio: templates, preview, issued documents, verification/history.
- Timetable and staff/teacher assignments.
- Reports and exports.
- Settings: school/stage/year, roles/permissions, document requirements, templates, audit, system health.
Menus follow actual permissions, but server/database enforce the same permissions. Make the site responsive and usable on phones, with Arabic RTL forms, clear validation, keyboard/accessibility basics, consistent loading/empty/error states, and minimal unnecessary clicks. Preserve the logo and established visual identity. Follow WCAG 2.2 AA principles where practical: visible focus, labels, contrast, adequate targets, accessible errors.


## 13. Database and migration discipline

- Compare generated types, SQL migrations, ORM schema, actual database schema, foreign keys, indexes, triggers, functions, grants, RLS, and app queries.
- Identify missing tables/columns/functions and drift. Do not hide missing relationships with type casts.
- Migrations must be ordered, reproducible, documented, safe to rerun where possible, and fail clearly. Update migration journal only to reflect migrations actually applied.
- Identify test seeds by content and environment; never run test seed data in a live environment.
- Use foreign keys and unique/check constraints for critical invariants, transactions for multi-record workflows, and indexes based on actual queries.
- Define history/retention for student, finance, document, and audit records.
- After migration, query the actual DB to prove required tables/columns/functions/policies exist and run integration tests against the same environment.
- The user permits reset of test data, but first state exactly what is removed and verify the target environment. Never infer environment from project naming alone.

## 14. Required tests

Create/extend automated unit, integration, and browser tests for:

1. New secondary admission with intermediate certificate.
1. Transfer into Grade 2 with previous school and previous-term report/certificate required.
1. Missing document blocks approval; authorized waiver requires reason and audit event.
1. Returning student retains permanent number and history.
1. Retry/double-click cannot duplicate student, enrollment, payment, receipt, attendance, notification, or rollover.
1. Accountant can perform permitted finance tasks; supervisor/guardian cannot bypass permissions via direct API/database calls.
1. Parent can access only linked children; changing request IDs cannot reveal another child.
1. Grade draft/approval/publication/correction state machine and audit trail.
1. Attendance correction records before/after; notification does not send from unapproved draft data.
1. Fee assessment, partial payment, exemption, receipt, reversal, and outstanding balance reconcile.
1. Future fee schedule change does not alter historical accounts.
1. Annual rollover preview, confirmation, idempotency, and history preservation.
1. Template save/version/placeholders; missing required values block issuance; correct student data only.
1. Print only selected region; Arabic RTL and multi-page layouts remain readable.
1. RLS/role matrix proves default-deny and per-record restrictions.
1. Network interruption/retry if offline support is implemented.
Do not weaken tests to obtain a green run. If credentials, tools, credits, or environment prevent tests, state the blocker and do not mark them passed.


## 15. Implementation sequence

Phase 1 — Discovery: inspect repo, DB, migrations, routes, permissions, print code, templates, and Notion references. Produce prioritized gap matrix. Do not begin a large visual rewrite before identifying data-model/security gaps.

Phase 2 — Core workflows: implement admission checklist, intermediate certificate, previous-term transfer report, enrollment history, stable identity, finance foundations, accountant permissions, ledger/receipts/exemptions/reports. Fix schema/migrations and authorization before polishing screens.

Phase 3 — Document Studio and printing: implement safe editable/versioned templates, allowlisted @ placeholders, target-only print/PDF, Arabic RTL checks, and first useful document templates.

Phase 4 — Human-error prevention: approval queues, audit, idempotency/concurrency, import/export dry-run, actionable reports, safe corrections.

Phase 5 — Verification/release: run all checks and real integration/browser tests, inspect deployed build separately from preview, and report remaining gaps.


## 16. Required final evidence report

Return:

- Implemented: exact files/migrations/pages.
- Database: actual tables/functions/constraints/RLS verified after changes.
- Tests: exact commands/results and browser/manual tests actually performed.
- Security: role matrix and access checks performed.
- Documents/printing: target-only print evidence, supported placeholders, sample templates, Arabic/RTL/PDF result.
- Remaining: unresolved school policy questions, blockers, and untested behavior.
- Release: source/preview only or also published.
- Human decisions needed: only genuinely unresolved policy questions.
Never say “complete”, “fixed”, “secure”, or “production-ready” without evidence for that specific claim. Start by inspecting the real current project, then implement the highest-priority missing workflows in small, testable increments.


---


# Engineering Addendum — Critical Corrections from Three Review Cycles

**Purpose:** This addendum strengthens the existing plan. It supplements the original requirements; it does not replace or weaken them. Follow it together with the full plan. Do not claim implementation or verification unless supported by direct evidence.


## A. Mandatory evidence gates — do not skip

Use this execution sequence:

1. **Discovery only:** inspect repository, current branch/commit, application routes/components, tests, migration files and journal, actual database schema/RLS/grants, storage buckets and policies, deployed site, and Android project/artifacts if accessible. Record what was actually inspected and what was inaccessible.
1. **Gap matrix:** for each requirement, record current state as verified present, partially present, missing, broken, or not verifiable. Link the evidence (file/line, migration, query output, test result, screenshot, or build artifact). Do not infer implementation from a UI mockup or a passing type-check.
1. **Proposed change plan:** list exact files, schema changes, data impact, security impact, tests, rollback/recovery plan, and dependencies. Separate confirmed school decisions from recommendations and unanswered questions.
1. **Implement in small phases:** complete one phase and its verification before starting the next. If a gate fails, stop that phase, report the failure and fix it; do not silently continue.
1. **Remote/production gate:** never reset, delete, overwrite, apply migrations to, or publish against a remote environment until the target environment is positively identified, the exact operation and affected records are described, a recovery path is confirmed, and explicit approval is obtained for destructive or externally visible changes. The user's statement that current records are test data is not proof that every connected environment is disposable.
1. **Evidence-based release:** preview, tests, database state, deployed web build, and Android APK are separate verification targets. Do not call the whole project complete because one target passed.
Every phase exit report must state: requirements covered; exact files/migrations changed; commands and actual outputs; tests passed/failed/not run; DB/storage evidence; known risks; remaining questions; and next safe step.


## B. Security verification baseline

Use OWASP ASVS 5.0.0 as a traceable reference for relevant web/API security controls, and cite exact requirement identifiers where applicable. Do not claim full ASVS compliance unless a scoped, documented verification has actually been completed. Tailor controls to this school system and its real architecture.

Create a permission matrix for every role and sensitive resource, covering read, create, update, delete/archive, approve, publish, export, download, and administer where relevant. Include owner, principal/director, supervisor, accountant, teachers if implemented, and guardians in the separate Android app. A user may have multiple explicitly granted roles, but roles must not silently imply each other.

For every matrix entry, test both allowed and denied access through the UI and direct API/database paths. Verify RLS and SQL grants together; do not rely on hidden buttons or frontend checks. Default to deny. Test record-level isolation, forged IDs, cross-student access, role changes, expired/revoked sessions, and attempts to access files directly. Never expose service-role keys or secrets in client bundles or logs.

Do not create a blanket owner grant for the first registering user. Use a documented, controlled, one-time bootstrap process and verify it cannot be replayed.


## C. File and private-document handling

Before implementing uploads, define a per-document allowlist of file types, extensions, actual content checks, maximum file size, image dimensions where relevant, and safe processing behavior. Do not trust filename or Content-Type alone. Use generated storage names, private buckets for student documents, least-privilege storage policies, and short-lived authorized access where needed. Do not expose public URLs for certificates, prior-school reports, identity documents, or guardian data.

Validate authorization on the server for every upload, view, download, replacement, and deletion/archive operation. Test that changing a student, enrollment, guardian, or file ID cannot disclose another person's document. Keep file metadata and the file object consistent; handle failed or partial uploads safely. Record access and consequential document actions in audit logs without logging the document contents or secrets.


## D. Backup and recovery must include Storage

A database backup is not proof that uploaded files can be restored. Document the actual hosting plan and available backup features rather than assuming a feature is enabled. Define, with the owner, acceptable recovery-point and recovery-time objectives; define retention, access restrictions, off-site copies where feasible, and responsibility for checking backup success.

Include both database data and Storage objects/metadata in the recovery plan. Run a restore drill in an isolated test environment, verify relationships and representative files, and record the result/date. If no restore drill was performed, label recovery as not verified. Do not perform a restore against production as a test.


## E. Finance: clarify the accounting boundary before building

Treat student fee accounts and general-ledger accounting as distinct concepts. First inspect existing requirements and data structures, then ask the school/accountant only for decisions that materially affect the design. Do not invent local accounting rules.

At minimum, prove that fee assessment, installment schedules, partial payments, numbered receipts, scholarships/exemptions with authorization and reason, outstanding balances, reversals/refunds, and historical fee schedules reconcile consistently. Financial events must be transactional and auditable; do not silently edit or delete posted transactions. Use reversal/correction entries with reason and actor. Prevent duplicate payment/receipt creation on retry or double-click, including concurrent requests. Reconcile reports against underlying ledger entries with automated tests.

If a general ledger, cashbook, daily cashier closing, bank reconciliation, or chart of accounts is not confirmed as required, document it as an open design decision instead of adding a complex accounting module by assumption. Accountant permissions must be independently scoped; accountant must not automatically become owner or gain access to unrelated sensitive settings.


## F. Document template placeholder registry — canonical literal syntax

Keep placeholder names in inline or fenced code so Notion formatting cannot transform them into links. Treat the following as canonical examples, subject to validation against actual schema and authorized fields:

- `@student.full_name`
- `@student.school_number`
- `@student.date_of_birth`
- `@student.stage`
- `@student.grade`
- `@student.section`
- `@student.academic_year`
- `@guardian.full_name`
- `@guardian.relationship`
- `@school.name`
- `@school.stage`
- `@school.branch`
- `@school.logo`
- `@document.issue_date`
- `@document.number`
- `@results.total`
- `@results.percentage`
- `@results.status`
- `@attendance.absence_count`
- `@finance.balance`
Build a registry with: canonical token, source table/field or approved resolver, data type, formatting rules, required/optional status per template, roles allowed to resolve it, and relevant academic-year/enrollment context. Unknown tokens must be flagged and must never be evaluated as code, SQL, or expressions. Escape inserted values for the rendering context. Do not expose financial or sensitive personal fields in a template merely because a token exists.

Resolve stage, grade, section, results, attendance, and fee values from the correct student enrollment and academic year for the document being issued—not blindly from the student's current profile. Validate guardian-to-student linkage server-side. Preview with test data, show missing fields clearly, and block issuance if a required value is absent. Issued documents must remain bound to the exact template version and data snapshot or otherwise preserve a reproducible issued copy; template edits must not silently alter prior issued documents.


## G. Printing and Arabic document acceptance

Every print action must target an explicit document/report root, not the whole application shell. Use isolated print styles and hide navigation, buttons, overlays, unrelated cards, and dialogs. Verify print preview and generated PDF, not just CSS or a unit test.

Acceptance tests must include Arabic RTL, mixed Arabic/Latin values, Arabic-capable embedded fonts, logo sizing, A4 portrait and landscape, margins, tables, signatures/stamps, long names, empty optional fields, multiple pages, page breaks, headers/footers, and repeated printing. Confirm that only the requested region prints and that batch printing contains exactly the selected records. Record browser/device and test artifact when available.


## H. Offline sync and concurrent edits

Do not claim offline support unless the actual implementation preserves work through refresh/restart and has been tested under real network loss. Represent local pending work, syncing, synced, conflict, and failure distinctly. Every retryable write must have a stable idempotency key and a server-side deduplication rule.

Define conflict handling per data type. Never silently overwrite attendance, grades, financial events, identity fields, or approved records. Preserve conflicting values and show a review workflow where automatic resolution is unsafe. Test interrupted sync, repeated retry, duplicate delivery, concurrent edits, partial success, app restart, and resume-from-failure. Show which records synced and which did not, with actionable safe retry behavior.


## I. Android APK scope and release evidence

Keep the parent product as a separate Android application; do not create a parent web portal as a substitute. First determine whether an Android project and build pipeline actually exist. Report separately: source project present/missing; build attempted/not attempted; build result; APK path/artifact if produced; install and launch tested/not tested; supported Android versions/devices; authentication and guardian approval tested/not tested; multi-child isolation tested/not tested; published-only data tested/not tested; notifications tested/not tested. Never say APK ready without an actual build artifact and install/run evidence.


## J. Migration and release discipline

Follow the official Supabase migration workflow for the actual project. Keep migration files version-controlled and test them against a disposable/local database before any remote deployment. Compare local migration files, migration history, and actual schema. Do not edit migration history just to make it appear synchronized; do not run a seed migration until its contents and target environment are verified. Do not apply concurrent remote migration pushes.

For each migration, document preconditions, affected objects/data, expected result, validation query/test, and recovery strategy. Prefer additive, backward-compatible changes where practical. For destructive or data-transforming changes, include a dry run, explicit counts, data mapping, backup/recovery evidence, and approval gate. After application, query the actual database and run integration tests against that same environment.


## K. Required acceptance tests added by this review

1. Role/resource matrix: allowed and denied access for every sensitive operation, including direct API/database access.
1. Private file upload and download: invalid MIME/content, oversize file, forged IDs, cross-student access, unauthorized download, and storage policy enforcement.
1. Backup drill: database plus uploaded documents restored in an isolated environment and representative relationships verified.
1. Finance concurrency: two simultaneous payment attempts and repeated retries do not create duplicate payments or receipts; reversal preserves history and reports reconcile.
1. Template registry: every token is literal and documented; unknown token rejected; missing required field blocks issue; historical-year data resolves correctly; guardian/financial access is restricted.
1. Printing: only selected print root, Arabic RTL, multi-page and PDF output verified with a retained test artifact.
1. Offline conflict: interrupted sync resumes safely; conflicting edits are preserved for review; retries do not duplicate records.
1. Phase gates: next phase does not start while required tests are failing or critical evidence is missing.
1. Android: report build/install/login/isolation/publication tests independently; absent evidence is explicitly not verified.
1. Migration: local test, remote target identity, approval, post-migration schema check, and integration tests are recorded.

## L. Research sources to consult and cite in the evidence report

- OWASP ASVS 5.0.0: [https://asvs.owasp.org/](https://asvs.owasp.org/)
- OWASP ASVS 5.0 file handling requirements: [https://github.com/OWASP/ASVS/blob/master/5.0/en/0x14-V5-File-Handling.md](https://github.com/OWASP/ASVS/blob/master/5.0/en/0x14-V5-File-Handling.md)
- Supabase database migrations: [https://supabase.com/docs/guides/deployment/database-migrations](https://supabase.com/docs/guides/deployment/database-migrations)
- Supabase database backups and limitations, including Storage objects: [https://supabase.com/docs/guides/platform/backups](https://supabase.com/docs/guides/platform/backups)
These sources inform engineering controls; they do not establish school-specific policy or prove that any feature has been implemented.

**Final instruction:** Apply this addendum without deleting original requirements. If the existing stack, credentials, credits, environment, or evidence do not permit a task, report the blocker precisely. Never substitute a mockup, inferred schema, green type-check, or unverified claim for end-to-end evidence.

