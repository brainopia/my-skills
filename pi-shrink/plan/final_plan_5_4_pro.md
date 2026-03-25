# Build the `adaptive-planning` Pi skill — final integrated plan (v1)

This plan is a living document. As implementation proceeds, keep `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` up to date. The goal is that a fresh agent can open only this file plus the current workspace and still finish the work correctly.

## Purpose / Big Picture

We want one Pi skill that helps an agent choose **how much planning is necessary before acting**. The skill must prevent two common failures at once: over-planning trivial tasks and under-planning risky or ambiguous ones. After this work is complete, a Pi agent equipped with `adaptive-planning` will be able to classify a request into one of five planning depths, create a live plan only when it is worth the cost, ask only truly necessary questions, use research and subagents when uncertainty warrants it, pause for human approval before coding when risk justifies it, and decompose very large initiatives into milestone-sized child plans.

The user-visible effect should be easy to observe. For small, local, reversible changes, the agent should move quickly with a lightweight blind-spot check and a short self-review. For medium and large work, the agent should produce a plan file that is readable, reviewable, and restartable, then either pause for approval or continue milestone by milestone depending on the selected tier. For long-running work, the plan file must become the source of truth so a fresh agent can resume from it without re-reading the whole chat.

This version is intentionally **skill-only**. It should use Pi’s existing primitives—`read`, `write`, `edit`, `bash`, `subagent`, and `interview`—rather than requiring an extension, hooks, or custom tools. The design should be strong enough to work well now, while leaving room for future extension-based enforcement if practice shows that soft instructions are not enough.

## Progress

- [x] (2026-03-08 12:40 UTC) Read and compared the five candidate plans and wrote `result.md` with a detailed analysis.
- [x] (2026-03-08 12:55 UTC) Chose the target direction: use the Pi-native `pi-execplan-opus` approach as the base, strengthen it with RPD, backpressure, restart-from-plan, and review gates.
- [x] (2026-03-08 13:05 UTC) Authored this final integrated plan in `final_plan_5_4_pro.md`.
- [ ] Create the skill skeleton at `adaptive-planning/` with `SKILL.md`, `README.md`, `references/`, and `assets/templates/`.
- [ ] Write the router-style `SKILL.md` with a strong frontmatter `description`, universal invariants, the five tiers, and explicit instructions for when to read each reference file.
- [ ] Write the five reference files: `mode-selection.md`, `live-plan.md`, `research-and-subagents.md`, `alignment-and-gates.md`, and `examples.md`.
- [ ] Write `assets/templates/live-plan-template.md` and `assets/templates/mega-plan-template.md`.
- [ ] Validate the skill with the local validator and test it in isolation with `pi --no-skills --skill ./adaptive-planning`.
- [ ] Run at least five behavioral scenarios, one per tier, refine the skill, and update this plan with the results.
- [ ] Optionally add v1.1 improvements only after the core behavior is stable.

## Surprises & Discoveries

- Observation: The best plan in the set was not the most abstract one but the one that balanced conceptual rigor with Pi-specific mechanics.
  Evidence: `pi-execplan-opus` was the only candidate that simultaneously specified a concrete live-plan contract, used `interview` for structured HITL, and described realistic subagent patterns.

- Observation: Several plans had strong ideas that were not fully implemented, especially around RPD, backpressure, and restart-from-plan.
  Evidence: `pi-5.4-pro-high` articulated those ideas better than other plans, but it left too much detail for future reference files.

- Observation: OMP-centric plans contained useful workflow patterns but should not be copied structurally into a Pi implementation.
  Evidence: `omp-opus` depended on `exit_plan_mode`, `local://PLAN.md`, and OMP-specific task agents; these do not map directly to Pi’s skill model.

- Observation: In Pi, the frontmatter `description` and progressive disclosure structure matter more than many candidate plans initially acknowledged.
  Evidence: `docs/skills.md` and `skill-creator/SKILL.md` make it explicit that the description controls auto-loading, while long guidance should be split into references and templates.

- Observation: The local skill validator effectively makes `README.md` and an `Installation` section part of the practical contract, even if Pi itself does not strictly require README for loading.
  Evidence: `validate_skill.py` fails if `README.md` is missing or lacks an Installation heading.

## Decision Log

- Decision: Build one unified skill named `adaptive-planning`, not five separate skills.
  Rationale: All tiers share the same core protocol—frame → classify → remove blind spots → validate → execute or pause. One skill avoids trigger ambiguity and keeps behavior consistent.
  Date/Author: 2026-03-08 / OpenAI agent

