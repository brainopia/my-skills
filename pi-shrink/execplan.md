# pi-shrink: Self-Improving Agent Extension for Pi

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

Maintained in accordance with `execplan/references/PLANS.md` from the repository root (`/home/bot/projects/pi-skills-with-self-analysis/execplan/references/PLANS.md`).


## Purpose / Big Picture

After this work is done, a Pi user can invoke a slash command (`/shrink`) at any point during or after a session. The extension reads the current session log, identifies chunks of agent work that could be extracted into reusable skills (delegatable to subagents), and presents those candidates to the user. If the user agrees (or specifies their own candidate), the extension orchestrates creating a new skill — plan first, then implementation — all via subagents so the main context stays clean. In later milestones, it also analyzes how existing skills performed in the session and proposes targeted improvements backed by tests.

The name "pi-shrink" is a play on "shrink" (therapist): the extension psychoanalyzes sessions to make the agent smarter over time.

**What someone can do after this change that they could not do before:** Run `/shrink` in any Pi session and get actionable suggestions for new skills to create, with one-click creation flow. Later: get suggestions for improving existing skills that underperformed, were not invoked when they should have been, or were invoked incorrectly.


## Progress

- [ ] Milestone 0: Project scaffolding — extension skeleton, command registration, session parsing utilities.
- [ ] Milestone 1A: Abstraction detection — analyze session log, identify skill candidates, present to user.
- [ ] Milestone 1B: Skill creation — from approved candidate, generate ExecPlan, get user approval, create skill via subagent.
- [ ] Milestone 2: Skill improvement — analyze existing skill invocations, propose and implement improvements with tests.


## Surprises & Discoveries

(None yet — to be updated as work proceeds.)


## Decision Log

- Decision: Use a Pi extension (not a skill) as the delivery mechanism.
  Rationale: We need event hooks (slash command registration), UI interaction (select/confirm dialogs), direct access to `ctx.sessionManager.getEntries()` for session log parsing, and the ability to spawn subagents. Skills cannot do any of this — they are instruction-only markdown files. Extensions have the full `ExtensionAPI`.
  Date/Author: 2026-03-04 / initial plan

- Decision: Extension source lives in the project at `pi-shrink/` (repo-relative), not in `~/.pi/agent/extensions/`. It is registered for pi auto-discovery via `settings.json` `"extensions"` array pointing to the project path, or via a symlink from `~/.pi/agent/extensions/pi-shrink` to the project directory. This keeps all source versioned in git alongside the skills and execplan.
  Rationale: Follows the same pattern as other project artifacts in this repo (skills are symlinked too). Keeps development, testing, and version control in one place.
  Date/Author: 2026-03-04 / initial plan

- Decision: File organization follows the pi-subagents pattern — flat TypeScript files in the extension root, an `agents/` subdirectory for subagent definitions, and a `package.json` with the `"pi"` field declaring the entry point. No `src/` or `dist/` directories — jiti loads TypeScript directly.
  Rationale: This is the established convention for pi extensions. pi-subagents (the most complex extension in the ecosystem) uses this exact layout. It keeps imports simple (e.g., `import { foo } from "./bar.js"`) and avoids build steps.
  Date/Author: 2026-03-04 / initial plan

- Decision: Run analysis and creation steps in subagents via pi-subagents, not in the main agent context.
  Rationale: The main agent's context window may already be large after a session. Analyzing logs and creating skills would consume significant tokens. Subagents get isolated context windows. We use the pi-subagents extension (already installed globally as `pi-subagents@0.11.0`) which provides the `subagent` tool for spawning isolated pi processes.
  Date/Author: 2026-03-04 / initial plan

- Decision: Each created skill gets its own ExecPlan (markdown file) in its directory, created via the `execplan` skill.
  Rationale: The user explicitly wants ExecPlans as living documents per skill — tracking decisions, surprises, and history of changes. This aligns with the project's existing `execplan` skill methodology.
  Date/Author: 2026-03-04 / initial plan

