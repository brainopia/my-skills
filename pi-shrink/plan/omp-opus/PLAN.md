# Plan: `smart-plan` Skill for Optimal Agent Planning

## Summary

Create a skill named `smart-plan` that teaches the agent how to classify task complexity and apply the appropriate planning strategy — from a quick blind-spot pass with immediate execution, up to a mega-plan that decomposes a large problem into coordinated milestones. The skill is pure instructional Markdown (a `SKILL.md` file) injected into the agent's system prompt as context; it requires no code, no extensions, no custom tools. It operates entirely on top of OMP's existing plan mode, task agents, and tool set.

---

## Context: Key Findings

### What skills are in OMP
- A skill is a directory `<skills-root>/<skill-name>/SKILL.md` with `name` + `description` frontmatter.
- At runtime, skill body is available to the agent via `read skill://<name>`.
- The agent reads skills on demand; skill content is instructional, not executable.
- Placement: `~/.omp/skills/smart-plan/SKILL.md` (user-level) or `.omp/skills/smart-plan/SKILL.md` (project-level).

### What plan mode already provides
- `exit_plan_mode { title }` — agent calls this when plan is ready; triggers HITL dialog.
- HITL dialog has three options: **Approve and execute**, **Refine plan**, **Stay in plan mode**.
- After approval: plan file renamed to `local://<title>.md`, new session started with full tool access, plan content injected as context.
- Two built-in workflow variants: `parallel` (default) and `iterative`.
- `local://PLAN.md` is the canonical plan scratch file during planning.
- `plan` model role exists for dedicated planning model selection.

### Available agents (via `task` tool)
- `explore` — fast read-only scout, returns structured JSON
- `plan` — full planning agent (spawns explores), produces plan file
- `oracle` — deep reasoning advisor, read-only, blocking
- `reviewer` — code review specialist, blocking
- `librarian` — external API/library research
- `task` / `quick_task` — general purpose

### Context management
- OMP handles auto-compaction; TTSR (too-to-stream-restart) handles context overflow.
- No need to build context management into the skill — the runtime handles it.

---

## Architecture Decision

**A single `SKILL.md`** (not a bundle of files, not an extension). Reason: all five plan tiers use the same tools already in OMP. The skill is a decision framework and format convention, not a new capability. Complexity is in the prose, not the code.

The skill will be split into logical sections the agent can navigate:
1. **Tier classification** — how to pick the right plan tier
2. **Tier-by-tier protocols** — what each tier does step-by-step
3. **Execplan format** — canonical live plan format (OpenAI execplan-inspired)
4. **Agent recipes** — when/how to invoke oracle, librarian, nested plans
5. **Self-review protocol** — mandatory final pass before `exit_plan_mode`

---

## Five Plan Tiers

### Tier 0 — Micro (no HITL)
**When**: Trivially scoped, single file, ≤5 tool calls, no ambiguity.
**Protocol**:
1. Think through blind spots (assumptions, edge cases, callers affected).
2. Execute immediately — no plan file, no `exit_plan_mode`.
3. After execution: run `task { agent: "reviewer" }` as self-review on the diff.

**Plan file**: None.
**HITL**: No.
**Self-review**: Yes (reviewer agent post-execution).

---

### Tier 1 — Simple (HITL, no questions)
**When**: Clear requirement, multi-file or non-trivial, but no ambiguity in approach.
**Protocol**:
1. Spawn parallel `explore` agents to map relevant code areas.
2. Write `local://PLAN.md` using execplan format.
3. Run `task { agent: "oracle" }` to audit the plan for blind spots.
4. Incorporate oracle feedback, finalize plan.
5. Call `exit_plan_mode { title }`.

**Plan file**: Yes — execplan format.
**HITL**: Yes.
**Questions**: None during planning.
**Self-review**: oracle during plan, reviewer optionally post-execution.

---

### Tier 2 — Moderate (HITL + focused questions)
**When**: Clear goal, but tradeoffs exist or technical approach has meaningful alternatives.
**Protocol**:
1. Spawn parallel `explore` agents.
2. Draft initial plan in execplan format.
3. Use `ask` for ≤3 targeted questions about tradeoffs or preferences that exploration cannot resolve.
4. Run `task { agent: "oracle" }` to audit the plan.
5. Incorporate feedback.
6. Call `exit_plan_mode { title }`.

**Plan file**: Yes — execplan format.
**HITL**: Yes.
**Questions**: Up to 3, batched in one `ask` call.
**Research**: Use `librarian` or `web_search` if external API/library knowledge is needed.

---

### Tier 3 — Complex Feature (HITL + deep questions + research)
**When**: Non-trivial feature, multiple subsystems, external library research needed, or significant architectural choices.
**Protocol**:
1. Spawn multiple parallel `explore` agents across subsystems.
2. If external library/API knowledge is needed: spawn `task { agent: "librarian" }`.
3. Draft plan with detailed sections (see execplan format).
4. Use `ask` with up to 5 focused questions — batch into minimal calls.
5. Optionally write supporting spec files under `local://specs/` for large cross-cutting concerns.
6. Run `task { agent: "oracle" }` to audit the full plan.
7. Incorporate feedback, finalize.
8. Call `exit_plan_mode { title }`.

