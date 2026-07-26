# Palette Usability & Document View Controls

*[ LLM Generated ]*

> Type: refactor
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: "test the pallette get my feedback and make it more usable and cosy - like foldable sections, or changing font size of the math in all document - that would be a usable function. Also a slider for the document font size. And if it would be possible to somehow do not always stretch the notebook content but display it in some column in the center (it should be some viewer option) - document it in the tutorial, if there is such option, and the palette should again have some slider that supports this."

The palette is a flat column of seventeen buttons in six labelled groups — everything visible at once, nothing adjustable.
This item turns it into a comfortable writing surface: groups that fold away, and live controls for the three typographic decisions an author actually revisits while writing — how big the text is, how big the mathematics is, and how wide the column of content is.
The last one is the reason papers are readable on a wide screen at all, and it may already exist as a front end option; if it does, the palette should expose it and the tutorial should teach it rather than reinventing it.

Done when the palette folds, the controls work across all four stylesheets and survive save/reopen, the tutorial documents them, and Pavel has used it on a real document and signed off.

**Amended 2026-07-26 (session 8):** the centered content column is **withdrawn**, on Pavel's call after driving it — not reworked, removed.
The item ships two controls, prose size and math size, plus the fold and the reset.

### Requirements

- **Foldable groups.** Each labelled group (Referencing, Environments, Stylesheet, LaTeX ⇄ math, MaTeX, Setup) opens and closes independently. Open/closed state persists across front end sessions — palettes are `Saveable -> False`, so state belongs in `CurrentValue[$FrontEnd, {TaggingRules, "MathNotebook", ...}]`, not in the palette file.
- **Document font size.** A slider setting the size of prose for the whole document, not one cell — and it must be a real font size that survives PDF export, distinct from `Magnification`, which only zooms the screen. Offer both if both are wanted, but never conflate them in one control.
- **Math font size.** The same for mathematics, independently of prose: display equations, inline math, and the equation-number labels.
- ~~**Centered content column.** Content in a fixed-width column centered in the window instead of stretching to the full width, with a slider for the width. Investigate native support before implementing anything.~~ **Withdrawn in session 8** — built as a fraction of the page (T4), rebuilt as an absolute centered measure (session 7), then dropped entirely at Pavel's request.
- **Reset.** Any control can be returned to the stylesheet default — a document must be able to leave no trace of these overrides.
- **Feedback round.** Pavel drives the palette on a real paper and the result is revised against that, per the `revise` protocol.

### Design / API

Three exported functions, each acting on a notebook and settable from the palette, plus the palette controls that drive them:

```
SetDocumentFontSize[ notebook, size ]
SetMathFontSize[ notebook, size ]
SetContentWidth[ notebook, width ]   (* withdrawn in session 8 *)
```

Mechanisms to evaluate in T1, cheapest first:

| Concern | Candidates |
|---|---|
| Prose / math size | private style definitions via `CurrentValue[ nb, { StyleDefinitions, style, FontSize } ]`; `StyleHints`; regenerating the stylesheet with a size parameter |
| Screen-only zoom | `CurrentValue[ nb, Magnification ]` |
| Content width | a native front end setting (check 15.0 menus and `$FrontEnd` options first); `PageWidth`; symmetric `CellMargins` in private style definitions; `ScreenStyleEnvironment` |

The style names to touch are already partitioned in `Scripts/BuildStyleSheets.wls` as `$proseStyles` and `$mathStyles` — reuse those lists rather than hardcoding a second copy.

### Edge cases & out of scope

- **MaTeX cells are images.** They are rasterized at a fixed `FontSize -> 14`, so no font-size control can rescale them; changing sizes must either re-render them through `ConvertToMaTeX` or say plainly that it cannot. Decide which.
- All four templates plus `Default.nb` must behave; the controls cannot assume MathNotebook styles are loaded.
- Equation numbers live in `CellFrameLabels` with their own style (`DisplayFormulaEquationNumber`) — they need to scale with the math, or they drift visually.
- Private style definitions must not clobber a stylesheet the user re-applies afterwards; applying a stylesheet from the palette should probably clear the overrides.
- Print/PDF output is the acceptance test, not the screen.
- Out of scope: per-cell formatting (the front end already does that), and any change to the stylesheet files themselves.

## Tasks

### Done

- [x] T1 — Investigate the three mechanisms in a scratch notebook; write down what actually works in 15.0, especially whether a native centered-content-width option exists. (Session 1)
- [x] T2 — Foldable groups with persisted state; rebuild the palette and its screenshot. (Session 2)
- [x] T3 — `SetDocumentFontSize` / `SetMathFontSize` plus palette sliders, with a reset, and a decision recorded on MaTeX cells. (Session 3)
- [x] T4 — `SetContentWidth` plus slider — exposing the native option if T1 found one, otherwise private style definitions. (Session 4)
- [x] T5 — Document all of it in the tutorial (`Scripts/BuildTutorial.wls`), in a new section on reading and writing comfortably; tests for the three functions. (Session 5)
- [x] T6 — Feedback round: Pavel writes with it on a real document; revise. (Sessions 6–9)

## Progress

### Session 1 — 2026-07-25 — T1

- **Did:** Investigated all three mechanisms and wrote `PaletteUsability-T1.nb` alongside this file — a runnable harness plus seven experiments and a Findings section.
  Every claim is measured on an exported PDF (wrapped line count as a font-size proxy, ink column extent for layout), not judged by eye.
  All seventeen input cells were re-evaluated after generation and each number in the prose matches its cell's output.
