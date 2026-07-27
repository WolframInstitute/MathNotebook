# Submission Bundle

*[ LLM Generated ]*

> Type: feature
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

**This Spec is a proposal, not a decision.** It is the output of `JournalSubmission` T3, which was a
scoping task; read that item's T3 progress entry for the measurements behind every claim here, and
revise this before anyone starts T1.

`ExportLaTeXDocument` writes exactly one file. Measured on the second specimen — `main.tex`, seven PNGs
and `references.bib` — exporting into an empty directory leaves `main.tex` alone in it, while that
`.tex` names all seven `\includegraphics` files and `\bibliography{references}`. The export is correct
and the result does not compile anywhere but the paper's original directory. Closing that gap is this
item.

Scope is **arXiv only**. T3 established that *Complex Systems* needs no bundle: the journal is
notebook-native, submission is a Wolfram Cloud form, and its `.sty` is not redistributable, so the
artifact is the `.nb` the author already has. A "check this notebook against the journal's template"
button is a different, smaller idea and is not in this item.

Done when a paper written or imported in a notebook exports to a directory that `tar czf`s into an
arXiv upload arXiv accepts without hand-editing, and the palette has a button for it.

### Requirements

- **One new exported symbol**, taking a notebook and a target directory. `ExportLaTeXDocument` keeps
  its current one-file behaviour — an author who wants a `.tex` should keep getting a `.tex`.
- **Figures**: copy the file each `\includegraphics` names. The importer already stores the path, as
  `Import[FileNameJoin[{NotebookDirectory[], f}]]` in an `Input` cell, so the path is in the notebook.
  A figure cell whose code now *generates* the picture has no file: decide whether to evaluate and
  export it or to report it, but do not silently omit it.
- **Bibliography**: copy the `.bib` the preamble names. arXiv blocks a submission that has neither the
  `.bbl` nor every `.bib`, so copying is necessary and not sufficient.
- **Degrade, do not require**: emit the source tree always; add `.bbl` and PDF only where a local
  pdfLaTeX is found, reusing the detection shape `MaTeX.wl` already uses for pdfLaTeX/Ghostscript.
- **Report what is missing** — a named figure with no file, a `.bib` that is not on disk (the
  `ImportLaTeXDocument::nobib` case, which hodgepaper already exercises), a `\documentclass` that is
  not in TeX Live. Messages, not silence and not a search of the author's TeX tree.
- **Palette button** in the `Document` group, "Whole paper (LaTeX)", beside Import and Export. Buttons
  are stored verbatim, so everything it does is written out literally in fully qualified symbols.

### Edge cases & out of scope

- arXiv accepts PDF/PNG/JPG for PDFLaTeX and EPS/PS for LaTeX and **performs no conversion**; a
  bundle that converts formats is guessing at the author's compile route.
- arXiv excludes `.aux`, `.log`, `.pdf`, `.ps` from the upload — a `.bbl`-producing LaTeX run must not
  leave its by-products in the bundle directory.
- The `Complex Systems` importer gap is *not* fixed here and is not blocking: `documentStyleSheet`
  routes on the `\documentclass`, a CS paper declares `article`, so the importer can never choose the
  fifth template for one. Routing on a `\usepackage` is a design change of its own.
- Out of scope: uploading anywhere; a `.nb`-side check against the journal's author template; the
  three journals other than arXiv.

## Tasks

- [ ] T1 — Revise this Spec with Pavel, then settle the two open decisions: what to do with a generated
      figure that has no file, and whether the PDF belongs in the bundle at all.
- [ ] T2 — The source tree: figures and `.bib` copied beside the `.tex`, missing pieces reported.
- [ ] T3 — The optional LaTeX run: `.bbl` where pdfLaTeX is found, by-products kept out of the bundle.
- [ ] T4 — Palette button, tests, and a bundle built from a specimen and checked against arXiv's list.

## Progress

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-28 | Scope this item to arXiv alone | `JournalSubmission` T3: *Complex Systems* is notebook-native and submits through a form, so it needs no bundle, and its non-redistributable `.sty` means a compilable CS LaTeX bundle is not something this repo can ship |