- Decision: Milestone 1 (create skills) is split from Milestone 2 (improve skills) because creation only needs the current session log, while improvement needs to read subagent session logs as well.
  Rationale: Subagent sessions are stored as separate JSONL files linked by `parentSession`. Parsing those adds complexity. Shipping creation first gives a useful, testable feature sooner.
  Date/Author: 2026-03-04 / initial plan

- Decision: Abstraction quality criteria — an abstraction must be (a) independent of the surrounding conversation, (b) replaceable (a large chunk of agent work that could be a single skill invocation), and (c) reusable (likely to recur across sessions, not a one-off unique task).
  Rationale: Per user requirements. Prevents the extension from suggesting every code block as a skill. Programming-related abstractions are first-class candidates.
  Date/Author: 2026-03-04 / initial plan

- Decision: At every user-facing decision point, provide an "other / custom" option so the user can override the extension's suggestions.
  Rationale: The extension should suggest but never gate-keep. If it finds nothing, the user can still point it at a specific part of the session.
  Date/Author: 2026-03-04 / initial plan


## Outcomes & Retrospective

(To be filled at milestone completions.)


## Context and Orientation

**Repository:** `/home/bot/projects/pi-skills-with-self-analysis/` — a project for Pi skills with self-analysis capabilities. Currently contains an `execplan` skill (at `execplan/`), an `extending-pi` skill (at `extending-pi/`), and the `pi-shrink` extension (at `pi-shrink/`). The project's `.pi/skills` directory is symlinked to `~/.pi/agent/skills/pi-skills-with-self-analysis` for global skill discovery.

**Project structure (target):**

    pi-skills-with-self-analysis/
    ├── README.md
    ├── execplan/                      # ExecPlan skill (existing)
    │   ├── SKILL.md
    │   └── references/
    │       └── PLANS.md
    ├── extending-pi/                  # Extending-pi skill (existing)
    │   ├── SKILL.md
    │   └── skill-creator/
    ├── pi-shrink/                     # The extension (THIS WORK)
    │   ├── execplan.md                # Living ExecPlan for the extension itself
    │   ├── package.json               # Extension manifest with "pi" field
    │   ├── index.ts                   # Entry point — registers /shrink, orchestrates pipeline
    │   ├── types.ts                   # Shared TypeScript interfaces
    │   ├── session-parser.ts          # Session JSONL parsing and segmentation
    │   ├── analyzer.ts                # Abstraction detection (Milestone 1A)
    │   ├── creator.ts                 # Skill creation orchestration (Milestone 1B)
    │   ├── improver.ts                # Skill improvement analysis (Milestone 2)
    │   ├── subagent-sessions.ts       # Subagent session log reader (Milestone 2)
    │   └── agents/                    # Subagent definitions (markdown with YAML frontmatter)
    │       ├── shrink-analyzer.md     # Analyzes sessions for abstractions
    │       ├── shrink-planner.md      # Plans new skills from candidates
    │       ├── shrink-builder.md      # Implements skill plans
    │       └── shrink-improver.md     # Analyzes and improves existing skills
    └── .pi/
        └── skills -> symlink          # Project skills (existing)

**How pi discovers the extension:** The `pi-shrink/` directory contains a `package.json` with:

    {
      "name": "pi-shrink",
      "private": true,
      "version": "0.1.0",
      "type": "module",
      "pi": {
        "extensions": ["./index.ts"]
      }
    }

A symlink from `~/.pi/agent/extensions/pi-shrink` to `/home/bot/projects/pi-skills-with-self-analysis/pi-shrink/` enables auto-discovery. Alternatively, the path can be added to `settings.json` `"extensions"` array. The symlink approach matches how skills in this repo are already exposed.

**How pi discovers the subagent definitions:** pi-subagents scans project-scoped agents from `.pi/agents/` (searching up the directory tree). Since our agents live inside `pi-shrink/agents/`, we have two options: (a) symlink them into `.pi/agents/` at the project root, or (b) the extension registers them programmatically at load time via `pi.sendUserMessage()` triggering `subagent { action: "create", config: {...} }`. Option (a) is simpler and keeps agents versioned. Option (b) avoids symlink maintenance. We will start with (a) — symlinks from project `.pi/agents/shrink-*.md` to `pi-shrink/agents/shrink-*.md`.

