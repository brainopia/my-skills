# Analysis of pi-shrink/execplan.md: Weaknesses and Improvement Recommendations

## Summary

The plan is well-structured, follows the PLANS.md methodology, and demonstrates solid research into the Pi extension/session/subagent APIs. However, after cross-referencing with the actual source code of Pi agent (`@mariozechner/pi-coding-agent@0.56.0`), pi-subagents (`pi-subagents@0.11.0`), and the session JSONL format, I identified several weaknesses ranging from architectural risks to factual inaccuracies and missing details.

---

## Weakness 1: Fragile Subagent Invocation Mechanism

**Location:** Milestone 1A, step 3 (line 229); Milestone 1B, steps 1-4 (lines 291-302)

**Problem:** The plan says the extension will invoke subagents via `pi.sendUserMessage()` to trigger the `subagent` tool. This is how pi-subagents' `/run` command works internally — it sends a user message like `"Call the subagent tool with these exact parameters: {JSON}"`, relying on the LLM to faithfully parse and execute that tool call.

This is inherently fragile:
- The LLM may refuse, rewrite, or misinterpret the tool call parameters
- It consumes a full LLM round-trip just to relay the parameters
- The subagent results come back as text in the LLM conversation, not as structured data the extension can programmatically parse
- Race conditions: the extension cannot reliably wait for the subagent to complete and get its output back as structured data

**Recommendation:** Use `pi.exec()` (available on ExtensionAPI) to spawn a Pi subprocess directly, or use the async mode of pi-subagents and watch for `subagent:complete` events on `pi.events`. Alternatively, since pi-subagents registers a tool called `"subagent"`, the extension could potentially call `pi.sendUserMessage()` and then listen for `tool_execution_end` events where `toolName === "subagent"` to capture structured results. But the cleanest path is to study how pi-subagents' `subagent-runner.ts` spawns `pi` processes and replicate that directly — the extension has `pi.exec()` which can run shell commands.

**Impact:** HIGH — this is the core communication mechanism between the extension and its analysis/creation subagents. If it's unreliable, nothing works.

---

## Weakness 2: Missing `editor()` UI Method — Plan Claims Feature That Exists But Works Differently

**Location:** Milestone 1B, step 3 (line 296); UI API description (line 151)

**Problem:** The plan lists `editor(title, prefill)` in the UI API section (line 151) and plans to use `ctx.ui.editor()` to show an editable multi-line view for skill plan approval. The actual API signature confirms this exists:

```typescript
editor(title: string, prefill?: string): Promise<string | undefined>;
```

This is correct. However, the plan doesn't account for what happens if the user edits the plan text — the downstream `shrink-builder` subagent would receive the user-modified text, not the original. The plan should explicitly state that the edited text is what gets passed to the builder.

**Recommendation:** Minor — just clarify the data flow. The `editor()` return value (user-edited string) should be the plan passed to the builder subagent.

**Impact:** LOW — the API exists as described; just clarify the contract.

---

## Weakness 3: No `.pi/` Directory in the Repo

**Location:** Context and Orientation (line 100-101); Milestone 0 (lines 175-176); Milestone 1A (lines 277-278)

**Problem:** The plan describes `.pi/skills` symlink and `.pi/agents/` directory at the project root. But `.pi/` does not currently exist in the repo. The plan mentions creating `.pi/agents/` and symlinks, but `.pi/skills` is listed as if it already exists (line 100-101: `└── .pi/ └── skills -> symlink`). It doesn't.

Additionally, the plan says skills are symlinked at `~/.pi/agent/skills/pi-skills-with-self-analysis`, which is confirmed to exist. But `.pi/agents/` for project-scoped agent discovery is a **different mechanism** — pi-subagents discovers agents from `.pi/agents/` when looking at project scope. The plan needs to ensure this directory is created.

