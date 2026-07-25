# LaTeX Paper Import — Round Trip on a Real Paper

*[ LLM Generated ]*

> Type: investigation
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: "There is the infra causality paper in zip. Can we test converting it to a notebook and back? We could actually also have the generating code for the pictures in the notebook."

`ConvertLaTeXCells` converts *mathematics* — `$…$`, `\(…\)`, `$$…$$`, `\[…\]`, `equation`, `align` — and nothing else.
Document structure is untouched: `\section`, `\begin{theorem}`, `\label`/`\ref`, `\cite`, `thebibliography`, `figure`, and TikZ all pass through as literal text.
So "convert a paper to a notebook and back" is today only true of the formulas in it.

This item measures that honestly against a real paper — `Axiomatic_Relativity_from_Causal_Graphs.zip` in the repo root, with `hodgepaper.tex` as a second specimen — and then closes the gap between "math converter" and "paper importer", far enough that a submitted paper opens as a working notebook and comes back out as compilable LaTeX.
The figures are the interesting half: rather than importing TikZ as an opaque picture, the notebook should carry the Wolfram code that *generates* each figure, with the rendered graphic as its output, so the picture stays live and the paper stays reproducible.

Done when the paper round-trips with its sectioning, theorem environments, cross-references, and bibliography intact, the diff against the original source is understood line by line, and at least one figure is regenerated from code in the notebook.

### Requirements

- A baseline report first: convert as-is, and record exactly what survives, what is mangled, and what is dropped. No implementation before that report exists.
- Sectioning: `\section`/`\subsection`/`\subsubsection` → the corresponding cell styles, and back.
- Theorem-like environments → the twelve environment styles the stylesheets define, and back to the same environment names the source used.
- `\label` → cell tags; `\ref`/`\eqref` → the palette's live reference buttons; back out to `\label`/`\ref` with the original keys.
- `\cite` → `Citation` buttons; `thebibliography` (or the `.bib`) → `Reference` cells; and back.
- Figures: TikZ source preserved verbatim for the return trip, plus an `Input` cell holding Wolfram code that produces the same picture, its graphic as output.
- Round trip is *lossless where claimed*: whatever the importer converts, the exporter must return to compilable source, and the pipeline must be able to say what it could not handle rather than silently passing it through.

### Design / API

The existing pure-core convention holds: functions on `Notebook` expressions, thin `NotebookGet`/`NotebookPut` wrappers, so all of it is headless-testable.
The importer is a second layer above the current math conversion, not a rewrite of it — `convertLaTeXCell` stays the math primitive.

```
ImportLaTeXDocument[ "paper.tex" ]        (* → Notebook *)
ExportLaTeXDocument[ notebook, "paper.tex" ]
```

Unconverted constructs stay in the notebook as tagged Text cells so the exporter can put them back untouched.

### Edge cases & out of scope

- Preambles are project-specific: custom macros (`\newcommand`), `\usepackage`, theorem declarations. The preamble should probably be carried in the notebook's tagging rules and re-emitted verbatim rather than interpreted.
- `align` currently becomes a `GridBox`; multi-line environments with `\intertext`, `cases`, `split`, and `array` need deciding.
- Numbering must match: LaTeX numbers theorems per section from the source order, the stylesheets number by counters — the same document must produce the same numbers on both sides.
- Out of scope: BibTeX processing beyond reading entries, and full TikZ-to-Graphics translation (the generating code is written by hand or by an LLM, not parsed out of TikZ).

## Tasks

- [ ] T1 — Baseline: unzip the paper, convert with today's pipeline, convert back, diff against the source, and write the gap report into this item's Progress.
- [ ] T2 — Sectioning and theorem environments, both directions, with tests.
- [ ] T3 — `\label`/`\ref`/`\eqref` ↔ cell tags and reference buttons.
- [ ] T4 — Citations and bibliography ↔ `Citation`/`Reference` cells.
- [ ] T5 — Figures: preserve TikZ, add generating Wolfram code with rendered output, for one real figure of the paper.
- [ ] T6 — Make the paper a round-trip test fixture under `MathNotebook/Tests/`.

### Done

(completed tasks move here with the session that closed them)

## Progress

(no sessions yet)

## Decisions

| Date | Decision | Rationale |
|---|---|---|
