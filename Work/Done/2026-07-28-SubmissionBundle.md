# Submission Bundle

*[ LLM Generated ]*

> Type: feature
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

**Settled in T1 and implemented in T2–T4.** It began as the output of `JournalSubmission` T3, a
scoping task; read that item's T3 progress entry for the measurements behind every claim here.
Pavel's instruction on 2026-07-28 was to finish the item rather than revise the Spec with him, so the
two open decisions were taken in T1 without a revision round and are recorded under *Decisions* with
their reasons.

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

### Done

- [x] T1 (Session 1) — Settle the two open decisions: what to do with a generated figure that has no
      file, and whether the PDF belongs in the bundle at all.
- [x] T2 (Session 1) — The source tree: figures and `.bib` copied beside the `.tex`, missing pieces reported.
- [x] T3 (Session 1) — The optional LaTeX run: `.bbl` where pdfLaTeX is found, by-products kept out of the bundle.
- [x] T4 (Session 1) — Palette button, tests, and a bundle built from a specimen and checked against arXiv's list.

## Progress

### Session 1 — 2026-07-28 — T1, T2, T3, T4

- **Prompt:** "please finish the tasks already, if something too hard remove, commit and push, I need
  a working version and clean backlog" — so all four tasks in one session, the T1 revision round
  replaced by deciding and recording, and the item closed.

- **Did:** `ExportLaTeXBundle` in a new `Kernel/Bundle.wl`, the 23rd public symbol, taking a notebook
  and a directory.
  `ExportLaTeXDocument` is untouched: an author who wants a `.tex` still gets a `.tex`.
  It writes the `.tex`, copies every file the exported source names — each `\includegraphics` and each
  `.bib` the preamble declares — creating subdirectories where a name has one, compiles the `.bbl` in a
  scratch copy where a local pdfLaTeX is found, and returns an Association of the directory, the files
  written and the names it could not resolve.
  Five messages: `::nofile`, `::nohome`, `::nolatex`, `::nobbl`, `::noclass`.
  `Document.wl` gained three `PackageScope` declarations and one refactor: `bibliographyFiles` split so
  that `bibliographyNames[source]` reads the declared names with no file on disk, which is what the
  export side needs, and `bibliographyFile` now takes a directory and a `\jobname` rather than a `.tex`
  path.
  Palette: a third button in the `Document` group, "Export submission…", with a `"Directory"` dialog
  where the other two take a file, everything written out literally as a stored button must be.
  Tests: a new `Tests/Bundle.wlt` (17) and a bundle group in `Tests/Specimens.wlt` (10 more, gated on
  the papers as the rest of that file is) — 228 tests to 258, all green.
  Also the reference page (22 now, derived from `ExportLaTeXDocument.nb`), the usage string, the
  `PacletInfo` `Symbols` entry, three tutorial items, a README section, and the version at 0.1.13.

- **Learned:**
  - The bundle worked first time on the causal-graphs specimen: seven PNGs, `references.bib` and
    `main.bbl` beside a byte-identical `main.tex`, with no `.aux`, `.log` or `.pdf`.
    That is the arXiv upload, and it is the exact gap `JournalSubmission` T3 measured.
  - Compiling in a scratch copy of the bundle rather than in the bundle is what satisfies arXiv's
    exclusion list with no cleanup pass, and it is why no PDF can leak in.
  - `Lookup[{}, "Target"]` answers `Missing["KeyAbsent", …]` — the empty list reads as an empty rule
    list — so the first version returned an unevaluated `Join` *inside* the result Association.
    `Map[#[key] &, …]` over a list of associations is the form.
  - An exclusion test keyed on `".pdf"` fails on `plot.pdf`, which is a **figure**: arXiv accepts PDF
    figures and rejects the compiled *paper*, so the assertion has to be keyed on the job name.
  - The bundle directory may be the paper's own, and then every copy is a file onto itself, which
    `CopyFile` refuses with a message rather than treating as a no-op.
  - A `thebibliography` paper declares no `.bib` and needs no `.bbl`, so all four `LaTeX/Sample-*.tex`
    bundle to a `.tex` alone and are right doing it.
    hodgepaper is the reported case: `\jobname.bib`, not shipped, and the bundle is short by exactly
    that file.
  - Two bite checks, both confirmed by reintroducing the defect and restoring from a copy aside, never
    `git checkout --`: disabling the file copy fails 2 Bundle and 2 Specimens tests; compiling in the
    bundle instead of a scratch copy fails 3 and 6.
  - Deriving the 23rd reference page from a sibling needs the template's own `ref/<oldsymbol>`
    self-references rewritten **before** the new cells go in, or the same pass rewrites the deliberate
    back-links the new page carries to the old symbol.

- **Next:** none — the item is complete.

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-28 | A figure the paper names but disk does not have is **reported, not evaluated** | The only way an `\includegraphics` reaches the exported source is from an imported paper's stored markup — the whole evaluation family emits nothing — so the case is an author who replaced the `Import` with generating code and whose shipped file has gone. Evaluating it would have to guess the format, which arXiv does not convert (PDF/PNG/JPG for PDFLaTeX, EPS/PS for LaTeX), and the size the source's own options assume: guessing at the author's compile route, which the Spec rules out |
| 2026-07-28 | **No PDF in the bundle, ever** | arXiv excludes `.pdf` and `.ps` from a source upload, so a compiled paper beside its source is a rejected submission and not a convenience. This also decided the mechanism: the LaTeX run happens in a scratch copy of the bundle and only the `.bbl` comes back, which keeps the `.aux` and `.log` out with no cleanup pass |
| 2026-07-28 | Scope this item to arXiv alone | `JournalSubmission` T3: *Complex Systems* is notebook-native and submits through a form, so it needs no bundle, and its non-redistributable `.sty` means a compilable CS LaTeX bundle is not something this repo can ship |
