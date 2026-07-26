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

- [ ] T7 — Display math and nested environments *inside* a theorem-like environment body. T2 deliberately runs only the inline converter there, since an environment has to stay one cell; on `hodgepaper.tex` that leaves 53 `equation`/`align` blocks and two nested `sublemma*` as literal source inside otherwise converted cells.
- [ ] T8 — Front matter: `\title`, `\author`, `\date`, `\maketitle`, `abstract` → the `Title`/`Author`/`Date`/`Abstract` styles the stylesheets define, and lists (`itemize`, `enumerate`, `description`) → the `Item` family.
- [ ] T9 — Numbering. The Spec's "numbering must match" is measurably violated: the causal-graphs paper declares `\newtheorem{defn}{Definition}[subsection]` and numbers per subsection, while the imported notebook renders `Axiom 3.2`, `Definition 3.5` — per section, from the stylesheet's counters.
- [ ] T10 — `thebibliography` written into the `.tex` ↔ `Reference` cells, and a report when a declared `.bib` is missing. T4 does the `.bib` route, which both specimens use; an in-source bibliography needs a per-item source and separator on each cell inside one environment wrapper, which is the same design problem as T7.
- [ ] T11 — An imported paper opens with its environments live. `latexToNotebook` sets no `StyleDefinitions` at all, so a fresh import lands on `Default.nb`, where the twelve environment styles do not exist and a reference reads `2.0`. Two halves: a fifth stylesheet that is `Default.nb` plus the environments — same base cell list, Default's typography, contributing only the environment/`Caption`/`Reference`/`Citation` styles and their counters — and `ImportLaTeXDocument` choosing a sheet from the source's `\documentclass` (`amsart` → `AMSArticle`, `revtex` → `RevTeXAPS`, else the new one). What must *not* be done is writing `CounterIncrements`/`CellDingbat` onto each cell to survive any sheet: per-cell options beat the sheet, so swapping sheets to retarget a journal would stop working, and that is the paclet's whole point. *(Pavel's question, Session 6)*
- [ ] T12 — `FrontEnd.wlt`'s T2 display-ink test compares two measurement scales and fails at HEAD. `Starred` (7742) comes from a whole-notebook PNG render and `Literal` (2440) from a single-cell `Rasterize`, so `Starred < Literal` cannot hold; the clause beside it, `Starred < Unstarred` (56959), is sound and passes. Measure both sides the same way, or drop the clause — `Formula > 0` already says the formula renders. *(Found in Session 6, pre-existing)*

### Done

- [x] T1 — Baseline: unzip the paper, convert with today's pipeline, convert back, diff against the source, and write the gap report into this item's Progress. *(Session 1)*
- [x] T2 — Sectioning and theorem environments, both directions, with tests. *(Session 2)*
- [x] T3 — `\label`/`\ref`/`\eqref` ↔ cell tags and reference buttons. *(Session 3)*
- [x] T4 — Citations and bibliography ↔ `Citation`/`Reference` cells. *(Session 4)*
- [x] T5 — Figures: preserve TikZ, add generating Wolfram code with rendered output, for one real figure of the paper. *(Session 5)*
- [x] T6 — Make both papers round-trip test fixtures under `MathNotebook/Tests/`. T2 already gets a byte-identical round trip on each; the fixture pins it. *(Session 6)*

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

### Session 2 — 2026-07-26 — T2

