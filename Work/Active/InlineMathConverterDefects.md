# Inline Math Converter Defects

*[ LLM Generated ]*

> Type: bugfix
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: measured, not reported — [LaTeX Paper Import](LaTeXPaperImport.md) T1, 2026-07-26, running today's pipeline over `Axiomatic_Relativity_from_Causal_Graphs.zip`.

Three defects in `Conversion.wl`, all reproduced on that paper and all reducible to one-line cases.
They are filed apart from the import work because they are wrong behaviour in a shipped, documented feature — `TeX → math` on an ordinary paper — rather than a missing importer.
They should be fixed before that item's T2, which builds on this layer.

**A comma makes the parser fail.**
`texToBoxes` answers `$Failed` for any fragment containing one: `"a, b"`, `"(a, b)"`, `"x_1, x_2"`, `"p,q\in M"`.
`"a; b"` and `"a \in B"` are fine, so it is the comma specifically.
A failing span is left in the cell as literal `$…$`, silently.
On the specimen paper this is every unconverted inline span — 35 of 238, 15% — and they are the ones a reader notices, since `$(V, E)$`-style tuples are what mathematics is written in.

**`equation*` is not recognised.**
As an entire cell it converts to nothing at all, while `equation` becomes `DisplayFormulaNumbered`.
The tutorial says the starred forms convert and stay unnumbered, so the documentation describes behaviour that does not exist.
Both display equations in the specimen paper are starred, so none of its display math converts.
`$$…$$` inside a paragraph splits out correctly, so the paragraph-splitting machinery is not the problem — the environment simply is not matched.

**WL's protected letters vanish.**
`texToBoxes["E"]` and `texToBoxes["I"]` return an empty box, because `E` is 2.718… and `I` is the imaginary unit.
The specimen paper writes `$E$` for its hyperedge set and it renders as a blank.
`V`, `D`, `N`, `C`, `K` are unaffected.
This one is invisible to a round-trip diff — the exporter reads the stored `"SourceTeX"`, not the boxes, so the cell exports perfectly while displaying nothing.

Done when all three convert correctly, each has a test, and the tutorial's claim about starred environments is either true or reworded.

### Requirements

- A comma-bearing fragment converts, and the sequence stays a sequence rather than becoming a single expression.
- `equation*`, and the starred forms of any other supported environment, convert to the unnumbered style; check `align*` while there.
- A single-letter span renders as that letter regardless of what the letter means to the kernel — including `E`, `I`, and anything else `Protected`.
- A test that asserts what a converted cell *displays*, not only that it exports back to the source. T1 established that round-trip fidelity hides display defects entirely.

### Edge cases & out of scope

- The comma fix must not change how `align`'s `&` alignment or `cases` behave.
- Out of scope: everything structural — sectioning, environments, references — which is the import item.

## Tasks

- [ ] T3 — Protected single letters; sweep the alphabet and assert every one displays itself.

### Done

- [x] T1 — Comma-bearing fragments; test with tuples, subscripted lists, and a comma inside `\{…\}`. *(Session 1)*
- [x] T2 — Starred environments, `equation*` and `align*`; reconcile the tutorial sentence with whatever lands. *(Session 2)*

## Progress

### Session 1 — 2026-07-26 — T1

