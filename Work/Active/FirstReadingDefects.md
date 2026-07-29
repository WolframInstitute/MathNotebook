# First Reading Defects

*[ LLM Generated ]*

> Type: defect
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Pavel read the imported causal-graphs paper (`main.nb`, 0.1.17 import, 0.1.19 installed) and reported
six defects — the reading `ImportDisplayDefects` T4 was waiting on, and its output. All six were
triaged this session; four have measured root causes, one is a design gap, one needs a live front end
to reproduce. As before, the round trip is byte-exact through every one of them: these are display,
navigation and interaction defects, the classes the census and fidelity tests cannot see.

### The defects, triaged

1. **`\varnothing` renders as nothing.** The paper writes `\varnothing` (5 uses; never `\emptyset`).
   `Convert`TeX`TeXToBoxes["\\varnothing"]` answers U+F3A0 — a private-use character with **no
   Wolfram name**, which the front end cannot draw — and measured through `texToBoxes`,
   `U \neq \varnothing` came back as `RowBox[{"U", "≠"}]`: the glyph is not wrong, it is *gone*.
   (`\emptyset` alone happens to survive — the expression path parses it as a symbol named ∅,
   U+2205, the right glyph.) Same family as the `E`/`I` sweep: the box path emits characters the
   front end has no glyph for, and nothing detects it because ink was never measured for these
   macros. Fix: map the box path's private-use outputs to named characters (`\[EmptySet]` here), and
   **sweep** the common macro table for other unnamed private-use outputs rather than fixing one.

2. **`\&` displays verbatim.** `\section{Conclusion \& Further Work}` imports as a Section cell
   reading literally `Conclusion \& Further Work`; same for `Introduction \& Motivation`, the
   `[Light Rays \& Particles]` environment title, and prose (`Johnson \& Johnson \& 100\% \_x.`
   measured verbatim). No import pass unescapes the TeX character escapes (`\&`, `\%`, `\_`, `\#`,
   `\$`), so they reach displayed text raw. The export side must re-escape symmetrically or the
   byte-exact round trip of both specimens breaks — this is an import-unescape *plus*
   export-reescape pair, applied to displayed text only (stored-source tagging rules stay verbatim).

3. **Displayed and inline mathematics scale differently, tied to text scaling.** Two halves,
   both real, from `View.wl`'s design: `InlineFormula` is *relative* (1.05 × the host cell), so the
   **document** slider moves inline math while `DisplayFormula` (absolute, moved only by the
   **math** slider) stands still; and when *both* sliders are set, inline math **double-scales** —
   its ratio is scaled by the math control and its host by the document control, so at doc 14→21 and
   math 16→24 an inline island renders ~33 pt beside display math at 24. Proposed model (needs
   Pavel's nod): with `MathFontSize` untouched, the math styles and MaTeX follow the **document**
   ratio, so one slider scales the whole page coherently; an explicit `MathFontSize` overrides; and
   the inline ratio is scaled by mathScale/docScale so inline tracks display, not the product.

4. **A copied reference to `Axiom 3.1.3` pastes as `Theorem 0.0`.** Measured end to end: the paper's
   `\newtheorem{axiom}{Axiom}[subsection]` lands as style `Theorem` whose *cell* carries the dingbat
   `Axiom Section.Subsection.TheoremAxiom.` — word and chain both per-cell, both deviating from the
   style. `CopyCellReference` ignores the cell: it looks the *style* up in `$referenceLabelSpec`,
   getting `{"Theorem ", {"Section", "Theorem"}, ""}` — wrong word, and counters the cell never
   increments, which read 0. This is the same defect the imported `\ref` already had fixed ("read
   the chain off the target cell, not the target's style") and `CopyCellReference` never got: it
   must take the word and the counter names from the target's own `CellDingbat` (or
   `CellFrameLabels` for a display formula), falling back to the spec only for a cell carrying no
   number of its own.

5. **Refreshing labels, and sometimes clicking references afterwards, freezes.** Not reproduced
   headless yet. `LabelReferences` is `NotebookPut[labelReferenceCells @ NotebookGet[nb], nb]` — a
   whole-notebook rewrite to relabel 14 `Reference` cells, forcing the front end to re-typeset all
   167 cells and 238 inline-math islands, which on this paper can present as a freeze; and rewriting
   every cell is also the prime suspect for reference clicks misbehaving *after* a refresh. Fix
   direction: rewrite only the `Reference` cells (`Cells[nb, CellStyle -> "Reference"]` +
   `NotebookWrite` per cell), never the notebook; then reproduce the click-freeze on the real paper
   with the rewrite in place before believing it gone.

6. **A composed citation is one dead button.** `\cite{marzke1959measurement, marzke1964gravitation}`
   becomes a single `ButtonBox` labelled `[marzke1959measurement, marzke1964gravitation]` whose
   `ButtonData` is the compound key string — `NotebookLocate` finds no cell tagged with the compound,
   so the click silently does nothing. Fix: one button per key (`[a], [b]` with literal separators
   between), each navigating; the exporter recomposes adjacent citation buttons into the one
   `\cite{…}` with the source's own spacing, so both specimens stay byte-exact. `mergedButtons`
   (the reopen-split repair), `citationTeX`'s optional-argument arithmetic and `citedTags` all read
   the current shape and move with it.

### Requirements

- Every fix verified the way its defect was found: rendered ink for the glyph, cell text for the
  escapes, rendered sizes for the scaling, the pasted button's own boxes for the copy, wall-clock on
  the real paper for the freeze, a resolvable `ButtonData` per key for the citations.
- The round trip of both specimens and all four samples stays byte-exact through every task, and
  `Tests/Specimens.wlt`'s census counts move only where a fix legitimately moves them (the split
  citation buttons will move `Cites`-adjacent counts if any key on them; re-measure, never guess).