- Decision: Keep v1 entirely within skill boundaries; do not require an extension, hooks, or custom tools.
  Rationale: The target behavior can be expressed with Pi’s existing tools. Hard enforcement can be a later follow-up if needed.
  Date/Author: 2026-03-08 / OpenAI agent

- Decision: Use five tiers named `direct`, `guided`, `research`, `feature`, and `mega`.
  Rationale: These names are clearer and more professional than purely metaphorical names while still mapping cleanly to the compared plans: `direct` ≈ quickstrike/P0, `guided` ≈ P1, `research` ≈ P2, `feature` ≈ P3, `mega` ≈ P4.
  Date/Author: 2026-03-08 / OpenAI agent

- Decision: Make RPD mandatory in every tier, but lightweight in `direct`.
  Rationale: Even the simplest tasks benefit from a tiny restatement of goal, constraints, and proof of success. This lowers the chance of acting on a wrong interpretation.
  Date/Author: 2026-03-08 / OpenAI agent

- Decision: Make backpressure an explicit design concept, not an implicit side effect of HITL.
  Rationale: Good planning is not just about producing a plan; it is also about stopping unsafe forward motion when context, validation, or alignment is insufficient.
  Date/Author: 2026-03-08 / OpenAI agent

- Decision: Use one main live plan file for `guided`, `research`, and `feature`; use a master plan plus child plans on demand for `mega`.
  Rationale: A single source of truth keeps medium-complexity work readable. Mega initiatives need decomposition, but child plans should be created only when a milestone actually begins so they do not go stale.
  Date/Author: 2026-03-08 / OpenAI agent

- Decision: Use `interview` for structured approval and multi-question alignment when it materially improves UX; keep a plain-text fallback path.
  Rationale: Structured HITL is superior to ad hoc chat for plan review and bundled questions, but the skill must remain usable if `interview` is unavailable or inappropriate.
  Date/Author: 2026-03-08 / OpenAI agent

- Decision: Keep subagent usage optional and cost-aware.
  Rationale: Second opinions are valuable for uncertain or high-blast-radius work, but mandatory subagents on every task would make the skill slow and expensive.
  Date/Author: 2026-03-08 / OpenAI agent

- Decision: Write `SKILL.md` and reference files in English.
  Rationale: English gives the best portability across repos and the highest chance that a broad range of user requests will semantically match the frontmatter description. Human discussion around the skill can remain bilingual if desired.
  Date/Author: 2026-03-08 / OpenAI agent

- Decision: Implement the skill at `./adaptive-planning/` in this workspace, not under `./skills/` for v1.
  Rationale: A single root-level skill directory is simplest for validation and isolated testing with `--skill ./adaptive-planning`. If later published as a multi-skill package, it can be moved under a `skills/` directory without changing its internals.
  Date/Author: 2026-03-08 / OpenAI agent

- Decision: Keep the optional “meta overlay” as a v1.1 capability, not a required first-class tier.
  Rationale: It is genuinely useful when the hardest part is choosing the approach rather than implementing it, but making it mandatory in v1 would overcomplicate the skill before the base five-tier behavior is stable.
  Date/Author: 2026-03-08 / OpenAI agent

## Outcomes & Retrospective

At this stage, the output is a final implementation plan, not the implemented skill itself. The most important synthesis is this: the best result does not come from choosing the single most detailed candidate or the single most elegant candidate. It comes from combining the Pi-specific operational quality of `pi-execplan-opus` with the stronger conceptual controls from `pi-5.4-pro-high` and the review-gate rigor from `omp-5.4`.

The plan should therefore optimize for three things at once: clarity of activation, proportionality of planning depth, and restartability from files. If later manual tests show that one of these properties is consistently weaker than the others, that should be treated as a product-level issue, not a minor wording bug.

## Context and Orientation

Pi skills are self-contained capability packages discovered by Pi from skill directories. A valid skill requires a directory whose name matches the `name` in `SKILL.md` frontmatter. The most important frontmatter field for runtime behavior is `description`, because Pi decides whether to auto-load the skill based on that description before reading the skill body. This means the description cannot be generic; it must clearly say what the skill is for and when to use it.

Pi loads skill content progressively. The frontmatter is always in context, the body is loaded when the skill is triggered, and reference files or assets are only useful if the body explicitly tells the agent when to read them. Therefore the body should act as a **router**, not an encyclopedia. Long explanations belong in `references/`; copyable skeletons belong in `assets/templates/`.