- **Prompt:** `/next-session` — work the next task; the item was pulled out of `Backlog/` because both `LaTeXPaperImport`'s Progress and `Work/README.md` say these defects come before that item's T2.
- **Did:** Fixed the comma defect in `texToBoxes` and covered it with seven tests.

  **The comma was never the cause.**
  `texToBoxes` read the fragment through `ToExpression[ tex, TeXForm, HoldComplete ]`, which demands the TeX be *one Wolfram expression* — and a comma-separated fragment never is, so it answered `$Failed`.
  The comma was only the most common way an ordinary formula fails that demand.
  `Convert`TeX`TeXToBoxes` — the box-producing half of the same importer, which `ToExpression` itself calls before interpreting — already returns perfectly correct boxes for every one of these fragments.
  So the fix is to keep the semantic parse as primary and consult the presentational one when it fails (`presentationBoxes`), not to teach anything about commas.

  **On the specimen paper: 35 of 241 inline spans unconverted → 0.**
  Every span now converts, and the round trip stays byte-identical over all 116 paragraphs, with 44 cells now carrying real math where fewer did before.

  **A second defect in the same function, found while measuring.**
  `ToExpression` answers `HoldComplete[$Failed]` for malformed TeX (`\frac{a`, `%`), which the old `HoldComplete[ expression_ ]` pattern matched — so `MakeBoxes` was applied to `$Failed` and the cell rendered the literal word **`$Failed`** instead of falling back to the source.
  Fixed in the same rule list; it is one line and it is the same "a parse failure was not reported as one" bug.

  **Scope guard.** `\ref`/`\eqref`/`\pageref` reach the fallback and `TeXToBoxes` renders them as a bogus `CounterBox` built letter-by-letter out of the word "Section". They are held at `$Failed`, i.e. left as literal source, exactly as before — cross-references are `LaTeXPaperImport` T3, not this layer.

  **Tests.** Six in `Tests/Conversion.wlt` (sequence stays a sequence, eight real specimen shapes, both subscripts survive, malformed TeX answers `$Failed` and not `"$Failed"`, the whole converted cell for `$(V, E)$` asserted literally, `align`'s `&` columns and `cases`' rows unchanged at 2×2) and one in `Tests/FrontEnd.wlt`.
  The front-end one is requirement 4 — asserting what the cell *displays* — measured as **ink area**: `Blank < Converted < Literal`, since a converted span has lost the two `$` glyphs but is not empty.
  All 96 tests pass; reintroducing the defect fails exactly the 7 new ones and none of the 13 pre-existing `Conversion.wlt` tests, so each new test bites.
- **Learned:**
  - The two halves of the TeX importer have opposite failure modes and neither dominates. The expression path is right where it works (`\mathcal{H}` → a script character, `E=mc^2` → a real `=`), while `TeXToBoxes` renders `\mathcal{H}` as an italic `H`; the box path is right for anything that is not a single expression. Consulting one as the other's fallback is what makes both usable.
  - `\cite{foo}` already mangles into a `MakeBoxes` rendering of a literal `Button[...]` expression through the *old* path — pre-existing, unrelated to this fix, and T4 material for the import item. Its `TeXToBoxes` rendering is a genuine `ButtonBox` with `BaseStyle -> "Citation"`, so that task has an easier road than it looks.
  - `\mathcal{H}` converts to a plain `"H"`, not to `"\[ScriptCapitalH]"` as `LaTeXPaperImport` Session 1 recorded — measured identical before and after this change, so the earlier note is wrong rather than something this session broke.
  - Rasterized ink area is a workable headless display assertion, and the three-way `Blank < Converted < Literal` inequality is comfortably separated (390 / 575 / 703 on `$(V, E)$`) rather than marginal. This is the measurement T3 needs, since a blank `$E$` is precisely an ink-area-zero defect.
- **Next:** T2 — `equation*` and `align*`. Note that `displayParse` *does* already list `equation*` and `align*`, and `displayTeXQ` matches them, so the Spec's "not recognised at all" needs re-measuring before anything is changed.

### Session 2 — 2026-07-26 — T2

