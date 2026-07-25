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

- [ ] T3 — `SetDocumentFontSize` / `SetMathFontSize` plus palette sliders, with a reset, and a decision recorded on MaTeX cells.
- [ ] T4 — `SetContentWidth` plus slider — exposing the native option if T1 found one, otherwise private style definitions.
- [ ] T5 — Document all of it in the tutorial (`Scripts/BuildTutorial.wls`), in a new section on reading and writing comfortably; tests for the three functions.
- [ ] T6 — Feedback round: Pavel writes with it on a real document; revise.

### Done

- [x] T1 — Investigate the three mechanisms in a scratch notebook; write down what actually works in 15.0, especially whether a native centered-content-width option exists. (Session 1)
- [x] T2 — Foldable groups with persisted state; rebuild the palette and its screenshot. (Session 2)

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
