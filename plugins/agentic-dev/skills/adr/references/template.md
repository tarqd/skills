# ADR body template (default / Nygard-strict)

This is the canonical body the `new` flow scaffolds when the project
has zero ADRs (no existing convention to detect). Copy it
verbatim, replacing the angle-bracket placeholders.

If the project's existing ADRs already use a different shape, the
detected convention wins; this template is the **default**, not the
mandate.

---

```markdown
# ADR-NNNN: <Title>

**Status:** Proposed

## Context

<One or two paragraphs. What is the problem, what's the current
state, what's driving the decision now. Stick to facts,
constraints, and forces — leave opinions for the Decision and
Alternatives sections.>

## Decision

<One paragraph. State the decision in active voice: "We will do
X." Be specific: what is in, what is out, what configuration
values, what defaults.>

## Alternatives Considered

**<Alternative name>.** <One- or two-sentence summary of the
alternative.> Rejected: <one-sentence rationale>.

**<Alternative name>.** <Summary.> Rejected: <rationale>.

## Consequences

**Positive:**
- <bullet>
- <bullet>

**Negative:**
- <bullet>
- <bullet>

## References

- <ADR cross-link, issue link, or external link>
```

---

## Field-by-field guidance

- **Title.** Imperative, specific, present tense. "Snapshot
  persistence over event sourcing" beats "Use snapshots." Avoid
  generic titles like "Database choice"; name the actual decision.
- **Status.** One of `Proposed`, `Accepted`, `Deprecated`,
  `Rejected`. Use `Superseded` only if the project's status legend
  includes it (then `Deprecated` is reserved for "we don't do this
  anymore but nothing replaces it").
- **Context.** Anchor in observable facts: current code state,
  benchmark numbers, user complaints, constraints from other ADRs.
  Don't say "we should X"; that's the Decision.
- **Decision.** "We will" voice. If the decision has knobs (a
  default, a threshold, a feature flag), name them.
- **Alternatives.** At least one. The Alternatives section is the
  primary audit trail for *why this and not that*; skipping it
  guts the ADR's future value.
- **Consequences.** Both positive and negative. The negatives
  bound the decision — they're what makes a later supersede
  legible.
- **References.** Other ADRs, issues, PRs, external docs. Use
  the project's cross-link shape (default: bullet list with
  `[ADR-NNNN: Title](file.md)` for ADRs).

## When to override the default

The user may want a different style — free-form bold paragraphs,
two-digit numbering, no README. They can:

1. Edit the first ADR manually after scaffolding, OR
2. Tell the skill what to use up front (the `new` flow honors
   user-supplied overrides).

From ADR-0002 onward, convention detection picks up whatever the
user established in ADR-0001.
