# Build the `adaptive-planning` Pi skill — optimal agent planning across five complexity tiers

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

Maintained in accordance with `execplan/references/PLANS.md` (`/home/bot/projects/pi-skills-with-self-analysis/execplan/references/PLANS.md`).


## Purpose / Big Picture

After this work is complete, a Pi agent equipped with the `adaptive-planning` skill will know how to plan before it acts — and how much planning is appropriate. Instead of treating every request the same way (either over-planning trivial changes or under-planning complex features), the agent will classify each task into one of five tiers and follow a protocol tuned for that tier. The five tiers are:

1. **quickstrike** — think briefly, eliminate blind spots, execute immediately, self-review at the end. No plan file, no human-in-the-loop (HITL).
2. **guided** — write a saved plan file, include self-review in the plan itself, pause for HITL before execution. No questions asked during planning — the agent makes reasonable assumptions and records them.
3. **research** — like guided, but preceded by targeted research and a limited number of high-impact questions to the user. One main plan file, HITL before execution.
4. **feature** — for complex features. More research, more questions, deeper blind spot coverage, validation/backpressure checkpoints. Possibly supporting notes alongside the main plan, but one plan file remains the source of truth. HITL before execution.
5. **mega** — for large initiatives. First, a top-level decomposition plan that breaks work into feature-sized milestones. Each milestone is then solved using the feature protocol. The mega plan is the routing document for the whole effort.

The user-visible effect: the agent consistently produces better outcomes because it (a) prevents blind spots before they become bugs, (b) saves a living plan file where justified so the user can review and redirect, (c) asks only genuinely necessary questions, (d) leverages subagents for research, review, and second opinions when justified, (e) performs self-review, and (f) manages its own context by handing off to fresh subagents when the current context is crowded.

