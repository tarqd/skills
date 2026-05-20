# ADR convention detection

Every `adr` operation runs this first. The goal is to extract the
project's existing conventions so the operation conforms exactly.
Never invent. Never fall back to a generic template if the project
already has ADRs.

## What to extract

1. ADR directory path.
2. Filename pattern (number width, prefix, slug separator).
3. Header line shape.
4. Section template (Nygard-strict vs. free-form bold paragraphs).
5. Index format (is there a `README.md`, what does an entry look like).
6. Status legend (which strings are in use).
7. Reference / cross-link line shape.

## How to detect each

### 1. Directory path

Probe in this order; first match wins:

- `docs/adr/`
- `docs/architecture/decisions/`
- `doc/adr/`
- `adr/`

### 2. Filename pattern

List ADR files (exclude `README.md`, `TEMPLATE.md`, and anything not
starting with a digit or the literal `adr`). Examples seen in
practice:

| Pattern         | Example                            |
| --------------- | ---------------------------------- |
| `NNNN-slug.md`  | `0014-postcard.md`                 |
| `adr-NN-slug.md`| `adr-14-suspend-on-pending.md`     |
| `NN-slug.md`    | `14-postcard.md`                   |

Capture: literal prefix (or none), number width, separator before
slug. The pattern of the **lexicographically last** ADR file is
authoritative — newer ADRs reflect current convention.

### 3. Header line shape

Read the first non-blank line of the most-recently-edited ADR
(`ls -t <dir>` or `git log -1 --format=%H -- <file>`). Match one of:

- `# ADR-NNNN: Title` — colon separator
- `# ADR-NN — Title` — em-dash separator (sometimes uses
  non-breaking hyphen `‑` rather than `-`; preserve the exact byte)
- `# NN. Title` — Nygard original
- `# Title (ADR-NN)` — title-first

Record the exact separator character(s).

### 4. Section template

Read the top ~40 lines. Two common shapes:

**Nygard-strict.** Sections as H2 headers:

```
## Context
## Decision
## Alternatives Considered
## Consequences
```

Sometimes with `### Positive` / `### Negative` subheads inside
Consequences. Status is a separate line near the top:
`**Status:** Accepted`.

**Free-form / inline.** Paragraphs led by a bold marker with a
period:

```
**Decision.** ...
**Why.** ...
**Out of scope.** ...
**Open questions.** ...
**Migration.** ...
**References.** ...
```

Status is often combined with context: `**Status:** Proposed.
Builds on ADR-N…`.

If both styles appear across ADRs, use the style of the
most-recently-edited one. If the most-recent is too thin to tell,
fall back to the second-most-recent.

### 5. Index format

Check for `<adr-dir>/README.md`. If present, read the index entries
to learn the exact line shape. Examples:

```
- [ADR-NNNN: Title](file.md) — one-line summary.
- ADR-NN — Title (file.md)
- [NN](file.md) Title
```

Match the dash style, link format, summary placement.

If no README exists, **do not create one** as a side effect of
`new`. The project chose not to have one.

### 6. Status legend

Default: Proposed / Accepted / Deprecated / Rejected. If the README
has a "Status legend" section, use those exact labels.

Some projects also use **Superseded** as a distinct status from
Deprecated; check the README. If neither label is documented but
existing ADRs use one of them, follow what the existing ADRs do.
When in doubt, default to `Deprecated` for the superseder-target.

### 7. Reference / cross-link line shape

Read one ADR that has a References section (ideally a recent one
with multiple links). Capture:

- Bullet style (`- `, `* `, or prose with no bullets).
- Link format: `[ADR-N: Title](file.md)`, `ADR-N`, or `[file.md]`.
- Whether issue / PR references appear as `#N`, `https://...`, or
  spelled out.

`Supersedes` / `Superseded by` lines follow this same shape.

## When the project has zero ADRs

**Use the plugin default** (Nygard-strict, four-digit numbering, with
a README index). Don't ask. The default is:

- **Filename:** `NNNN-slug.md` — 4-digit zero-padded number, no
  prefix, hyphen-separated lowercase slug.
  Example: `0001-snapshot-persistence.md`.
- **Header:** `# ADR-NNNN: Title` — colon separator, full 4-digit
  number.
- **Status line:** `**Status:** Proposed` — separate line near the
  top, blank line before and after.
- **Sections:** Nygard-strict — `## Context`, `## Decision`,
  `## Alternatives Considered`, `## Consequences` (with
  `**Positive:**` and `**Negative:**` subheads), `## References`.
- **README index:** create `<adr-dir>/README.md` with an index
  section (one bullet per ADR) and a status legend (Proposed /
  Accepted / Deprecated / Rejected).
- **Cross-link line shape:**
  `- [ADR-NNNN: Title](file.md) — one-line summary.`
- **Reference list shape:** bullet list (`- `).

The canonical body template lives in [`template.md`](template.md);
the `new` flow copies from there.

**The user can override** by either:

1. Editing the first ADR manually after scaffolding (the cleanest
   move — convention detection will pick up whatever they chose
   from ADR-0002 onward), or
2. Supplying an explicit override at the time of the `new` call
   (the `new` flow honors user-supplied filename pattern / section
   template choices).

Do not ask up front. The default works for the common case; the
user's first action after seeing it is the override hook.

## Cache

Whatever the operation does next, cache the detected values for the
run. Do not re-detect per step. The cache is invalidated only by a
new `adr` invocation.
