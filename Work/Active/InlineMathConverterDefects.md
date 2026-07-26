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

- [ ] T2 — Starred environments, `equation*` and `align*`; reconcile the tutorial sentence with whatever lands.
- [ ] T3 — Protected single letters; sweep the alphabet and assert every one displays itself.

### Done

- [x] T1 — Comma-bearing fragments; test with tuples, subscripted lists, and a comma inside `\{…\}`. *(Session 1)*

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

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-26 | Filed apart from `LaTeXPaperImport` rather than as tasks inside it | these are defects in shipped `TeX → math` behaviour that anyone converting a paper hits today, independent of whether the importer is ever built; the import item depends on them but does not contain them |
