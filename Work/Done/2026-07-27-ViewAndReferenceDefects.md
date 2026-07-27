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

### Done

- [x] T6 — Pavel re-checks both fixes on the document that produced the report. This is the Spec's one remaining *Done when* gate; there is nothing left to implement, and no session can close it. *(Pavel, 2026-07-27 — "rechecked")*

- [x] T1 — Rebuild the font-size setters on resolved per-style sizes read from the document's own chain; assert every prose style moves, screen and print, on all five sheets. (landed during `PaletteUsability` T6's feedback round, 2026-07-26)
- [x] T2 — Render the `Reference` label from the cell's `CellTags` at the beginning of the cell; make `InsertCitation` and the bibliography entry agree. *(Session 5)*
- [x] T3 — Investigate whether a target theorem's resolved counter value is readable at insert time, then make a citation to a numbered environment display `Theorem 1.1` rather than its tag. *(Session 6)*
- [x] T4 — Tests for all of it. *(Session 7 — the re-check half is split out as T6, since it is Pavel's and not a session's)*
- [x] T5 — Add the sentence the tutorial's *Reading and Writing Comfortably* section has been missing since `PaletteUsability` T5 deliberately withheld it: the text slider now reaches the theorem, proof, reference and list styles, which T1 above made true. *(Session 8)*

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

### Session 6 — 2026-07-26 — T3

- **Prompt:** `/next-session`.
- **Did:** The investigation the task asked for came out better than either option the Spec anticipated.
  The counter *is* readable at insert time — `CurrentValue[cell, {"CounterValue", "Theorem"}]` returns 1, 2, … on a tagged theorem cell — but baking that number in would go stale, so it is not what shipped.
  The front end has a native tagged counter, `CounterBox[counter, tag]`, which resolves against the **tagged cell** rather than the box's own position; it needs no kernel, no `Dynamic` and no renumbering pass.
  `citationButton[tag, style]` is a new overload that builds the citation from the existing `$referenceLabelSpec` entry for the target's style — prefix, counters riffled with `.`, suffix — as `CounterBox`es inside the same red `Citation` button, and falls through to the old `[tag]` for any style with no spec entry.
  `citationTargetStyle[notebook, tag]` resolves the target's style from `Cells[notebook, CellTags -> tag]` at insert time, answering `None` when no cell carries the tag, and `InsertCitation` now routes through the pair.
  Verified live on an `AMSArticle` document: citations render `Theorem 1.1`, `Lemma 2.1`, `(1)`, `Section 1`, `[ollivier]`, and after inserting a section above the target the theorem citation renumbered itself to `2.1` with nothing re-run.
  The PDF export carries the same numbers, so print needed no separate treatment.
  Five tests in `Referencing.wlt` covering the theorem, equation and subsection renderings, that *every* key of `$referenceLabelSpec` cites by number, and that a `Reference`, a plain `Text` and an absent target all keep the tag; suite green at 73.
- **Learned:**
  - **`CounterBox[counter, tag]` is the front end's cross-reference primitive** and it is exactly what this task needed: pure front-end, correct in print, and self-renumbering.
    Note this is the opposite of the `CellDingbat` finding in T2 — a `CounterBox` in a *dingbat* reads the owning cell's counter, and a `CounterBox` with a *tag* reads a distant cell's, while `Dynamic` + `EvaluationCell[]` reads neither.
  - `referenceButton` (`CopyCellReference`) cannot be folded into this: it is keyed on a `CellID`, and `CounterBox`'s second argument is a cell **tag**, not an ID. The two renderings of one `$referenceLabelSpec` are irreducible.
  - An unknown tag renders as `XXX.XXX` if a `CounterBox` is written for it, so resolving the style at insert time is what keeps a forward citation readable: with no cell carrying the tag the fallback writes `[tag]` instead.
  - **`Rasterize` on a single cell strips document context** — every counter in it reads 0, tagged ones read `XXX`. A counter can only be seen by rendering the whole notebook (`Export[file, notebookObject]`).
  - `NotebookWrite` of a whole `Cell[TextData[...]]` splits a `ButtonBox[RowBox[...]]` into one button per run; writing the bare `ButtonBox` at a selection point, which is what `InsertCitation` does, leaves it intact. Both render identically, but only the inline path round-trips.
- **Next:** T4 — tests for all of it, then Pavel re-checks on the document that produced the report.

### Session 7 — 2026-07-26 — T4