- **Learned:**
  - **There is no native centered-content-width option in 15.0.** Checked the Format menu (only the three `PageWidth` word-wrapping items), `Options[$FrontEnd]`, the Preferences dialog resource, and the screen style environments (Working, Presentation, SlideShow, Condensed). `SetContentWidth` has to be built.
  - **`CurrentValue[ nb, { StyleDefinitions, style, option } ] = value` is silently ignored** — it does not convert a shared stylesheet into a private one and does not record the value. The private sheet must be constructed and installed with `SetOptions`. The Spec's cheapest candidate is therefore not available.
  - **The `"Printout"` environment beats a plain style definition across the whole chain.** `LaTeXBase` gives every prose and math style an explicit `FontSize` in its `"Printout"` variant, so an override on the bare style name changes the screen and leaves the PDF byte-identical. Every setter must write both variants. This is the single biggest constraint on T3 and T4 and it is invisible on screen.
  - **Duplicate `StyleData` cells for the same name and environment in one sheet are both dropped** and the parent value survives — so a setter must rewrite its override cell in place, never append.
  - **`Magnification` does not reach print** (identical PDFs at 1 and 2), confirming it must stay a separate control.
  - **Content width works via symmetric `Scaled` in `CellMargins`**, which the front end resolves against `PageWidth` — `WindowWidth` on screen, the printable width in print. A fraction of 0.2 gives a centered column, verified in print. The slider therefore sets a *fraction*, not a point width.
  - **`Dynamic` in `CellMargins` is accepted and lays out identically to the static equivalent.** What breaks is a *window-driven* Dynamic in print, since there is no window — it collapsed the printed measure to a third. A true fixed point width is reachable by splitting the environments (window Dynamic on screen, static margin in print), but that Dynamic could not be verified here: a headless front end never lays out to a window. Check it interactively before preferring it to `Scaled`.
  - **Reset is clean.** The parent sheet is recoverable from the wrapper with `FirstCase[ ..., Cell[ StyleData[ StyleDefinitions -> name_ ] ] :> name ]` and assigning it back leaves no trace. It arrives as a string from the menus but as a `FrontEnd`FileName` from the palette's *Apply stylesheet*, so carry it through as-is. That same button already discards the wrapper, so switching template resets everything as a side effect.
  - **MaTeX cells can be rescaled after all.** `toMaTeXCell` stores the TeX in `TaggingRules` under `"SourceTeX"` and renders at a hardcoded `FontSize -> 14`, so a size change can re-render rather than give up.
  - **Theorem, Proof and Abstract draw their dingbat in the left margin**, so a narrow column makes it protrude past the text block. Preserving each style's indent relative to `Text` beats giving every style the same margin pair.
  - Headless testing note: `"MathNotebook/AMSArticle.nb"` resolves in the service front end, but `FrontEnd`FileName[ { <absolute path> }, ... ]` does not — it silently falls back to `Default.nb`, which produced two wrong intermediate results before being caught. Always assert the sheet loaded (`CurrentValue[ nb, { StyleDefinitions, "Title", FontSize } ]` is 26, not 45).
- **Next:** T2 — foldable palette groups with state in `$FrontEnd` tagging rules.

### Session 2 — 2026-07-25 — T2

- **Did:** Rewrote `Scripts/BuildPalette.wls` so the palette is a list of six foldable groups instead of a flat `Column` of labels and buttons.
  The seventeen buttons are now data — `$groups` is a list of `{ key, label, buttons }` — rendered by either `paletteGroup` (the live, foldable version written into the palette) or `staticGroup` (a fully-open rendition used only for the README screenshot, because `Rasterize` does not evaluate `Dynamic`).
  Each group header is an `Opener` plus a click-anywhere label that highlights on hover.
  Rebuilt `MathNotebook/FrontEnd/Palettes/MathNotebook.nb` and `Images/Palette.png`; all 35 tests still pass and the script runs clean under `wolframscript`.
- **Learned:**
  - **The Spec's premise about persistence was wrong, and the native channel is better.** `Saveable -> False` does not stop a palette's own tagging rules from persisting: the front end saves them in `$UserBaseDirectory/FrontEnd/init.m` under `CurrentValue[ $FrontEnd, PalettesMenuSettings ]`, an association keyed by palette file name — and `"MathNotebook.nb"` is already a key there.
    `WritingAssistant.nb` and `ColorSchemes.nb` store exactly this kind of fold state that way (`"ShowWritingTools" -> True`, `"GradientsOpener" -> True`).
    So state is written on `EvaluationNotebook[]` under a flat key (`"ReferencingOpen"`, …), matching Wolfram's own palettes, instead of polluting global `$FrontEnd` tagging rules.
  - **`PaneSelector` sizes to the *largest* pane unless `ImageSize -> Automatic` is given explicitly.** Without it a closed group still reserves its open height, so the fold does nothing — measured 540 px for both states, versus 540 open / collapsed closed with the option. This is the one non-obvious line in the implementation.
  - **`CurrentValue[ EvaluationNotebook[ ], { TaggingRules, key }, True ]` is the whole mechanism** — a three-argument `CurrentValue` supplies the default, so no initialization is needed and no kernel is ever launched to display or fold the palette. Assignment happens in an `EventHandler` with `Method -> "Preemptive"`, copied from `BasicMathAssistant.nb`. The label is a `PaneSelector` over two handlers (one setting `False`, one setting `True`) rather than a `Not`, so nothing has to be computed.
  - **Fold state drives layout, verified by measurement.** With tagging rules baked into a copy of the palette, `AbsoluteCurrentValue[ nb, WindowSize ]` gives 603 px tall for the default (all open), 211 px all closed, and 308 px with only Referencing open. `WindowSize -> { All, All }` refits at open time.
  - **Whether the window refits *live* on a click could not be verified headlessly** — a kernel-side write to an open palette's `TaggingRules` neither changed the size nor read back. `BasicMathAssistant.nb` folds live with this same construction, so it is expected to work; confirm by hand.
  - `Rasterize` renders `Dynamic` as an unevaluated placeholder and `PaneSelectorBox` at its default max size, so a raster can neither show nor measure fold state — hence the separate static rendition for the screenshot.
  - **Do not `Import` a palette `.nb` into a variable to inspect it.** The returned expression is re-evaluated, so the literal `EvaluationNotebook[]` inside it evaluates to `$Failed` with `FrontEndObject::notavail` and every `CurrentValue` collapses to its default — which silently emptied two verification queries. Read it as text and match with `StringCases`, or count boxes without dereferencing.
  - `Images/` was never added to git even though `README.md` embeds `Images/Palette.png`; tracked as of this session.
