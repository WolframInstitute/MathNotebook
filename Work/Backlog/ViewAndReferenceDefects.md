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
Decide whether the label comes from the cell's `CellTags` (matching what `InsertCitation` links to, so `[Ollivier]`) or from an auto-incremented counter (matching LaTeX's `\bibitem` numbering, so `[1]`), then render it as a dingbat so it is never typed by hand.

Done when a text-size change moves every prose style on screen and in print on all four templates plus `Default.nb`, a tagged `Reference` cell shows its label without the author typing it, and Pavel confirms both on the document that produced the report.

### Requirements

- Every structural prose style follows the text-size slider: `Text`, `Item`, `ItemNumbered`, `ItemParagraph`, `Reference`, `Proof`, the twelve theorem environments, `Author`, `Date`, `Abstract`, `Title`, the three section levels.
- Both the bare style and its `"Printout"` variant, per the standing decision — screen and PDF.
- A `Reference` cell renders its label automatically, and the label agrees with what `InsertCitation` inserts for the same tag.
- Reproduction assertions become tests, so neither defect can come back silently: assert resolved `FontSize` per style after a `SetDocumentFontSize` call, not merely that the call returned.

### Edge cases & out of scope

- Reading resolved values needs a front end and a `NotebookObject`; memoize per parent stylesheet, as `baseCellMargins` does, so the sliders stay cheap.
- On a `Default.nb` document the theorem styles do not exist; writing override cells for absent styles must stay harmless.
- If the label comes from `CellTags`, a cell can carry several tags — pick one rule and state it.
- The equation-number style is a `CellFrameLabels` label, not a column style; it scales with the math slider and must not be given column margins.
- Out of scope: changing the four template stylesheets' design (fonts, sizes, spacing) — this is about the controls reaching what the design already declares, and about one missing label.

## Tasks

- [ ] T1 — Rebuild the font-size setters on resolved per-style sizes read from the document's own chain; assert every prose style moves, screen and print, on all five sheets.
- [ ] T2 — Decide the `Reference` label rule and implement it as a dingbat; make `InsertCitation` and the bibliography entry agree.
- [ ] T3 — Tests for both, then Pavel re-checks on the document that produced the report.

### Done

(completed tasks move here with the session that closed them)

## Progress

(no sessions yet)

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-26 | Filed as its own item rather than folded into `PaletteUsability` T6 | the reference label is a referencing defect, not a view control, and the font-size fix rewrites T3's mechanism rather than revising it |