- Each fix lands with a test that **bites** (reintroduce the defect, watch it fail), per the repo
  rule; display claims go in `Tests/FrontEnd.wlt`.
- Defect 3's model changes what two shipped controls do — confirm the proposed model with Pavel
  before or at T5, and record his call in this file.

### Out of scope

- The by-name stylesheet question (`BasicFunctionality`'s outstanding clause) — nothing in this
  report answers it either way, since an imported paper's dingbats are per-cell.
- New TeX macros beyond what the private-use sweep of the existing table surfaces.

## Tasks

- [ ] **T1 — The unnamed glyphs.** Map `presentationBoxes`' private-use outputs to named characters
  (`\varnothing` → `\[EmptySet]`), sweeping the common-macro table for every other unnamed
  private-use character rather than patching one. Assert by rendered ink (a `\varnothing` island
  measures > 0 against the blank it is today) and by character code kernel-side; round trip stays
  byte-exact (inline math re-exports from `"SourceTeX"`).
- [ ] **T2 — The character escapes.** Unescape `\&`, `\%`, `\_`, `\#`, `\$` into displayed text on
  import — prose, section titles, environment titles, captions, wherever `inlineContent` reaches —
  and re-escape on export so both specimens stay byte-exact. Watch the specimen census: cell counts
  must not move.
- [ ] **T3 — Split the composed citations.** One button per key with the separators as literal text,
  export recomposing adjacent citation buttons to the source's own `\cite{…}` bytes;
  `citationTeX`, `mergedButtons` and `citedTags` move together. Assert a compound citation's every
  key resolves through `NotebookLocate` on the imported specimen, and the reopen-split
  (`FrontEnd.wlt`) still merges right.
- [ ] **T4 — Copy reference reads the cell.** `CopyCellReference` takes the word and counter chain
  from the target's own `CellDingbat`/`CellFrameLabels`, spec only as fallback — the `\ref` fix
  applied to the copy path. The pasted button for the specimen's `axiom` 3.1.3 must read
  `Axiom 3.1.3` and navigate.
- [ ] **T5 — One coherent scale for mathematics.** Confirm the model with Pavel: math follows the
  document slider when `MathFontSize` is `Automatic`; an explicit math size overrides; inline ratio
  scaled by mathScale/docScale so inline tracks display instead of double-scaling. Then implement in
  `viewStyleCells`/`inlineMathCells`/`maTeXFontSize` and measure rendered sizes under all four
  slider states.
- [ ] **T6 — The freeze.** Rewrite `LabelReferences` to touch only the `Reference` cells, time it on
  the real `main.nb` before and after, then chase the click-after-refresh freeze on the installed
  paclet with the rewrite in place. This task ends with a measured number, not "feels fast".

## Progress

### Session 0 — 2026-07-29 — triage

- **Prompt:** Pavel's six-point defect report against the imported causal-graphs paper.
- **Did:** Triaged all six headless against the working tree. Measured: `\varnothing` → U+F3A0
  (unnamed, undrawable, and dropped outright inside a `RowBox`); `\&` verbatim in Section, Text and
  environment-title cells of a minimal import; the `axiom` environment landing as style `Theorem`
  with per-cell dingbat `Axiom S.SS.TheoremAxiom.`, so `CopyCellReference`'s style-spec lookup
  produces exactly the reported `Theorem 0.0`; the compound `\cite`'s single `ButtonBox` with an
  unresolvable compound `ButtonData`. Read `View.wl` end to end for defect 3 and found the
  double-scaling corner beyond what was reported. Wrote this item; closed `ImportDisplayDefects`
  (its T4 reading half is this report).
- **Learned:** The probe trap again, in a new coat: `Symbol["…PackageScope`importedNotebook"]`
  *created* the symbol it went looking for, and the next probe found it in `Names` — the entry
  point is `latexToNotebook`. And `\emptyset` vs `\varnothing` differ in kind: the expression path
  parses `\emptyset` to a *symbol named ∅* (right glyph, by luck), while the box path's
  `\varnothing` is an unnamed private-use character — so a sweep must test both pipeline halves.
- **Next:** T1.
