# Skill design plan for agent-first planning

## Goal
Design a reusable skill-level planning system for agents that supports multiple planning depths, optional human-in-the-loop approval, research, validation, blind-spot reduction, and decomposition of large work into smaller executable plans.

## Request summary
The skill family must support these planning modes:
1. Ultra-simple action: think enough to remove blind spots, execute immediately without human approval, then run a lightweight self-review.
2. Simple action with planning: produce a plan, save a plan file, do self-review during planning, require human-in-the-loop approval before execution, but ask no questions during planning.
3. Medium complexity action: same as above, but may require limited research and a few user questions.
4. Complex feature: more research, more user questions, deeper blind-spot elimination, possibly additional supporting files, but one main plan file.
5. Large complex feature: first create a higher-level decomposition plan, then solve each smaller complex feature using the previous mode.

Additional desired properties:
- Prefer an ExecPlan-style live plan that records progress, decisions, surprises, and action log.
- Optionally use an extra model/agent role (supervisor/council/oracle) to improve difficult plans.
- Support research when needed.
- Support nested subagents where useful.
- Consider meta-plan and mega-plan variants, but treat them as optional rather than required.
- Include validation in every plan to create backpressure.
- Use up-front context gathering / RPD to reduce missing context.
- Ask questions when needed for alignment.
- Consider but do not require multi-file spec-kit style specifications.

## Key findings from discovery
- The workspace is empty, so this is a greenfield design plan rather than adaptation to an existing repository.
- The deliverable should focus on the design of the skill package itself, not runtime integration, telemetry, or rollout.
- Exact file-by-file package structure is not mandatory at plan stage, but the plan should recommend an eventual structure.
- The optional extra model should remain optional and be activated only for harder planning modes.
- Publicly discussed OpenAI ExecPlan guidance consistently emphasizes a live plan with at least: purpose, context, plan of work, progress, surprises/discoveries, decision log, validation/acceptance, and recovery/idempotence.

## Recommended approach
Create a planning skill family with one shared planning contract and five selectable operating modes. Keep a single canonical plan document format across all non-trivial modes so the executor, reviewer, and human approver always read the same shape. Vary depth by a policy layer rather than inventing a new format per mode.

Recommended architectural idea:
- One planner skill owns mode selection, plan drafting, self-review, and handoff criteria.
- One shared ExecPlan schema defines the main plan file.
- Optional helper roles are invoked only when mode policy requires them:
  - researcher/oracle for external or internal research
  - critic/reviewer for blind-spot discovery and self-review hardening
  - decomposer for splitting large work into milestones/subplans
- Execution is outside this planning skill, but the plan must be self-sufficient for a fresh execution session.

Reason for this choice:
- A single plan schema reduces cognitive load and tool complexity.
- Policy-driven depth selection lets the same system cover trivial and very large work.
- Optional helper roles improve difficult plans without slowing easy tasks.
- A self-contained main plan preserves continuity across context resets.

## Variants to evaluate and compare
### 1. Pure markdown skill package
Description:
- Implement the planning system as markdown skill docs, prompt templates, decision rubrics, and plan-file templates.

Pros:
- Fastest to build and iterate.
- Easy to audit and edit.
- Portable across agent runtimes.
- Best fit if the host platform already treats skills as prompt/instruction packages.

Cons:
- Harder to enforce invariants mechanically.
- Mode selection and plan completeness checks remain prompt-driven.
- Weaker guarantees around schema validation and action logging.

### 2. Markdown-first package with lightweight config/schema
Description:
- Keep prompts and instructions in markdown, but add structured metadata/config describing modes, gating criteria, required sections, and escalation thresholds.

Pros:
- Good balance of flexibility and enforcement.
- Easier to validate required sections, mode thresholds, and helper-agent triggers.
- Still human-readable.
- Strong recommended default for this request.

Cons:
- Slightly more design and implementation effort.
- Requires a host runtime to honor config rules.

### 3. Code-centric planning runtime
Description:
- Build planning logic primarily in TypeScript or Python with prompts as supporting assets.

Pros:
- Strongest enforceability.
- Easier automatic completeness checks, mode selection heuristics, and artifact management.
- Better if planning must deeply integrate with orchestration APIs.

Cons:
- Highest implementation cost.
- Harder to tune quickly.
- Overkill for a skill-level first version if runtime integration is not yet requested.