The local validator script used in this environment is `/home/bot/projects/pi-skills-with-self-analysis/extending-pi/skill-creator/scripts/validate_skill.py`. It checks frontmatter rules and also expects a `README.md` with an `Installation` section. The relevant Pi documentation also establishes that names must be lowercase letters, digits, and hyphens only, and that the directory name must match the skill name exactly.

The implementation workspace currently contains plan documents and analysis, but not the finished skill package. We are creating a new root-level skill directory named `adaptive-planning/`. That directory will be self-contained enough to validate locally and test with `pi --no-skills --skill ./adaptive-planning`.

### Explicit non-goals for v1

This plan does **not** aim to build an extension, a hard policy enforcement layer, or a custom planner runtime. It does not try to detect actual token window usage programmatically. It does not introduce custom tools. It does not create a separate skill per tier. It does not require subagents or `interview` in every non-trivial case. It does not attempt to solve long-term plan history or persistent telemetry.

## Target Architecture

The final skill package should look like this:

    adaptive-planning/
    ├── SKILL.md
    ├── README.md
    ├── references/
    │   ├── mode-selection.md
    │   ├── live-plan.md
    │   ├── research-and-subagents.md
    │   ├── alignment-and-gates.md
    │   └── examples.md
    └── assets/
        └── templates/
            ├── live-plan-template.md
            └── mega-plan-template.md

This layout is deliberately constrained. Five reference files are enough to cover the moving parts without fragmenting the skill into too many tiny documents. The intended roles are:

- `SKILL.md`: always-loaded router; short, explicit, and instruction-heavy.
- `README.md`: human-facing summary, installation, and usage examples.
- `references/mode-selection.md`: the full rubric for choosing among the five tiers, including escalation, de-escalation, anti-patterns, and tier override guidance.
- `references/live-plan.md`: the canonical live-plan contract, status lifecycle, update rules, naming conventions, and handoff protocol.
- `references/research-and-subagents.md`: when and how to use research, scouts, second opinions, councils, and fresh-agent handoffs.
- `references/alignment-and-gates.md`: question policy, HITL behavior, backpressure, review gates, blocker remediation, and fallback behavior when `interview` is not used.
- `references/examples.md`: one worked example per tier plus a few anti-examples.
- `assets/templates/*.md`: copyable skeletons for plan-file creation.

## Universal Skill Contract

Every tier must obey the same universal contract, even though the amount of ceremony changes.

First, the agent must perform a short **RPD** (Rapid Problem Definition). The RPD is a concise restatement of the user’s request, the relevant constraints, the known repo facts, the biggest unknowns, the proof of success, and the chosen planning tier. In `direct`, this may only be one or two sentences in the agent’s reasoning and short user-facing summary. In other tiers it must be written into the plan file.

Second, the agent must choose the **lightest tier that still removes blind spots**. Speed is desirable, but speed that skips risk discovery is false efficiency.

Third, the agent must define **validation before execution**. Validation means observable proof that the work succeeded, not merely “the code compiles.”

Fourth, the agent must apply **backpressure**. If the task is ambiguous, risky, or under-contextualized, the agent must pause, gather missing context, ask focused questions, or escalate tiers rather than pressing ahead.

Fifth, the agent must perform **self-review in every tier**. The location and depth of self-review vary by tier, but it is never optional.

Sixth, for any tier that uses a plan file, that file is a **living artifact**. It must be updated as research changes the plan, as implementation advances, when discoveries occur, and before any fresh-agent handoff.

## The Five Tiers

### Tier 0 — `direct`

Use this tier for narrow, low-risk, low-ambiguity, highly reversible work. Typical signals: one local area, no significant architectural choice, no need for external research, no dependency on user preferences, and a straightforward validation path.

Behavior: perform a tiny RPD, think through 2–4 likely blind spots, define a short validation statement, execute immediately, then end with a brief self-review. No plan file. No pre-execution HITL. No planning-time questions. If the agent discovers real uncertainty or wider impact while investigating, it must escalate out of `direct`.

### Tier 1 — `guided`

Use this tier for small but non-trivial work where a saved plan and user approval are worth the overhead, but the agent can proceed without asking planning-time questions.

Behavior: write one live plan file, record assumptions instead of asking clarifying questions, run a plan self-review, present the plan for approval, and pause before execution. After approval, execute and update the plan as work proceeds. Post-execution self-review is still expected.

### Tier 2 — `research`

Use this tier when the goal is known but there are material unknowns, important trade-offs, or external interfaces that justify a limited research pass and a small number of focused questions.

