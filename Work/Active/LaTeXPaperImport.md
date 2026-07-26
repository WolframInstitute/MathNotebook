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

- [ ] T2 — Sectioning and theorem environments, both directions, with tests.
- [ ] T3 — `\label`/`\ref`/`\eqref` ↔ cell tags and reference buttons.
- [ ] T4 — Citations and bibliography ↔ `Citation`/`Reference` cells.
- [ ] T5 — Figures: preserve TikZ, add generating Wolfram code with rendered output, for one real figure of the paper.
- [ ] T6 — Make the paper a round-trip test fixture under `MathNotebook/Tests/`.

### Done

- [x] T1 — Baseline: unzip the paper, convert with today's pipeline, convert back, diff against the source, and write the gap report into this item's Progress. *(Session 1)*

## Progress

### Session 1 — 2026-07-26 — T1

- **Prompt:** work the backlog autonomously overnight, committing after each task.
- **Did:** The baseline report the Spec demands before any implementation.
  `main.tex` is 496 lines, 105 body paragraphs, imported the way the tutorial describes — paste as `Text` cells, then `convertLaTeXNotebook` and `convertMathNotebook` back.

  **The round trip is byte-identical.** All 105 paragraphs come back exactly as they went in.
  Nothing the converter touches is lost, and everything it does not touch passes through verbatim, so importing and re-exporting this paper today is safe — it simply does very little.

  **Structure: nothing is converted, as the Spec predicted.** Literal text on both sides: 8 `\section`, 11 `\subsection`, 32 theorem-like environments, 7 `figure`, 12 lists, 25 `\label`, 5 `\ref`, 9 `\cite`, 7 `\includegraphics`. That is T2–T5.

  **The paper's theorem environments are not the paclet's.** It declares its own — `\newtheorem{defn}{Definition}[subsection]`, and likewise `axiom`, `thm`, `constr` — and uses `defn` 20 times, `axiom` 10, `constr` 2. Two consequences for T2: the source names are arbitrary, so the mapping has to be read out of the `\newtheorem` declarations rather than from a fixed table of twelve English names; and `axiom` has no counterpart among the twelve at all. The `[subsection]` argument also numbers them per *subsection*, where the stylesheets number per section — the Spec's "numbering must match" requirement is already violated by the first real specimen.

  **Three defects in the existing math converter**, found by measuring rather than by reading, filed as [Inline Math Converter Defects](../Backlog/InlineMathConverterDefects.md) because they are bugs in shipped behaviour, not import gaps. They should be fixed before T2, since T2 builds on this layer:
  1. `texToBoxes` answers `$Failed` on any fragment containing a **comma** — `"a, b"`, `"(a, b)"`, `"x_1, x_2"` — so the span is left as literal `$…$`. This is the whole of the paper's unconverted inline math: 35 of 238 spans, 15%, and every single leftover contains a comma.
  2. **`equation*` is not recognised at all**, even as an entire cell, while `equation` becomes `DisplayFormulaNumbered`. Both of this paper's display equations are starred, so 100% of its display math is missed — and the tutorial claims the starred forms convert and stay unnumbered. `$$…$$` inside a paragraph *does* split correctly, so the machinery exists.
  3. `texToBoxes["E"]` and `texToBoxes["I"]` return an **empty box**: WL's protected symbols for 2.718… and the imaginary unit swallow the letter. The paper writes `$E$` for its hyperedge set, which therefore renders as a blank. The round trip still recovers it from the stored `"SourceTeX"`, which is exactly why this did not show up in the diff — it is invisible on paper and visible on screen.

  **Preamble:** 103 lines, 45 `\newcommand`, 26 `\usepackage`. Confirms the Spec's instinct to carry it verbatim in tagging rules rather than interpret it.

  **Figures:** all 7 are `\includegraphics` of PNGs shipped in the zip, not TikZ. So T5's "preserve the TikZ source" has no work to do on this specimen; the generating-code half is the whole of it, and `hodgepaper.tex` should be checked for actual TikZ before T5 is scoped.
- **Learned:**
  - Measuring the converter by `Head[texToBoxes[tex]] === String` is wrong twice over, and I made both mistakes before catching them: a successful parse of an atom returns a String (`"V"` → `"V"`), and a successful parse of `\mathcal{H}` returns the *one-character* string `"\[ScriptCapitalH]"`. The honest test for a failed parse is a backslash surviving into the output, or `$Failed`.
  - A byte-identical round trip is a much weaker signal than it looks. Defect 3 above is invisible to it, because the exporter reads back the stored `"SourceTeX"` rather than the boxes, so a cell that renders as a blank still exports perfectly. Round-trip fidelity and display fidelity have to be measured separately.
- **Next:** the converter defects above, then T2 — sectioning and theorem environments.

## Decisions

| Date | Decision | Rationale |
|---|---|---|
