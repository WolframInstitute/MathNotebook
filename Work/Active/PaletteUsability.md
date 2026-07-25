# Palette Usability & Document View Controls

*[ LLM Generated ]*

> Type: refactor
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: "test the pallette get my feedback and make it more usable and cosy - like foldable sections, or changing font size of the math in all document - that would be a usable function. Also a slider for the document font size. And if it would be possible to somehow do not always stretch the notebook content but display it in some column in the center (it should be some viewer option) - document it in the tutorial, if there is such option, and the palette should again have some slider that supports this."

The palette is a flat column of seventeen buttons in six labelled groups — everything visible at once, nothing adjustable.
This item turns it into a comfortable writing surface: groups that fold away, and live controls for the three typographic decisions an author actually revisits while writing — how big the text is, how big the mathematics is, and how wide the column of content is.
The last one is the reason papers are readable on a wide screen at all, and it may already exist as a front end option; if it does, the palette should expose it and the tutorial should teach it rather than reinventing it.

Done when the palette folds, the three controls work across all four stylesheets and survive save/reopen, the tutorial documents them, and Pavel has used it on a real document and signed off.

### Requirements

- **Foldable groups.** Each labelled group (Referencing, Environments, Stylesheet, LaTeX ⇄ math, MaTeX, Setup) opens and closes independently. Open/closed state persists across front end sessions — palettes are `Saveable -> False`, so state belongs in `CurrentValue[$FrontEnd, {TaggingRules, "MathNotebook", ...}]`, not in the palette file.
- **Document font size.** A slider setting the size of prose for the whole document, not one cell — and it must be a real font size that survives PDF export, distinct from `Magnification`, which only zooms the screen. Offer both if both are wanted, but never conflate them in one control.
- **Math font size.** The same for mathematics, independently of prose: display equations, inline math, and the equation-number labels.
- **Centered content column.** Content in a fixed-width column centered in the window instead of stretching to the full width, with a slider for the width. Investigate native support before implementing anything.
- **Reset.** Any control can be returned to the stylesheet default — a document must be able to leave no trace of these overrides.
- **Feedback round.** Pavel drives the palette on a real paper and the result is revised against that, per the `revise` protocol.

### Design / API

Three exported functions, each acting on a notebook and settable from the palette, plus the palette controls that drive them:

```
SetDocumentFontSize[ notebook, size ]
SetMathFontSize[ notebook, size ]
SetContentWidth[ notebook, width ]
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

- [ ] T6 — Feedback round: Pavel writes with it on a real document; revise.

### Done

- [x] T1 — Investigate the three mechanisms in a scratch notebook; write down what actually works in 15.0, especially whether a native centered-content-width option exists. (Session 1)
- [x] T2 — Foldable groups with persisted state; rebuild the palette and its screenshot. (Session 2)
- [x] T3 — `SetDocumentFontSize` / `SetMathFontSize` plus palette sliders, with a reset, and a decision recorded on MaTeX cells. (Session 3)
- [x] T4 — `SetContentWidth` plus slider — exposing the native option if T1 found one, otherwise private style definitions. (Session 4)
- [x] T5 — Document all of it in the tutorial (`Scripts/BuildTutorial.wls`), in a new section on reading and writing comfortably; tests for the three functions. (Session 5)

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