**Plan file**: Yes — execplan format. Optionally supplementary `local://specs/*.md` for complex sub-areas.
**HITL**: Yes.
**Questions**: Up to 5, in at most 2 `ask` batches.
**Research**: librarian + web_search.
**Subagent depth**: explore agents for each major subsystem.

---

### Tier 4 — Mega (multi-milestone decomposition)
**When**: Large, complex feature that spans multiple independent milestones, each of which is itself a Tier 2–3 feature.
**Protocol**:
1. **Meta-exploration**: spawn `explore` agents to understand the full problem domain.
2. **Decompose** the work into N milestones (2–5), each independently shippable.
3. Write a `local://MEGA_PLAN.md` describing: goal, milestones, order, dependencies.
4. Run `task { agent: "oracle" }` on the mega plan.
5. Call `exit_plan_mode { title: "MEGA_PLAN" }` → user approves.
6. In the execution session: each milestone is itself treated as a Tier 3 task — plan → HITL → execute in sequence.

**Plan file**: `local://MEGA_PLAN.md` as top-level. Each milestone will produce its own plan file during execution.
**HITL**: Yes — once at mega-plan level; then once per milestone.
**Note**: Do not try to plan all milestones in detail upfront. The mega plan describes what, not how.

---

## Execplan Format

The execplan format is the canonical plan file format for all tiers that produce a plan file (Tier 1–4). Inspired by OpenAI's "live plan" concept: the plan reflects the current understanding, including what changed and why, not just a static checklist.

```markdown
# Plan: <Title>

## Goal
One paragraph. What to build, why, what success looks like.

## Constraints & Non-Goals
- MUST: …
- MUST NOT: …

## Approach
Chosen approach and brief justification. One alternative considered and why it was rejected.

## Tasks
Ordered, dependency-annotated list. Each task: file path + what changes + acceptance criterion.

- [ ] Task 1 — `src/foo/bar.ts`: Add X to Y. **Acceptance**: …
- [ ] Task 2 — `src/baz.ts`: Modify Z. **Acceptance**: … *(depends on Task 1)*

## Edge Cases
Explicitly enumerated. Each: what it is, how the plan handles it.

## Validation
- How to run the tests that cover this change.
- Any manual verification steps.
- Regression risks.

## Action Log
*Populated during execution. Each entry: what was done, what was surprising, what changed and why.*

- [timestamp] Started Task 1. File: `src/foo/bar.ts`.
- [timestamp] Surprise: discovered Z was already partially implemented. Adjusted Task 2 scope.

## Open Questions
*Populated during planning. Cleared before `exit_plan_mode`.*

- Q: Should X support Y? → Resolved: yes, per user answer.
```

**Rules for the action log:**
- Updated after each task completion during execution (by the implementing agent).
- Surprises must be noted — deviation from plan is expected; undocumented deviation is a bug.
- Never cleaned up retroactively. The log is an audit trail.

---

## Oracle (Plan Auditor) Recipe

Invoke oracle to audit a draft plan before calling `exit_plan_mode`:

```
task {
  agent: "oracle",
  context: "Audit this plan for blind spots, missing edge cases, incorrect sequencing, and unstated assumptions. Be specific — name the file, the assumption, the failure mode.",
  tasks: [{
    id: "PlanAudit",
    description: "Review draft plan",
    assignment: "## Target\nRead local://PLAN.md.\n\n## Change\nIdentify: (1) missing edge cases, (2) incorrect task ordering, (3) unstated assumptions, (4) any section that will be ambiguous to an implementing agent.\n\n## Acceptance\nReturn findings as a structured list with file/section references."
  }]
}
```

The oracle's output is incorporated into the plan before `exit_plan_mode`. If oracle finds nothing significant, note "oracle review: no blockers" in the plan's Action Log.

---

## Research Recipe (Librarian + Web)

For Tier 2–3 when external library knowledge is needed:

```
task {
  agent: "librarian",
  context: "…",
  tasks: [{
    id: "LibraryResearch",
    description: "Research X API",
    assignment: "## Target\n<package or API>\n\n## Change\nAnswer: (1) current API for X, (2) breaking changes in recent version, (3) edge cases in usage.\n\n## Acceptance\nReturn verified answers with source references."
  }]
}
```

For general research, use `web_search` directly. Use `librarian` when the answer lives in package source code or official API docs.

---

## Self-Review Protocol

### During planning (all tiers ≥1):
- Run oracle audit before `exit_plan_mode`.

### After execution (optional, recommended for Tier 1–3):
```
task {
  agent: "reviewer",
  context: "Review the changes just made against the approved plan.",
  tasks: [{...}]
}
```

