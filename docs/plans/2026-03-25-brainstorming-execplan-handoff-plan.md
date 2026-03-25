# Align brainstorming handoff and ExecPlan storage under docs/plans

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

`execplan/references/PLANS.md` is checked into this repository. This document must be maintained in accordance with `execplan/references/PLANS.md`.

## Purpose / Big Picture

After this change, the `brainstorming` skill will no longer tell an agent to commit an approved design document. Instead, it will tell the agent to save the design to `docs/plans/YYYY-MM-DD-<topic>-design.md`, immediately use the `execplan` skill, and create `docs/plans/YYYY-MM-DD-<topic>-plan.md`. The shared ExecPlan reference in `execplan/references/PLANS.md` will also name `docs/plans/YYYY-MM-DD-<topic>-plan.md` as the default save location, so direct use of `execplan` lands in the same directory. You can see the change working by reading the two edited files and verifying the old commit instruction and old `execplan` directory guidance are gone.

## Progress

- [x] (2026-03-25 16:14 UTC+8) Reviewed `brainstorming/SKILL.md`, `execplan/SKILL.md`, `execplan/references/PLANS.md`, repository layout, and recent history to capture the current workflow and documentation constraints.
- [x] (2026-03-25 16:20 UTC+8) Confirmed with the user that the approved workflow keeps a separate design document, forbids committing at the brainstorming stage, requires an immediate handoff to the `execplan` skill, and also updates `execplan/references/PLANS.md` so direct ExecPlan creation defaults to `docs/plans/YYYY-MM-DD-<topic>-plan.md`.
- [x] (2026-03-25 16:21 UTC+8) Updated `brainstorming/SKILL.md` so its checklist, process flow, after-design section, and terminal-state wording require `docs/plans/...-design.md`, explicitly forbid committing, and require immediate use of the `execplan` skill to create `docs/plans/...-plan.md`.
- [x] (2026-03-25 16:21 UTC+8) Updated `execplan/references/PLANS.md` so the default save-location guidance points to `docs/plans/YYYY-MM-DD-<topic>-plan.md` instead of the repository’s `execplan` directory.
- [x] (2026-03-25 16:21 UTC+8) Validated the wording changes with targeted searches and a focused diff, then recorded the results, one validation false positive, and the final outcome in this ExecPlan.

## Surprises & Discoveries

- Observation: `brainstorming/SKILL.md` already saves design documents under `docs/plans/YYYY-MM-DD-<topic>-design.md`, so the main inconsistency is the extra commit requirement and the lack of an explicit `execplan` handoff.
  Evidence: The current checklist says “Write design doc — save to `docs/plans/YYYY-MM-DD-<topic>-design.md` and commit”.
- Observation: The shared ExecPlan methodology still points new plans to an `execplan` directory, which conflicts with the user’s desired single storage location under `docs/plans/`.
  Evidence: `execplan/references/PLANS.md` currently says “You should save it to the project's `execplan` directory with a clear filename.”
- Observation: The repository did not contain a `docs/plans/` tree before this planning session, so the first plan and design documents establish the convention in practice as well as in guidance.
  Evidence: `find docs -maxdepth 3 -type f` returned no files before these documents were created.
- Observation: A broad negative search for `and commit` produced a false positive because `execplan/references/PLANS.md` still contains the unrelated implementation-time guidance “commit frequently.” That line does not describe brainstorming or plan storage, so validation had to use a narrower obsolete-phrase search.
  Evidence: `rg -n "and commit|Commit the design document to git|execplan directory" brainstorming/SKILL.md execplan/references/PLANS.md` matched only `execplan/references/PLANS.md:9`; `rg -n 'Write design doc.*and commit|Commit the design document to git|`execplan` directory' brainstorming/SKILL.md execplan/references/PLANS.md` returned no output.

## Decision Log

- Decision: Limit the implementation scope to `brainstorming/SKILL.md` and `execplan/references/PLANS.md`.
  Rationale: The user chose the minimal, instruction-only change, and the current repository has no conflicting README text that must be updated to make the workflow understandable.
  Date/Author: 2026-03-25 / OpenAI Codex
- Decision: Keep separate design and plan documents, both stored under `docs/plans/`, with the topic slug `brainstorming-execplan-handoff`.
  Rationale: The user explicitly chose to keep the design document and then generate a separate ExecPlan, and a shared topic slug makes the pair easy to find.
  Date/Author: 2026-03-25 / OpenAI Codex
- Decision: Make the post-design handoff explicit by naming the `execplan` skill, the no-commit rule, and the exact plan-file path in `brainstorming/SKILL.md`.
  Rationale: A generic “transition to implementation” instruction leaves room for old behavior to persist; the user asked for a single, unambiguous next step.
  Date/Author: 2026-03-25 / OpenAI Codex
