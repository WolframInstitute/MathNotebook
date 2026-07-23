# MathNotebook paclet

Paclet for writing math papers in Wolfram notebooks: referencing palette, LaTeX journal stylesheets, LaTeX ↔ notebook conversion, MaTeX integration.

## Layout

- `MathNotebook/` — paclet root: `PacletInfo.wl`, `Kernel/` (Package[] format, loader `MathNotebookLoader.wl`, usage strings in `Usage.wl`), `FrontEnd/Palettes/`, `FrontEnd/StyleSheets/MathNotebook/`, `Assets/`, `Tests/*.wlt`.
- `Scripts/Build*.wls` — generate ALL `.nb` artifacts (stylesheets, palette, tutorial). Never edit generated `.nb` files directly; edit the script and regenerate.
- `Referencing.nb`, `Infrageometry.nb`, `TikZ.nb` — original prototypes, kept as reference; do not modify.

## Conventions

- Conversion functions have pure cores operating on `Notebook` expressions (headless-testable) with thin `NotebookGet`/`NotebookPut` wrappers.
- All four template stylesheets chain to `LaTeXBase.nb` and must define identical style names (enforced by `Tests/StyleSheets.wlt`).
- Palette buttons must be cold-kernel-safe: `Needs["WolframInstitute`MathNotebook`"]` + fully qualified symbols, `Method -> "Queued"`.

## Build & test

- Tests: `./run_tests.wls` or `TestReport` over `MathNotebook/Tests/*.wlt` after `PacletDirectoryLoad`.
- Build/install: temp copy → `CreatePacletArchive` → `PacletInstall[..., ForceVersionInstall -> True]` (build-paclet skill).
- After first install, front end menus need a restart or ``FrontEndExecute[FrontEnd`ResetMenusPacket[{Automatic, Automatic}]]``.