## Recommendation on package format
Recommend variant 2: markdown-first package with lightweight structured config/schema.
Rationale:
- It preserves the flexibility and auditability of markdown-based skills.
- It provides enough structure to support multiple plan modes, approval gates, required validation, and optional helper-agent escalation.
- It avoids prematurely coupling the design to a specific implementation language.

## Proposed skill family design
### A. Core concepts
1. Plan mode selector
   - Chooses one of five planning depths.
   - Inputs: task complexity, blast radius, ambiguity, novelty, expected duration, need for research, need for decomposition, and user-requested caution level.
   - Outputs: selected mode, whether HITL is required, whether questions are allowed/required, whether research is allowed/required, whether helper agents should be used.

2. Shared ExecPlan contract
   Main plan file should contain at least:
   - Title
   - Goal / user-visible outcome
   - Scope / non-goals
   - Inputs and assumptions
   - Context and orientation
   - Chosen mode and why
   - Plan of work
   - Concrete execution steps or milestones
   - Validation and acceptance criteria
   - Risks / blind spots / open questions
   - Progress log
   - Surprises & discoveries
   - Decision log
   - Recovery / idempotence guidance
   - Handoff notes for fresh-session execution

3. Review gates
   - Completeness gate: every plan must specify validation, assumptions, and a concrete stopping condition.
   - Blind-spot gate: every plan must enumerate likely failure modes, missing information, and impacted surfaces.
   - Execution gate: only modes that require HITL pause for approval; the ultra-simple mode skips HITL but still runs self-review.
   - Escalation gate: if ambiguity or blast radius crosses thresholds, move to a deeper mode or ask questions.

4. Helper roles
   - Researcher/oracle: gathers external or repo context.
   - Critic/reviewer: attacks the draft plan for hidden assumptions, unverified leaps, weak validation, or poor rollback thinking.
   - Decomposer: converts a big feature into milestone plans and identifies per-milestone plan depth.
   - Supervisor/council: optional, reserved for high-uncertainty or high-blast-radius work; should synthesize disagreements rather than merely vote.

### B. Five operating modes
#### Mode 0: Instant plan-execute
Use when:
- Task is narrow, low-risk, low-ambiguity, and local.
- No user approval needed.
- No research needed.

Behavior:
- Think briefly but explicitly about blind spots.
- Do not produce a heavyweight human-facing plan.
- Optionally produce a minimal internal micro-plan or action checklist.
- Execute immediately.
- End with self-review using a compact checklist.

Strengths:
- Minimal overhead.
- Preserves speed for trivial work.

Failure risk:
- May under-document reasoning unless the skill enforces a minimum blind-spot checklist.

#### Mode 1: Simple planned action with HITL
Use when:
- Task is still small, but failure cost or ambiguity justifies review.
- User questions are unnecessary.

Behavior:
- Create main plan file.
- Run self-review during planning.
- Do not ask questions at planning time.
- Pause for human approval before execution.

Strengths:
- Removes many blind spots while keeping interaction short.
- Good default for small but non-trivial changes.

Failure risk:
- If no-question policy is too strict, planner may lock in a wrong assumption. Mode selector must only choose this mode when ambiguity is actually low.

#### Mode 2: Moderate planning with research and limited questions
Use when:
- Some novelty or ambiguity exists.
- Small amount of research may be needed.
- A few user answers materially improve the plan.

Behavior:
- Research relevant patterns or docs.
- Ask a small number of focused questions.
- Create self-contained plan file.
- Run self-review and then pause for approval.

Strengths:
- Better alignment and evidence base.
- Good for medium features or unfamiliar domains.

Failure risk:
- Over-research can slow simple tasks. Need explicit thresholds and limits.

#### Mode 3: Deep feature planning
Use when:
- Feature affects multiple surfaces or has meaningful blast radius.
- More extensive research and clarification are needed.
- Blind-spot pressure is high.

Behavior:
- Perform deeper context gathering.
- Ask more questions, grouped by design trade-off.
- Possibly create supporting artifacts, but retain one main plan file.
- Use helper agents for research and critique when worthwhile.
- Pause for approval.

Strengths:
- Strongest option before program-level decomposition.
- Better resilience against hidden dependencies and weak validation.

Failure risk:
- Can become expensive or overly verbose without a strict section contract and escalation policy.

