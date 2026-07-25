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
- Never `Import` a palette `.nb` into a variable to inspect it — the result is re-evaluated, so a literal `EvaluationNotebook[]` becomes `$Failed` and every `CurrentValue` collapses to its default. Read it as text, or measure via `AbsoluteCurrentValue[nb, WindowSize]` after `NotebookOpen`.

## Style overrides on a document

- The `"Printout"` variant of a style wins over the bare style name **across the whole stylesheet chain**. Since `LaTeXBase` sets an explicit `FontSize` on every prose/math style's `"Printout"` variant, an override written only on the bare name changes the screen and leaves the PDF byte-identical. Always write both.
- `CurrentValue[nb, {StyleDefinitions, style, option}] = value` is silently ignored. Build the private sheet (`Notebook[{Cell[StyleData[StyleDefinitions -> parent]], overrides...}, StyleDefinitions -> "PrivateStylesheetFormatting.nb"]`) and install it with `SetOptions`.
- Duplicate `StyleData` cells for the same name and environment in one sheet are **both dropped**. Rewrite an override in place; never append a second cell.
- The front end **drops `TaggingRules` from a private stylesheet notebook** — string, rule list or association alike — while adding `Visible` and `FrontEndVersion` of its own. To recognise a sheet you generated, mark it with a hidden cell (`Cell[StyleData["<marker>"], StyleMenuListing -> None, MenuSortingValue -> None]`); cells survive the round trip. Without a marker each install nests the previous sheet inside the new one and reset can no longer recover the real parent.
- Reset = recover the parent with `FirstCase[..., Cell[StyleData[StyleDefinitions -> name_]] :> name]` and assign it back verbatim — it is a string from the menus but a `FrontEnd`FileName` from the palette.
- `Magnification` never reaches print; it is not a font-size control.
- Headless testing: `"MathNotebook/AMSArticle.nb"` resolves in the service front end, `FrontEnd`FileName[{<absolute path>}, ...]` does not — it falls back to `Default.nb` silently. Assert the sheet loaded before trusting a measurement.

## Build & test

- Tests: `./run_tests.wls` or `TestReport` over `MathNotebook/Tests/*.wlt` after `PacletDirectoryLoad`.
- Build/install: temp copy → `CreatePacletArchive` → `PacletInstall[..., ForceVersionInstall -> True]` (build-paclet skill).
- After first install, front end menus need a restart or ``FrontEndExecute[FrontEnd`ResetMenusPacket[{Automatic, Automatic}]]``.
