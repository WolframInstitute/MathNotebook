# View and Reference Defects

*[ LLM Generated ]*

> Type: bugfix
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: Pavel, 2026-07-26, driving the palette on a real document — "Currently the reference cell looks ugly, not showing the tag [...]. Also the font size is not changed in itemized, references, theorem etc. cells."

Two defects found in first real use, both reproduced.

**The text-size slider misses most of the prose.**
`SetDocumentFontSize` writes one override cell per style that carries an explicit `FontSize` in `LaTeXBase.nb`, and only those styles change.
Measured on an `AMSArticle` document after `SetDocumentFontSize[ document, 20 ]`: `Text` 13 → 20, `Abstract` 12 → 18 and `Title` 26 → 40, but `Theorem`, `Proof` and `Reference` stay at 13 and `Item` and `ItemNumbered` stay at 15.
Two distinct causes.
Styles declared as `StyleData[ name, StyleDefinitions -> StyleData[ "Text" ] ]` — the twelve theorem environments, `Proof`, `Reference`, `Author`, `Date` — carry no bare `FontSize` of their own, so T3's extraction produces no screen override cell for them, and the inheritance is resolved inside the parent sheet: a child sheet overriding `Text` does **not** reach them.
The list styles are not in `LaTeXBase.nb` at all — the templates give them only a `FontFamily` — so their size comes from `Default.nb` and nothing is ever written for them.
The fix is to stop reading base sizes out of `LaTeXBase.nb` and read each style's *resolved* size from the document's own stylesheet chain, which is what T4's `baseCellMargins` already does for margins: `CurrentValue[ notebook, { StyleDefinitions, style, CellMargins } ]` resolves through the chain and covers the `Item` family and a plain `Default.nb` document alike.
The style list then has to be the paper's structural styles rather than "whatever `LaTeXBase` happens to declare".

**A `Reference` cell shows no label.**
The `Reference` style is a bare hanging-indent paragraph — `CellMargins -> { { 90, 10 }, { 3, 3 } }`, `ParagraphIndent -> -24` — with no `CellDingbat`, no counter and no use of the cell's own `CellTags`.
So a tagged reference displays nothing where `[1]` belongs, and the hanging indent pulls the first line 24 pt left of the block with nothing in the gap, which is what reads as broken.
`InsertCitation` meanwhile writes `[tag]` into the body as a `Citation` button, so the citation shows a label the bibliography entry does not.
Pavel settled the rule on 2026-07-26: the label is the cell's **custom tag**, rendered at the beginning of the reference cell — not an auto-incremented counter.

**A citation to a theorem shows the tag, not the number.**
Pavel, 2026-07-26: "Could insert citation for theorems etc. actually show the actualized name like Theorem 1.1 instead of the custom tag?"
`InsertCitation` writes the raw `CellTags` string into the `Citation` button for every target, so a cross-reference to a theorem reads `[myThm]` where a paper wants `Theorem 1.1`.
The environments already number themselves — `theoremStyleCells` builds the dingbat from `CounterBox[ "Section" ]` and `CounterBox[ "Theorem" ]` — so the number exists in the front end but is not readable from the tag.
This needs investigation before it is designed: whether a target cell's resolved counter value can be queried at insert time, and if it can only be resolved at display time, whether the citation must become a `CounterBox`-bearing button that renumbers itself when cells move.
A citation to a bibliography entry keeps showing the tag (that is item 6); this applies to the numbered environments.

Done when a text-size change moves every prose style on screen and in print on all four templates plus `Default.nb`, a tagged `Reference` cell shows its tag as its label without the author typing it, a citation to a theorem shows its number, and Pavel confirms on the document that produced the report.

### Requirements

- Every structural prose style follows the text-size slider: `Text`, `Item`, `ItemNumbered`, `ItemParagraph`, `Reference`, `Proof`, the twelve theorem environments, `Author`, `Date`, `Abstract`, `Title`, the three section levels.
- Both the bare style and its `"Printout"` variant, per the standing decision — screen and PDF.
- A `Reference` cell renders its label automatically, and the label agrees with what `InsertCitation` inserts for the same tag.
- Reproduction assertions become tests, so neither defect can come back silently: assert resolved `FontSize` per style after a `SetDocumentFontSize` call, not merely that the call returned.

### Edge cases & out of scope

- Reading resolved values needs a front end and a `NotebookObject`; memoize per parent stylesheet, as `baseFontSizes` does, so the sliders stay cheap.
- On a `Default.nb` document the theorem styles do not exist; writing override cells for absent styles must stay harmless.
- If the label comes from `CellTags`, a cell can carry several tags — pick one rule and state it.
- The equation-number style is a `CellFrameLabels` label, not a column style; it scales with the math slider and must not be given column margins.
- Out of scope: changing the four template stylesheets' design (fonts, sizes, spacing) — this is about the controls reaching what the design already declares, and about one missing label.

## Tasks

- [ ] T3 — Investigate whether a target theorem's resolved counter value is readable at insert time, then make a citation to a numbered environment display `Theorem 1.1` rather than its tag.
- [ ] T4 — Tests for all of it, then Pavel re-checks on the document that produced the report.
- [ ] T5 — Add the sentence the tutorial's *Reading and Writing Comfortably* section has been missing since `PaletteUsability` T5 deliberately withheld it: the text slider now reaches the theorem, proof, reference and list styles, which T1 above made true.

### Done

- [x] T1 — Rebuild the font-size setters on resolved per-style sizes read from the document's own chain; assert every prose style moves, screen and print, on all five sheets. (landed during `PaletteUsability` T6's feedback round, 2026-07-26)
- [x] T2 — Render the `Reference` label from the cell's `CellTags` at the beginning of the cell; make `InsertCitation` and the bibliography entry agree. *(Session 5)*

