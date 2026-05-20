# Phase shapes

One worked phase arc that fits many systems-style projects. **Not a
mandate.** Adapt to what the actual design needs. The arc below is
biased toward "library or framework with persistence, building toward
a demo"; tools, services, and apps will need different shapes.

## The systems-library arc

- **Phase 1 — Minimum skeleton.** Core types/traits, basic happy
  path, no persistence, no IO. Should produce something you can
  import and call. Useful end-state: a `cargo test` / `pnpm test` /
  `pytest` run that exercises the core types in-memory.
- **Phase 2–3 — Persistence and recovery.** Add storage, snapshot /
  load, replay if applicable. The "counter survives restart"
  milestone — the first time the system genuinely *works*. Useful
  end-state: a tiny example binary that increments a counter,
  exits, restarts, and resumes from the saved state.
- **Phase 4 — First demo.** Something you can show someone outside
  the project. Real-looking data, real-looking interactions. May
  involve a UI, a CLI, or a hosted demo. Useful end-state: a
  screen-recorded walkthrough or a deployed URL.
- **Phase 5+ — Polish and secondary features.** Tooling, observability,
  the "wow" demo, secondary integrations, performance work. By here
  the architecture is settled; phases become more parallelizable.

## When this arc doesn't fit

- **CLI tool with no persistence.** Collapse Phases 2–3 into "Phase 2
  — IO and side effects" (file handling, stdin/stdout, exit codes).
  Phase 4 demo is a script someone can run from a fresh clone.
- **Web service.** Phase 1 is request/response with no DB; Phase 2 is
  DB + migrations; Phase 3 is auth; Phase 4 is the first deploy;
  Phase 5+ is observability and scaling.
- **AI app / agent.** Phase 1 is the prompt + tool surface in
  isolation; Phase 2 is wiring to a real model with caching; Phase 3
  is the eval harness; Phase 4 is the deployed demo; Phase 5+ is
  fine-tuning the prompts, expanding tools, cost optimization.
- **Standalone CLI utility / one-off script.** Probably doesn't need
  phases at all — a single PR with the whole feature is fine. If
  you're tempted to write `design` output for a 200-line
  script, the skill is the wrong fit for the work.

## Useful per-phase questions

When drafting each phase, ask:

- **What demonstrable capability exists at the end of this phase
  that didn't before?** Phases should produce things you can run /
  show / point at, not just refactors.
- **What's the smallest thing that unlocks the next phase?**
  Resist scope creep. Move "nice to have" items into a later phase
  even if they're tempting now.
- **What's the failure-mode budget?** Early phases tolerate ugly
  internals; late phases tolerate slow performance; very late
  phases tolerate gaps in tooling. Knowing what's acceptable per
  phase lets the coding agent push back on premature polish.
- **Could a new agent, given the design doc + ADRs + this phase
  doc, start and finish without asking for clarification?** If no,
  the phase doc is underspecified for agent-driven execution.

## Sizing heuristics

- **Tasks per phase:** 3–6 is the sweet spot. More than 7 is
  probably two phases.
- **Days per task:** if any single task would take more than ~3
  days of focused work, it's probably a phase by itself.
- **Acceptance criteria per task:** 2–6 checkboxes. Fewer is
  vague; more is over-specified.