- Decision: Update the shared PLANS reference to default new ExecPlans to `docs/plans/YYYY-MM-DD-<topic>-plan.md`.
  Rationale: The user wants direct invocation of `execplan` to store plans in the same location as brainstorming-driven handoffs, so the convention must live in the methodology file that `execplan` reads first.
  Date/Author: 2026-03-25 / OpenAI Codex
- Decision: Leave the existing “commit frequently” sentence in `execplan/references/PLANS.md` untouched.
  Rationale: The task is limited to brainstorming handoff behavior and default plan storage. Changing implementation-time version-control guidance would expand scope and could alter the broader ExecPlan methodology without user approval.
  Date/Author: 2026-03-25 / OpenAI Codex

## Outcomes & Retrospective

Implementation is complete. `brainstorming/SKILL.md` now removes the instruction to commit the approved design, turns the terminal state into an explicit handoff to the `execplan` skill, and requires the resulting plan to be written to `docs/plans/YYYY-MM-DD-<topic>-plan.md`. `execplan/references/PLANS.md` now uses that same `docs/plans/` path as the default save location for newly authored ExecPlans, so direct `execplan` use and brainstorming-driven handoff converge on one storage convention.

Validation showed one expected false positive when searching for the generic phrase `and commit`, because `PLANS.md` still tells implementers to “commit frequently.” A narrower obsolete-phrase search returned no matches, the positive search found the new design-path, no-commit, and `execplan` handoff wording, and `git diff -- brainstorming/SKILL.md execplan/references/PLANS.md` showed only the intended documentation changes. No code or unrelated documentation files were modified.

## Context and Orientation

This repository stores reusable Pi skills. The file `brainstorming/SKILL.md` is the instruction document for the brainstorming skill. It governs how an agent explores an idea, presents a design, records that design, and transitions to planning. The file `execplan/SKILL.md` is a thin wrapper that tells the agent to follow `execplan/references/PLANS.md`, and `execplan/references/PLANS.md` is the authoritative methodology for creating an ExecPlan. An ExecPlan is a step-by-step implementation specification that must be self-contained and observable. In this task, “handoff” means the exact point where the brainstorming skill stops and tells the agent what to do next. After the change, that handoff must say: save the approved design in `docs/plans/YYYY-MM-DD-<topic>-design.md`, do not commit, immediately use the `execplan` skill, and save the resulting ExecPlan in `docs/plans/YYYY-MM-DD-<topic>-plan.md`.

The current inconsistency is easy to summarize. `brainstorming/SKILL.md` already points design documents to `docs/plans/...-design.md`, but it still says to commit the design and only vaguely says planning comes next. `execplan/references/PLANS.md` still tells authors to save new ExecPlans in the project’s `execplan` directory. A novice following both documents today would receive mixed instructions about where plans belong and whether a commit should happen before planning. The implementation must remove that ambiguity without broadening scope into unrelated skill documentation.

## Plan of Work

Start in `brainstorming/SKILL.md`. Rewrite the numbered checklist so step 5 only saves the approved design document and step 6 becomes an explicit handoff to the `execplan` skill. Update the process-flow diagram and the sentence immediately below it so the terminal state is no longer a generic “create implementation plan” but a specific sequence: write the design document, do not commit, invoke `execplan`, and create `docs/plans/YYYY-MM-DD-<topic>-plan.md`. Then revise the prose in the “After the Design” and “Implementation” subsections so every occurrence of the old transition language matches the new rule. Keep the existing hard gate against implementation and do not add any behavior beyond the requested documentation changes.

Then edit `execplan/references/PLANS.md`. Change the single save-location instruction near the top so it names `docs/plans/YYYY-MM-DD-<topic>-plan.md` as the default destination for a new ExecPlan. Preserve the rest of the methodology, especially the requirements about self-contained plans and living-document sections. Do not rewrite the broader skeleton unless a wording dependency makes a tiny adjacent clarification necessary.

After the text edits, verify the repository tells one consistent story. Read both files end to end and ensure no sentence still instructs the user to commit a design as part of brainstorming. Ensure both documents mention the `docs/plans/` plan location consistently. Record the validation evidence and any surprising wording interactions in this ExecPlan before considering the work complete.

## Concrete Steps

Work from the repository root `/home/bot/projects/my-skills`.

1. Open `brainstorming/SKILL.md` and change the checklist, process flow, “After the Design”, and transition prose so the approved design is written to `docs/plans/YYYY-MM-DD-<topic>-design.md`, no commit occurs, and the next mandatory action is to use the `execplan` skill to create `docs/plans/YYYY-MM-DD-<topic>-plan.md`.

2. Open `execplan/references/PLANS.md` and replace the sentence that currently points authors to the project’s `execplan` directory with wording that establishes `docs/plans/YYYY-MM-DD-<topic>-plan.md` as the default save location.