**Pi extensions** are TypeScript files that export a default function receiving an `ExtensionAPI` object. They can register slash commands, subscribe to events, show UI dialogs, and register tools. Extensions live in `~/.pi/agent/extensions/` (global) or `.pi/extensions/` (project-local). They are loaded via `jiti` — no compilation needed. The file organization convention (established by pi-subagents) is flat TypeScript modules in the extension root — no `src/` directory, no build step. Imports use `.js` extensions per ESM convention (e.g., `import { foo } from "./types.js"`), and jiti resolves them to `.ts` at load time.

**Pi sessions** are JSONL files stored at `~/.pi/agent/sessions/--<path>--/<timestamp>_<uuid>.jsonl`. Each line is a JSON object with a `type` field. Key entry types:
- `session` — header line with version, id, cwd, optional `parentSession`
- `message` — wraps an `AgentMessage` (user, assistant, toolResult, bashExecution, custom, branchSummary, compactionSummary)
- `compaction` — summary of earlier messages when context was compacted
- `custom` — extension state (not in LLM context)
- `custom_message` — extension message (in LLM context)

Entries form a tree via `id`/`parentId` fields. The `SessionManager` API (`ctx.sessionManager`) provides:
- `getEntries()` — all entries in the session
- `getBranch()` — entries on the current branch (root to leaf)
- `getLeafId()` — current leaf entry ID
- `getSessionFile()` — path to the JSONL file

**AgentMessage types** relevant to analysis:
- `UserMessage` — `role: "user"`, `content: string | ContentBlock[]`
- `AssistantMessage` — `role: "assistant"`, `content: (TextContent | ThinkingContent | ToolCall)[]`, includes `model`, `usage`, `stopReason`
- `ToolResultMessage` — `role: "toolResult"`, `toolName`, `content`, `isError`
- `BashExecutionMessage` — `role: "bashExecution"`, `command`, `output`, `exitCode`

**pi-subagents** (installed globally as `pi-subagents@0.11.0`) is an extension that provides:
- A `subagent` tool with modes: single (`{ agent, task }`), parallel (`{ tasks: [...] }`), chain (`{ chain: [...] }`)
- Agent definitions as markdown files with YAML frontmatter (name, description, tools, model, thinking level, system prompt body)
- Agent scopes: builtin (`~/.pi/agent/extensions/subagent/agents/`), user (`~/.pi/agent/agents/`), project (`.pi/agents/`)
- Management: `{ action: "create", config: {...} }`, `{ action: "list" }`, `{ action: "get", agent: "name" }`
- Built-in agents: scout, planner, worker, reviewer, context-builder, researcher

**Extension UI API** (`ctx.ui`):
- `select(title, options)` — returns selected option or `undefined`
- `confirm(title, message)` — returns boolean
- `input(title, placeholder)` — returns string or `undefined`
- `editor(title, prefill)` — multi-line text input
- `notify(message, level)` — non-blocking notification ("info" | "warning" | "error")
- `setStatus(id, text)` — persistent footer status
- `setWidget(id, lines)` — widget above/below editor
- `custom(fn)` — full custom TUI component

**Extension commands** are registered via `pi.registerCommand(name, { description, handler })` and invoked as `/name` in the chat.

**Existing skills relevant to our flow:**
- `execplan` at `execplan/SKILL.md` — creates execution plans following PLANS.md methodology
- `skill-creator` at `extending-pi/skill-creator/SKILL.md` — guidance for creating Pi skills (structure, frontmatter, body, resources)


## Plan of Work

### Milestone 0 — Project Scaffolding

Create the extension files in `pi-shrink/` within the project repo. Set up the symlink for pi auto-discovery. Register the `/shrink` command. Implement session log parsing utilities. Verify the extension loads and the command works.

**What exists after this milestone:** A working Pi extension at `pi-shrink/` (repo-relative path: `/home/bot/projects/pi-skills-with-self-analysis/pi-shrink/`) with:
- `package.json` — extension manifest with `"pi": { "extensions": ["./index.ts"] }`
- `index.ts` — entry point, registers `/shrink` command
- `types.ts` — shared type definitions
- `session-parser.ts` — reads session entries, extracts conversation segments
- A symlink `~/.pi/agent/extensions/pi-shrink` → `/home/bot/projects/pi-skills-with-self-analysis/pi-shrink/`