To verify this works, run five test scenarios (one per tier) and confirm: the agent picks the right tier, produces the expected artifacts (or intentionally produces none), pauses for HITL at the right moment (or doesn't), and performs self-review.


## Progress

- [x] (2026-03-08 18:12 UTC+8) Read PLANS.md methodology, Pi skills docs, skill-creator docs, and the prior `pi-execplan-5.4` plan.
- [x] (2026-03-08 18:30 UTC+8) Analyzed weaknesses of the prior plan (see Surprises & Discoveries).
- [x] (2026-03-08 18:45 UTC+8) Drafted and saved this ExecPlan.
- [ ] Milestone 1: Create skill skeleton — directory structure, SKILL.md frontmatter+body, README.md.
- [ ] Milestone 2: Write all reference files — mode-selection rubric, live-plan format, research/subagent protocol, question protocol, examples.
- [ ] Milestone 3: Write template assets — live-plan-template.md, mega-plan-template.md.
- [ ] Milestone 4: Validate and test — syntax validation, five behavioral scenarios, iterative fixes.
- [ ] Final: Retrospective and handoff.


## Surprises & Discoveries

- Observation: A prior ExecPlan exists at `plan/pi-execplan-5.4/execplan/adaptive-planning-skill.md` but it has notable gaps: the "how to choose a tier" rubric is vague, the live plan format is described in general terms but never concretely specified, the self-review protocol is mentioned but not defined, and there is no discussion of how the agent should actually interact with subagents or manage context resets mechanically.
  Evidence: Reading the full prior plan — mode descriptions are 1-2 sentences each, no escalation/de-escalation criteria, no examples of what a self-review looks like, no handoff protocol.

- Observation: The skill must work purely through instructions and existing tools (read, write, edit, bash, subagent, interview). There is no extension API, no hooks, no policy enforcement. This means the skill cannot force the agent to stop — it can only strongly instruct it to pause and present the plan for approval.
  Evidence: `extending-pi/SKILL.md` decision tree recommends skills when bash + instructions suffice.

- Observation: Pi's `interview` tool is ideal for structured HITL moments — presenting the plan for review, asking mode-selection confirmation, or gathering targeted questions — rather than relying on free-form chat.
  Evidence: Tool description shows `interview` supports single/multi/text/info question types with recommendations, code blocks, and media.

- Observation: The `subagent` tool already supports single tasks, chains, and parallel execution — exactly what's needed for research, reviewer passes, and council patterns without building custom infrastructure.
  Evidence: Tool documentation shows `{ agent, task }`, `{ chain: [...] }`, `{ tasks: [...] }` modes, plus built-in agent management.

- Observation: The concept of "context reset by handoff" is critical for long-running feature/mega plans but cannot rely on measuring actual token usage. The practical approach is: when the plan file has become large and the agent has already done significant research, persist everything to files and spawn a fresh subagent that reads only what it needs.
  Evidence: Skills have no API to query context window fill level. File-based handoff is the only reliable mechanism.


## Decision Log

- Decision: Create one unified skill `adaptive-planning` with five tiers, not five separate skills.
  Rationale: All tiers share the same core protocol (classify → plan → validate → execute). Separating them would cause trigger ambiguity (which skill fires?) and duplicate shared logic. One skill with clear internal routing is simpler for discovery and maintenance.
  Date/Author: 2026-03-08 / pi

- Decision: Stay within skill boundaries (no extension).
  Rationale: The core value is cognitive — teaching the agent when and how to plan. All needed tools (read, write, edit, bash, subagent, interview) already exist. An extension would only add value for hard enforcement (forced HITL gates, context budget tracking), which can be a v2 follow-up if instructions prove insufficient.
  Date/Author: 2026-03-08 / pi

- Decision: Use the `interview` tool for structured HITL moments instead of free-form chat.
  Rationale: interview provides structured forms with options, recommendations, code blocks, and info panels. This is far better for presenting a plan summary and asking "approve / request changes / escalate tier" than hoping the user reads a wall of text. It also naturally handles the "no questions in guided mode" constraint — simply don't invoke interview during planning for that tier.
  Date/Author: 2026-03-08 / pi

- Decision: Name the five tiers `quickstrike`, `guided`, `research`, `feature`, `mega`.
  Rationale: These names map directly to the user's requirements. They are short, memorable, and ordered by increasing complexity. The naming also avoids confusion with generic terms like "simple" or "complex".
  Date/Author: 2026-03-08 / pi

- Decision: Self-review is mandatory in every tier, but its placement and depth varies.
  Rationale: The user explicitly wants self-review even for quickstrike. For quickstrike, it's a brief post-execution check. For guided+, it's embedded in the plan file itself (pre-execution review of the plan) plus a post-execution check. This creates backpressure at two points.
  Date/Author: 2026-03-08 / pi

- Decision: Subagent-based second opinion (supervisor/council/oracle) is optional, triggered by uncertainty level, not mandatory.
  Rationale: Mandatory second opinion for every task would be wasteful for quickstrike/guided. The skill should describe when it's worthwhile (high-risk architecture decisions, unfamiliar domains, conflicting constraints) and how to invoke it (single reviewer, parallel council, or oracle query), but leave the agent to decide based on context.
  Date/Author: 2026-03-08 / pi

- Decision: For context reset, use file-based handoff: update plan file → write handoff summary → spawn fresh subagent.
  Rationale: No reliable way to measure actual context usage from a skill. The trigger should be heuristic: if the agent has done extensive research, the plan file is large, or reasoning is getting circular, it should hand off. The plan file is the single source of truth that survives the reset.
  Date/Author: 2026-03-08 / pi

- Decision: The live plan format is inspired by OpenAI's ExecPlan style but adapted: it must include purpose, assumptions, blind spots addressed, action log with timestamps, decision log, surprises, validation criteria, and a handoff note.
  Rationale: The user explicitly prefers a live plan that "reflects changes and reasons, reflects surprises, action log." This aligns with PLANS.md philosophy. The handoff note is added for context reset scenarios.
  Date/Author: 2026-03-08 / pi

- Decision: RPD (rapid problem definition) is built into every tier as the first micro-step, not a separate phase.
  Rationale: Even quickstrike benefits from a 2-sentence problem restatement that clarifies scope, constraints, and definition of done. Making it a distinct named phase would over-formalize it for simple cases. Instead, it's the opening move of every tier's protocol.
  Date/Author: 2026-03-08 / pi

- Decision: mega tier creates child plan files only when a milestone actually starts, not all upfront.
  Rationale: Pre-creating all child plans leads to stale documents. The mega plan defines milestones, dependencies, and exit criteria. When a milestone begins, the agent creates its child plan using the feature protocol. This keeps documents alive and relevant.
  Date/Author: 2026-03-08 / pi


## Outcomes & Retrospective

Initial outcome: a concrete, self-contained plan exists for building the adaptive-planning skill. The main lesson from reviewing the prior iteration is that the skill's value depends on the specificity of its reference files — vague mode descriptions produce vague behavior. This plan prioritizes detailed rubrics, concrete examples, and explicit protocols over abstract principles.


## Context and Orientation

The working directory is `/home/bot/projects/pi-skills-with-self-analysis/plan/pi-execplan-opus/`. This is an empty sandbox inside the git repository `/home/bot/projects/pi-skills-with-self-analysis/`. All new files will be created here.

A Pi skill is a directory containing a mandatory `SKILL.md` file. Pi discovers skills by scanning known locations (`~/.pi/agent/skills/`, `.pi/skills/`, settings, CLI flags). The `description` field in the SKILL.md frontmatter is what Pi uses to decide whether to auto-load the skill for a given request — the body is read only after the skill is triggered. This means the description must be precise enough to trigger on planning-related requests but not so broad that it fires on every coding task.

Key files and their roles in the skill we are building:

    adaptive-planning/
    ├── SKILL.md                              # Core orchestrator: classify → route → protocol
    ├── README.md                             # Human-facing: what, why, install, examples
    ├── references/
    │   ├── mode-selection.md                 # Detailed rubric for choosing a tier
    │   ├── live-plan.md                      # Canonical live plan format and lifecycle
    │   ├── research-and-subagents.md         # When/how to use subagents, council, handoff
    │   ├── questions-and-alignment.md        # When to ask, when to assume, how to phrase
    │   └── examples.md                       # One worked example per tier
    └── assets/
        └── templates/
            ├── live-plan-template.md         # Copyable skeleton for guided/research/feature
            └── mega-plan-template.md         # Copyable skeleton for mega decomposition

Key terms used throughout this skill:

"Blind spot" — an aspect of a task that is easy to forget but causes real problems: migrations, backward compatibility, observability, rollback, tests, docs, permissions, performance, UX side effects, error handling, security, rate limits.

"Validation" — checking that the implementation produces observable, correct behavior (not just "it compiles"). Defined before implementation, verified after.

"Backpressure" — mandatory pause points where the agent stops or lowers confidence if it lacks sufficient context, has no acceptance criteria, or faces high risk of error. Backpressure prevents the agent from plowing ahead on shaky ground.

"RPD" (rapid problem definition) — a brief restatement of the task that clarifies: what is being asked, what constraints exist, what the environment looks like, and what "done" means. Every tier starts with RPD, but its depth varies.

"HITL" (human-in-the-loop) — a deliberate pause where the agent presents its plan to the user for review before proceeding to implementation. The user can approve, request changes, or escalate to a higher tier.

"Self-review" — the agent re-reads its own plan or implementation with fresh eyes and checks: did I address all blind spots? Does validation cover the acceptance criteria? Are there assumptions I didn't record? Is anything missing? For quickstrike this is a brief post-execution check; for other tiers it's embedded in the plan and repeated after execution.

"Context reset" — when the agent's working context has grown large (extensive research, long plans, many files read), it persists everything to files and spawns a fresh subagent that reads only what's needed to continue. The plan file is the survival document.

"Council" — running multiple subagents in parallel on the same question and synthesizing their answers. Useful when facing architectural decisions with no clear winner.

"Oracle" — a single subagent with a different model or specialized prompt that reviews the plan for weaknesses. Lighter than a council, useful for catching blind spots in the plan itself.


## Plan of Work

The work is organized into four milestones. Each milestone is independently verifiable and builds on the previous one.


### Milestone 1: Skill Skeleton

Create the directory structure, SKILL.md with frontmatter and body, and README.md. After this milestone, the skill can be loaded by Pi (even if reference files are empty stubs) and the agent can see the tier selection logic.

The SKILL.md body must be concise (under 200 lines) and serve as an orchestrator, not an encyclopedia. It must:

1. Open with a brief explanation of the skill's purpose: the agent should plan proportionally to task complexity.
2. Define the universal protocol that applies to all tiers:
   - Start with RPD: restate the task, constraints, environment, and definition of done.
   - Identify blind spots relevant to this task.
   - Define validation criteria before writing any code.
   - Apply backpressure: if you lack context or clarity, pause and gather it before proceeding.
3. List the five tiers with a 2-3 sentence summary each, just enough for the agent to understand the shape of each tier. The full rubric lives in `references/mode-selection.md`.
4. For each tier, state clearly:
   - Whether a plan file is created (no for quickstrike; yes for all others).
   - Whether HITL is required (no for quickstrike; yes for all others).
   - Whether questions to the user are allowed during planning (no for quickstrike and guided; limited for research; yes for feature and mega).
   - Whether research is expected (no for quickstrike and guided; yes for research, feature, mega).
   - Whether subagents should be considered (optional for research and feature; recommended for mega).
   - When self-review happens (post-execution for quickstrike; in-plan + post-execution for others).
5. Tell the agent when to read each reference file:
   - Read `mode-selection.md` if unsure which tier to pick or when escalating/de-escalating.
   - Read `live-plan.md` before creating any plan file.
   - Read `research-and-subagents.md` when planning to do research, invoke a reviewer, run a council, or hand off context.
   - Read `questions-and-alignment.md` when deciding what to ask the user.
   - Read `examples.md` when unsure how a tier should look in practice.
6. Define the self-review protocol: what the agent checks, when, and how it reports findings.
7. Define the context reset protocol: when to trigger, what to persist, how to spawn fresh subagent.

The README.md should be human-facing: what this skill does, how to install it, the five tiers at a glance, and a note that this is v1 (skill-only, no extension enforcement).


### Milestone 2: Reference Files

Write the five reference files. These are the real substance of the skill — the detailed playbooks that the agent reads on demand.

**mode-selection.md** must contain:

A prose-first rubric for tier selection. The agent should evaluate these dimensions:
- Scope: how many files, modules, or systems are touched?
- Unknowns: does the agent already know how to do this, or does it need to learn?
- Risk: what's the blast radius of getting it wrong? Is rollback easy?
- Integration surface: does this touch APIs, databases, external services, or just internal code?
- User alignment: is the request clear enough to proceed, or are there ambiguities that would change the approach?
- Validation complexity: can correctness be checked with a quick test, or does it need multi-step verification?

For each dimension, provide rough thresholds that map to tiers. Then provide escalation rules (when to bump up a tier) and de-escalation rules (when to simplify). Include anti-patterns: "don't use mega for a task that's just big but not complex", "don't use quickstrike if you've never worked in this codebase before."

**live-plan.md** must contain:

The canonical format of a live plan file. This format is used by guided, research, feature, and mega tiers (with mega having additional sections). The plan file is always saved to `execplan/<slug>.md` relative to the project root. The format:

    # <Task title>

    Status: planning | awaiting-review | approved | in-progress | blocked | done
    Tier: guided | research | feature | mega
    Created: <timestamp>
    Last updated: <timestamp>

    ## Purpose
    What this change enables and how to verify it works.

    ## RPD (Rapid Problem Definition)
    Task restatement, constraints, environment, definition of done.

    ## Assumptions & Constraints
    What the agent assumed without asking. Each assumption should note what would change if it's wrong.

    ## Blind Spots Addressed
    Which blind spots were considered and how they're handled. Format: blind spot → mitigation.

    ## Approach
    The chosen solution strategy, in prose. Why this approach over alternatives.

    ## Validation & Acceptance
    How to verify the implementation is correct. Specific commands, expected outputs, behavioral checks.

    ## Action Log
    Timestamped log of what was done, in chronological order. Updated during execution.

    ## Decision Log
    Decisions made during planning/execution, with rationale.

    ## Surprises & Discoveries
    Unexpected findings during research or implementation.

    ## Self-Review
    Pre-execution: does the plan cover all blind spots? Is validation sufficient?
    Post-execution: does the implementation match the plan? Any drift?

    ## Next Steps
    What remains to be done. Updated continuously.

    ## Handoff Note
    If context reset is needed: what a fresh agent needs to know to continue.

The file must also explain the lifecycle: the plan starts at "planning" status, moves to "awaiting-review" when the agent presents it for HITL, becomes "approved" after user approval, "in-progress" during execution, and "done" when validation passes. The agent must update the plan file after every significant action.

**research-and-subagents.md** must contain:

When to do research: if the agent doesn't know the answer to a design question, if there are multiple viable approaches with non-obvious tradeoffs, if external libraries/APIs are involved, or if the domain is unfamiliar.

How to do research: use `bash` to read docs, explore codebases, run experiments. Use `subagent` with a dedicated research task for deep dives that would crowd the main context.

Three subagent strategies:

1. Single reviewer pass — after creating a plan, spawn a subagent with the task "Review this plan for blind spots, missing validation, unclear assumptions, and risks. Be critical." The reviewer reads only the plan file (and optionally key source files). Its output is appended to the plan's Decision Log as "Reviewer feedback." This is the lightest second opinion.

2. Parallel council — for high-stakes architectural decisions, spawn 2-3 subagents in parallel (using `{ tasks: [...] }`) with slightly different prompts: one optimizing for simplicity, one for robustness, one for performance. Compare their recommendations and pick the best synthesis. Record the council's output in the Decision Log.

3. Oracle query — spawn a single subagent with a different model (using `model` override) to review the plan or a specific decision. Useful when the main agent suspects its own reasoning might be biased.

Context reset protocol: when the current context has grown large (agent has read many files, done extensive research, the plan is detailed), the agent should:
1. Update the plan file with everything learned so far.
2. Write a handoff note in the plan: what's done, what's next, what files to read.
3. Spawn a fresh subagent with a task like "Continue implementing the plan at execplan/<slug>.md. Read the plan first, then proceed from the Next Steps section."

The trigger for context reset is heuristic: if the agent notices it's forgetting earlier context, if reasoning is becoming circular, or if it has read 15+ files and hasn't started implementing yet.

**questions-and-alignment.md** must contain:

The fundamental rule: ask a question only if the answer would materially change scope, architecture, risk, timeline, external dependencies, or acceptance criteria. If the answer wouldn't change the approach, make a reasonable assumption and record it.

Tier-specific question protocols:

- quickstrike: no questions. Make assumptions, execute, self-review.
- guided: no questions during planning. Record all assumptions in the plan. The user will see them during HITL and can correct.
- research: up to 3 targeted questions allowed, asked upfront before research begins. These should resolve the biggest unknowns. Use the `interview` tool to present them as structured questions with recommended answers.
- feature: questions allowed both upfront and during research. Batch them — don't ask one at a time. Use `interview` for structured multi-question forms. Typical feature questions: scope boundaries, integration preferences, rollout strategy, testing expectations.
- mega: more strategic questions early on (decomposition strategy, priority order, constraints across milestones) plus per-milestone questions as each one starts.

Anti-patterns: asking "should I use X or Y?" when both are equivalent, asking about implementation details the user doesn't care about, asking the same question in different words, asking questions whose answers are in the codebase.

How to phrase questions: provide context, state what you think the answer is and why, then ask for confirmation or correction. This respects the user's time by giving them something to react to rather than starting from zero.

**examples.md** must contain:

One worked example per tier. Each example shows: the user's request, the tier selected, why that tier was chosen, what the agent does step by step, what artifacts are produced, and where HITL/self-review/subagents happen.

Example prompts and expected tier classification:

- "Rename the `UserService` class to `AccountService` and update all imports" → quickstrike. Reasoning: mechanical change, no unknowns, easy to validate, easy to rollback. Agent: RPD (1 sentence) → blind spots (check for string references, test fixtures, docs) → execute → self-review (grep for leftover references).

- "Add a --verbose flag to the CLI that enables debug logging" → guided. Reasoning: small feature, some design choices (flag parsing, log level), but no unknowns. Agent: RPD → blind spots (existing flags, help text, test coverage) → write plan file → self-review plan → present for HITL → execute → post-execution self-review.

- "Integrate GitHub OAuth login into our Express app" → research. Reasoning: external API, library choices, security considerations, callback flow. Agent: RPD → 2-3 targeted questions (which OAuth libraries are acceptable? Is there an existing auth middleware?) → research OAuth flow and libraries → write plan file → self-review plan → present for HITL → execute.

- "Build a billing system with Stripe integration, subscription management, usage tracking, and invoice generation" → feature. Reasoning: large scope, external API, database changes, webhook handling, security, testing complexity. Agent: RPD → structured questions about scope, existing models, Stripe account setup → deep research → write detailed plan with blind spots for idempotency, webhook replay, currency handling, PCI compliance → reviewer subagent pass → present for HITL → execute in stages → post-execution self-review.

- "Migrate our monolithic Django app to a microservices architecture with separate auth, billing, and content services" → mega. Reasoning: multi-month initiative, architectural decisions, data migration, service boundaries, deployment strategy. Agent: RPD → strategic questions → research → write mega plan with 4-5 milestones → council subagent for architecture review → present mega plan for HITL → per-milestone child plans using feature protocol.


### Milestone 3: Template Assets

Create two copyable templates that the agent uses when creating plan files.

**live-plan-template.md** should contain the full skeleton from the format defined in live-plan.md, with placeholders like `<describe what this change enables>`, `<list assumptions>`, etc. The agent copies this template and fills it in. This ensures consistency across plans and prevents the agent from inventing a new structure each time.

**mega-plan-template.md** extends the live plan template with additional sections:

    ## Decomposition
    How this initiative breaks into milestones. For each milestone:
    - Name and scope
    - Dependencies on other milestones
    - Exit criteria (what must be true before this milestone is "done")
    - Estimated tier (usually feature, but some may be research or guided)

    ## Milestone Map
    Ordered list of milestones with dependencies shown.

    ## Cross-Cutting Concerns
    Issues that span multiple milestones: shared data models, API contracts, deployment pipeline, testing strategy.

    ## Per-Milestone Plans
    Links to child plan files as they are created. Format: `execplan/<mega-slug>-m<N>-<name>.md`


### Milestone 4: Validation and Testing

Validate the skill syntactically and behaviorally.

Syntactic validation: run the skill validator from the parent repo. The skill must pass with "Skill is valid!" and no errors.

Behavioral validation: load the skill in Pi in isolation and run five test scenarios, one per tier. For each scenario, check:
1. The agent selects the expected tier.
2. For quickstrike: no plan file is created, execution happens immediately, self-review appears at the end.
3. For guided: a plan file appears in execplan/, no questions are asked during planning, the plan contains assumptions and self-review sections, the agent pauses for HITL.
4. For research: targeted questions are asked upfront (via interview), research is done, a plan file is created, HITL before execution.
5. For feature: broader questions, deeper research, plan covers blind spots comprehensively, reviewer subagent is considered, HITL before execution.
6. For mega: a top-level mega plan is created with milestone decomposition, strategic questions are asked, the agent does not try to implement everything at once.

After each test, fix any issues in the skill files and re-test. The goal is stable correct behavior across all five scenarios.


## Concrete Steps

1. Working directory:

       cd /home/bot/projects/pi-skills-with-self-analysis/plan/pi-execplan-opus

2. Create directory structure:

       mkdir -p adaptive-planning/references adaptive-planning/assets/templates execplan

   Verify:

       find . -type d | sort

   Expected output should include `./adaptive-planning/references`, `./adaptive-planning/assets/templates`, `./execplan`.

3. Create `adaptive-planning/README.md` with:
   - Title: Adaptive Planning Skill for Pi
   - One-paragraph summary: what the skill does
   - Installation: `pi install git:github.com/<org>/adaptive-planning` (or local path)
   - Five tiers at a glance (table with: tier name, plan file?, HITL?, questions?, research?, subagents?)
   - Note: v1 is skill-only, no extension enforcement

4. Create `adaptive-planning/SKILL.md` with frontmatter:

       ---
       name: adaptive-planning
       description: Adaptive planning for coding tasks. Use when deciding how much planning a task needs, choosing between immediate execution or a saved plan, structuring research, asking clarifying questions, using subagents for review or research, creating live plans with validation, or decomposing large initiatives into milestones.
       ---

   Body: the orchestrator instructions as described in Milestone 1 (under 200 lines of prose).

5. Create reference files as described in Milestone 2:

       adaptive-planning/references/mode-selection.md
       adaptive-planning/references/live-plan.md
       adaptive-planning/references/research-and-subagents.md
       adaptive-planning/references/questions-and-alignment.md
       adaptive-planning/references/examples.md

6. Create template assets as described in Milestone 3:

       adaptive-planning/assets/templates/live-plan-template.md
       adaptive-planning/assets/templates/mega-plan-template.md

7. Validate skill syntax:

       python /home/bot/projects/pi-skills-with-self-analysis/extending-pi/skill-creator/scripts/validate_skill.py ./adaptive-planning

   Expected: `Skill is valid!`

8. Test skill loading in Pi:

       pi --no-skills --skill ./adaptive-planning

   Inside Pi, verify with `/skill:adaptive-planning` that the skill is loaded.

9. Run five behavioral scenarios (one per tier):

       "Rename the Logger class to AppLogger and update all references"        → expect quickstrike
       "Add a --dry-run flag to the deploy script"                             → expect guided
       "Add OAuth2 authentication with Google as the provider"                 → expect research
       "Build a notification system with email, SMS, and push channels"        → expect feature
       "Refactor the app from a monolith into separate API, worker, and UI services" → expect mega

10. After each scenario, verify the checklist from Milestone 4. Fix and re-test until stable.

11. Update this ExecPlan with results and write the Outcomes & Retrospective.


## Validation and Acceptance

Acceptance is behavioral, not just structural.

Structural acceptance: all files in the target tree exist, SKILL.md has valid frontmatter, the skill validator passes.

Behavioral acceptance for quickstrike: the agent restates the task in one sentence, lists 2-3 blind spots, executes immediately without creating a plan file, and ends with a brief self-review paragraph.

Behavioral acceptance for guided: the agent creates `execplan/<slug>.md`, the plan contains Purpose, RPD, Assumptions, Blind Spots, Approach, Validation, Self-Review sections. No questions are asked during planning. The agent presents the plan (ideally via `interview` tool showing a summary with approve/revise options) and waits.

Behavioral acceptance for research: the agent asks 1-3 targeted questions via `interview` before researching. After research, a plan file is created with the same sections as guided plus research findings. HITL before execution.

Behavioral acceptance for feature: broader discovery, more blind spots covered (integration, rollback, observability, security, performance), reviewer subagent is at least considered (skill should prompt toward it). Plan is comprehensive. HITL before execution.

Behavioral acceptance for mega: a top-level plan exists with a Decomposition section listing 3+ milestones with dependencies and exit criteria. The agent does not try to implement all milestones at once. Strategic questions are asked upfront.

Acceptance for subagent usage: in at least one feature/mega scenario, the agent uses the `subagent` tool for research or review, and the result is reflected in the plan's Decision Log.

Acceptance for self-review: in every tier, a self-review is visible — either as a section in the plan file or as explicit output after execution.


## Idempotence and Recovery

All directory creation uses `mkdir -p` — safe to repeat. All file creation uses the `write` tool which overwrites — safe to repeat with updated content.

If the skill validator fails: fix frontmatter (name must match directory, description must be present), ensure README.md exists with an Installation section, re-run validator.

If a behavioral scenario picks the wrong tier: first check `mode-selection.md` rubric — are the thresholds clear enough? Then check `SKILL.md` body — does it tell the agent to read mode-selection.md? Then check the description — is it triggering for this type of request?

If the agent asks questions when it shouldn't (e.g., in guided mode): check `questions-and-alignment.md` — is the "no questions for guided" rule clear? Check `SKILL.md` — does it link to that reference for question behavior?

If the agent creates a plan file when it shouldn't (quickstrike): check `SKILL.md` — is the quickstrike protocol clear that no file is needed?

If context grows too large during implementation of this plan: save this ExecPlan file (it's the source of truth), write a handoff note here in the Progress section, and continue in a fresh agent that reads only this file.


## Artifacts and Notes

Expected final tree:

    pi-execplan-opus/
    ├── execplan/
    │   └── adaptive-planning-skill.md          # This living plan
    └── adaptive-planning/
        ├── SKILL.md                            # ~150-200 lines, orchestrator
        ├── README.md                           # Human-facing, ~50 lines
        ├── references/
        │   ├── mode-selection.md               # ~150 lines, tier rubric
        │   ├── live-plan.md                    # ~100 lines, plan format + lifecycle
        │   ├── research-and-subagents.md       # ~120 lines, three strategies + handoff
        │   ├── questions-and-alignment.md      # ~80 lines, per-tier question rules
        │   └── examples.md                     # ~200 lines, one example per tier
        └── assets/
            └── templates/
                ├── live-plan-template.md       # ~60 lines, copyable skeleton
                └── mega-plan-template.md       # ~80 lines, extended skeleton

Key design insight: SKILL.md is the router, references are the playbooks, templates are the scaffolds. The agent reads SKILL.md always, reads a reference only when it needs the detail, and copies a template only when creating a plan file. This three-layer design keeps context lean while making deep knowledge available on demand.

Example fragment of what SKILL.md body should convey (not exact text, but the spirit):

    When you receive a task, before writing any code, classify it into one of five planning
    tiers: quickstrike, guided, research, feature, or mega. Choose the lightest tier that
    still eliminates blind spots and ensures validation. If unsure, read
    references/mode-selection.md for the full rubric.

    Universal invariants across all tiers:
    - Start with RPD: restate the task, constraints, and definition of done.
    - Identify blind spots before they become bugs.
    - Define validation before execution.
    - Apply backpressure: stop if you lack context or clarity.
    - Self-review your work.

    For tiers that require a plan file (guided, research, feature, mega), read
    references/live-plan.md and copy assets/templates/live-plan-template.md to
    execplan/<slug>.md. Keep the plan file updated as work proceeds.


## Interfaces and Dependencies

The skill depends on Pi's skill discovery mechanism (documented at `/home/bot/.local/share/pnpm/global/5/.pnpm/@mariozechner+pi-coding-agent@0.57.1_ws@8.19.0_zod@3.25.76/node_modules/@mariozechner/pi-coding-agent/docs/skills.md`). The key contract: SKILL.md must have `name` and `description` in frontmatter, directory name must equal `name`, and `description` controls auto-activation.

The skill relies on these existing Pi tools (no new tools needed):
- `read` — for reading source files during research
- `write` — for creating plan files and skill artifacts
- `edit` — for updating plan files
- `bash` — for running commands, tests, exploration
- `subagent` — for research, reviewer, council, oracle, and context-reset handoffs
- `interview` — for structured HITL moments (plan approval, targeted questions)

The local skill validator at `/home/bot/projects/pi-skills-with-self-analysis/extending-pi/skill-creator/scripts/validate_skill.py` is used for syntax validation. It checks frontmatter fields and README.md structure.

No npm dependencies. No extension API. No custom tools. The skill is pure Markdown instructions with reference files.

The public interface of the skill consists of:

    adaptive-planning/SKILL.md:
      frontmatter.name = "adaptive-planning"
      frontmatter.description = <trigger description covering planning, research, subagents, decomposition>

      Body instructs the agent to:
        1. RPD — restate the task
        2. Classify into tier (quickstrike | guided | research | feature | mega)
        3. Follow tier-specific protocol
        4. Eliminate blind spots
        5. Define validation
        6. Apply backpressure
        7. Ask questions only when justified (per tier rules)
        8. Use research/subagents when justified
        9. Create plan file (if not quickstrike)
        10. Self-review
        11. HITL (if not quickstrike)
        12. Execute
        13. Post-execution self-review

    adaptive-planning/references/mode-selection.md:
      Tier selection rubric with six dimensions:
        scope, unknowns, risk, integration surface, user alignment, validation complexity
      Escalation/de-escalation rules
      Anti-patterns

    adaptive-planning/references/live-plan.md:
      Plan file format with sections:
        Purpose, RPD, Assumptions, Blind Spots, Approach, Validation,
        Action Log, Decision Log, Surprises, Self-Review, Next Steps, Handoff Note
      Plan lifecycle: planning → awaiting-review → approved → in-progress → done

    adaptive-planning/references/research-and-subagents.md:
      Three strategies: single reviewer, parallel council, oracle query
      Context reset protocol: update plan → handoff note → fresh subagent

    adaptive-planning/references/questions-and-alignment.md:
      Per-tier question budgets:
        quickstrike: 0, guided: 0, research: 1-3, feature: unbounded, mega: strategic
      Question quality rules and anti-patterns

    adaptive-planning/references/examples.md:
      Five worked examples, one per tier

    adaptive-planning/assets/templates/live-plan-template.md:
      Copyable skeleton matching the live-plan.md format

    adaptive-planning/assets/templates/mega-plan-template.md:
      Extended skeleton with Decomposition, Milestone Map, Cross-Cutting Concerns

---

Revision note (2026-03-08): Initial ExecPlan created. This is a fresh plan in the `pi-execplan-opus` sandbox, informed by reading the prior `pi-execplan-5.4` plan and its gaps. Key improvements over the prior iteration: (1) concrete live plan format specified in full, not just described in general terms; (2) explicit self-review protocol defined; (3) interview tool integrated for structured HITL; (4) subagent strategies detailed with three named patterns; (5) per-tier question budgets specified numerically; (6) anti-patterns included in mode selection; (7) context reset protocol fully described; (8) RPD embedded as first step of every tier; (9) mega tier's child plan creation explicitly deferred to milestone start, not upfront.