### For Tier 0 (no plan file):
- After execution, run reviewer on the diff.
- No HITL — reviewer result is consumed by the implementing agent directly.

---

## Tier Selection Guide (Quick Reference)

| Tier | Complexity Signal | HITL | Plan File | oracle | Questions | Research |
|------|-------------------|------|-----------|--------|-----------|----------|
| 0 — Micro | ≤5 tool calls, 1 file, no ambiguity | No | No | No | No | No |
| 1 — Simple | Multi-file, clear approach | Yes | Yes | Yes | No | No |
| 2 — Moderate | Tradeoffs exist | Yes | Yes | Yes | ≤3 | Maybe |
| 3 — Complex | Multiple subsystems, external APIs | Yes | Yes | Yes | ≤5 | Yes |
| 4 — Mega | Multiple milestones, large scope | Yes | Mega | Yes | ≤5 | Yes |

**When in doubt, pick one tier higher.**

---

## File Layout

```
~/.omp/skills/smart-plan/
└── SKILL.md
```

The skill references no external files. All conventions are self-contained in `SKILL.md`.

---

## Implementation Steps

### Phase 1: Write the Skill File

**File**: `~/.omp/skills/smart-plan/SKILL.md`

Content structure (in order):
1. Frontmatter: `name: smart-plan`, `description: …`
2. Tier classification table + decision rules
3. Tier 0 protocol
4. Tier 1 protocol
5. Tier 2 protocol
6. Tier 3 protocol
7. Tier 4 (mega) protocol
8. Execplan format specification (with example)
9. Oracle audit recipe (exact task invocation pattern)
10. Research recipe (librarian + web_search)
11. Self-review protocol
12. Common pitfalls section

### Phase 2: Verify Discovery

Confirm `~/.omp/skills/smart-plan/SKILL.md` is discoverable:
- Run: `/skill:smart-plan` in OMP interactive mode — should inject skill content.
- Or: the model should list `smart-plan` when skills are enumerated.

### Phase 3: Smoke Test

Test each tier with a representative prompt:
- Tier 0: "add a null check to `foo.ts` line 42"
- Tier 1: "refactor the config loading to support env override"
- Tier 2: "add pagination to the user list endpoint"
- Tier 3: "integrate OAuth2 with the existing auth system"
- Tier 4: "build a full notifications system with email, push, and in-app channels"

---

## Critical Files

- `~/.omp/skills/smart-plan/SKILL.md` — the only file to create (the skill itself)
- `/home/bot/.bun/install/cache/@oh-my-pi/pi-coding-agent@13.9.2@@@1/src/prompts/agents/plan.md` — reference for agent frontmatter conventions
- `/home/bot/.bun/install/cache/@oh-my-pi/pi-coding-agent@13.9.2@@@1/src/prompts/system/plan-mode-active.md` — reference for how plan mode context is structured
- `/home/bot/.bun/install/cache/@oh-my-pi/pi-coding-agent@13.9.2@@@1/src/prompts/agents/oracle.md` — reference for oracle invocation
- `pi://skills.md` — discovery rules and directory layout

---

## Verification

1. **Discovery**: After creating `~/.omp/skills/smart-plan/SKILL.md`, start OMP and confirm the skill appears in the loaded skills list (`smart-plan` with description).
2. **Injection**: Run `/skill:smart-plan` — confirms OMP can read and inject the content.
3. **Tier 0 path**: Give a micro task; confirm agent executes immediately + calls reviewer post-execution.
4. **Tier 1 path**: Give a simple multi-file task; confirm: plan file written in execplan format, oracle spawned, `exit_plan_mode` called.
5. **Tier 3 path**: Give a complex task; confirm: questions asked, librarian spawned if applicable, plan written.
6. **Mega path**: Give a large task; confirm: mega plan decomposed into milestones, oracle consulted.

---

## Open Questions (Resolved)

- **Q: Should the skill be a single SKILL.md or multiple files?**
  A: Single SKILL.md. No logic requires multiple files. Extra files add navigation complexity without benefit.

- **Q: Should the skill override the bundled `plan` agent?**
  A: No. The skill augments the main agent's behavior when it enters plan mode. The bundled `plan` task-agent is used internally for spawned sub-planning tasks and is not replaced.

- **Q: Where should the skill live — user level or project level?**
  A: User level (`~/.omp/skills/smart-plan/`) as the default, so it applies to all projects. Project-level (`.omp/skills/smart-plan/`) is an override for project-specific planning conventions.

- **Q: Should context-window restart be handled explicitly?**
  A: No. OMP's TTSR mechanism handles context overflow automatically. The skill does not need to describe this.

- **Q: Should the skill define a custom `/plan` slash command?**
  A: Out of scope for this iteration. The skill is instructional content; slash commands require extension code.

---

## Non-Goals

- No extension code, no custom tools, no hooks.
- No modification to OMP internals.
- No per-tier slash commands (future work).
- No automatic tier detection — the agent classifies; humans may override via `ask`.
- No persistent plan history or cross-session plan tracking.