Behavior: do bounded repo and/or external research, ask up to three targeted questions only if the answers materially change the approach, write one live plan file, run a plan self-review, present the plan for approval, then execute after approval. Post-execution self-review is required.

### Tier 3 — `feature`

Use this tier for multi-surface features or changes with meaningful integration risk, rollout implications, or complex validation. This is the strongest single-plan mode before decomposition.

Behavior: perform deeper discovery, use subagents if they reduce uncertainty or context crowding, ask bundled questions through `interview` when multiple dimensions need alignment, write one main live plan file, optionally keep supporting notes if needed, run stronger review gates, present the plan for approval, and execute in tracked stages after approval. The main plan file remains the source of truth.

### Tier 4 — `mega`

Use this tier when the work is too large or heterogeneous to manage responsibly as one execution plan. The top-level problem must be decomposed into milestone-sized child efforts.

Behavior: create a master plan first, define milestones, dependencies, sequencing, and exit criteria, ask strategic questions early, optionally use subagent councils for architecture evaluation, present the master plan for approval, and only create child plans when a milestone actually begins. Each child plan usually follows the `feature` protocol, though some milestones may qualify as `research` or `guided`.

## Optional Meta Overlay (v1.1, not required for MVP)

If the hardest uncertainty is not implementation but approach selection—such as choosing the right architecture, third-party strategy, or system decomposition—then a short **meta overlay** may wrap `research`, `feature`, or `mega`. The meta overlay is not a sixth tier. It is a bounded pre-plan that answers: what approaches exist, what criteria matter, and what recommendation is justified. Once that is resolved, the normal implementation tier proceeds.

Do not implement the meta overlay as a mandatory first-class component in v1. Mention it in documentation as an optional advanced pattern only after the core five-tier behavior is stable.

## Review Gates and Finding Classification

The skill should not treat self-review as a vague re-read. It should structure review around explicit gates.

### Gate 1 — RPD gate

Is the task actually understood? Are the goal, constraints, repo facts, and proof of success clear enough to proceed at the current tier?

### Gate 2 — Completeness gate

Does the plan or direct action path include a concrete approach, assumptions, validation, stopping condition, and next step?

### Gate 3 — Blind-spot gate

Did the agent consider the most likely missing surfaces for this task type: compatibility, rollback, tests, observability, permissions, documentation, user-visible side effects, data integrity, performance, or integration boundaries?

### Gate 4 — Execution gate

Is it safe to proceed? For `guided` and above, does the plan exist, has self-review happened, and has approval been obtained where required?

### Gate 5 — Escalation gate

Has new information invalidated the chosen tier? If uncertainty, blast radius, dependency complexity, or required user input increased, the skill must escalate rather than forcing the old tier to fit.

Findings from self-review or subagents should be classified as:

- `blocker`: must be resolved before approval or execution.
- `watchout`: not a blocker, but must be tracked during execution or called out to the user.
- `nice-to-have`: useful refinement that should not stall the workflow.

If a blocker appears, the plan must either be revised to resolve it or explicitly state why execution cannot safely proceed yet.

## Mode Selection Policy

The tier rubric in `references/mode-selection.md` must evaluate at least these dimensions:

- scope: how many files, modules, or systems are likely affected?
- unknowns: does the agent already know how to solve this, or is it learning?
- risk / blast radius: how costly is a wrong move?
- integration surface: internal-only, or touching APIs, jobs, auth, persistence, third-party services?
- user alignment risk: are there unresolved preferences or unclear success criteria?
- validation complexity: can success be shown quickly, or does it require multi-step verification?
- reversibility: how easy is it to undo mistakes?

The default mapping should be:

- `direct` when all dimensions are low and reversibility is high.
- `guided` when the work is still small but the user should review the direction before coding.
- `research` when bounded unknowns or trade-offs exist.
- `feature` when multiple surfaces, stronger validation, or broader discovery are needed.
- `mega` when the work is too large or mixed to fit one robust plan.

### Escalation rules

Escalate at least one tier if any of the following is true:

- validation is unclear or cannot yet be stated concretely;
- there are unanswered questions whose answers would materially change the plan;
- the agent discovers unfamiliar external dependencies or non-trivial architectural trade-offs;
- the task affects multiple independently testable milestones;
- the user explicitly asks for a plan, research, decomposition, or extra caution.

### De-escalation rules

De-escalate if the task turned out to be much narrower than it first appeared, if repo evidence removes the unknowns, or if the broader plan can be split and only one trivial local edit remains.