## Progress

### T1 — 2026-07-26 — landed under `PaletteUsability` T6

- **Did:** Replaced `View.wl`'s `baseFontSizes[]` — which extracted sizes from `LaTeXBase.nb` — with `baseFontSizes[ parent ]`, a chain reader memoized per parent sheet, exactly parallel to T4's `baseCellMargins`.
  Verified on an `AMSArticle` document after `SetDocumentFontSize[ document, 20 ]`: `Theorem`, `Proof` and `Reference` 13 → 20 and `Item`/`ItemNumbered` 15 → 23, where all five previously did not move; `Text` 13 → 20, `Title` 26 → 40, `Abstract` 12 → 18 as before; the `"Printout"` variants scale too (10 → 15, 15 → 23); `ResetDocumentView` restores every base size exactly and leaves the tagging rules `Inherited`.
  Suite is 51 tests, including a regression test asserting a screen cell is written for each of the five styles.
- **Learned:**
  - **`{ style, "Printout" }` inside a `StyleDefinitions` path resolves the print environment through the whole chain** — `CurrentValue[ nb, { StyleDefinitions, { "Theorem", "Printout" }, FontSize } ]` returns 10 where the bare path returns 13. `StyleData[ style, "Printout" ]` in that position does **not** work: it silently returns the screen value, which would have written every printout override at its screen size.
  - The style *list* still comes from `LaTeXBase.nb` rather than from the chain, deliberately: the chain resolves a size for the character styles too (`Hyperlink`, `Citation`, `URL`), and pinning those would stop an inline citation inheriting the size of the cell it sits in.
  - Non-numeric resolved values are real and must be filtered — `Default.nb` gives `DisplayFormulaEquationNumber` the symbolic `-1 + Inherited`.
  - The chain reader needs a front end, so the previously kernel-only test suite had to stub `baseFontSizes` for the one test that passes a real sheet name, or it fails on messages alone with a correct value.
- **Next:** T2 — the `Reference` label from `CellTags`.

### Session 5 — 2026-07-26 — T2

- **Prompt:** `/next-session`, third task of the run — and "build the paclet and reinstall and redeploy".
- **Did:** The label is a static `CellDingbat` carrying `[tag]`, written from the cell's own `CellTags`.
  `Referencing.wl` gained one source of the label text — `referenceLabel[tag]` — used by both `citationButton` (which `InsertCitation` now writes) and `referenceDingbat`, so the entry and the citations pointing at it cannot drift apart.
  `labelReferenceCells[notebook_Notebook]` is the pure core in the repo's usual shape: it relabels every `Reference` cell, strips a stale label from one whose tag went away, and leaves every other style alone.
  `TagSelectedCell` now routes through `tagCell`, which sets the tag and, on a `Reference` cell, the label with it — so tagging from the palette labels the entry with nothing else to press.
  Exported `LabelReferences[]` / `LabelReferences[notebook]` for a bibliography tagged before this or tagged through the Cell Tags dialog, with a usage string and a `PacletInfo.wl` entry.
  Seven tests in `Referencing.wlt` (label text, entry-and-citation agreement, add, clear, replace, first-of-several tags, non-`Reference` untouched); suite green at 68.
  The tutorial's *Referencing* section says what the label is and names `LabelReferences[]`, and `BuildTutorial.wls` now tags its four Credits entries and runs the notebook through `labelReferenceCells`, so the shipped tutorial demonstrates the labels it describes.
  Published 0.1.10, reinstalled it *through the update path itself* (0.1.9 → 0.1.10, a second live run of T4's code and of the `"0.1.9" < "0.1.10"` ordering), redeployed the previews, and removed the 0.1.8/0.1.9 test installs.
- **Learned:** The obvious design — a `CellDingbat` holding `Dynamic[CurrentValue[EvaluationCell[], CellTags]]`, so the label tracks the tag with no code — **does not work**: rendered in a real front end the dingbat's `EvaluationCell[]` does not resolve to the cell that owns the dingbat, and every label came out empty. A dingbat cannot read its own cell's options; the label has to be written in.
  With the label written in, the existing `ParagraphIndent -> -24` hanging indent is exactly right — `[ollivier]` sits right-aligned in the margin and the body hangs under itself, which is the `thebibliography` look. Nothing in the stylesheets had to change.
  A `Reference` cell's options are plain rules, so `FilterRules[..., Except[CellDingbat]]` plus a freshly computed dingbat is enough to make relabelling idempotent — no separate "is there already a label" branch.
- **Next:** T3 — whether a target theorem's resolved counter is readable at insert time, so a citation can show `Theorem 1.1`.

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-26 | Filed as its own item rather than folded into `PaletteUsability` T6 | the reference label is a referencing defect, not a view control, and the font-size fix rewrites T3's mechanism rather than revising it |
| 2026-07-26 | The `Reference` label is the cell's own custom tag, shown at the beginning of the cell — not an auto-incremented `[1]` | Pavel's call in the T6 feedback round; it also makes the bibliography entry agree with what `InsertCitation` already writes into the body |
| 2026-07-26 | A citation to a *numbered environment* shows its resolved number (`Theorem 1.1`), while a citation to a bibliography entry keeps showing its tag | Pavel's call; a paper cross-references theorems by number and literature by label, so the two targets get different renderings from the same button |
| 2026-07-26 | T1 was implemented during `PaletteUsability` T6 rather than in its own session | Pavel reported the defect a second time while driving the palette, so the fix was the direct revision his feedback round called for; the chain reader T4 had already built made it a contained change |