- **Prompt:** `/next-session` continued — keep working the items, now that the three converter defects are fixed and this one is unblocked.
- **Did:** Built the document layer, `Kernel/Document.wl`, and the API the Spec asks for: `ImportLaTeXDocument["paper.tex"]` and `ExportLaTeXDocument[notebook]`.

  **Both papers round-trip byte-identically, with their structure converted.**

  | | causal graphs | hodgepaper |
  |---|---|---|
  | source | 496 lines | 1745 lines |
  | cells | 109 | 172 |
  | sectioning | 8 `Section`, 11 `Subsection` | 6 `Section` |
  | environments | 20 `Definition`, 10 `Theorem` (Axiom), 2 `Construction` | 15 `Definition`, 12 `Proof`, 11 `Remark`, 10 `Lemma`, 8 `Example`, 7 `Theorem`, 5 `Proposition` |
  | round trip | identical | identical |

  T1's baseline was byte-identical too, but only because *nothing* was converted; this is byte-identical with 32 and 68 environments respectively turned into real cells.

  **The environment map is read out of the preamble, not from a table of English names.**
  T1 measured that the specimen declares its own — `defn`, `axiom`, `thm`, `constr` — so a fixed table would have matched none of them.
  All three `\newtheorem` forms are read, including the starred one and the shared-counter `\newtheorem{cor}[thm]{Corollary}`; the amsthm defaults (the twelve style names, lowercased, plus `proof`) are the fallback.

  **`Axiom` is not one of the twelve, and is not left as text.**
  It is written as a `Theorem` — which numbers it with them — carrying a `CellDingbat` that says `Axiom`.
  Verified on the page, not just in the boxes: the imported notebook exports to a **7-page PDF whose text contains `Axiom 3.2`, `Definition 3.5`, `Construction 4.1`** — 10, 20 and 2 of them, every environment in the paper numbered.

  **What makes the round trip exact** is that every cell records the whitespace that followed it in the source, under a `"Separator"` tagging rule, and the export is then a plain `StringJoin`.
  Riffling with `"\n\n"` instead was 7 diff lines on the first paper and 38 on the second: the papers separate blocks with two newlines in most places, three in two of them, one before a `\section` that follows `\tableofcontents` directly, and one around a display equation lifted out of a paragraph.
  Indentation is recorded the same way — the opening `\begin`, the body, and the closing `\end` each keep their own, which is what the second paper's tab-indented `\end{proof}` needed.
- **Learned:**
  - **A string pattern will not take a back-reference to a named `Alternatives`.** `"\\begin{" ~~ name : (a|b|c) ~~ "}" ~~ … ~~ "\\end{" ~~ name ~~ "}"` answers `StringExpression::invld` — it does not simply fail to match, it is not a valid pattern. One rule per environment name, with the name written literally into both delimiters, is the way; and it is also what keeps `\begin{figure}` from being matched.
  - **Anchor structural delimiters to `StartOfLine`.** Without it `%\begin{example}` is matched inside its own comment, and the commented-out block becomes a live cell — which `hodgepaper.tex` has, twice. `StartOfLine` also gives the indentation for free.
  - **`First @ StringCases[s, rule, default]` puts the default inside `StringCases`**, where it is read as the match count. Three separate bugs in this session, each silent: the function returns unevaluated and the caller's `Module` destructuring then leaves symbolic values everywhere. Write `First[ StringCases[...], default ]`.
  - Calling `mergeStrings` from a second file cost twenty minutes — it is the `PackageScope` trap `CLAUDE.md` documents, and it presents as *content silently vanishing*: 86 of 171 cells disappeared and the export halved in length, with no message.
  - The document layer composes `splitDisplayMath` and `splitInlineMath` rather than `convertLaTeXCell`, because that function trims the whitespace around a display equation it lifts out and here the whitespace is exactly what must survive. The Spec's "`convertLaTeXCell` stays the math primitive" is honoured one level down.
- **Next:** T3 — `\label`/`\ref`/`\eqref`. Every label is already sitting in a `"Trailing"` tagging rule waiting to be read.

### Session 3 — 2026-07-26 — T3

