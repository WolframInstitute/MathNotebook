# MathNotebook paclet

Paclet for writing math papers in Wolfram notebooks: referencing palette, LaTeX journal stylesheets, LaTeX ↔ notebook conversion, MaTeX integration.

## Layout

- `MathNotebook/` — paclet root: `PacletInfo.wl`, `Kernel/` (Package[] format, loader `MathNotebookLoader.wl`, usage strings in `Usage.wl`), `FrontEnd/Palettes/`, `FrontEnd/StyleSheets/MathNotebook/`, `Assets/`, `Tests/*.wlt`.
- `Scripts/Build*.wls` — generate ALL `.nb` artifacts (stylesheets, palette, tutorial). Never edit generated `.nb` files directly; edit the script and regenerate.
- `Referencing.nb`, `Infrageometry.nb`, `TikZ.nb` — original prototypes, kept as reference; do not modify.

## Conventions

- Conversion functions have pure cores operating on `Notebook` expressions (headless-testable) with thin `NotebookGet`/`NotebookPut` wrappers.
- In the `Package[]` format an **undeclared symbol is private to its own file** (`WolframInstitute`MathNotebook`<File>`PackagePrivate`x`). Calling such a helper from another file creates a distinct, definition-less symbol, so the call just stays unevaluated — **no message, no failure, the operation silently does nothing**. Every cross-file helper needs `PackageScope["name"]` in the file that defines it.
- All four template stylesheets are generated from the same base cell list as `LaTeXBase.nb` and each chains to `Default.nb`; they must define identical style names (enforced by `Tests/StyleSheets.wlt`).
- Palette buttons must be cold-kernel-safe: `Needs["WolframInstitute`MathNotebook`"]` + fully qualified symbols, `Method -> "Queued"`.

## Palette state and folding

- Palette state persists **despite `Saveable -> False`**: the front end saves a palette's own `TaggingRules` in `$UserBaseDirectory/FrontEnd/init.m` under `CurrentValue[$FrontEnd, PalettesMenuSettings]`, keyed by palette file name. Write state on `EvaluationNotebook[]` under a flat key, as the built-in palettes do; do not use `$FrontEnd` tagging rules.
- `CurrentValue[EvaluationNotebook[], {TaggingRules, key}, True]` is fully front-end-side — no kernel is launched to display or fold the palette. Set it from an `EventHandler` with `Method -> "Preemptive"`, and use two handlers (set `True` / set `False`) rather than a `Not`.
- `PaneSelector` reserves the size of its **largest** pane unless given `ImageSize -> Automatic` explicitly. Without that option a collapsed group still occupies its open height and the fold does nothing.
- `Rasterize` renders `Dynamic` as a placeholder and `PaneSelectorBox` at max size, so a raster can neither show nor measure fold state. Build a separate static rendition for screenshots (`Scripts/BuildPalette.wls` has `staticGroup` beside `paletteGroup`).
- Never `Import` **or `Get`** a palette `.nb` into a variable to inspect it — the result is re-evaluated, so a literal `EvaluationNotebook[]` becomes `$Failed` and every `CurrentValue` collapses to its default, reporting one window size for every fold state. Read it as text, or measure via `AbsoluteCurrentValue[nb, WindowSize]` after `NotebookOpen`.
- To measure a fold state, patch the palette's **existing** `TaggingRules` option as text — the generated file already carries one (an all-`True` association the exporting front end writes), a second copy of the option is ignored, and the association spans several lines, so the regex needs `(?s)`: WL's `RegularExpression` `.` does not cross a newline.

## Style overrides on a document