#### Mode 4: Mega-plan / program decomposition
Use when:
- Work is too large for a single robust execution plan.
- Different sub-features likely need different plan depths.

Behavior:
- Create a top-level decomposition plan.
- Split work into milestones/sub-features.
- For each sub-feature, assign a recommended planning mode and acceptance criteria.
- Execution should proceed milestone by milestone, each with its own derived plan if needed.

Strengths:
- Keeps big work tractable.
- Prevents giant vague plans.

Failure risk:
- Decomposition can be shallow or arbitrary unless driven by dependency boundaries and verifiable milestones.

## Optional advanced variants
### Meta-plan
Use when the main uncertainty is not implementation but how to solve the problem domain well. The output is a research-and-approach plan that precedes the actual execution plan.

### Supporting spec files
Use only for large or long-lived work where stable interfaces or requirements benefit from separate documents. The plan should reference them, but the main plan remains the single source of execution truth.

## Recommended mode selection rubric
Evaluate each task along these axes:
- Ambiguity of desired outcome
- Technical novelty
- Blast radius / number of affected systems
- Reversibility of mistakes
- Need for external/internal research
- Need for user input
- Size / expected duration
- Dependency graph complexity

Recommended policy:
- Low across all axes -> Mode 0
- Low complexity but non-trivial risk -> Mode 1
- Moderate ambiguity or novelty -> Mode 2
- High ambiguity, high blast radius, or multi-surface feature -> Mode 3
- Program-sized or multi-milestone work -> Mode 4

Escalation rules:
- Missing acceptance criteria automatically escalates at least to Mode 1.
- Material unanswered questions prohibit Mode 1 and should escalate to Mode 2 or 3.
- Unknown external domain or missing technical precedent strongly favors adding research.
- Large work with heterogeneous subproblems escalates to Mode 4.

## Recommended self-review contract
Every mode, including Mode 0, should run a reviewer pass with checks for:
- Hidden assumptions
- Missing validation
- Unclear user-visible success condition
- Missing impacted surfaces
- Weak rollback/recovery thinking
- Overly complex plan shape
- Questions that should have been asked earlier

For higher modes, the reviewer should explicitly classify findings into:
- Blocker before approval
- Nice-to-have improvement
- Execution-time watchout

## Recommended plan document shape
Use one canonical main plan template, adapted by depth:
1. Header
2. Request summary
3. Chosen planning mode and rationale
4. Desired outcome and acceptance criteria
5. Known context
6. Assumptions and open questions
7. Risks and blind spots
8. Research findings (if any)
9. Proposed approach and trade-offs
10. Plan of work / milestones
11. Validation strategy
12. Progress log
13. Surprises & discoveries
14. Decision log
15. Execution handoff notes

Mode-specific adaptation:
- Mode 0 may keep this implicit or compressed.
- Modes 1-3 use one full plan file.
- Mode 4 uses one main plan file plus linked subplans when execution begins.

## Proposed skill components to implement later
Because the workspace is empty, these are design targets rather than existing files.

Critical files to create during implementation:
- `skills/agent-planner/SKILL.md` — top-level skill behavior, mode selector, planning contract, escalation rules.
- `skills/agent-planner/templates/execplan.md` — canonical main plan template.
- `skills/agent-planner/templates/micro-plan.md` — compact template for Mode 0 or ultra-light plans.
- `skills/agent-planner/templates/meta-plan.md` — optional research-first template.
- `skills/agent-planner/templates/mega-plan.md` — top-level decomposition template for Mode 4.
- `skills/agent-planner/checklists/self-review.md` — blind-spot and validation checklist.
- `skills/agent-planner/checklists/mode-selection.md` — rubric and escalation criteria.
- `skills/agent-planner/config/modes.yaml` or `modes.json` — structured mode policies, gating rules, and helper-role triggers.
- `skills/agent-planner/examples/` — one example per mode.
- `skills/agent-planner/README.md` only if repository conventions require an extra overview file.

Optional later files:
- `skills/agent-planner/templates/supporting-spec.md`
- `skills/agent-planner/checklists/research.md`
- `skills/agent-planner/checklists/decomposition.md`
- `skills/agent-planner/prompts/critic.md`
- `skills/agent-planner/prompts/researcher.md`
- `skills/agent-planner/prompts/decomposer.md`