- **Next:** T3 — `SetDocumentFontSize` / `SetMathFontSize` plus palette sliders, with a reset, and a decision recorded on MaTeX cells.

### Session 3 — 2026-07-26 — T3

- **Did:** Added `MathNotebook/Kernel/View.wl` with `SetDocumentFontSize`, `SetMathFontSize` and `ResetDocumentView`, and a *Document view* group to the palette holding a text-size slider, a math-size slider and a *Reset view* button.
  A size is stored on the document under `{ TaggingRules, "MathNotebook", <key> }` and the whole private stylesheet is rebuilt from those two values on every call, so the sliders read a document's real state and no override cell is ever appended twice.
  Both sliders scale the *whole* hierarchy proportionally about `Text` (prose) and `DisplayFormula` (math): the ratios are read out of the paclet's own `LaTeXBase.nb` at run time, so nothing about the size hierarchy is restated in kernel code.
  MaTeX cells are re-rendered from their stored TeX at the scaled size, as T1's decision required.
  Verified on exported PDFs: 9 → 12 → 8 wrapped body lines at Text 13 / 18 / 9 and exactly 9 again after reset, with the notebook's `StyleDefinitions` back to the bare `"MathNotebook/AMSArticle.nb"` and its tagging rules empty; MaTeX images measured 46 px wide at math 13, 89 px at math 26, and 46 px again after reset; palette window 695 px all open, 247 px all closed, 303 px with only *Document view* open.
  All 35 tests still pass.