- **Prompt:** `/next-session` continued.
- **Did:** `\label` → `CellTags`, `\ref`/`\eqref` → the front end's own cross-reference, both directions, with the round trip still exact on both papers.

  | | causal graphs | hodgepaper |
  |---|---|---|
  | `\label` → `CellTags` | 18 of 25 | 60 of 92 |
  | `\ref` / `\eqref` → buttons | 1 of 5 | 119 of 191 |
  | round trip | identical | identical |

  **What is not converted is exactly what has no cell to point at**, and it is left as literal source rather than rendered wrong.
  The causal paper's 7 unclaimed labels and 4 unconverted `\ref`s are all `fig:` — figures are T5.
  Hodge's 32 unclaimed labels and 72 unconverted references are all `Eq:` — its equations sit *inside* theorem environments, which T2 deliberately leaves as one cell, so they never became `DisplayFormulaNumbered` cells. That is T7, and this is the measurement of what T7 is worth.

  **A reference is a `CounterBox` chain, not text.**
  `\ref` becomes the bare chain for the target's style — `CounterBox["Section", key]` for a section, `Section.Theorem` for a theorem-like environment — and `\eqref` the same in parentheses, which is what the two commands print in LaTeX.
  No prefix: authors write `Theorem~\ref{Thm:2}`, so `citationButton`'s `"Theorem "` prefix would say the word twice.
  Which command it was is recovered on the way out from whether the box is parenthesised, so `\ref` and `\eqref` both come back as themselves.

  **Verified on the page.** The imported hodgepaper renders as a **25-page PDF with zero `XXX`** — the front end's rendering of an unresolvable tag — and its prose reads `Definition~3.15` where the source wrote `Definition~\ref{Def:dPDModel}`, with 49 parenthesised equation references.

  **The tag is the origin of the exported `\label`, not a mirror of it.** The label is taken out of the stored trailing source and written back from `CellTags`, so retagging a cell in the notebook changes the `\label` that comes out — asserted by a test. The one exception is a label inside a display equation, which is re-emitted from the stored `"SourceTeX"`; there the tag is a read-only mirror.

  **Tests.** Five in `Tests/Document.wlt` and one in `Tests/FrontEnd.wlt`; 130 pass. Reintroducing the defect fails 4 and 1 respectively.
- **Learned:**
  - A `Definition` cell numbers itself only under a MathNotebook stylesheet — the counter lives in `CounterIncrements` on the *style*. Rendered on `Default.nb` the same document reads `Definition~2.0`, which looks exactly like a broken reference and is not one. Any front-end test of numbering has to install the sheet.
  - LaTeX's `~` survives into the notebook as a literal tilde, so imported prose reads `Definition~3.15` on the page. Turning it into a non-breaking space would improve the rendering and would have to be recorded to keep the round trip; not done, and worth a task if the rendering matters.
- **Next:** T4 — citations and bibliography.

### Session 4 — 2026-07-26 — T4

- **Prompt:** `/next-session` continued.
- **Did:** `\cite` → `Citation` buttons and the `.bib` → `Reference` cells, both directions, with the round trip still exact on both papers.

  | | causal graphs | hodgepaper |
  |---|---|---|
  | `\cite` → buttons | 9 of 9 | 78 of 80 |
  | bibliography | 14 `Reference` cells | none — no `.bib` shipped |
  | round trip | identical | identical |

  **A citation converts unconditionally, unlike a reference.**
  T3 left a `\ref` as literal source when no cell carried the key, because a `CounterBox` on an unknown tag renders the front end's `XXX`.
  A citation's label is literal text — `referenceLabel`'s `[key]`, the same string a `Reference` cell's dingbat shows — so it is right whether or not the paper has a bibliography, which is the whole of hodgepaper's 78.
  The two hodgepaper citations left as source are both inside an environment's optional title (`\begin{lemma}[{\cite[Lemma~11.1]{Cieliebak2015},\cite{triplepaper}}]`), which T2 stores verbatim and never renders.

  **The verbatim brace content rides along as the `ButtonData`**, which is both what `NotebookLocate` navigates by and what the exporter writes back, so `\cite{first, second}` and `\cite{first,second}` come back as themselves.
  An optional argument is rendered after the keys, and the exporter counts the keys to tell `[a, b]` (two keys) from `[a, note]` (one key and a note) — the same shape of recovery as T3's parenthesised `\eqref`.

  **The bibliography is the one block of a paper whose content is not in the `.tex` at all.**
  The source says `\bibliography{references}` and the entries live in a `.bib`, so the commands become the `Reference` cells of the entries the paper cites and the **last** cell of the block carries the commands verbatim while the rest carry a `"Suppressed"` rule and emit nothing.
  Only the cited keys become cells — three of the specimen's seventeen entries are never cited — in the order of the `.bib` rather than the order the bibliography style would sort them.
  Where the `.bib` is missing the rule is not built at all, so hodgepaper is byte-for-byte what it was before this session.

  **Verified on the page.** The imported causal paper renders as an **8-page PDF** (7 before this session) whose last page is the bibliography, each entry under its own `[key]` dingbat, with `Jürgen Ehlers` and `1587–1609` drawn as characters, `[marzke1959measurement, marzke1964gravitation]` as one two-key citation label, no `XXX`, no literal `\cite`, and no uncited key.

  **Tests.** Five in `Tests/Document.wlt` and one in `Tests/FrontEnd.wlt`; 137 pass.
  Reintroducing three separate defects — dropping the suppression, splitting `.bib` fields on every comma, and converting no citations — fails 2, 2, and 12+2 respectively.
