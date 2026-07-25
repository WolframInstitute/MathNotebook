# MathNotebook paclet

Paclet for writing math papers in Wolfram notebooks: referencing palette, LaTeX journal stylesheets, LaTeX ↔ notebook conversion, MaTeX integration.

## Layout

- `MathNotebook/` — paclet root: `PacletInfo.wl`, `Kernel/` (Package[] format, loader `MathNotebookLoader.wl`, usage strings in `Usage.wl`), `FrontEnd/Palettes/`, `FrontEnd/StyleSheets/MathNotebook/`, `Assets/`, `Tests/*.wlt`.
- `Scripts/Build*.wls` — generate ALL `.nb` artifacts (stylesheets, palette, tutorial). Never edit generated `.nb` files directly; edit the script and regenerate.
- `Referencing.nb`, `Infrageometry.nb`, `TikZ.nb` — original prototypes, kept as reference; do not modify.

## Conventions

- Conversion functions have pure cores operating on `Notebook` expressions (headless-testable) with thin `NotebookGet`/`NotebookPut` wrappers.
- All four template stylesheets are generated from the same base cell list as `LaTeXBase.nb` and each chains to `Default.nb`; they must define identical style names (enforced by `Tests/StyleSheets.wlt`).
- Palette buttons must be cold-kernel-safe: `Needs["WolframInstitute`MathNotebook`"]` + fully qualified symbols, `Method -> "Queued"`.

## Style overrides on a document

- The `"Printout"` variant of a style wins over the bare style name **across the whole stylesheet chain**. Since `LaTeXBase` sets an explicit `FontSize` on every prose/math style's `"Printout"` variant, an override written only on the bare name changes the screen and leaves the PDF byte-identical. Always write both.
- `CurrentValue[nb, {StyleDefinitions, style, option}] = value` is silently ignored. Build the private sheet (`Notebook[{Cell[StyleData[StyleDefinitions -> parent]], overrides...}, StyleDefinitions -> "PrivateStylesheetFormatting.nb"]`) and install it with `SetOptions`.
- Duplicate `StyleData` cells for the same name and environment in one sheet are **both dropped**. Rewrite an override in place; never append a second cell.
- Reset = recover the parent with `FirstCase[..., Cell[StyleData[StyleDefinitions -> name_]] :> name]` and assign it back verbatim — it is a string from the menus but a `FrontEnd`FileName` from the palette.
- `Magnification` never reaches print; it is not a font-size control.
- Headless testing: `"MathNotebook/AMSArticle.nb"` resolves in the service front end, `FrontEnd`FileName[{<absolute path>}, ...]` does not — it falls back to `Default.nb` silently. Assert the sheet loaded before trusting a measurement.

## Build & test

- Tests: `./run_tests.wls` or `TestReport` over `MathNotebook/Tests/*.wlt` after `PacletDirectoryLoad`.
- Build/install: temp copy → `CreatePacletArchive` → `PacletInstall[..., ForceVersionInstall -> True]` (build-paclet skill).
- After first install, front end menus need a restart or ``FrontEndExecute[FrontEnd`ResetMenusPacket[{Automatic, Automatic}]]``.