**Files to create:**

`pi-shrink/package.json` — extension manifest:

    {
      "name": "pi-shrink",
      "private": true,
      "version": "0.1.0",
      "type": "module",
      "pi": {
        "extensions": ["./index.ts"]
      }
    }

`pi-shrink/index.ts` — the extension entry point. Exports a default function that:
1. Registers `/shrink` command with handler that calls the analysis pipeline
2. On `/shrink`, reads `ctx.sessionManager.getBranch()` to get current branch entries
3. Passes entries to the analysis pipeline (Milestone 1A)

`pi-shrink/session-parser.ts` — utilities for parsing session data:
- `extractConversationSegments(entries)` — groups consecutive message entries into "segments" — logical conversation chunks. A segment is a sequence of entries (user prompt + assistant response + tool calls + results) that form one coherent unit of work. Segments are separated by topic shifts (detected by long pauses, user prompts that start new topics, or compaction boundaries).
- `segmentToText(segment)` — serializes a segment into a readable text summary suitable for LLM analysis. Strips base64 images, truncates long tool outputs, preserves tool names and key actions.
- `getSessionStats(entries)` — returns basic stats: total entries, token usage, models used, tools invoked, skills referenced.

`pi-shrink/types.ts` — type definitions:
- `ConversationSegment` — `{ entries: SessionEntry[], startTime: string, endTime: string, tokenCount: number, toolsUsed: string[], summary?: string }`
- `AbstractionCandidate` — `{ segmentIndices: number[], description: string, rationale: string, skillName: string, reusabilityScore: number, independenceScore: number, replacementSize: number }`
- `SkillProposal` — `{ candidate: AbstractionCandidate, execPlan?: string, approved: boolean }`

**Validation:** Create the symlink, start pi in the project directory. Type `/shrink`. Expect: the command is recognized, it reads session entries and prints a notification with session stats (entry count, token usage). No errors in the console.

    # Setup symlink
    ln -sf /home/bot/projects/pi-skills-with-self-analysis/pi-shrink ~/.pi/agent/extensions/pi-shrink

    # Start pi and test
    cd /home/bot/projects/pi-skills-with-self-analysis
    pi
    # In pi, type: /shrink
    # Expected: notification "Session: 15 entries, 12.3k tokens, tools: bash(5), read(3), edit(2)"


### Milestone 1A — Abstraction Detection

Implement the core analysis logic that identifies skill candidates in a session. This runs as a subagent to avoid consuming the main agent's context.

**What exists after this milestone:** Running `/shrink` analyzes the session and presents a list of abstraction candidates to the user via `ctx.ui.select()`. Each candidate shows: a proposed skill name, a description of what it would do, which session segments it would replace, and a reusability/independence assessment. The user can select one, select "none of these", or type a custom description.

**How it works internally:**

1. `/shrink` handler calls `session-parser.ts` to extract segments and serialize them to text.
2. The handler writes the serialized session text to a temporary file.
3. The handler uses `pi.sendUserMessage()` to invoke the `subagent` tool with a specialized "shrink-analyzer" agent. This agent:
   - Reads the temp file containing the serialized session
   - Applies the abstraction quality criteria (independent, replaceable, reusable, programming-focused)
   - Returns a JSON array of `AbstractionCandidate` objects
4. The handler parses the subagent's response and presents candidates via `ctx.ui.select()`.
5. If the user selects a candidate, it's stored for Milestone 1B. If "custom", the user provides a text description via `ctx.ui.input()`.

**The "shrink-analyzer" agent** is a project-scoped agent definition (`.pi/agents/shrink-analyzer.md`) with:
- A focused system prompt that explains abstraction criteria
- Tools: `read` only (reads the temp file)
- Model: a fast, capable model (claude-sonnet-4-5 or similar)
- Output: structured JSON

**Abstraction quality criteria encoded in the agent prompt:**