- **Learned:**
  - **A `.bib` field cannot be found by a string pattern.** A value holds both the comma that separates fields and the braces that end the entry (`title={A first paper, with a comma}`), so the split has to be at the commas standing at brace depth zero, and the entry has to end at the brace where the running depth first reaches −1. `Accumulate` over the brace characters gives both in one pass.
  - **Six of the Wolfram named characters an accent table wants do not exist**: `\[NAcute]`, `\[SAcute]`, `\[ZAcute]`, `\[IBar]`, `\[OBar]`, `\[UBar]` print as their own literal name, while their neighbours (`\[CAcute]`, `\[ABar]`, every hacek and cedilla tried) are real. A table like this has to be swept in the kernel, not assumed from the pattern of the names that do work.
  - **In a string pattern `~~` binds loosest and `:` binds tightest**, so `optional : ( … ) | "" ~~ rest` is `StringExpression[Pattern[optional, Alternatives[…, ""]], rest]` and not, as it reads, an `Alternatives` over the whole pattern. I assumed the opposite and would have "fixed" the T2 environment rule.
  - **A defect-reintroduction check is worthless until you confirm the patch landed.** One of my three `perl` edits silently matched nothing, and the suite came back green — which reads exactly like "the test does not bite". Print the changed line before believing the result.