### Anti-patterns

The rubric should explicitly warn against common mistakes:

- Do not use `direct` in an unfamiliar codebase just because the diff looks small.
- Do not use `mega` for work that is large in volume but conceptually simple.
- Do not keep a task in `guided` if there are unresolved questions that materially change the approach.
- Do not overuse research when repo evidence already answers the question.
- Do not create a plan file in `direct` merely as ritual.
- When in doubt between two adjacent tiers, choose the safer one temporarily and de-escalate later if evidence supports it.

## Live Plan Contract

For `guided`, `research`, and `feature`, the live plan file should be named:

    execplan/YYYY-MM-DD-<tier>-<slug>.md

For `mega`, the master plan should live at:

    execplan/<initiative-slug>/master-plan.md

Child plans should be created only when a milestone begins, using:

    execplan/<initiative-slug>/m<N>-<milestone-slug>.md

The canonical live-plan format should contain these sections in order:

1. Title
2. Status
3. Tier
4. Created / Last updated
5. Purpose
6. RPD
7. Assumptions & Constraints
8. Blind Spots Addressed
9. Research Findings (optional)
10. Approach
11. Work Plan / Milestones
12. Validation & Acceptance
13. Rollback / Recovery
14. Action Log
15. Decision Log
16. Surprises & Discoveries
17. Self-Review
18. Next Steps
19. Handoff Note

The plan should move through a lifecycle such as:

- `planning`
- `awaiting-review`
- `approved`
- `in-progress`
- `blocked`
- `done`

Update rules matter as much as the sections themselves. The plan must be updated whenever the chosen approach changes, after any material research finding, after each significant execution step, before and after approval, when a blocker appears, and immediately before a fresh-agent handoff.

## Alignment, Questions, and Approval Policy

The fundamental question rule is simple: ask only when the answer would materially change **scope, architecture, risk, dependencies, acceptance criteria, or milestone ordering**. If the answer would not change the approach, make a reasonable assumption and record it.

Tier-specific question budgets should be:

- `direct`: zero questions.
- `guided`: zero planning-time questions; assumptions go into the plan, and the user can correct them during approval.
- `research`: up to three targeted questions, ideally batched once.
- `feature`: bundled questions allowed; prefer `interview` when there are multiple dimensions of choice.
- `mega`: strategic questions early, plus per-milestone questions only when each milestone begins.

Approval behavior should also vary by tier:

- `direct`: no approval pause.
- `guided`, `research`, `feature`, `mega`: approval required before implementation begins.

When using `interview` for approval, the default choices should be:

- approve as proposed;
- request changes to the plan;
- escalate to a deeper tier;
- defer implementation and keep planning.

A plain-text fallback must exist. If `interview` is not used, the agent should still present a concise plan summary and ask for explicit confirmation before coding in tiers `guided` and above.

## Research and Subagent Policy

The skill should recognize four distinct subagent patterns.

### 1. Scout pass

Use the built-in `scout` agent for fast, low-cost repo reconnaissance. This is especially useful in `guided`, `research`, `feature`, and `mega` when multiple surfaces might be involved.

### 2. Research pass

Use `researcher` when external documentation or unfamiliar libraries matter. Keep the prompt narrow and outcome-oriented so the research closes a real unknown rather than generating trivia.

### 3. Second-opinion plan pass

Use `planner` or `worker` for an independent critique or alternative plan when the task is high-risk or the main agent suspects blind spots. This is the Pi-native version of an “oracle” or plan auditor.

### 4. Post-implementation review pass

Use `reviewer` after non-trivial implementation, especially in `guided`, `research`, and `feature`, to compare the change against the approved plan and surface missed risks.

### 5. Parallel council (optional)

For genuinely high-stakes architectural choices, run 2–3 subagents in parallel with different optimization goals, such as simplicity, robustness, and operational safety, then synthesize the output into the main plan. This should be rare and justified, not the default.

### Cost-awareness rule

Subagents are not free. The skill should recommend them when they reduce uncertainty or context crowding enough to justify their cost. A lightweight scout pass is much cheaper than a full council. The default should be the smallest helpful pattern.

### Fallback rule

If `subagent` is unavailable or would be wasteful, the main agent must perform the same reasoning sequentially and continue. The workflow must remain correct without parallelism.

## Context Reset and Restart-from-Plan

The skill must treat restart-from-plan as a first-class workflow, not an exception. If context becomes crowded—because many files were read, research sprawled, or the plan has grown into the main source of truth—the agent must persist what it knows before continuing.

