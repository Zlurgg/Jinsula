---
description: End a Jinsula session — rewrite KICKOFF.md clean, update memory, commit + push
---

End-of-session ritual for Jinsula:

1. **Rewrite `KICKOFF.md` from scratch** (it's a brief, not a log — clear out anything done or stale). Keep this structure:
   - `## State` — 2-4 bullets: what's true now (what got built/decided this session folds in here)
   - `## Next session — pick one` — small list of candidate topics
   - `## Load in` — for each candidate topic, the exact files/sections to read (repo paths, SPEC.md sections). This is the efficiency path — be specific.
   - `## Open questions` — only ones still open; delete answered ones
2. **Update CLAUDE.md only if a stable fact changed** (architecture decision, constraint, design rule, layout change). Keep it small and tight — if it's session state, it belongs in KICKOFF, not CLAUDE.md.
3. **Update SPEC.md** if a durable decision or plan was produced this session (e.g. a screen plan). SPEC.md is the durable record; KICKOFF is disposable.
4. **Update memory**: fold new decisions into existing Jinsula memory files; don't create duplicates.
5. **Commit and push**: stage the session's changes with a concise message describing what the session accomplished, then `git push`.
6. Confirm to the user in 2-3 lines: what was persisted, what the next session's default topic is.