- **Next:** T5 — figures: preserve TikZ, add generating Wolfram code with rendered output. Two things this session deliberately left: a missing `.bib` is dropped silently rather than reported (the Spec's "say what it could not handle"), and `thebibliography` written into the `.tex` is not imported — neither specimen has one, and it needs its own per-item separator design, so it is filed as T10.

### Session 5 — 2026-07-26 — T5

- **Prompt:** `/next-session` continued.
- **Did:** A `figure` becomes the code that draws it plus a `Caption` cell, and one figure of the paper is regenerated from Wolfram code.

  | | causal graphs | hodgepaper |
  |---|---|---|
  | `figure` → cells | 7 → 7 `Input` + 7 `Caption` | none — no figures |
  | `\label{fig:…}` → `CellTags` | 7 of 7 | — |
  | `\ref{fig:…}` → counters | 4 of 4 | — |
  | round trip | identical | identical |

  T3 left the causal paper's 7 labels and 4 references unconverted because they were all `fig:` and no cell carried the key.
  All of them convert now, and the paper's remaining literal `\ref` count is **zero**.

  **The caption is the cell; the picture's markup is the tagging rule.**
  Everything up to and including `\caption{` rides in a `"FigurePrefix"` rule and everything from its closing brace on rides in `"Trailing"`, where `labelledCell` finds the `\label` and turns it into the cell's tag exactly as it does for a section.
  So editing a caption in the notebook reaches the `.tex` — unlike a bibliography entry, which cannot — while `\centering`, the `\includegraphics` options and a whole `tikzpicture` are returned untouched.
  That is what makes the Spec's "TikZ source preserved verbatim" true without translating TikZ: neither specimen has any, so it is asserted on a synthetic figure instead.
  A figure with no caption owns nothing and re-emits its whole source from `"FigureTeX"`.

  **The generating code is the notebook's alone.**
  Each `\includegraphics` becomes an `Input` cell holding `Import[FileNameJoin[{NotebookDirectory[], "spatial_hg.png"}]]` — code that produces that picture, for the author to replace with the code that generates it — and the whole evaluation family (`Input`, `Output`, `Code`, `Print`, `Message`, `Echo`) emits nothing into the `.tex`.
  Replacing the causal-graph figure's cell with
  ```wolfram
  Needs[ "SetReplace`" ];
  Graph[
    WolframModel[ { { 1, 2 }, { 1, 3 } } -> { { 3, 4 }, { 4, 1 }, { 2, 4 } }, { { 1, 1 }, { 1, 1 } }, 8,
      "CausalGraph" ],
    GraphLayout -> "LayeredDigraphEmbedding", VertexStyle -> RGBColor[ 0.62, 0.76, 0.89 ],
    EdgeStyle -> RGBColor[ 0.72, 0.66, 0.80 ], VertexSize -> 0.4, ImageSize -> 340 ]
  ```
  and evaluating gives **7 `GraphicsBox`es for 6 rasters** — the six shipped PNGs plus one live causal graph, 13 events and 24 edges, which is the object Figure 3 of the paper depicts — and the export is still the source byte for byte.
  The Spec's "at least one figure is regenerated from code in the notebook" is met; what does *not* happen is the reverse, since the exporter writes the original `\includegraphics` back rather than rasterizing the code into a new PNG.

  **A `Caption` style was added to all five stylesheets**, numbering itself from its own counter — `article` counts figures straight through the document, and neither specimen declares `\numberwithin{figure}{section}` — with `$referenceLabelSpec` extended so the palette's own buttons read `Figure 3` too.

  **Verified on the page.** The imported causal paper renders as a **10-page PDF** (8 before this session) carrying `Figure 1`–`Figure 7`, all 32 environments still numbered, no `XXX`, and no literal `\cite`, `\ref` or `includegraphics` anywhere in the text.

  **A defect the whole importer had, found by being the first session to save the notebook.** The front end splits a `ButtonBox[RowBox[…]]` inside a `TextData` into one button per run when a notebook is written to disk and opened again — `CLAUDE.md` records this of `NotebookWrite`, and it is not only `NotebookWrite`. So the specimen's 14 buttons came back as 46, `\cite{first, second}` exported five `\cite` commands and the 7-key citation fifteen, and `\eqref{eq:a}` came back as `\cite{eq:a}\ref{eq:a}\cite{eq:a}` — the parentheses had been carried off into buttons of their own, so the counter no longer looked parenthesised and the brackets no longer looked like references at all. Consecutive buttons on one key are now merged before anything reads them, and the saved-and-reopened paper round-trips exactly. T2–T4's central claim held only for a notebook nobody had saved.

  **Tests.** Four in `Tests/Document.wlt` and two in `Tests/FrontEnd.wlt`; 147 pass.
  Reintroducing two defects — dropping the figure rules, and dropping the button merge — fails 5+1 and 1+1 respectively.
- **Learned:**
  - **`NotebookEvaluate` inside `UsingFrontEnd` hangs.** The front end's evaluator is the same kernel that is driving it, so asking it to evaluate a notebook deadlocks; it sat for ten minutes with no output and had to be killed. Put the `Output` cell in kernel-side with `ToBoxes` instead — which is also what makes the assertion cheap.
  - **Byte-identical round trips measured in one kernel do not survive a file.** Every earlier session compared `notebookToLaTeX @ latexToNotebook[source]`, which never touches the front end; the button-splitting defect above was invisible to all of it and is a *bug in shipped behaviour*, not an import gap. Any fidelity claim about a notebook has to go through `Export`/`NotebookOpen`/`NotebookGet` at least once.
  - The front end also **groups** the reopened cells into `CellGroupData` and reads 130 cells back as 11 at top level. That one is harmless — `notebookCellList` already flattens — but it makes a naive `Cases[…, Cell[_, style_String, ___]]` on a reopened notebook report almost nothing.
  - `Cases` on a `Notebook` defaults to level 1, where the only elements are the cell *list* and the options; every count of cells in a probe needs `Infinity` or `First`. Cost one demonstration run that reported the generating code was not installed when it was.
  - `WolframModel` takes no `VertexStyle`/`EdgeStyle`; it warns `optx` and returns unevaluated, so the figure silently came out as no graphic at all. Wrap the result in `Graph[…, opts]`.
  - `pkill -f wolframscript` is not safe on this machine: Pavel had three long-running scripts of his own going, and a broad kill reached whatever was running. Scope a kill to the script name.
- **Next:** T6 — make both papers round-trip test fixtures under `MathNotebook/Tests/`.

### Session 6 — 2026-07-26 — T6

- **Prompt:** `/next-session` continued.
- **Did:** Both papers are round-trip fixtures — `MathNotebook/Tests/Specimens.wlt`, ten tests, five per paper, and the suite is 157.

  | | causal graphs | hodgepaper |
  |---|---|---|
  | cells | 130 | 172 |
  | source bytes | 36656 | 142877 |
  | tagged cells | 39 | 60 |
  | citation and reference buttons | 14 | 197 |
  | counters | 25 | 222 |
  | literal `\ref` left in the prose | 0 | 72 |
  | literal `equation`/`align` left | 0 | 55 |
  | export is the source | yes | yes |
  | written file is the source | yes | yes |

  **Neither paper is in the repo, and that was Pavel's call.**
  One is an unpublished draft with two co-authors and not on arXiv, the other a published paper of his, and neither is the paclet's to redistribute — and `PublishPaclet.wls` stages `Tests/`, so anything put there ships.
  So the fixture *finds* its specimens instead of carrying them: `MATHNOTEBOOK_SPECIMENS`, else the parent of `PacletObject["WolframInstitute/MathNotebook"]["Location"]`, which is the repo root exactly when the paclet is loaded from the working tree.
  A paper it cannot find gets no tests at all rather than green ones, and a printed notice names what was missing — verified by pointing the variable at an empty directory: 0 passed, 0 failed, notice shown.
  Installed from an archive, the file finds nothing and asserts nothing.

  **The byte round trip and the structure census are independent detectors, and the fixture needs both.**
  Two complementary bites prove it: dropping `figureRules[]` from `structureRules` fails three of the causal paper's five tests — cells and styles, tags and counters, and what is still literal — while **the round trip stays byte-identical**, because the figure source is carried verbatim either way.
  Forcing `cellSeparator` to `"\n\n"` fails exactly the other four — both papers' round trips — and leaves every census test passing.
  So a converter can regress with the bytes intact, which is the same lesson as T5's save-and-reopen one level up: fidelity is not a proxy for correctness.

  Five tests per paper rather than one census each, so a failure names the half that moved: the pure core's round trip, the same thing through `ExportLaTeXDocument` and a real file (`Export` could add or drop a byte the core never sees), cells and styles, tags/citations/counters, and the literal remainder.
  The remainder counts read only cell *content*, never options, so a figure's verbatim `\includegraphics` in its tagging rules is not mistaken for LaTeX left in the prose.
  Hodgepaper's two non-zero remainders are the open gaps and not defects: 72 references whose target is not a converted cell, which is T3's rule, and 55 `equation`/`align` blocks inside theorem bodies, which is T7.
- **Learned:**
  - **`$InputFileName` inside a `.wlt` is the driving script, not the `.wlt`.** Under `TestReport[file]` it reads `run_tests.wls`, so `DirectoryName[$InputFileName, 3]` points three levels above the wrong file and a test cannot locate repo files that way. `PacletObject[...]["Location"]` is the idiom that works, and `FrontEnd.wlt` and `StyleSheets.wlt` already use it.
  - **`VerificationTest` inside `If` and `Do` works under `TestReport`**, and a test that is never reached simply does not appear in the report — which is what makes an optional fixture honest instead of vacuously green.
  - **`hodgepaper.tex` has CRLF line endings** (1746 of them), and `Import[..., "Text"]` normalizes them away, so `Bytes` reads 142877 for a 144624-byte file. Every round-trip claim in this item is against the *imported text*; re-exporting that paper is faithful to the document and rewrites its line endings.
  - **An ink area from a whole-notebook render and one from a single-cell `Rasterize` are not on the same scale.** `FrontEnd.wlt`'s T2 test compares them — `Starred` 7742 from a rendered notebook against `Literal` 2440 from a rasterized cell — and now fails on that clause; the sound one beside it, `Starred` 7742 `< Unstarred` 56959, both whole-notebook, passes. Pre-existing at HEAD and unrelated to this session (`FrontEnd.wlt` fails the same way run on its own), so it is T12 rather than a fix here.
  - A file-private helper read from a probe is the trap `CLAUDE.md` records, seen from the outside this time: `Length[notebookCellList[cells]]` answered **1** and `Cases` answered `{}`, because the unevaluated expression has one argument. Every count in the first census was wrong and nothing said so.
  - Serena's `replace_content` inserts `\n` in a replacement **verbatim**, as backslash-n, not as a newline — it silently collapsed two lines of `Document.wl` into one broken line, and the bite check that followed reported nine failures that meant nothing. Restore from git and use a single-line edit.
- **Next:** T7 — display math and nested environments inside a theorem-like environment body.

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-26 | `\ref` imports as a bare counter chain, with no `"Theorem "`-style prefix, unlike `citationButton` | LaTeX authors write the word themselves (`Theorem~\ref{...}`); the palette's citation button is for a citation, where the word is wanted, and an import is not that |
| 2026-07-26 | An environment whose printed name is none of the twelve stylesheet styles is written as `Theorem` with a `CellDingbat` naming it, rather than left as literal text | the specimen paper's `Axiom` is ten of its thirty-two environments; leaving them as text would drop a third of the structure, and the dingbat both numbers with the theorems and prints the right word |
| 2026-07-26 | `\cite` converts unconditionally, where `\ref` converts only when a cell carries the key | a citation's label is literal text and reads correctly with no bibliography to point at, whereas an unresolvable `CounterBox` renders the front end's `XXX`; it is what makes hodgepaper's 78 citations convert with no `.bib` at all |
| 2026-07-26 | A `.bib` bibliography's `Reference` cells emit nothing into the `.tex`; the block's last cell re-emits the `\bibliography` commands verbatim | the entries are not in the `.tex` and the `.bib` stays the source of truth, so editing an entry in the notebook does not reach the source — the alternative was to write a bibliography style engine and lose the exact round trip |
| 2026-07-26 | Only the cited entries become cells, in the order of the `.bib` | LaTeX prints only the cited ones (three of seventeen here are never cited); emulating the style's sort order is a bibliography style engine, which is out of scope |
| 2026-07-26 | A figure's caption is a `Caption` cell the notebook owns and writes back; the rest of the environment's source rides verbatim in a tagging rule | the caption is prose and an author will edit it, so it has to reach the `.tex`; the picture's markup is not prose and translating it is out of scope, so returning it untouched is both the honest and the lossless choice |
| 2026-07-26 | The generating code and its output live only in the notebook — the exporter writes the original `\includegraphics` back | writing a picture out means rasterizing the code into a new file and rewriting the source to point at it, which is a build step and not a converter; the paper stays compilable either way |
| 2026-07-26 | A figure is numbered by the `Caption` counter straight through the document, not per section | both specimens are `article` and declare no `\numberwithin{figure}{section}`; per-section figure numbering belongs with T9, which is about numbering generally |
| 2026-07-26 | Neither specimen paper is committed; `Tests/Specimens.wlt` finds them beside the loaded paclet or in `MATHNOTEBOOK_SPECIMENS`, and emits no tests for a paper it cannot find | Pavel's call — the causal-graphs paper is an unpublished draft with two co-authors and not on arXiv, and `PublishPaclet.wls` stages `Tests/`, so committing it would ship it in every published paclet; the cost is that a fresh clone pins nothing, which the printed notice makes visible rather than silent |
| 2026-07-26 | The fixture pins a structure census beside the byte round trip, five tests per paper | two complementary bites showed each detector misses what the other catches — dropping the figure rules leaves the bytes identical, forcing the separators leaves the census intact — and a census that moves is then the record of what a later task changed |
| 2026-07-26 | Every cell carries the source whitespace that followed it | it is the difference between a round trip that is exact and one that is approximately right, and the item's whole point is fidelity; it also means the exporter needs no rules about blocking |
