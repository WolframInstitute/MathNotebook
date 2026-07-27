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

*Nothing active.* All three items closed on 2026-07-27 — LaTeX Paper Import and View and Reference
Defects into `Done/`, Cross-Platform TeX into `Dropped/`. Pick the next item from the Backlog below
and `git mv` it into `Active/`, or use `/work` to write a new one.

The one thing no backlog item states plainly: the working tree is **0.1.11** and the cloud version
marker still reads **0.1.10** (checked 2026-07-27). So numbered citations, the whole LaTeX document
importer and the fifth stylesheet exist only here — a user installing from the README's URL gets
none of them. `First Public Release` is where that gets decided.

## Backlog
- [LaTeX via Markdown](Backlog/MarkdownImportRoute.md) — whether `MarkdownToNotebook` plus a LaTeX-to-Markdown tool beats the direct importer; likely a one-way route with no round trip, but measure it
- [Conversion and MaTeX UX](Backlog/ConversionUX.md) — four near-identical conversion labels; what a MaTeX conversion should leave behind; whether per-selection LaTeX conversion survives whole-document export
- [Adopt WolframInstituteTools Practices](Backlog/WolframInstituteToolsPractices.md) — real documentation pages for the exported symbols, and their notebook tooling
- [Complex Systems Stylesheet and Submission Buttons](Backlog/JournalSubmission.md) — a fifth template from the journal's own class file, and a "publish to Complex Systems / arXiv" bundle
- [Springer Journal Sample PDF](Backlog/SpringerJournalSample.md) — blocked on a manual `svjour3.cls` download
- [First Public Release](Backlog/Release.md) — tutorial and palette review, then publish; the README's install URL is dead until then
- [Repo Organization](Backlog/RepoOrganization.md) — root cleanup, and the `Wiki/` yes-or-no decision
- [Stylesheet Font Fidelity](Backlog/StylesheetFontFidelity.md) — TeX Gyre vs system fonts; why `ArXivArticle` substitutes in the browser
