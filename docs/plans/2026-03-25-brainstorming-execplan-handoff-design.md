# Update brainstorming handoff to execplan under docs/plans

## Summary

This design updates the `brainstorming` skill so that, after the user approves a design, the agent saves the design to `docs/plans/YYYY-MM-DD-<topic>-design.md`, does not commit, and immediately uses the `execplan` skill to create `docs/plans/YYYY-MM-DD-<topic>-plan.md`.

It also updates `execplan/references/PLANS.md` so that direct use of `execplan` defaults to `docs/plans/YYYY-MM-DD-<topic>-plan.md`, keeping design and implementation plans in one place.

## Scope

- Update `brainstorming/SKILL.md`.
- Update `execplan/references/PLANS.md`.
- Do not change code or unrelated README files.

## File changes

### `brainstorming/SKILL.md`

Adjust the checklist, process flow, terminal-state wording, and post-design guidance so the workflow is:

1. Save the approved design to `docs/plans/YYYY-MM-DD-<topic>-design.md`.
2. Do not commit.
3. Immediately use the `execplan` skill.
4. Create `docs/plans/YYYY-MM-DD-<topic>-plan.md`.

### `execplan/references/PLANS.md`

Replace the current default save-location guidance so that new ExecPlans are stored in `docs/plans/YYYY-MM-DD-<topic>-plan.md` by default.

## Acceptance

- `brainstorming/SKILL.md` no longer instructs the agent to commit the design document.
- `brainstorming/SKILL.md` explicitly requires the `execplan` handoff and exact plan-file path.
- `execplan/references/PLANS.md` names `docs/plans/YYYY-MM-DD-<topic>-plan.md` as the default plan location.
- No unrelated files are changed.
