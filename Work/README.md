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

- [First Public Release](Active/Release.md) — **the only thing standing between this repo and a
  working paclet.** The cloud marker reads 0.1.10 and the working tree is 0.1.11, so the LaTeX
  document importer, numbered citations and the `PlainArticle` stylesheet exist only here while the
  README describes all three. T2 is done — 0.1.11 builds from a clean archive, installs, and cold
  smoke-tests green: 196 shipped tests, 21/21 doc URIs resolving, the importer opening a sample on
  `PlainArticle` and round-tripping it byte for byte. The `LICENSE` copyright line is settled —
  `Pavel Hajek`, not the institute. Next: **T3**, publish — which waits on Pavel, as does the last
  part of T1: read the regenerated tutorial, now open in the front end

## Backlog

Reduced from eight items to three on 2026-07-27 — the four in `Dropped/` each carry a note saying
why and what would reopen them. Two survivors are parked rather than queued: neither blocks anything.

- [Conversion and MaTeX UX](Backlog/ConversionUX.md) — four near-identical conversion labels an author
  cannot tell apart, and a newly converted MaTeX cell that ignores the math slider. Trimmed to those
  two; the MaTeX display form went back on the pile as a design call needing Pavel at a notebook
- [Complex Systems Stylesheet and Submission Buttons](Backlog/JournalSubmission.md) — *parked.* A fifth
  template from the journal's own class file, and a "publish to Complex Systems / arXiv" bundle;
  Pavel's explicit request, so kept, but it is feature expansion and the bundle half wants the export
  path proven in real use first
- [Repo Organization](Backlog/RepoOrganization.md) — *parked.* Root cleanup; the `Wiki/` question is
  now decided (no) rather than open