An abstraction is a good skill candidate when ALL of the following hold:
1. **Independence** — The work chunk does not depend on the broader conversation context. You could describe the task to someone with no knowledge of the session and they could execute it.
2. **Replaceability** — The chunk represents substantial agent work (multiple tool calls, research, iteration) that could be replaced by a single skill invocation with a short input.
3. **Reusability** — The pattern is likely to recur in future sessions. It is not a one-off unique situation. Programming tasks (build systems, testing patterns, deployment, code generation for specific frameworks) are strong candidates.
4. **Bounded scope** — The abstraction has clear inputs and outputs. You can define what goes in and what comes out.

Counter-examples (NOT good candidates):
- A unique debugging session for a specific one-time bug
- A conversation about personal preferences or project-specific decisions
- A trivial task that takes the agent only one or two tool calls

**Files to create/modify:**

`pi-shrink/analyzer.ts` — orchestrates the analysis:
- `analyzeSession(entries, ctx)` — main function called by `/shrink`
- Writes serialized segments to a temp file
- Constructs the subagent invocation
- Parses results, presents UI

`pi-shrink/agents/shrink-analyzer.md` — the analyzer subagent definition. Symlinked from `.pi/agents/shrink-analyzer.md` at the project root so pi-subagents discovers it:

    ---
    name: shrink-analyzer
    description: Analyzes Pi session logs to find reusable abstractions that could become skills
    tools: read, bash
    model: claude-sonnet-4-5
    ---

    You are a session analyst for the Pi coding agent. Your job is to read a serialized
    session log and identify chunks of agent work that could be extracted into reusable skills.
    [... full criteria embedded in prompt ...]

**Symlink setup for agents:**

    mkdir -p /home/bot/projects/pi-skills-with-self-analysis/.pi/agents
    ln -sf ../../pi-shrink/agents/shrink-analyzer.md .pi/agents/shrink-analyzer.md

**Validation:** Start a Pi session, do some work that involves a recognizable pattern (e.g., searching for documentation, calculating something, setting up a project). Run `/shrink`. Expect: after a few seconds of subagent processing, a selection dialog appears with 0-N candidates. Each candidate has a name, description, and rationale. Selecting one stores it. Selecting "Custom..." prompts for a description. Selecting "None — skip" exits cleanly.


### Milestone 1B — Skill Creation

From an approved abstraction candidate, generate and execute a skill creation plan.

**What exists after this milestone:** After selecting (or describing) an abstraction in `/shrink`, the user is presented with a proposed skill plan (ExecPlan). If approved, the extension creates the skill files — SKILL.md, optional scripts/references, and an ExecPlan in the skill directory — all via a subagent.

**How it works internally:**

1. After Milestone 1A produces an approved candidate (or custom description), the handler invokes a "shrink-planner" subagent.
2. The planner subagent:
   - Receives the abstraction description, the relevant session segments, and the skill-creator guidelines (from `extending-pi/skill-creator/SKILL.md`)
   - Generates a skill plan: proposed directory structure, SKILL.md content, any scripts or references needed
   - Returns the plan as structured text
3. The handler presents the plan to the user via `ctx.ui.editor()` (editable multi-line view).
4. If the user approves (confirms), a "shrink-builder" subagent executes the plan:
   - Creates the skill directory under `~/.pi/agent/skills/` (or project-local `.pi/skills/`)
   - Writes SKILL.md, scripts, references
   - Creates an ExecPlan markdown file in the skill directory documenting the creation
   - Commits the new skill with a descriptive commit message
5. The handler notifies the user of completion and reloads Pi resources (`ctx.reload()`) so the new skill is immediately available.

**New subagent definitions (in `pi-shrink/agents/`, symlinked to `.pi/agents/`):**

`pi-shrink/agents/shrink-planner.md` — plans new skills:

    ---
    name: shrink-planner
    description: Creates detailed plans for new Pi skills based on abstraction candidates
    tools: read, bash, write
    model: claude-sonnet-4-5
    thinking: medium
    ---

    You are a skill architect for the Pi coding agent. Given an abstraction candidate
    extracted from a session, you design a complete skill [...]