The reset protocol is:

1. Update the live plan with current status, Action Log, Decision Log, Surprises, Validation state, and precise Next Steps.
2. Add a short Handoff Note that tells a fresh agent exactly what to read and what remains.
3. Continue through a fresh `subagent` run or an explicitly restarted session that reads the plan first.

Heuristic triggers for reset should include: the agent has read many files without implementing yet, the reasoning begins repeating itself, or too much context is now encoded in memory rather than in the plan file.

## Plan of Work

The implementation should proceed in six milestones.

### Milestone 1 — Create the skill skeleton and frontmatter contract

Create the `adaptive-planning/` directory, the `references/` and `assets/templates/` subdirectories, and stub files for `SKILL.md` and `README.md`. The crucial output of this milestone is not just the tree but the frontmatter contract: the skill name, the trigger description, and the decision to keep the body concise and reference-driven.

At the end of this milestone, Pi should be able to recognize the skill directory structure, and the validator should only fail because the contents are incomplete, not because the package layout is wrong.

### Milestone 2 — Write the router-style `SKILL.md`

`SKILL.md` must be short enough to remain cheap in context and rich enough to reliably route the agent. It should open with the purpose of proportional planning, define the universal invariants, summarize the five tiers, state the question and approval rules at a high level, and explicitly tell the agent when to read each reference file. It should also name the built-in Pi tools and subagents it expects to use.

This milestone is successful when a human can read `SKILL.md` and understand the operational flow without the file ballooning into a monolith.

### Milestone 3 — Write the five reference files

This is the real behavior layer. Each reference file must own one concern and avoid duplication.

`mode-selection.md` should define the rubric, escalation rules, de-escalation rules, anti-patterns, and tier override guidance.

`live-plan.md` should define file naming, lifecycle, section-by-section semantics, update rules, and handoff requirements.

`research-and-subagents.md` should define scout/research/second-opinion/reviewer/council patterns, cost-awareness, and reset behavior.

`alignment-and-gates.md` should define question policy, approval flow, structured HITL via `interview`, fallback plain-text approval, review gates, blocker remediation, and backpressure per tier.

`examples.md` should contain one worked example per tier and a few anti-examples that show what misclassification looks like.

### Milestone 4 — Write the plan templates

`assets/templates/live-plan-template.md` should be a fillable version of the guided/research/feature live plan.

`assets/templates/mega-plan-template.md` should extend the live plan with decomposition-specific sections such as milestone map, cross-cutting concerns, per-milestone exit criteria, and child-plan links.

This milestone is successful when an agent can copy a template and fill it in consistently instead of improvising structure from scratch.

### Milestone 5 — Validate and test in Pi

Run the validator, then load the skill in isolation with Pi. Exercise the five canonical scenarios and verify that the behavior matches the intended tier, file creation policy, question budget, and approval behavior.

The key success condition is behavioral consistency. The skill should not over-plan simple work, nor should it improvise its way through complex work without enough structure.

### Milestone 6 — Tighten language and capture lessons

After manual tests, edit only the files that actually caused the wrong behavior. If the skill triggers too often or not often enough, fix the frontmatter `description`. If tier choice is wrong, fix `mode-selection.md`. If questions are noisy, fix `alignment-and-gates.md`. If the agent invents inconsistent plan structures, fix `live-plan.md` and the templates.

When stable, update this plan’s retrospective with the final lessons, limits, and any v1.1 backlog.

## Concrete Steps

Work from the repository root.

1. Create the directory structure:

       mkdir -p adaptive-planning/references adaptive-planning/assets/templates execplan

2. Create `adaptive-planning/README.md`.

   The README must include:
   - a short human summary;
   - an `Installation` section;
   - the five tiers at a glance;
   - a short explanation that v1 is skill-only and uses Pi’s existing tools.

3. Create `adaptive-planning/SKILL.md` with this frontmatter:

       ---
       name: adaptive-planning
       description: Adaptive planning for coding and implementation tasks. Use when a request may need choosing the right planning depth, creating or updating a live plan, doing focused research, asking clarifying questions, pausing for approval before coding, using subagents for exploration or review, or decomposing a large initiative into milestones.
       ---

   The body should be roughly 120–180 lines and must:
   - state the purpose of proportional planning;
   - define the universal contract;
   - summarize the five tiers;
   - name the references and when to read them;
   - explain the self-review and reset policy;
   - stay concise enough that it remains cheap to load.