- **Learned:**
  - **In the `Package[]` format an undeclared symbol is private to its own file.** `writeCells` is defined in `Conversion.wl` without a `PackageScope` declaration, so `View.wl` got its own definition-less `View`PackagePrivate`writeCells` and the MaTeX re-render **silently did nothing** — the call simply stayed unevaluated, with no message and no failure. Declaring `PackageScope["writeCells"]` fixed it. The same latent bug sits in the *uncommitted* `MaTeX.wl` work, whose `ConvertToMaTeX[{cell, ...}]` / `ConvertFromMaTeX[{cell, ...}]` selection paths call `writeCells` across files; the one-line declaration repairs those too.
  - **The front end drops `TaggingRules` from a private stylesheet notebook** — as a string, a rule list or an association alike — while adding `Visible` and `FrontEndVersion` of its own. So a generated sheet cannot be recognised by its options. A hidden marker *cell* (`Cell[StyleData["MathNotebookView"], StyleMenuListing -> None, MenuSortingValue -> None]`) survives intact. Without it every call nested the previous sheet inside the new one — measured three deep — and reset silently left the overrides in place.
  - **Reading the size hierarchy back out of `LaTeXBase.nb` is exact and cheap.** Styles that inherit from `Text` carry *no* bare `FontSize` but *do* carry an explicit `"Printout"` size, so the extraction naturally yields 11 screen sizes and 25 printout ones; writing only the variants that exist keeps theorem and proof styles inheriting from `Text` on screen while still reaching print.
  - `Rasterize` needs a static stand-in for *every* dynamic item, not just the fold: the slider rasterised with its thumb at the minimum and the readout as a `⋮` placeholder. `Scripts/BuildPalette.wls` now pairs each dynamic item with a static one through `dual[ live, static ]`, which `paletteGroup` and `staticGroup` select from.
  - `FrontEnd`CurrentValue[ FrontEnd`InputNotebook[], { TaggingRules, ... }, default ]` inside a `Dynamic` is the front-end-side idiom for a palette control that follows the focused document — `SlideShow.nb` uses exactly this shape. Nested `TaggingRules` paths do resolve in the front end. **Not verifiable headlessly:** whether the slider tracks a document switch live and whether its release-time setter fires, same limitation as T2's fold.
  - Newly converted MaTeX cells still render at the base size of 14 until the math slider is touched again — `ConvertToMaTeX` does not yet consult the document's math size. Left as a rough edge for T6 rather than widening T3.
  - The service front end's link died reproducibly at the tail of a long verification script (five PDF exports, then a second document). The same steps pass in isolation; split long headless front-end checks into separate scripts.
  - The installed paclet was still 0.1.3, two sessions stale, so the palette Pavel actually saw had neither the folding nor the view controls.
    Built and installed 0.1.4 at the end of this session — the archive must include `FrontEnd/` and `Assets/` as well as `Kernel/` and `Tests/`, which the generic build recipe omits; without them the palette, the five stylesheets and the tutorial vanish from the install.
    The front end needs a restart before the new palette is served.
- **Next:** T4 — `SetContentWidth` plus slider.

### Session 4 — 2026-07-26 — T4

- **Prompt:** `/next-session` on this item, plus mid-session feedback from Pavel — "the reference cell looks ugly, not showing the tag [...]. Also the font size is not changed in itemized, references, theorem etc. cells" — filed as `Work/Backlog/ViewAndReferenceDefects.md` rather than worked here.
- **Did:** Added `SetContentWidth` to `MathNotebook/Kernel/View.wl` and a *Column width* slider to the palette's *Document view* group, so the three sliders now share one `viewSlider` and one static stand-in.
  The width is the fraction of the page the content column occupies; each column style gets `CellMargins -> { { Scaled[ inset ] + dLeft, Scaled[ inset ] + dRight }, base vertical }` with `inset = (1 - width)/2`, on the bare style and its `"Printout"` variant.
  The per-style offsets are read from the document's own stylesheet chain and measured from the smallest base margin, so no offset is negative and every style keeps its indent.
  Verified on exported PDFs at 595 pt: ink columns `{ 73, 521 }` unmodified, `{ 163, 422 }` at width 0.6 — the left edge moving in by exactly `0.2 × 451.28` pt of printable width — `{ 87, 498 }` at 0.9, and `{ 73, 521 }` again after `ResetDocumentView`, with `StyleDefinitions` back to the bare `"MathNotebook/AMSArticle.nb"`, the tagging rules `Inherited`, and exactly one marker cell in the sheet (no nesting).
  On screen the right text edge moves 855 → 623 px at 0.6 and back on reset, and the same holds on a document still on `Default.nb` (855 → 583 → 855), which the control has to support.
  The generated margin cells read `{ 26 + Scaled[0.2], Scaled[0.2] }` for `Text`, `{ Scaled[0.2], 15 + Scaled[0.2] }` for `Section`, `{ 90 + Scaled[0.2], Scaled[0.2] }` for `Theorem` and `{ 41 + Scaled[0.2], Scaled[0.2] }` for `Item`.
  Palette rebuilt with its screenshot: 715 px tall all open, 247 px all closed, 323 px with only *Document view* open. All 35 tests still pass, and 0.1.5 is built and installed so the slider is actually in the front end after a restart.
- **Learned:**
  - **`CellMargins` accepts `Scaled[fraction] + points` and the front end resolves the sum** — measured 14 wrapped lines for `Scaled[0.1]` against 23 for `Scaled[0.1] + 200`, and `Scaled[0.1] + Scaled[0.44]` laid out identically to `Scaled[0.54]`. This is what T1 left open, and it is the whole design: a symmetric `Scaled` inset centers the column while a per-style point offset keeps the section numbers and the theorem, proof and abstract dingbats, which are drawn to the left of their own cell margin, inside the page.
  - **Reading `CurrentValue[ nb, { StyleDefinitions, style, option } ]` resolves through the whole chain**, even though assigning to it is ignored (T1). It returns `{ { 81, 10 }, { 4, 8 } }` for `Item` — a style no MathNotebook sheet declares — and works on a `Default.nb` document. So base geometry comes from the document's parent sheet at run time rather than from `LaTeXBase.nb`, which is what makes the control correct on all five sheets.
  - **Offsets have to be measured from the smallest base margin, not from `Text`.** `Section` sits 26 pt *left* of `Text`, so anchoring on `Text` would make the section number's offset negative and push it off the page as the column widens. Anchoring on the minimum also fixes the slider's top end: 0.9 is both the default and the maximum, since the dingbats hang left of the anchor by their own width and zero inset would clip them.
  - **T3's font-size mechanism is broken for most of the prose, and this task's reader is the fix.** Measured after `SetDocumentFontSize[ document, 20 ]`: `Text` 13 → 20, `Abstract` 12 → 18, `Title` 26 → 40, but `Theorem`, `Proof` and `Reference` stay at 13 and `Item` and `ItemNumbered` at 15. Two causes — a style declared `StyleData[ name, StyleDefinitions -> StyleData[ "Text" ] ]` carries no bare `FontSize` and does not inherit a child sheet's `Text` override, and the list styles are not in `LaTeXBase.nb` at all. This is exactly Pavel's report; it is T1 of the new item.
  - **The generated palette `.nb` already carries a `TaggingRules` association** — all groups `True`, written by the exporting front end. Patching fold state for a measurement has to replace it, since a second copy of the option is ignored and the first wins; and `Get`ting the palette to patch it re-evaluates it, which is the trap that reported one window size for all three fold states. Both mistakes were made and caught here. WL's `RegularExpression` also needs `(?s)` to match across the association's line breaks.
  - Ink-column measurements are exact in print (the 0.6 shift matched `0.2 × 451.28` pt to the pixel) but not on screen, where `Scaled` resolves against a `PageWidth` noticeably wider than the window: the right edge moved 232 px where the window width predicts 180. Use print for numbers, screen only for direction.
- **Next:** T5 — document the three controls in the tutorial and add tests.

### Session 5 — 2026-07-26 — T5

- **Prompt:** `/next-session` on this item.
- **Did:** Added a *Reading and Writing Comfortably* section to `Scripts/BuildTutorial.wls` — ten items covering the fold, the three sliders, what each one scales, that they are real sizes and margins rather than `Magnification`, that they are stored in the notebook and survive save and reopen, the MaTeX re-render, reset, and the four functions from code — and rebuilt `MathNotebook/Assets/MathNotebookTutorial.nb`.
  Added `MathNotebook/Tests/View.wlt`, fourteen tests over the pure core: the size hierarchy read out of the base sheet, an untouched document producing no override cells, the anchor size reproducing every base size exactly, the whole hierarchy scaling, prose and mathematics staying independent, the equation number scaling with the math, the `"Printout"` variant always being written, the width arithmetic, and the stylesheet wrapper's parent cell and marker.
  The margin tests stub `baseCellMargins[ "StubSheet.nb" ]` so the arithmetic is checked without a front end; the suite stays kernel-only and now runs 49 tests, all passing.
  Writing those tests turned up a real defect and it is fixed here: `viewStyleCells` emitted the font size and the column margin for a style as **two** cells, so setting a text size made the column width a silent no-op on every style that also carries a size — which is nearly all of them.
  `mergedStyleCells` now folds the generated cells into one per style and environment.
  Verified in print on an AMS-styled document: ink column `{ 108, 520 }` by default, `{ 60, 534 }` at text size 20, `{ 176, 424 }` at text size 20 *and* width 0.6 — the combination that previously did nothing — and `{ 108, 520 }` again after `ResetDocumentView`, with `Text` back at 13.
  Save/reopen verified separately: sizes, margins and the stored tagging rules all come back unchanged, and reset afterwards still restores the bare parent sheet with `TaggingRules` `Inherited`.
  Built and installed 0.1.6 so T6's feedback round runs against the fix.
- **Learned:**
  - **Of two `StyleData` cells for the same style and environment, the first wins and the second is discarded whole** — measured directly, both for the same option written twice (30 and 44 → 30) and for two different options (a `FontSize` cell followed by a `CellMargins` cell → the size applied, the margins fell back to the parent's `{ { 66, 10 }, { 7, 8 } }`). T1 recorded this as "both dropped", which is not what happens and hides the failure mode that actually bit: the option in the second cell is the one that vanishes. `CLAUDE.md` corrected.
  - **The `PackageScope` trap caught the tests themselves.** `fontSizeCells` has no `PackageScope` declaration, so the test's call stayed unevaluated and `Cases` over it returned `{ }` — a test that failed for a reason unrelated to what it was testing. Rewrote it through `viewStyleCells` rather than widen the package surface for a test.
  - **`Scaled[ f ] + 0` evaluates to `Scaled[ f ]`**, so a pattern like `Scaled[ _ ] + offset_?NumericQ` silently skips every style whose offset is zero. Assert the absence of negative offsets instead of taking a `Min`.
  - **Neither sheet reference resolves headlessly any more.** `StyleDefinitions -> "MathNotebook/AMSArticle.nb"` fell back to `Default.nb` in `wolframscript` with 0.1.5 installed, exactly as `FrontEnd`FileName` does — the `Title` size read 45, not 26. `StyleDefinitions -> Get[ <absolute path> ]` loads it every time. Two whole measurement runs were made on `Default.nb` before the assertion caught it; the assertion is the only reason the numbers above are trustworthy.
  - The tutorial deliberately does not claim that the text slider scales the theorem, proof, reference or list styles, because it does not yet — that is T1 of `ViewAndReferenceDefects`. The section is accurate as written and needs one more sentence once that item lands.
- **Next:** T6 — Pavel writes with it on a real document; revise.

### Session 6 — 2026-07-26 — T6 (feedback round open)

- **Prompt:** `/next-session` on this item, then six numbered feedback points from Pavel as he drove the palette.
- **Did:** Prepared the round, then revised against the one point that was fully determined.
  Found and removed a stale **0.1.0** install that was still shipping the *pre-fold* flat palette — with two versions installed there was no guarantee which palette the front end served, so any feedback before this was against an unknown build.
  Added `Scripts/BuildViewProbe.wls`, generating `Work/Active/PaletteUsability-T6.nb`: a one-screen `AMSArticle` probe holding every style the three controls touch, in stylesheet order, so a size or width change is readable straight down the page and the styles that do *not* follow are equally visible.
  Fixed Pavel's point 2 (**text size does not reach itemized, reference or theorem cells**) by replacing `baseFontSizes[]`, which extracted sizes from `LaTeXBase.nb`, with `baseFontSizes[ parent ]`, a chain reader memoized per parent sheet exactly parallel to T4's `baseCellMargins`.
  Verified on an `AMSArticle` document after `SetDocumentFontSize[ document, 20 ]`: `Theorem`, `Proof` and `Reference` 13 → 20 and `Item`/`ItemNumbered` 15 → 23, all five of which previously did not move at all; `Text` 13 → 20, `Title` 26 → 40, `Abstract` 12 → 18 unchanged in behaviour; the `"Printout"` variants scale too; `ResetDocumentView` restores every base size exactly and leaves the tagging rules `Inherited`.
  Suite is 51 tests including a regression test that asserts a screen cell is written for each of the five styles.
  Disproved the cheap fix for point 1 by measurement before writing any of it, and filed points 3, 5 and 6.
- **Learned:**
  - **`{ style, "Printout" }` in a `StyleDefinitions` path resolves the print environment through the whole chain**, while `StyleData[ style, "Printout" ]` in the same position silently returns the *screen* value — which would have written every printout override at its screen size and been invisible until a PDF was compared. This is what made point 2's fix possible at all.
  - **`Scaled` cell margins are relative and cannot be made absolute by arithmetic.** `Scaled[0.5] + (-width/2)` is exactly the shape that ought to cancel `PageWidth` out, and it does stay perfectly centered — ink midpoints 305 and 412 on 612 pt and 842 pt paper — but the block width goes 290 → 594. `PageWidth -> w` in a style *is* absolute (identical ink on both papers) and left-aligns; the two mechanisms combined collapsed the block to 73 pt and were not centered. So point 1 is a genuine design change, not a tweak, and it needs Pavel's call between absolute-left-aligned and absolute-centered-via-a-screen-only-`Dynamic`.
  - **A private sheet whose parent is an embedded notebook lets unoverridden styles fall through to `Default.nb`.** In the verification run the math styles read `DisplayFormula` 14 and `DisplayFormulaEquationNumber` `-1 + Inherited` — Default's values — after a *prose* size change, which reads exactly like the prose control leaking into mathematics. It is a harness artifact of `Cell[StyleData[StyleDefinitions -> Get[path]]]`, the only form that loads a paclet sheet headlessly; prose/math independence is covered by a kernel test instead of by that number. Two earlier measurements were nearly reported as defects because of it.
  - **The `PackageScope` trap caught the new tests again**, third session running: `styleFontSizeNames` has no declaration, so the test's direct call stayed unevaluated and `Intersection` errored on an unevaluated head. Rewrote both new tests through `viewStyleCells` rather than widen the package surface.
  - **The chain reader costs the suite its kernel-only property.** One test passes a real sheet name and now needs a front end, failing on `FrontEndObject::notavail` messages alone with a correct value; stubbing `baseFontSizes[ "AMSArticle.nb" ]` restores it.
  - Pavel's point 6 settles a question `ViewAndReferenceDefects` T2 had left open: the `Reference` label is the cell's **custom tag**, not an auto-incremented `[1]`.
- **Next:** T6 stays open, and Pavel chose to finish it next: build the column width as an **absolute, centered** point measure with a `Full` position (his decision, recorded below).
  Point 4 is closed as not-a-defect — the palette follows the front end, which is `Automatic` against a dark macOS; see the decision below.
  Points 3, 5 and 6 are filed and out of T6's way: 3 → `Work/Backlog/ConversionUX.md`, 5 and 6 → `Work/Backlog/ViewAndReferenceDefects.md`.
  Still unverified interactively from T2 and T3, and worth a look in the same pass: whether the fold refits live on a click, whether the sliders follow a document switch, and whether the release-time setter fires.

### Session 7 — 2026-07-26 — T6 (feedback round still open)

- **Prompt:** `/next-session` on this item.
- **Did:** Rebuilt the column width as the **absolute, centered point measure** Pavel asked for, with `Full` at the top of the slider.
  `contentWidthCells` now emits different arithmetic per environment: on screen a symmetric `Scaled[ 0.5 ] - width/2`, in print a point inset `( printable - width ) / ( 2 × magnification )` computed from the paper the document is set to print on.
  `baseCellMargins` reads both environments, as `baseFontSizes` already did; new `printableWidth` and `printMagnification` supply the paper geometry; `SetContentWidth` takes `Full` and treats the top of the slider's range as `Full`, which is stored as no setting at all because that is already the unconstrained page.
  The palette slider is now `{ 240, 500, 20 }` points with `Full` shown at the top — the slider and the readout take *different* three-argument `CurrentValue` defaults, so an unset document reads `Full` in the readout and the top step on the slider with no front-end-side logic at all.
  Tutorial, usage string and the palette screenshot rebuilt; 0.1.7 built and installed, and it is the only version present.
  Suite is 54 tests: the screen column, Section's hang, the printed measure in paper points, the clamp, and `Full`.
  Two defects found and fixed while verifying, neither of them the thing being changed: the offsets were anchored on the *smallest* base margin, which centers the hull and left the body text 11.5 pt right of centre on a 340 pt column; and `printableWidth` was read through the private sheet this function had installed on the previous call, where `PaperSize` answers `Automatic` and every printed margin came out of a symbolic width — the second `SetContentWidth` on a document produced a column *wider* than the untouched page. The parent sheet now goes back on before the read.
- **Learned:**
  - **`Scaled` in `CellMargins` resolves against the window in print as much as on screen** — a bare `Scaled[ 0.2 ]` in the `"Printout"` variant put the left ink at 174 on both 612 pt and 842 pt paper. T4 recorded that a `Scaled` print inset tracked the printable width and T6 recorded that only the `+ points` sum was broken; both were wrong, and the sum form is fine. The consequence is the whole design: on screen `Scaled[ 0.5 ] - width/2` *is* an absolute centered column that tracks a resize, and in print `Scaled` is unusable.
  - **A printout cell margin is laid out at 0.72 and only then put on the paper** — `Default.nb` gives `Cell[ StyleData[ All, "Printout" ] ]` a `Magnification -> 0.72`. Verified to the point at 200, 300 and 400 pt on two papers. It is not readable as a style option (`{ style, "Printout" }` answers 1); `AbsoluteCurrentValue[ nb, Magnification ]` on a scratch document created with `ScreenStyleEnvironment -> "Printout"` is what resolves it.
  - **The embedded-parent trap reaches notebook options, not only styles.** With an embedded parent `PrintingOptions` answers `Automatic`, and a headless PDF export uses `Default.nb`'s 54 pt printing margins while a read taken before the wrap reports the sheet's own 72 — a disagreement of exactly the size that makes a correct absolute column look wrong. Both numbers were nearly written up as defects.
  - **Do not stage a stylesheet into `$UserBaseDirectory/SystemFiles/FrontEnd/StyleSheets/`** to get a sheet to resolve by name in a script. It resolves, and then every subsequent front end launch on the machine hangs indefinitely — including the palette and tutorial builds — until the directory is removed. Two sessions were wedged and a round of kernels killed before the cause was found; killing kernels that broadly can also take out an interactive notebook's kernel, so scope it to the script's own pid.
  - Only the **left** ink edge of an exported page is exact — prose is ragged right — and the page headers and footers have to be turned off or their own margins widen the measured column.
- **Next:** T6 stays open on Pavel.
  What no script can check, and what his own recorded decision requires before this control is done: that the column is centered and stays centered as a real window is resized, since a headless front end resolves screen `Scaled` against a constant 706 rather than the window.
  Worth the same pass, still unverified from T2 and T3: whether the fold refits live on a click, whether the sliders follow a document switch, and whether the release-time setter fires.

### Session 8 — 2026-07-26 — T6 (feedback round still open)

- **Prompt:** `/next-session` on this item, then two mid-session messages from Pavel: first "keep the column width relative … obviously the absolute does not work and the relative is more natural", then "just remove that functionality whatsoever".
- **Did:** Removed the content-width control outright.
  The session opened on the interactive verification the last two left hanging; Pavel's first message redirected it to reverting the width to a fraction, and his second withdrew the control entirely, which is what shipped.
  Gone from `View.wl`: the exported `SetContentWidth`, `contentWidthCells`, `marginCells`, `styleOffsets`, `baseCellMargins`, `printableWidth`, `printMagnification`, `columnStyleNames`, `$fullContentWidth`, and the `printable` argument that `viewStyleSheet` and `viewStyleCells` carried only for it.
  Gone from the palette: the *Column width* slider, and `viewSlider`'s `readoutDefault` parameter, which existed only so an unset document could read `Full`.
  Gone from the tutorial, the usage strings and `PacletInfo.wl`'s symbol list.
  `ResetDocumentView` keeps clearing the old `"ContentWidth"` tagging rule through a new `$obsoleteViewSettingKeys`, so a document written with 0.1.5–0.1.7 still resets to no trace — verified on a document seeded with a stored width of 300, whose tagging rules came back `Inherited`.
  Suite is 47 tests (was 54): the six width tests are gone, replaced by one asserting a `"ContentWidth"` setting now generates nothing, and the `columnStyleNames` test dropped as dead — its coverage of the list styles is already carried by the text-size test, which intersects the real name list against the stub.
  Verified end to end on an `AMSArticle` document: `Text` 13 → 20, `Theorem` 13 → 20, `Item` 15 → 23, `Title` 26 → 40 and the `"Printout"` variant 10 → 15 after `SetDocumentFontSize[ document, 20 ]`; `DisplayFormula` and `DisplayFormulaEquationNumber` 13 → 26 after `SetMathFontSize[ document, 26 ]` with `Text` left at 20; every size back to base after `ResetDocumentView`, the private sheet unwrapped and the tagging rules `Inherited`.
  No `CellMargins` appears among the 50 generated override cells, and the document's `Text` and `Section` margins read back exactly at base after a reset.
  Palette, screenshot and tutorial rebuilt; 0.1.8 built and installed, and it is the only version present.
- **Learned:**
  - **Reading `CellMargins` through an installed private sheet answers `PrivateStylesheetFormatting.nb`'s own geometry** — `{ { 7, 3 }, { 4, 4 } }` for both `Text` and `Section`, where the document's real values are `{ { 66, 10 }, { 4, 4 } }` and `{ { 40, 25 }, { 10, 28 } }` and `Default.nb`'s are `{ { 66, 10 }, { 7, 8 } }` and `{ { 27, 3 }, { 8, 18 } }`.
    This is a third face of the embedded-parent trap, and it briefly read as the removal having changed the margins.
    A structural check on the generated cells settles such a question directly, and needs no front end.
  - `FreeQ[ CurrentValue[ nb, StyleDefinitions ], CellMargins ]` cannot show that a control writes no margins: the private sheet embeds the whole parent, which is full of them. Test `Rest @ Rest @ First @ ...`, the cells after the parent reference and the marker.
  - Removing the width left `mergedStyleCells` with no overlapping styles to merge — prose and mathematics are disjoint. It stays, because the two lists are generated independently and it is what makes that safe; the comment now says so instead of naming the width.
- **Next:** T6 stays open on Pavel — the palette is now the fold, a text-size slider, a math-size slider and a reset, and it needs his sign-off on that.
  Still unverified interactively from T2 and T3, and unchanged by this session: whether the fold refits live on a click, whether the sliders follow a document switch, and whether the release-time setter fires.

### Session 9 — 2026-07-26 — T6 (closed)

- **Prompt:** `/next-session` on this item, then Pavel's sign-off on the shipped palette.
- **Did:** Closed the feedback round and completed the item.
  Refreshed `Scripts/BuildViewProbe.wls` and regenerated `PaletteUsability-T6.nb`, which was built in session 6 and still narrated the column-width control that 0.1.8 removed — three stale passages, and an Abstract pointing at a checklist the notebook never contained.
  The probe now describes two sliders rather than three, says which styles each one should move, and carries a *What to Check* section holding the six things no script can verify: that a fold refits the palette window on the click rather than on the next open, that fold state survives a front end restart, that both sliders follow the focused document, that the release-time setter fires while dragging does not, that reset leaves no trace, and that the palette is comfortable to keep open beside a real paper.
  Confirmed the installed 0.1.8 palette carries exactly *Text size*, *Math size* and *Reset view* under *Document view*, with no width remnant, and that 0.1.8 is the only version installed.
  Pavel signed off on that palette, which closes T6 and, with it, the item.
- **Learned:**
  - **A probe document is deliverable state and goes stale like any other.** This one survived the withdrawal untouched for a session, so the artifact built specifically to make the feedback round honest would have handed Pavel a page describing a control that no longer exists. Anything generated for a review round wants regenerating whenever what it reviews changes.
  - The three interactive behaviours that T2 and T3 could not verify headlessly — live refit on a click, sliders following a document switch, the release-time setter — are **accepted on Pavel's sign-off**, not measured. They are written into the probe's checklist so that a future regression has somewhere to be caught.
- **Next:** none — item complete.
  The nearest follow-on is `Work/Backlog/ViewAndReferenceDefects.md` T2, and the tutorial's *Reading and Writing Comfortably* section can now claim the text slider reaches the theorem, proof, reference and list styles, which session 5 deliberately left out and session 6 made true.

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-25 | Implement `SetContentWidth` ourselves; no native option is exposed | 15.0 has no centered-content-width setting anywhere in the menus, `$FrontEnd`, Preferences, or the style environments |
| 2026-07-25 | Private style definitions installed with `SetOptions`, built and rewritten in place | `CurrentValue` assignment to a `StyleDefinitions` path is ignored, and duplicate `StyleData` cells cancel each other |
| 2026-07-25 | Every override writes both the bare style and its `"Printout"` variant | the environment-specific definition wins across the chain, so a bare override never reaches the PDF |
| 2026-07-25 | Content width is a fraction of the window via symmetric `Scaled` cell margins, not a point width | `Scaled` resolves against `PageWidth`, which is `WindowWidth` on screen; the point-width alternative needs a Dynamic that cannot be verified headlessly |
| 2026-07-25 | Font-size changes re-render MaTeX cells rather than declining to scale them | the TeX survives in `TaggingRules` under `"SourceTeX"` |
| 2026-07-25 | Reset restores the recovered parent stylesheet value verbatim, whatever its form | the palette supplies a `FrontEnd`FileName`, the menus a string |
| 2026-07-25 | Fold state lives in the palette notebook's own `TaggingRules`, not `$FrontEnd`'s — a deviation from the Spec's requirement, pending Pavel's confirmation | the front end already persists palette tagging rules in `init.m` under `PalettesMenuSettings`, keyed by palette file name, so `Saveable -> False` is irrelevant; this is what the built-in palettes do and it keeps the state scoped to the palette |
| 2026-07-25 | Every group opens by default | folding is opt-in, so a first-time user still sees all seventeen buttons; the closed-by-default alternative hides functionality |
| 2026-07-26 | One slider scales the whole hierarchy proportionally about `Text` (prose) / `DisplayFormula` (math), rather than setting one style | an author wants the document bigger, not `Text` bigger while `Title` stays put; the ratios come from `LaTeXBase.nb` so they are never restated in code |
| 2026-07-26 | View state lives on the document under `{ TaggingRules, "MathNotebook", <key> }` and the private sheet is rebuilt whole on every call | the front-end-side slider can then read the focused document's real size, and rebuilding sidesteps the duplicate-`StyleData` trap entirely |
| 2026-07-26 | The generated sheet is marked by a hidden `StyleData` cell, not by notebook options | the front end drops `TaggingRules` from a stylesheet notebook, so options cannot carry a marker; without one the sheets nest and reset cannot recover the parent |
| 2026-07-26 | Applying a stylesheet from the palette also clears the stored sizes | the new sheet replaces the private one, so keeping the numbers would make the sliders report a size the document no longer has |
| 2026-07-26 | No `Magnification` slider | the Spec warns against conflating the two and the front end already has a window zoom control; revisit if T6 asks for it |
| 2026-07-26 | `ResetDocumentView` is a fourth exported function beside the three in the Spec | "any control returns to the stylesheet default" needs both a per-control reset (`Automatic`) and a one-click clear-all; T4's width joins the same reset |
| 2026-07-26 | The width is a fraction of the page, realised as a symmetric `Scaled` inset plus a per-style point offset | `Scaled` resolves against `PageWidth`, so the column follows a window resize and still prints; the offsets keep the hanging section numbers and dingbats inside the page, which one margin pair for every style would not |
| 2026-07-26 | Per-style base geometry is read from the document's own stylesheet chain, not from `LaTeXBase.nb` | reading `{ StyleDefinitions, style, CellMargins }` resolves through the chain, so the control covers the list styles the paclet never declares and a document still on `Default.nb` |
| 2026-07-26 | Offsets are anchored on the smallest base margin, and the slider tops out at 0.9 rather than 1 | `Section` sits left of `Text`, so a `Text` anchor gives negative offsets; and the dingbats hang left of the anchor by their own width, so zero inset would clip them |
| 2026-07-26 | The three controls emit one merged `StyleData` cell per style and environment, not one cell per control | of two cells for the same style the front end keeps the first and discards the second, so a text size and a column width written separately cancel — the width never reaching any style that carries a size |
| 2026-07-26 | Pavel's report of unchanged font size in itemized, reference and theorem cells is its own work item, not a revision of T3 | the reference label is a referencing defect and the font-size fix replaces T3's extraction with T4's chain reader, so it is a rewrite rather than a tweak; see `Work/Backlog/ViewAndReferenceDefects.md` |
| 2026-07-26 | The column width becomes an **absolute point measure, centered** — superseding the 2026-07-25 decision that it is a fraction of the page | Pavel drove it and rejected a window-relative column outright. `Scaled` cannot be made absolute by arithmetic: `Scaled[0.5] - width/2` stays centered on both 612 pt and 842 pt paper but the block goes 290 → 594. `PageWidth` supplies the absolute measure; centering it needs a window-driven `Dynamic` margin on screen and a static paper-derived margin in print, with `Full` at the top of the slider for the unconstrained case |
| 2026-07-26 | The absolute column is `Scaled[0.5] - width/2` on screen and a point inset on paper — no `Dynamic`, superseding the plan to drive the screen margin from the window | `Scaled` resolves against the window in *both* environments, so on screen the two symmetric halves already cancel it out and leave an absolute column that tracks a resize; a window-driven `Dynamic` was measured working but reads `WindowSize`, which includes the chrome, so it would size the column wrong by the bracket gutter |
| 2026-07-26 | The per-style offsets are anchored on `Text`, superseding T4's anchor on the smallest base margin | anchoring on the smallest margin centers the *hull*, leaving the body text 11.5 pt right of centre on a 340 pt column; anchoring on `Text` centers the body and lets section numbers and dingbats hang into the margin as they do in LaTeX, at the cost of a clamp so the widest hang cannot fall off the paper |
| 2026-07-26 | Paper geometry is read only after restoring the bare parent sheet | read through the private sheet installed by an earlier call, `PaperSize` answers `Automatic` and the printed margins come out of a symbolic width |
| 2026-07-26 | The centering `Dynamic` must be confirmed interactively before the control is considered done | T1 measured a window-driven `Dynamic` collapsing the printed measure to a third, and a headless front end never lays out to a window, so this is the one part of the design that cannot be verified in a script |
| 2026-07-26 | The content-width control is **withdrawn**, superseding every earlier decision about it — no fraction, no absolute measure, no slider, no exported function | Pavel drove the absolute column shipped in 0.1.7, asked first for the relative one back, then for the functionality removed outright. The Spec requirement is struck rather than reworked; the front end knowledge it produced stays in `CLAUDE.md`, marked as background rather than as shipped code |
| 2026-07-26 | `ResetDocumentView` goes on clearing the withdrawn `"ContentWidth"` key | documents written with 0.1.5–0.1.7 carry it, and reset promises to leave no trace; nothing else reads the key, so one line buys a clean upgrade path |
| 2026-07-26 | T6 closes on Pavel's sign-off of 0.1.8, and the item is complete | the palette folds, the two size sliders reach every prose and math style, and reset leaves no trace; the withdrawn width is struck from the Spec rather than carried as an open requirement |
| 2026-07-26 | The three interactive behaviours are accepted on sign-off rather than measured | live refit, document-switch tracking and the release-time setter need a real window and a real click, which no headless front end supplies; they are recorded in the probe's *What to Check* list so a regression has a place to be caught |
| 2026-07-26 | Point 4, the palette rendering dark, is **not a defect** — no code change | Diagnosed: `CurrentValue[ $FrontEnd, LightDark ]` is `Automatic` and macOS is in Dark mode, so the front end resolves dark and the palette, which sets no `LightDark` of its own, inherits it — the same behaviour as every built-in palette. The document was the outlier, carrying an explicit `"Light"`. The fix is the global setting `CurrentValue[ $FrontEnd, LightDark ] = "Light"`, left to Pavel. Making the palette follow the *focused document* was rejected: `LightDark` is not a dynamic notebook option, so it would mean restyling the palette's contents by hand and would make it behave unlike every other palette |