`pi-shrink/agents/shrink-builder.md` — executes skill creation plans:

    ---
    name: shrink-builder
    description: Implements Pi skills from approved plans
    tools: read, bash, write, edit
    model: claude-sonnet-4-5
    ---

    You are a skill builder for the Pi coding agent. Given an approved skill plan,
    you create all necessary files [...]

**Files to create/modify:**

`pi-shrink/creator.ts` — skill creation orchestration:
- `createSkillPlan(candidate, segments, ctx)` — invokes shrink-planner, returns plan text
- `executeSkillPlan(plan, ctx)` — invokes shrink-builder, creates files, commits

**Validation:** Run `/shrink`, select or describe an abstraction. Expect: a plan appears in an editor dialog. After approval, a new skill directory is created with SKILL.md and an ExecPlan. The skill appears in `pi` after reload. Running `/shrink` again on a session where the new skill would apply should show that the analyzer recognizes its relevance.


### Milestone 2 — Skill Improvement

Analyze how existing skills performed in the session and propose improvements.

**What exists after this milestone:** `/shrink` not only finds new abstraction candidates but also reviews existing skills that were (or should have been) invoked. It identifies:
1. Skills that were invoked but performed poorly (took many iterations, produced errors, used excessive tokens)
2. Skills that should have been invoked but were not (based on session content matching skill descriptions)
3. Skills that were invoked unnecessarily (session context did not warrant them)

For each finding, it proposes a specific improvement (prompt change, description update, added heuristic) with a test that reproduces the issue before the fix and passes after.

**How it works internally:**

1. The analysis phase (extending Milestone 1A) now also:
   - Identifies which skills were loaded/invoked in the session (by checking for skill-related patterns in entries — skill loading appears as custom messages or in assistant reasoning)
   - For invoked skills, reads their SKILL.md and correlates with session outcomes
   - Reads subagent session logs (via `parentSession` links in session headers) to analyze skill execution in subagent contexts
2. A "shrink-improver" subagent analyzes each skill's performance:
   - Reads the skill's SKILL.md, its ExecPlan (if it exists), and the relevant session segments
   - Proposes specific changes with rationale
   - Generates a test scenario: a mock session fragment that triggers the skill and verifies improved behavior
3. The user reviews proposed improvements and approves/rejects each one.
4. Approved improvements are applied by the shrink-builder subagent:
   - Modifies SKILL.md or associated files
   - Creates or updates the skill's ExecPlan with the change log
   - Writes the test
   - Runs the test to verify the fix
   - Commits with a detailed message including: what was changed, why, what model detected the issue, and the test that validates it

**Subagent session log reading** — to find subagent sessions for analysis:
- Parse the current session's entries for `custom` entries from `pi-subagents` that reference child session files
- Read those child JSONL files and apply the same segment extraction
- Correlate parent/child by timestamp and task description

**New subagent definition (in `pi-shrink/agents/`, symlinked to `.pi/agents/`):**

`pi-shrink/agents/shrink-improver.md` — analyzes and improves existing skills:

    ---
    name: shrink-improver
    description: Analyzes skill performance in sessions and proposes improvements
    tools: read, bash, write, edit
    model: claude-sonnet-4-5
    thinking: high
    ---

    You are a skill optimizer for the Pi coding agent [...]

**Files to create/modify:**

`pi-shrink/improver.ts` — skill improvement orchestration:
- `analyzeSkillPerformance(entries, ctx)` — identifies skills and their performance
- `proposeImprovements(skillAnalysis, ctx)` — generates improvement proposals
- `applyImprovement(proposal, ctx)` — applies changes, runs tests, commits

`pi-shrink/subagent-sessions.ts` — utilities for reading subagent session logs:
- `findChildSessions(entries)` — finds subagent session file paths from parent entries
- `parseSubagentSession(filePath)` — reads and parses a subagent JSONL file
- `correlateSkillUsage(parentSegments, childSessions)` — matches skill invocations to outcomes

**Testing strategy for skill improvements:**

Each improvement produces a test file in the skill's directory (e.g., `tests/improvement-<date>.md`). The test contains:
1. A "before" scenario — a mock input that triggers the old behavior (failing or suboptimal)
2. An "after" scenario — the same input that should now produce better behavior
3. A verification script that can be run to confirm the improvement