4. Create `adaptive-planning/references/mode-selection.md`.

   It must contain:
   - the tier rubric;
   - escalation and de-escalation rules;
   - anti-patterns;
   - tier override guidance for user approval flows.

5. Create `adaptive-planning/references/live-plan.md`.

   It must contain:
   - naming rules for plan files;
   - the canonical section order;
   - lifecycle statuses;
   - update rules;
   - rules for handoff and recovery.

6. Create `adaptive-planning/references/research-and-subagents.md`.

   It must contain:
   - scout pass guidance;
   - research pass guidance;
   - second-opinion guidance;
   - reviewer guidance;
   - parallel council guidance;
   - cost-awareness guidance;
   - reset/handoff protocol.

7. Create `adaptive-planning/references/alignment-and-gates.md`.

   It must contain:
   - question budgets by tier;
   - approval rules by tier;
   - `interview` usage patterns;
   - plain-text approval fallback;
   - review gates;
   - blocker/watchout/nice-to-have classification;
   - backpressure rules for each tier.

8. Create `adaptive-planning/references/examples.md`.

   Include at least these examples:
   - rename a class and update imports → `direct`
   - add a CLI flag with help text and tests → `guided`
   - integrate OAuth2 login with provider constraints → `research`
   - build a notifications system across channels → `feature`
   - decompose a monolith into multiple services → `mega`

   For each example, show:
   - why the tier was chosen;
   - what files or artifacts should appear;
   - what questions are allowed;
   - where HITL occurs;
   - what self-review should look like.

9. Create `adaptive-planning/assets/templates/live-plan-template.md`.

   It must mirror the live-plan contract for `guided`, `research`, and `feature`.

10. Create `adaptive-planning/assets/templates/mega-plan-template.md`.

    It must extend the live-plan template with:
    - decomposition;
    - milestone map;
    - cross-cutting concerns;
    - child-plan links;
    - per-milestone exit criteria.

11. Validate the skill:

       python3 /home/bot/projects/pi-skills-with-self-analysis/extending-pi/skill-creator/scripts/validate_skill.py ./adaptive-planning

    Expected output:

       Skill is valid!

12. Load the skill in isolation:

       pi --no-skills --skill ./adaptive-planning

    Inside Pi, explicitly invoke:

       /skill:adaptive-planning

    Then test the canonical scenarios.

13. After each test scenario, inspect whether:
    - the correct tier was chosen;
    - a plan file was created only when it should be;
    - the question budget was respected;
    - approval happened only where required;
    - self-review was visible;
    - plan file updates and handoff behavior were correct.

14. Refine only the file responsible for the observed failure mode and re-test.

## Validation and Acceptance

Acceptance is behavioral first and structural second.

### Structural acceptance

The skill passes the validator. `SKILL.md` has valid frontmatter. The directory name matches the skill name. `README.md` exists and contains an Installation section. All five reference files and both templates exist.

### Activation acceptance

When the user asks for planning depth, research-before-coding, approval-before-implementation, milestone decomposition, or a live planning workflow, Pi should have a strong reason to auto-load this skill. If activation is weak or noisy, the frontmatter description must be revised.

### Tier acceptance

For `direct`, the agent should not create a plan file. It should perform a brief RPD, mention blind spots and validation concisely, execute, and end with a short self-review.

For `guided`, the agent should create `execplan/YYYY-MM-DD-guided-<slug>.md`, record assumptions instead of asking planning-time questions, run plan self-review, present the plan for approval, and wait.

For `research`, the agent should do bounded research, ask no more than three material questions, create one main plan file, present it for approval, and only then proceed.

For `feature`, the agent should show broader blind-spot coverage, stronger validation, and deeper discovery. A reviewer or second-opinion pass should at least be considered. One main plan file remains the source of truth.

For `mega`, the agent should create a master plan with milestone decomposition, cross-cutting concerns, and exit criteria. It should not try to fully detail every child plan upfront.

### Approval acceptance

For tiers `guided` and above, the agent must not begin coding before explicit approval. Using `interview` is preferred but not required if a clear plain-text approval step is present.

### Restart acceptance

In at least one `feature` or `mega` scenario, the agent must demonstrate restart-from-plan discipline by updating the live plan with status, discoveries, next steps, and a handoff note that a fresh agent can follow.

### Review acceptance

Every tier must show self-review. For non-trivial tiers, review findings should be classified as blocker, watchout, or nice-to-have.

### Progressive disclosure acceptance

The skill should not duplicate large guidance blocks across `SKILL.md` and references. The body should route to references rather than copying them.

## Idempotence and Recovery