3. From `/home/bot/projects/my-skills`, run these validation commands and compare the output to the expected examples.

    rg -n 'Write design doc.*and commit|Commit the design document to git|`execplan` directory' brainstorming/SKILL.md execplan/references/PLANS.md

    Expected result: no output.

    rg -n "docs/plans/YYYY-MM-DD-<topic>-plan.md|docs/plans/YYYY-MM-DD-<topic>-design.md|Do NOT commit|do not commit|execplan skill" brainstorming/SKILL.md execplan/references/PLANS.md

    Expected result: matches in `brainstorming/SKILL.md` showing the design path, no-commit rule, and `execplan` handoff, plus a match in `execplan/references/PLANS.md` showing the default plan path.

    git diff -- brainstorming/SKILL.md execplan/references/PLANS.md

    Expected result: a focused diff showing only the intended wording changes.

4. Update this ExecPlan’s `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` sections with the actual results before stopping.

## Validation and Acceptance

Acceptance is documentation behavior, not compiled code. A novice must be able to read only `brainstorming/SKILL.md` and know that brainstorming ends by saving a design document, not committing it, and immediately invoking the `execplan` skill to create `docs/plans/YYYY-MM-DD-<topic>-plan.md`. The same novice must be able to read only `execplan/references/PLANS.md` and see that the default save location for a newly authored ExecPlan is that same `docs/plans/...-plan.md` path.

Validation is complete when the negative search for the obsolete commit and `execplan directory` phrasing returns no matches, the positive search returns the new path and handoff phrases in the expected files, and `git diff -- brainstorming/SKILL.md execplan/references/PLANS.md` shows no unrelated edits. Because this is a documentation-only change, there is no separate test suite to run; the proof is a consistent, unambiguous set of instructions in the edited files.

## Idempotence and Recovery

These edits are safe to repeat because they affect only two text files. Re-read each file before applying replacements so you do not duplicate a phrase that is already updated. If an edit partially lands or the wording becomes inconsistent, discard the partial wording and re-apply the replacement to the exact affected section until the validation searches return the expected results. If you accidentally broaden the diff, use `git diff -- brainstorming/SKILL.md execplan/references/PLANS.md` to isolate the unintended text and revert only those lines before continuing.

## Artifacts and Notes

The implementation preserved the user-approved handoff behavior below, and the edited files now express it directly.

    Approved brainstorming handoff:
    1. Save the validated design to docs/plans/YYYY-MM-DD-<topic>-design.md.
    2. Do not commit.
    3. Immediately use the execplan skill.
    4. Create docs/plans/YYYY-MM-DD-<topic>-plan.md.

The before-state that needed to disappear is shown here for comparison.

    brainstorming/SKILL.md (before):
    5. **Write design doc** — save to `docs/plans/YYYY-MM-DD-<topic>-design.md` and commit
    6. **Transition to implementation** — create a detailed implementation plan

    execplan/references/PLANS.md (before):
    You should save it to the project's `execplan` directory with a clear filename.

The final validation evidence is concise and sufficient for a future contributor to confirm the outcome.

    Obsolete-phrase search:
    rg -n 'Write design doc.*and commit|Commit the design document to git|`execplan` directory' brainstorming/SKILL.md execplan/references/PLANS.md
    Expected and observed result: no output.

    Positive search highlights:
    execplan/references/PLANS.md:7: ... save it to `docs/plans/YYYY-MM-DD-<topic>-plan.md` by default ...
    brainstorming/SKILL.md:31: 6. **Handoff to execplan** — do NOT commit; immediately use the `execplan` skill to create `docs/plans/YYYY-MM-DD-<topic>-plan.md`
    brainstorming/SKILL.md:59: **The terminal state is handing off to the `execplan` skill and creating `docs/plans/YYYY-MM-DD-<topic>-plan.md`.** ...

    Focused diff command:
    git diff -- brainstorming/SKILL.md execplan/references/PLANS.md
    Observed result: only the intended wording changes in those two files.

## Interfaces and Dependencies

No runtime code interfaces change in this task. The required textual interfaces are the instruction sentences inside `brainstorming/SKILL.md` and `execplan/references/PLANS.md`.

In `brainstorming/SKILL.md`, the checklist and narrative must explicitly express four behaviors: save the design to `docs/plans/YYYY-MM-DD-<topic>-design.md`, do not commit, use the `execplan` skill immediately, and create `docs/plans/YYYY-MM-DD-<topic>-plan.md`. The diagram and terminal-state sentence must reinforce the same sequence rather than reintroduce a generic planning step.

In `execplan/references/PLANS.md`, the save-location guidance near the top must name `docs/plans/YYYY-MM-DD-<topic>-plan.md` as the default output path for a new ExecPlan. That wording is a dependency of `execplan/SKILL.md`, because the skill tells the agent to read and follow `PLANS.md` first.

Revision note: 2026-03-25 implementation completed; updated `brainstorming/SKILL.md` to forbid committing and require immediate `execplan` handoff, updated `execplan/references/PLANS.md` to default plans under `docs/plans/`, and recorded validation evidence and rationale for leaving unrelated ExecPlan commit guidance unchanged.