**Recommendation:** Add explicit step to Milestone 0: create `.pi/agents/` directory. Remove the claim that `.pi/skills` exists (it doesn't in the repo; skills are globally symlinked). Be precise about what already exists vs what needs creation.

**Impact:** MEDIUM — the agent definitions won't be discovered if `.pi/agents/` isn't properly set up.

---

## Weakness 4: Session Parsing Assumes Simpler Format Than Reality

**Location:** Milestone 0, `session-parser.ts` description (lines 197-199); Types (lines 494-502)

**Problem:** The plan describes `extractConversationSegments(entries)` as grouping entries by "topic shifts detected by long pauses, user prompts that start new topics, or compaction boundaries." But after examining the actual session JSONL format, several complications are unaddressed:

1. **Session entries include non-message types** like `model_change`, `thinking_level_change`, `label`, `session_info`, `custom`, `custom_message`. The plan's `ConversationSegment` type uses `entries: any[]` which doesn't account for filtering these.

2. **Messages contain encrypted thinking signatures** — large base64 blobs (`thinkingSignature` fields) that can be multi-KB. The `segmentToText()` function needs to strip these, but the plan only mentions "strips base64 images."

3. **Tool call IDs contain encrypted data** — the `toolCallId` fields in real sessions contain pipe-separated encrypted strings, not simple IDs. Parsing these correctly matters for correlating tool calls with results.

4. **Compaction entries** replace earlier messages with a summary. The plan mentions compaction boundaries but doesn't detail how to handle sessions where early context has been compacted — should the analyzer see the compaction summary or the original entries?

**Recommendation:**
- Define explicit filtering: which `SessionEntry.type` values go into segments
- Add `thinkingSignature` stripping to `segmentToText()` spec
- Decide compaction handling: use `getBranch()` (which returns the current branch, post-compaction) vs `getEntries()` (which returns all entries including compacted ones)
- Use `getBranch()` — it gives the current conversation thread, which is what the user experienced

**Impact:** HIGH — without correct parsing, the analyzer subagent will receive garbage (huge base64 blobs consuming its context window).

---

## Weakness 5: Subagent Output Retrieval Is Unspecified

**Location:** Milestone 1A steps 3-4 (lines 229-232); Milestone 1B steps 2-5 (lines 292-302)

**Problem:** The plan says "the handler parses the subagent's response" (line 232) without specifying HOW. The subagent runs in an isolated process. Its output exists in:
1. The subagent's JSONL session file
2. Potentially an output file (if `output` config is set on the agent)
3. As text returned to the calling agent's context via the `subagent` tool

If using `pi.sendUserMessage()`, the response comes back as assistant text in the **main** agent's conversation, not directly to the extension code. The extension cannot programmatically intercept it without event hooks.

**Recommendation:** Specify the exact mechanism:
- **Option A:** Use agent `output` config to write results to a temp file. Extension reads the file after the subagent completes. This is the most reliable approach.
- **Option B:** Use `pi.events` to listen for `subagent:complete` events and extract output from the event data.
- **Option C:** Use `pi.exec()` to run pi in print mode (`pi -p "task" --model ... --skill ...`) and capture stdout.

The plan should pick one and detail it.

**Impact:** HIGH — this is the data pipeline between subagents and the extension.

---

## Weakness 6: No Error Handling Strategy

**Location:** Throughout

**Problem:** The plan describes the happy path only. No discussion of:
- What happens if a subagent fails (non-zero exit, timeout, context overflow)?
- What happens if `ctx.ui.select()` returns `undefined` (user dismissed)?
- What happens if the session is empty or too short for meaningful analysis?
- What happens if the temp file write fails?
- What happens if the skill directory already exists during creation?
- Network errors during LLM calls to the subagent

The "Idempotence and Recovery" section (lines 452-455) is generic — "temp files are cleaned up" — but doesn't address subagent failures.

**Recommendation:** Add an explicit error handling section for each milestone:
- Milestone 0: Session parsing edge cases (empty session, only model_change entries, etc.)
- Milestone 1A: Subagent timeout/failure → notify user, clean up temp files, return gracefully
- Milestone 1B: Partial creation failure → what to clean up? What about partial git commits?
- Universal: all `ctx.ui.*` calls can return `undefined` — always handle the dismiss case

**Impact:** MEDIUM — without error handling, the extension will crash or hang on first failure.

---

## Weakness 7: Milestone 2 Is Severely Under-Specified

**Location:** Milestone 2 (lines 340-409)

**Problem:** Milestone 2 (Skill Improvement) is significantly less detailed than Milestones 0/1A/1B:

1. **"LLM-based behavioral testing"** (line 407) is mentioned but not designed. How do you verify a skill improvement? The plan says "a subagent acts as both the test runner and the verifier" — this is circular and unfalsifiable.

2. **"Skills that should have been invoked but were not"** (line 346) — detecting this requires understanding how Pi's skill activation works (frontmatter description matching). The plan doesn't explain how the analyzer would know which skills *should* have been triggered.

3. **Subagent session reading** (lines 369-372) assumes `custom` entries from pi-subagents contain child session file paths. After examining the actual pi-subagents code, session files are stored in temp directories (`/tmp/pi-subagent-session-*`), and the session paths appear in status files, not directly as custom entries in the parent session.

**Recommendation:** Either:
- Move Milestone 2 to a separate ExecPlan document (it's a different feature)
- Or significantly expand it with the same level of detail as Milestones 0/1A/1B, including concrete session parsing for subagent logs and a realistic testing strategy

**Impact:** MEDIUM — Milestone 2 is deferred, but its under-specification could lead to incorrect assumptions in Milestone 1A/1B architecture.

---

## Weakness 8: `pi.sendUserMessage()` Usage Pattern Is A Conversation Polluter

**Location:** Milestone 1A step 3 (line 229)

**Problem:** Using `pi.sendUserMessage()` injects messages into the main agent's conversation. After `/shrink` runs, the user's session will contain:
- The `/shrink` command
- A synthetic user message like "Call the subagent tool with..."
- The assistant's tool call response
- The subagent's output as a tool result

This pollutes the session log with internal machinery. If the user runs `/shrink` again later, the analyzer will see these meta-messages and potentially try to analyze them as "work" — creating recursive analysis artifacts.

**Recommendation:**
- Use `pi.sendMessage()` with `display: false` for internal communication that should be hidden from the user
- Or better: don't go through the LLM at all — use `pi.exec()` to run subagent processes directly
- Add a filter in `session-parser.ts` to exclude entries related to `/shrink` itself (identify by `customType` or by detecting the pattern)

**Impact:** MEDIUM — degrades user experience and creates feedback loops in analysis.

---

## Weakness 9: Missing Dependencies and Type Safety

**Location:** Interfaces and Dependencies (lines 482-531)

**Problem:**
1. The plan lists `@mariozechner/pi-coding-agent` as a dependency but the extension is loaded by jiti — it imports from the **runtime** Pi, not from a package dependency. There should be no `package.json` dependency on it. Instead, imports should use the types from the globally installed package.

2. The `ConversationSegment.entries` is typed as `any[]` (line 495). The actual session entry types are well-defined (`SessionEntry = SessionMessageEntry | ThinkingLevelChangeEntry | ...`). Using `any[]` throws away type safety.

3. The plan lists `@sinclair/typebox` as a dependency (line 486) "for tool parameter schemas if we register tools." The extension doesn't register tools in Milestones 0-1B — only a command. This is premature.

**Recommendation:**
- Remove `@mariozechner/pi-coding-agent` from package.json dependencies — import types only (available at runtime via jiti)
- Type `entries` as `SessionEntry[]` using imports from the Pi agent
- Remove `@sinclair/typebox` until Milestone 2 if needed
- Clarify that the extension has zero npm dependencies — it's pure TypeScript loaded by jiti

**Impact:** LOW — but getting types right from the start prevents bugs.

---

## Weakness 10: Extension Discovery Path May Be Wrong

**Location:** Context section (lines 103-115)

**Problem:** The plan says extensions are discovered from `~/.pi/agent/extensions/`. But looking at the actual filesystem, `~/.pi/agent/extensions/` does **not exist** on this system. Extensions are installed via npm/pnpm globally. Pi-subagents is at `~/.npm-global/lib/node_modules/pi-subagents/`.

The plan's symlink approach (`ln -sf ... ~/.pi/agent/extensions/pi-shrink`) may not work if Pi doesn't scan that directory. Need to verify how Pi actually discovers extensions.

**Recommendation:** Before implementing, verify the extension discovery mechanism:
- Check Pi's `settings.json` for extension paths
- Check if `~/.pi/agent/extensions/` is a valid discovery path (it may need to be created)
- Consider using `settings.json` `"extensions"` array as the primary discovery method

**Impact:** HIGH — if the extension isn't discovered, nothing works.

---

## Weakness 11: Concrete Steps Section Is Incomplete

**Location:** Concrete Steps (lines 412-437)

**Problem:** Per PLANS.md: "State the exact commands to run and where to run them. When a command generates output, show a short expected transcript." The Concrete Steps section only covers Milestone 0 and says "Steps for subsequent milestones will be elaborated when work begins."

This violates the PLANS.md requirement that the ExecPlan be self-contained and novice-guiding. A novice reading this plan would be blocked after Milestone 0.

**Recommendation:** At minimum, add concrete steps for Milestone 1A (the next milestone). Milestone 1B and 2 can remain high-level since they depend on Milestone 1A outcomes, but document that as an explicit decision.

**Impact:** LOW for now (Milestone 0 is next), but will become HIGH when milestones advance.

---

## Weakness 12: No Consideration of Context Window Limits

**Location:** Milestone 1A (lines 219-280)

**Problem:** The plan serializes the entire session to a temp file for the analyzer subagent. Real sessions can be large (the sample session file I examined had massive entries with encrypted thinking signatures). Even with `segmentToText()` truncation, the serialized text could exceed the subagent's context window.

**Recommendation:**
- Estimate maximum session sizes and set a budget for the serialized text
- If the session is too large, summarize segments before sending to the analyzer (or paginate)
- The analyzer agent should be given `claude-sonnet-4-5` with 200K context, but even that has limits
- Consider sending only stats + segment summaries, not full tool outputs

**Impact:** MEDIUM — large sessions will cause subagent failures.

---

## Summary of Recommendations by Priority

### Must Fix (HIGH impact)
1. **Subagent invocation mechanism** — replace `sendUserMessage()` with direct subprocess execution or event-based output capture
2. **Session parsing completeness** — handle thinking signatures, non-message entries, compaction
3. **Subagent output retrieval** — specify exact mechanism for getting structured results
4. **Extension discovery verification** — validate that symlink-based discovery works

### Should Fix (MEDIUM impact)
5. **Error handling strategy** — add per-milestone failure scenarios
6. **Session pollution** — prevent `/shrink` internals from polluting the session log
7. **Missing `.pi/` directory** — be explicit about what exists vs needs creation
8. **Milestone 2 specification** — either expand or defer to separate plan
9. **Context window limits** — add budgeting for serialized session text

### Nice to Fix (LOW impact)
10. **Type safety** — use proper `SessionEntry` types instead of `any`
11. **Dependencies cleanup** — remove premature/incorrect dependencies
12. **Concrete steps** — expand for Milestone 1A
13. **Editor data flow** — clarify that edited text flows to builder
