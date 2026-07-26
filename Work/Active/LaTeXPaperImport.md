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

- [ ] T5 — Figures: preserve TikZ, add generating Wolfram code with rendered output, for one real figure of the paper.
- [ ] T6 — Make both papers round-trip test fixtures under `MathNotebook/Tests/`. T2 already gets a byte-identical round trip on each; the fixture pins it.
- [ ] T7 — Display math and nested environments *inside* a theorem-like environment body. T2 deliberately runs only the inline converter there, since an environment has to stay one cell; on `hodgepaper.tex` that leaves 53 `equation`/`align` blocks and two nested `sublemma*` as literal source inside otherwise converted cells.
- [ ] T8 — Front matter: `\title`, `\author`, `\date`, `\maketitle`, `abstract` → the `Title`/`Author`/`Date`/`Abstract` styles the stylesheets define, and lists (`itemize`, `enumerate`, `description`) → the `Item` family.
- [ ] T9 — Numbering. The Spec's "numbering must match" is measurably violated: the causal-graphs paper declares `\newtheorem{defn}{Definition}[subsection]` and numbers per subsection, while the imported notebook renders `Axiom 3.2`, `Definition 3.5` — per section, from the stylesheet's counters.
- [ ] T10 — `thebibliography` written into the `.tex` ↔ `Reference` cells, and a report when a declared `.bib` is missing. T4 does the `.bib` route, which both specimens use; an in-source bibliography needs a per-item source and separator on each cell inside one environment wrapper, which is the same design problem as T7.

### Done

- [x] T1 — Baseline: unzip the paper, convert with today's pipeline, convert back, diff against the source, and write the gap report into this item's Progress. *(Session 1)*
- [x] T2 — Sectioning and theorem environments, both directions, with tests. *(Session 2)*
- [x] T3 — `\label`/`\ref`/`\eqref` ↔ cell tags and reference buttons. *(Session 3)*
- [x] T4 — Citations and bibliography ↔ `Citation`/`Reference` cells. *(Session 4)*

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

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-26 | `\ref` imports as a bare counter chain, with no `"Theorem "`-style prefix, unlike `citationButton` | LaTeX authors write the word themselves (`Theorem~\ref{...}`); the palette's citation button is for a citation, where the word is wanted, and an import is not that |
| 2026-07-26 | An environment whose printed name is none of the twelve stylesheet styles is written as `Theorem` with a `CellDingbat` naming it, rather than left as literal text | the specimen paper's `Axiom` is ten of its thirty-two environments; leaving them as text would drop a third of the structure, and the dingbat both numbers with the theorems and prints the right word |
| 2026-07-26 | `\cite` converts unconditionally, where `\ref` converts only when a cell carries the key | a citation's label is literal text and reads correctly with no bibliography to point at, whereas an unresolvable `CounterBox` renders the front end's `XXX`; it is what makes hodgepaper's 78 citations convert with no `.bib` at all |
| 2026-07-26 | A `.bib` bibliography's `Reference` cells emit nothing into the `.tex`; the block's last cell re-emits the `\bibliography` commands verbatim | the entries are not in the `.tex` and the `.bib` stays the source of truth, so editing an entry in the notebook does not reach the source — the alternative was to write a bibliography style engine and lose the exact round trip |
| 2026-07-26 | Only the cited entries become cells, in the order of the `.bib` | LaTeX prints only the cited ones (three of seventeen here are never cited); emulating the style's sort order is a bibliography style engine, which is out of scope |
| 2026-07-26 | Every cell carries the source whitespace that followed it | it is the difference between a round trip that is exact and one that is approximately right, and the item's whole point is fidelity; it also means the exporter needs no rules about blocking |