- **Prompt:** continue autonomously through the remaining tasks, committing after each.
- **Did:** New `Tests/FrontEnd.wlt`, 8 tests, deliberately the opposite of the rest of the suite: everything is measured through a real front end and a real chain, because both defects in this item passed their unit tests and still shipped broken — "the call wrote an override cell" is not "the style changed size".
  It measures each of the four templates plus a plain `Default.nb` document: asserts the sheet actually loaded (Title 26, not Default's 45) before trusting anything, that `Theorem`, `Proof`, `Reference`, `Item` and `ItemNumbered` are among the styles the control scales, that `Text` lands exactly on the requested 20, that **every** prose style's resolved size grew in both `"Screen"` and `"Printout"`, and that `ResetDocumentView` restores every base size exactly.
  For T3 it asserts `citationTargetStyle` resolves `Section`/`Theorem`/`Definition`/`Reference`/`Text`/`None` from tags on a live notebook, and that exactly the numbered ones cite with a `CounterBox`.
  Suite is 81.
- **Learned:**
  - The tests were checked by **reintroducing each defect** rather than by watching them pass. Dropping the list styles from `styleFontSizeNames[]` fails 2 of the 8 (and 1 in `View.wlt`); breaking `citationTargetStyle` to always answer `None` fails 2 — and `Referencing.wlt` **stays green**, which is precisely the hole this file fills: every kernel-only assertion about citations is satisfied by a target-style resolver that does not work.
  - A front-end test file must do all its measuring in one `UsingFrontEnd` up front and leave the `VerificationTest`s as pure comparisons; otherwise a front-end problem surfaces as a message storm across every test instead of one failed assertion.
  - The embedded-parent trap is tolerable here: while a view override is installed, styles the override does *not* write fall through to `Default.nb`, but every style asserted is one it writes. Worth stating in the file, since the next reader will otherwise "fix" it.
- **Next:** T5 — the tutorial sentence. Pavel's re-check on the original document remains open and is not something a session can close.

### Session 8 — 2026-07-26 — T5

- **Prompt:** as Session 7.
- **Did:** The withheld sentence, in the *Reading and Writing Comfortably* section: `Text size` now says it scales "the title, the headings, the abstract, the theorem environments, proofs, bibliography entries, and both kinds of list", which T1 made true.
  Found a second stale sentence while there, this one made stale by T3 two sessions ago: the *Referencing* section still said `Insert citation` "inserts a red bracketed link to that name", which now describes only a bibliography target.
  Added an Item next to it saying a citation to a numbered environment reads `Theorem 1.1`, renumbers itself when cells move, holds in the PDF, and keeps its brackets when no cell carries the tag yet.
  Regenerated `MathNotebookTutorial.nb` from the script; suite still 81.
- **Learned:** A behaviour change to an exported function silently ages the tutorial, and nothing in the build or the suite notices — `BuildTutorial.wls` is prose, and prose has no test. Worth a look at the *Referencing* and *Document view* sections whenever `Referencing.wl` or `View.wl` changes what a button does.
- **Next:** T6, which is Pavel's re-check. All implementation for this item is complete; the paclet has **not** been rebuilt or republished tonight (last published version is 0.1.10, from Session 5), since publishing is outward-facing and was not authorized for this run.

### T6 — 2026-07-27 — Pavel's re-check

- **Prompt:** "rechecked".
- **Did:** Nothing — this task was never a session's to do. Pavel re-checked both fixes on the document that produced the original report and confirmed it, which closes the Spec's last *Done when* clause and the item with it.
- **What that confirms**, in the words of the report that opened the item: the text-size slider now moves the theorem, proof, reference and list styles it used to skip, and a tagged `Reference` cell shows its label instead of an empty hanging indent. The third fix, a citation to a numbered environment reading `Theorem 1.1`, was Pavel's own follow-up request and is confirmed with them.
- **Standing caveat, unchanged by the re-check:** the last published paclet is **0.1.10** (Session 5). T3's numbered citations, T4's `Tests/FrontEnd.wlt` and T5's tutorial sentence have never been published, so a user installing from the cloud URL does not have them. Publishing is outward-facing and has not been authorized; it belongs with the `First Public Release` backlog item.
- **Next:** none — the item is complete.

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-26 | Filed as its own item rather than folded into `PaletteUsability` T6 | the reference label is a referencing defect, not a view control, and the font-size fix rewrites T3's mechanism rather than revising it |
| 2026-07-26 | The `Reference` label is the cell's own custom tag, shown at the beginning of the cell — not an auto-incremented `[1]` | Pavel's call in the T6 feedback round; it also makes the bibliography entry agree with what `InsertCitation` already writes into the body |
| 2026-07-26 | A citation to a *numbered environment* shows its resolved number (`Theorem 1.1`), while a citation to a bibliography entry keeps showing its tag | Pavel's call; a paper cross-references theorems by number and literature by label, so the two targets get different renderings from the same button |
| 2026-07-26 | A numbered citation is a `CounterBox[counter, tag]`, not a number captured at insert time nor a `Dynamic` | the counter is readable at insert time but would go stale; the tagged `CounterBox` is the front end's own cross-reference, so the number follows the target with no kernel and no renumbering pass, in print as on screen |
| 2026-07-26 | T1 was implemented during `PaletteUsability` T6 rather than in its own session | Pavel reported the defect a second time while driving the palette, so the fix was the direct revision his feedback round called for; the chain reader T4 had already built made it a contained change |
