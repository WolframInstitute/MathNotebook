# MathNotebook

A Wolfram Language paclet for writing mathematics papers in notebooks instead of LaTeX.

## Features

- **Referencing palette** (Palettes ▸ MathNotebook): copy live, clickable references to equations, theorems, and sections; tag cells as citation anchors; insert citations; jump back after following a link.
- **LaTeX journal stylesheets** (Format ▸ Stylesheet ▸ MathNotebook): `AMSArticle` (amsart, Palatino), `ArXivArticle` (article, Latin Modern), `SpringerJournal` and `RevTeXAPS` (Times), with LaTeX-style per-section theorem numbering, numbered equations, and hyperlink colors.
- **LaTeX conversion**: convert `$...$` fragments and `equation`/`align` environments to native typeset math and back, losslessly (original TeX is preserved in cell tagging rules).
- **MaTeX integration**: render display math through real LaTeX via [MaTeX](https://github.com/szhorvat/MaTeX), and convert back; one-click MaTeX installation.
- **Font installation**: install Latin Modern and TeX Gyre OpenType fonts from a local TeX Live distribution.
- **Tutorial notebook** with shortcuts and best practices.

## Installation

```wolfram
PacletInstall["<cloud-url>"]
```

Restart the front end (or evaluate ``FrontEndExecute[FrontEnd`ResetMenusPacket[{Automatic, Automatic}]]``) after the first install so the palette and stylesheet menus appear.

## Development

- `MathNotebook/` — paclet source (`Kernel/`, `FrontEnd/`, `Assets/`, `Tests/`).
- `Scripts/BuildStyleSheets.wls`, `BuildPalette.wls`, `BuildTutorial.wls` — generate all `.nb` artifacts; edit the scripts, not the generated files.
- `./run_tests.wls` — run the test suite.
- `Referencing.nb`, `Infrageometry.nb`, `TikZ.nb` — the original prototypes this paclet grew from.