- The `"Printout"` variant of a style wins over the bare style name **across the whole stylesheet chain**. Since `LaTeXBase` sets an explicit `FontSize` on every prose/math style's `"Printout"` variant, an override written only on the bare name changes the screen and leaves the PDF byte-identical. Always write both.
- `CurrentValue[nb, {StyleDefinitions, style, option}] = value` is silently ignored. Build the private sheet (`Notebook[{Cell[StyleData[StyleDefinitions -> parent]], overrides...}, StyleDefinitions -> "PrivateStylesheetFormatting.nb"]`) and install it with `SetOptions`.
- **Reading** that same path *does* work, and resolves through the whole chain — including styles no MathNotebook sheet declares (the `Item` family, which comes from `Default.nb`) and a document still on `Default.nb`. It is the way to get a style's base geometry; read it off a scratch notebook created with the *parent* sheet, or a second call compounds its own override.
- To read the **print** value, put the environment in the path as a list: `CurrentValue[nb, {StyleDefinitions, {"Theorem", "Printout"}, FontSize}]` returns 10 where the bare path returns 13. `StyleData[style, "Printout"]` in that position does **not** work — it silently returns the screen value, so every printout override gets written at its screen size. Filter the results for `NumericQ`: `Default.nb` resolves `DisplayFormulaEquationNumber` to the symbolic `-1 + Inherited`.
- Read the *list* of styles to touch from `LaTeXBase.nb`, not from the chain. The chain happily resolves a size for the character styles (`Hyperlink`, `Citation`, `URL`) too, and pinning those stops an inline citation from inheriting the size of the cell it sits in.
- `Scaled` in `CellMargins` is **relative, never absolute** — it tracks `PageWidth`, so the column follows the window and the paper. `Scaled[0.5] + (-width/2)` looks like it should give an absolute centered column and does not: measured, it stays exactly centered on both 612 pt and 842 pt paper but the block goes 290 → 594. `PageWidth -> w` in a style *is* absolute (identical ink `{102, 252}` on both papers) but left-aligns at the style's own margin, and combining it with symmetric `Scaled` margins fights — the two together collapsed the block to 73 pt and were not centered.
- Headless verification trap: a private sheet whose parent is an **embedded** notebook (`Cell[StyleData[StyleDefinitions -> Get[path]]]`) applies your own override cells but lets every *unoverridden* style fall through to `Default.nb` instead of the intended parent. Styles you wrote read correctly while styles you did not read Default's values, which looks exactly like a leaking control. Only the document-level `StyleDefinitions -> Get[path]` form resolves properly.
- A style declared `StyleData[name, StyleDefinitions -> StyleData["Text"]]` — the theorem environments, `Proof`, `Reference`, `Author`, `Date` — does **not** pick up a child sheet's override of `Text`; the inheritance is resolved inside the parent. Such a style carries no bare `FontSize` of its own, so an override generated from the base sheet's declared sizes skips it and its size never changes on screen.
- `CellMargins` accepts `Scaled[fraction] + points`, and the front end resolves the sum (`Scaled[a] + Scaled[b]` behaves as `Scaled[a + b]`). That is what lets a centered content column keep each style's own indent: symmetric `Scaled` inset for the column, plus a per-style point offset for the section numbers and theorem dingbats, which are drawn to the left of their own cell margin.
- Of two `StyleData` cells for the same name and environment in one sheet, the **first wins and the second is discarded whole** — its options are not merged in, so an option written only in the second never applies and silently falls back to the parent (measured both for the same option twice and for two different options). Emit exactly one cell per style and environment, carrying every option; never append a second. This is why `View.wl` runs its generated cells through `mergedStyleCells` — a text size and a column width both land on `Text`.
- The front end **drops `TaggingRules` from a private stylesheet notebook** — string, rule list or association alike — while adding `Visible` and `FrontEndVersion` of its own. To recognise a sheet you generated, mark it with a hidden cell (`Cell[StyleData["<marker>"], StyleMenuListing -> None, MenuSortingValue -> None]`); cells survive the round trip. Without a marker each install nests the previous sheet inside the new one and reset can no longer recover the real parent.
- Reset = recover the parent with `FirstCase[..., Cell[StyleData[StyleDefinitions -> name_]] :> name]` and assign it back verbatim — it is a string from the menus but a `FrontEnd`FileName` from the palette.
- `Magnification` never reaches print; it is not a font-size control.
- Headless testing: neither `"MathNotebook/AMSArticle.nb"` nor `FrontEnd`FileName[...]` reliably resolves in the service front end — both fell back to `Default.nb` silently in a `wolframscript` run with the paclet installed. What always works is embedding the sheet: `StyleDefinitions -> Get[<absolute path to AMSArticle.nb>]`. Assert the sheet loaded (`CurrentValue[nb, {StyleDefinitions, "Title", FontSize}]` is 26, not 45) before trusting any measurement.

## Build & test

- Tests: `./run_tests.wls` or `TestReport` over `MathNotebook/Tests/*.wlt` after `PacletDirectoryLoad`.
- Build/install: temp copy → `CreatePacletArchive` → `PacletInstall[..., ForceVersionInstall -> True]` (build-paclet skill).
- After first install, front end menus need a restart or ``FrontEndExecute[FrontEnd`ResetMenusPacket[{Automatic, Automatic}]]``.