- **Prompt:** `/next-session` — work the next task, then keep going through the work items.
- **Did:** Re-measured the Spec's second defect, found it filed against the wrong cause, and fixed the cause that is actually there.

  **`equation*` was never unrecognised.**
  Session 1's closing note was right to demand a re-measure.
  `displayParse` has listed `equation*` and `align*` since the feature shipped, and a cell that is *entirely* one starred environment has always converted to `DisplayFormula`, unnumbered, exactly as the tutorial says.
  Measured on all six supported forms before touching anything.

  **What the specimen paper actually hits is that display math inside a paragraph is never split out.**
  Its two display equations sit in the middle of a 903-character paragraph with prose on the lines above and below and no blank line anywhere — which is simply how LaTeX is written.
  `convertLaTeXCell` only ever asked whether the *whole cell* was one display environment; if not, the cell went to the inline path and the environment stayed as literal text.
  Starred or not made no difference: `\begin{equation}` embedded the same way was missed identically.

  **And the Spec's one reassurance was wrong too.**
  `$$…$$` inside a paragraph did *not* split out correctly — `splitInlineMath` read it as inline math and left a stray `$` on each side of the formula.
  `\[…\]` inside a paragraph was passed through untouched.

  **The fix.**
  One delimiter table (`$displayDelimiters`) now generates both the anchored whole-cell rules (`displayParse`) and unanchored split rules (`splitDisplayMath`), so the two can no longer disagree about which environments exist.
  `convertLaTeXCell` splits the text on display spans first, converts each span to its own `DisplayFormula`/`DisplayFormulaNumbered` cell, and runs the prose between them through the old inline path — so it can now answer with several cells, and `mapCells` flattens them back into the notebook.
  `displayTeXQ` and `displayCell` are gone: a whole-cell display is just a split that yielded exactly one part, and the failure case (span left as its own source string) collapses back to the original cell through `mergeStrings`.
  Cell options go to the first of the new cells only — a duplicated `CellID` is not an option, it is two cells claiming one identity.

  **On the specimen paper: 0 of 2 display equations converted → 2 of 2.**
  105 paragraphs become 109 cells, the one paragraph holding both equations splitting into five.
  Nothing else in the paper moved.

  **Round-trip fidelity survives, with a caveat the import item needs.**
  Every one of the 105 paragraphs still comes back byte-identically — but only after the five pieces of the split paragraph are rejoined, and the join is exactly `"\n"`, the newline that separated them in the source.
  So the content is verbatim and the *blocking* is what changed: a joiner that riffles cells with `"\n\n"` will insert a blank line the source did not have, which in LaTeX means an indented new paragraph.
  `LaTeXPaperImport` T6 has to record the join, not just the cells.

  **Tests.** Seven in `Tests/Conversion.wlt` — the specimen paragraph shape, all six environments starred and unstarred in mid-paragraph position, `$$…$$` leaving no `$` behind, the verbatim `"\n"` rejoin, the single `CellID`, an unreadable span leaving the paragraph whole, and `splitDisplayMath` itself — plus two starred whole-cell rows added to `$testNotebook`, and two in `Tests/FrontEnd.wlt`.
  All 105 tests pass.
  Reintroducing the defect (anchoring `splitDisplayMath` back to the whole string) fails 4 of `Conversion.wlt` and both of `FrontEnd.wlt` and no pre-existing test, so the new ones bite and nothing old was weakened.

  **The tutorial sentence is true and stays**, with a new Item beside it saying that a display environment written inside a paragraph is lifted into its own cell.
- **Learned:**
  - A single rasterized cell cannot see an equation number. `DisplayFormula` and `DisplayFormulaNumbered` on the same body both measured 243 units of ink, because the number is a `CounterBox` and a lone cell has no document to resolve one in — the same trap `CLAUDE.md` records for `Referencing`. Rendering the whole notebook with `Export[file, notebookObject]` separates them cleanly: 1268 starred against 1368 unstarred, the number being the entire difference. That is the only way to assert "unnumbered" as a *display* fact rather than as a style name.
  - `Map[ Apply[ { a, b, c } |-> … ] ]` is needed to build patterns from a table of tuples; `Map[ { a, b, c } |-> … ]` passes the whole list as one argument and the `Function::fpct` failure surfaces later as `StringExpression::invld`, far from its cause.
  - `Shortest` is what makes an unanchored environment rule safe. Two `equation*` blocks in one paragraph would otherwise match as one span running from the first `\begin` to the last `\end`, swallowing the prose between them.
  - Do not `git checkout <file>` to undo a scripted "reintroduce the defect" patch — it reverts the session's real work in the same stroke. Patch and un-patch the same way, or stash.
- **Next:** T3 — protected single letters (`E`, `I`), sweeping the alphabet with the ink measurement.

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-26 | Filed apart from `LaTeXPaperImport` rather than as tasks inside it | these are defects in shipped `TeX → math` behaviour that anyone converting a paper hits today, independent of whether the importer is ever built; the import item depends on them but does not contain them |
| 2026-07-26 | A paragraph with embedded display math converts to several cells, rather than staying one cell with the formula inline | a display equation is a display cell — that is what the style is for, and what the exporter, the numbering and the stylesheets all expect. The cost is that the source's paragraph blocking is no longer one-to-one with cells; the content is still verbatim, and the join that restores it is a single newline |