Tests are run via a subagent that simulates the scenario and checks outcomes. This is not unit testing in the traditional sense — it is LLM-based behavioral testing where the subagent acts as both the test runner and the verifier.

**Validation:** In a session where a skill was invoked (e.g., `execplan`), run `/shrink`. Expect: in addition to new abstraction candidates, the extension shows skill performance analysis. If a skill underperformed, a specific improvement is proposed. After approval, the skill is modified, a test is created, the test passes, and a commit is made with full context in the message.


## Concrete Steps

These will be filled in detail as each milestone begins. The high-level sequence for Milestone 0:

1. Working directory: `/home/bot/projects/pi-skills-with-self-analysis/pi-shrink/`

   Files to create: `package.json`, `types.ts`, `session-parser.ts`, `index.ts`.

2. Create the symlink for pi auto-discovery:

       ln -sf /home/bot/projects/pi-skills-with-self-analysis/pi-shrink ~/.pi/agent/extensions/pi-shrink

3. Create the `.pi/agents/` directory and symlinks for subagent definitions (when agents are added in Milestone 1A):

       mkdir -p /home/bot/projects/pi-skills-with-self-analysis/.pi/agents
       # For each agent file in pi-shrink/agents/:
       ln -sf ../../pi-shrink/agents/shrink-analyzer.md .pi/agents/shrink-analyzer.md

4. Test:

       cd /home/bot/projects/pi-skills-with-self-analysis
       pi

   Type `/shrink` in the chat. Expected output: a notification showing session stats (e.g., "Session: 15 entries, 12.3k tokens, tools: bash(5), read(3), edit(2)").

Steps for subsequent milestones will be elaborated when work begins on them.


## Validation and Acceptance

**Milestone 0:** Start pi, type `/shrink`, see session stats notification. No errors.

**Milestone 1A:** After a meaningful coding session, type `/shrink`. A selection dialog appears within 30 seconds showing 0-N abstraction candidates with names and descriptions. Each candidate's rationale references specific session segments. "Custom" and "None" options are available.

**Milestone 1B:** Select a candidate from 1A. A skill plan appears in an editor. After approval, a new skill directory exists with SKILL.md and ExecPlan. `pi` recognizes the skill after reload. The commit message describes what abstraction was extracted and why.

**Milestone 2:** After a session using existing skills, `/shrink` shows skill performance analysis alongside new candidates. Proposed improvements reference specific session moments. After approval, skill files are modified, tests are created and pass, and the commit includes full provenance (model, issue, fix, test).


## Idempotence and Recovery

Running `/shrink` multiple times is safe — it reads session state (read-only) and only creates/modifies files after explicit user approval. If a subagent fails mid-execution, temp files are cleaned up and the user is notified. Skill creation writes to new directories, so it cannot corrupt existing skills. Skill improvement modifies files but commits each change, so `git revert` is always available.

All temp files (serialized session data for subagents) are written to `os.tmpdir()` with unique names and cleaned up after use.


## Artifacts and Notes

Example session entry structure (from a real session JSONL):

    {"type":"message","id":"a1b2c3d4","parentId":"prev1234","timestamp":"2024-12-03T14:00:01.000Z",
     "message":{"role":"user","content":"Fix the auth bug in login.ts"}}
    {"type":"message","id":"b2c3d4e5","parentId":"a1b2c3d4","timestamp":"2024-12-03T14:00:02.000Z",
     "message":{"role":"assistant","content":[{"type":"text","text":"I'll look at..."},
     {"type":"toolCall","id":"call_1","name":"read","arguments":{"path":"src/login.ts"}}],
     "provider":"anthropic","model":"claude-sonnet-4-5","usage":{...},"stopReason":"toolUse"}}

Example abstraction candidate output from the analyzer:

    {
      "segmentIndices": [3, 4, 5],
      "description": "Research and configure ESLint rules for a TypeScript project",
      "rationale": "Agent spent 12 tool calls searching docs, trying configs, and fixing errors. This pattern recurs whenever setting up linting. A skill could encode best practices and common pitfalls.",
      "skillName": "eslint-ts-setup",
      "reusabilityScore": 0.85,
      "independenceScore": 0.9,
      "replacementSize": 4200
    }