Directory creation uses `mkdir -p` and is safe to repeat. Rewriting markdown files is safe if each rewrite keeps the contract aligned across `SKILL.md`, the references, and the templates.

If validation fails because of packaging issues, fix `SKILL.md` frontmatter, `README.md`, or the directory name first; do not begin by rewriting the references.

If auto-loading is poor, fix the frontmatter `description` before making the body larger. Trigger quality lives primarily in the description.

If tier choice is consistently wrong, fix `references/mode-selection.md` first. If the chosen tier is right but the behavior inside the tier is wrong, fix the relevant reference file or template. If the skill keeps asking noisy questions, fix `alignment-and-gates.md`. If it creates inconsistent plans, fix `live-plan.md` and the templates.

If implementation context becomes crowded while building this skill, use this plan as the handoff document: update Progress, Decisions, and Next Steps here, then continue in a fresh agent.

## Artifacts and Notes

### Recommended file size budget

To keep context efficient, target roughly:

- `SKILL.md`: 120–180 lines
- `mode-selection.md`: 120–160 lines
- `live-plan.md`: 100–140 lines
- `research-and-subagents.md`: 100–140 lines
- `alignment-and-gates.md`: 90–130 lines
- `examples.md`: 150–220 lines
- `live-plan-template.md`: 60–90 lines
- `mega-plan-template.md`: 80–110 lines

These are guides, not hard limits. The principle is more important than the exact numbers: keep the router compact and move detail outward.

### The one-page behavior summary the skill should imply

When the agent receives a task, it should first frame it briefly, then choose the lightest planning tier that still removes blind spots and defines observable validation. It should ask questions only when the answers materially change the plan. It should create a live plan file only when the selected tier justifies one. It should pause for approval before coding in `guided` and above. It should use subagents when they lower uncertainty or reduce context pressure enough to be worth the cost. It should update the live plan as a living source of truth and hand off through files when context gets crowded.

### v1.1 backlog, only after core stability

Possible future additions after v1 is stable:

- optional meta overlay as a documented advanced pattern;
- optional reusable JSON templates for `interview` forms;
- optional package publishing under a `skills/` directory or `package.json` Pi manifest;
- optional stronger model-specific “oracle” guidance;
- optional extension-based enforcement if real-world usage shows that soft pauses are ignored too often.

## Interfaces and Dependencies

The skill depends on Pi’s skill format and discovery rules. The public package interface is the directory `adaptive-planning/` containing `SKILL.md`. The skill name must be `adaptive-planning` and the directory name must match. The frontmatter description must be specific enough to trigger on planning-related tasks.

The skill relies on these Pi tools and existing built-in subagents:

- `read`, `write`, `edit`, `bash` for normal coding-agent work and plan-file maintenance.
- `interview` for structured approval and batched user questions.
- `subagent` with `scout` for reconnaissance.
- `subagent` with `researcher` for focused external research.
- `subagent` with `planner` or `worker` for second-opinion planning or critique.
- `subagent` with `reviewer` for post-implementation review.

The stable file-level interface at the end of implementation should be:

- `adaptive-planning/SKILL.md`
  - frontmatter name/description
  - universal contract
  - five-tier summary
  - reference-loading instructions
  - self-review and reset guidance

- `adaptive-planning/README.md`
  - summary
  - installation
  - tier overview
  - usage examples

- `adaptive-planning/references/mode-selection.md`
  - tier rubric
  - escalation / de-escalation
  - anti-patterns
  - tier override guidance

- `adaptive-planning/references/live-plan.md`
  - plan format
  - lifecycle
  - naming conventions
  - update rules
  - handoff rules

- `adaptive-planning/references/research-and-subagents.md`
  - scout/research/second-opinion/reviewer/council patterns
  - cost-awareness
  - reset protocol

- `adaptive-planning/references/alignment-and-gates.md`
  - question budgets
  - approval rules
  - interview/fallback patterns
  - review gates
  - blocker remediation
  - backpressure

- `adaptive-planning/references/examples.md`
  - worked examples and anti-examples

- `adaptive-planning/assets/templates/live-plan-template.md`
  - copyable plan skeleton

- `adaptive-planning/assets/templates/mega-plan-template.md`
  - copyable decomposition skeleton

Revision note (2026-03-08): This file is the final integrated plan produced after comparing five candidate plans and validating key assumptions against Pi docs, skill-creator guidance, the local validator, and the ExecPlan methodology. It deliberately combines the strongest Pi-native implementation details with the best conceptual controls from the broader plan set.