## Detailed implementation plan
### Phase 1: Design the planning contract
- Define the common ExecPlan section schema and minimum invariants.
- Define the five modes and exact transitions/escalations.
- Define when questions, research, and HITL are required or forbidden.
- Define the self-review contract shared by all modes.

### Phase 2: Design the skill package structure
- Choose the markdown-first + structured-config packaging approach.
- Draft SKILL.md instructions for mode selection, plan drafting, critique, and handoff.
- Draft reusable templates for main plan, mega-plan, meta-plan, and micro-plan.
- Draft checklists for selection and review.

### Phase 3: Define helper-role strategy
- Specify when researcher, critic, decomposer, and optional supervisor/council are used.
- Define bounded usage so extra agents do not slow low-risk tasks.
- Define how findings from helper roles are folded back into the main plan.

### Phase 4: Add examples and verification rules
- Write representative examples for each mode.
- Add verification guidance proving that the skill chooses the right mode, asks the right amount of questions, and always includes validation.
- Add negative examples showing bad plans and why they fail review.

### Phase 5: Prepare execution handoff quality bar
- Ensure every generated plan is self-contained for a fresh session.
- Ensure live sections are designed to evolve during execution: progress, surprises, decisions, retrospective.
- Define clear approval boundaries between plan and execute phases.

## Trade-offs considered
1. One schema for all non-trivial plans vs separate schema per mode
   - Chosen: one schema with depth policy.
   - Why: simpler mental model and easier execution handoff.

2. Mandatory extra model vs optional extra model
   - Chosen: optional.
   - Why: preserves speed on easy tasks and cost on routine work.

3. Full spec-kit multi-file planning vs single main plan by default
   - Chosen: single main plan by default; supporting specs only for larger work.
   - Why: most tasks do not benefit from heavy upfront artifact sprawl.

4. Runtime-language-specific implementation vs format-neutral skill design
   - Chosen: format-neutral with explicit comparison of package variants.
   - Why: user requested skill-level planning design rather than runtime integration.

## Verification section
When implementing this plan in a later writable session, verify at least the following:
1. Mode selection verification
   - Provide example tasks spanning all five modes.
   - Confirm the selector chooses the intended mode and explains why.
2. Plan completeness verification
   - Confirm every non-trivial generated plan includes acceptance criteria, validation, risks/blind spots, and handoff notes.
3. HITL verification
   - Confirm Mode 0 does not require approval.
   - Confirm Modes 1-4 do require approval before execution.
4. Question policy verification
   - Confirm Mode 1 asks no planning questions.
   - Confirm Modes 2-3 ask only focused questions when needed.
5. Research policy verification
   - Confirm research is skipped for trivial tasks and invoked when novelty/uncertainty justifies it.
6. Self-review verification
   - Confirm each mode runs a review pass and surfaces blockers separately from non-blockers.
7. Decomposition verification
   - Confirm Mode 4 splits a large feature into milestones and assigns each milestone a smaller planning mode.
8. Fresh-session handoff verification
   - Start from a generated plan alone and confirm a separate execution agent can proceed without prior chat context.

## Open decisions to resolve during implementation
- Exact structured config format: YAML vs JSON.
- Whether helper-role prompts live in separate prompt files or are embedded in SKILL.md.
- Whether examples should be minimal or fully worked, live-plan examples with updates over time.
- Whether a retrospective section should be required in all plans or only filled during/after execution.

## Recommended next implementation order
1. Implement the shared planning contract and mode rubric.
2. Implement the main ExecPlan template and micro/mega/meta variants.
3. Implement the self-review checklist.
4. Add helper-role instructions and escalation rules.
5. Add at least one worked example for each planning mode as part of MVP, plus a small set of negative examples.
6. Test the skill on representative prompts from each complexity band, ensuring each mode example passes the intended gate behavior.

## Sources informing this plan
- OpenAI community discussion reproducing ExecPlan guidance and emphasizing a living plan with progress, surprises, decision log, validation, and recovery sections: https://community.openai.com/t/plans-md-file-mentioned-in-the-shipping-with-codex-talk-at-dev-day/1361628
- General recent literature and guidance on hierarchical plan-and-execute agents, human-in-the-loop approval, and self-critique/review patterns were consulted during planning to reinforce the decomposition, review, and escalation recommendations.