## Interfaces and Dependencies

**Dependencies:**
- `@mariozechner/pi-coding-agent` — for `ExtensionAPI`, `ExtensionContext`, session types
- `@sinclair/typebox` — for tool parameter schemas (if we register tools beyond the command)
- `pi-subagents` — installed globally, provides the `subagent` tool. We invoke it via `pi.sendUserMessage()` with a prompt that triggers the subagent tool, or alternatively by directly constructing tool calls
- Node.js built-ins: `node:fs`, `node:path`, `node:os` — for temp files and file operations

**Key interfaces:**

In `pi-shrink/types.ts`:

    interface ConversationSegment {
      entries: any[];           // Raw session entries
      startTime: string;        // ISO timestamp of first entry
      endTime: string;          // ISO timestamp of last entry
      tokenCount: number;       // Sum of usage.totalTokens across assistant messages
      toolsUsed: string[];      // Unique tool names invoked
      skillsReferenced: string[]; // Skills mentioned or loaded
      textSummary: string;      // Human-readable serialization for LLM analysis
    }

    interface AbstractionCandidate {
      segmentIndices: number[];   // Which segments this covers
      description: string;        // What the skill would do
      rationale: string;          // Why it's a good abstraction
      skillName: string;          // Proposed kebab-case name
      reusabilityScore: number;   // 0-1, likelihood of recurrence
      independenceScore: number;  // 0-1, how context-free it is
      replacementSize: number;    // Approx tokens this would save per invocation
    }

    interface SkillProposal {
      candidate: AbstractionCandidate;
      plan: string;               // Full skill plan text (ExecPlan format)
      targetDir: string;          // Where the skill will be created
      approved: boolean;
    }

    interface SkillAnalysis {
      skillName: string;
      skillPath: string;          // Full path to SKILL.md
      invoked: boolean;           // Was it invoked in this session?
      shouldHaveBeenInvoked: boolean; // Should it have been, based on content?
      performance: "good" | "poor" | "unnecessary";
      evidence: string;           // Session segments showing performance
      proposedChange?: string;    // What to change
      testScenario?: string;      // How to verify the change
    }

In `pi-shrink/index.ts`:

    export default function (pi: ExtensionAPI): void
    // Registers /shrink command
    // Orchestrates the full pipeline

In `pi-shrink/session-parser.ts`:

    export function extractConversationSegments(entries: any[]): ConversationSegment[]
    export function segmentToText(segment: ConversationSegment): string
    export function getSessionStats(entries: any[]): SessionStats

In `pi-shrink/analyzer.ts`:

    export async function analyzeSession(
      segments: ConversationSegment[],
      ctx: ExtensionContext
    ): Promise<AbstractionCandidate[]>

In `pi-shrink/creator.ts`:

    export async function createSkillPlan(
      candidate: AbstractionCandidate,
      segments: ConversationSegment[],
      ctx: ExtensionContext
    ): Promise<string>

    export async function executeSkillPlan(
      plan: string,
      skillName: string,
      ctx: ExtensionContext
    ): Promise<void>

In `pi-shrink/improver.ts`:

    export async function analyzeSkillPerformance(
      segments: ConversationSegment[],
      ctx: ExtensionContext
    ): Promise<SkillAnalysis[]>

    export async function applyImprovement(
      analysis: SkillAnalysis,
      ctx: ExtensionContext
    ): Promise<void>


---

**Revision 2026-03-04:** Moved pi-shrink source from `~/.pi/agent/extensions/pi-shrink/` into the project repo at `pi-shrink/`. Adopted pi-subagents file organization pattern (flat .ts files, `agents/` subdirectory, `package.json` with `"pi"` field). Extension is discovered via symlink from `~/.pi/agent/extensions/pi-shrink` to the project directory. Subagent definitions live in `pi-shrink/agents/` and are symlinked to `.pi/agents/` at the project root. Added full project tree diagram to Context section. All file paths throughout the plan updated to repo-relative form.
