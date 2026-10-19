<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

## Project rules
- Roles live in `public.user_roles`; authorization is enforced by RLS using `has_role`/`is_staff`/`can_manage` — UI checks are hints only. Why: the future parent app must not bypass rules.
- Student identity (`students`) is separate from yearly `enrollments`; never delete students or enrollments, change status instead. Why: preserve academic history.
- Core tables carry the `audit_trigger`; add it to every new sensitive table. Why: auditable changes.
- Keep `docs/PROJECT_STATUS.md` and `docs/ANTIGRAVITY_HANDOFF.md` updated with each phase. Why: knowledge continuity for Antigravity handoff.
- Admin UI is Arabic, RTL.
