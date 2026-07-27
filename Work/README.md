# Work

Execution state for MathNotebook — what is being built now. Each file is one
**work item**: a Spec (what to build), Tasks (one ≈ one session), and a Progress
log. Durable knowledge lives in `CLAUDE.md` and the tutorial.

An item's **status is its folder** — there is no status field:

| Folder | Meaning | Names |
|---|---|---|
| `Active/` | in progress | `<Name>.md` |
| `Backlog/` | proposed / not started (drafts live here) | `<Name>.md` |
| `Done/` | completed | `YYYY-MM-DD-<Name>.md` (completion date) |
| `Dropped/` | abandoned / superseded | `YYYY-MM-DD-<Name>.md` (drop date) |

Changing status is a `git mv`. Names are clean while an item is live and get a
date prefix when archived, so `Done/` and `Dropped/` read chronologically.

Run `/next-session` in a **fresh** session to work the next task of an active
item — clean context per task is the whole point. Use `/work` to create a new item.

## Active

- [View and Reference Defects](Active/ViewAndReferenceDefects.md) — all implementation done (T1–T5: the text slider reaches every prose style, a tagged `Reference` shows its label, a citation to a theorem reads `Theorem 1.1`, front-end tests for all of it, tutorial updated); next: **T6**, Pavel re-checks on the document that produced the report — the Spec's last gate, and not something a session can close
- [LaTeX Paper Import](Active/LaTeXPaperImport.md) — T1–T11 done (`ImportLaTeXDocument`/`ExportLaTeXDocument`: both specimen papers **and the repo's four LaTeX samples** round-trip byte-identically — through a real save and reopen — with sectioning, theorem environments, labels, cross-references, citations, numbering, figures, front matter, lists and both bibliographies converted; and an imported paper now **opens with its environments live**, on the template its `\documentclass` asks for or on the new `PlainArticle` sheet — `Default.nb`'s typography with the paper structure added — where before it landed on `Default.nb` and a cross-reference read `2.0`); next: **T12**, `FrontEnd.wlt`'s display-ink test compares two measurement scales
- [Cross-Platform TeX and Font Support](Active/CrossPlatformTeX.md) — T1 done (the suite no longer assumes macOS or a TeX install, and a machine with no TeX gets a message telling it what to do); next: **T2**, Linux end to end — needs a Linux machine

## Backlog
- [LaTeX via Markdown](Backlog/MarkdownImportRoute.md) — whether `MarkdownToNotebook` plus a LaTeX-to-Markdown tool beats the direct importer; likely a one-way route with no round trip, but measure it
- [Conversion and MaTeX UX](Backlog/ConversionUX.md) — four near-identical conversion labels; what a MaTeX conversion should leave behind; whether per-selection LaTeX conversion survives whole-document export
- [Adopt WolframInstituteTools Practices](Backlog/WolframInstituteToolsPractices.md) — real documentation pages for the exported symbols, and their notebook tooling
- [Complex Systems Stylesheet and Submission Buttons](Backlog/JournalSubmission.md) — a fifth template from the journal's own class file, and a "publish to Complex Systems / arXiv" bundle
- [Springer Journal Sample PDF](Backlog/SpringerJournalSample.md) — blocked on a manual `svjour3.cls` download
- [First Public Release](Backlog/Release.md) — tutorial and palette review, then publish; the README's install URL is dead until then
- [Repo Organization](Backlog/RepoOrganization.md) — root cleanup, and the `Wiki/` yes-or-no decision
- [Stylesheet Font Fidelity](Backlog/StylesheetFontFidelity.md) — TeX Gyre vs system fonts; why `ArXivArticle` substitutes in the browser
