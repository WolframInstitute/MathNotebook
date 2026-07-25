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

- [Palette Usability & Document View Controls](Active/PaletteUsability.md) — next: **T2**, foldable palette groups with open/closed state in `$FrontEnd` tagging rules

## Backlog

- [Update From Cloud Button](Backlog/SelfUpdate.md) — palette button that installs a newer paclet from its cloud URL
- [Adopt WolframInstituteTools Practices](Backlog/WolframInstituteToolsPractices.md) — real documentation pages for the exported symbols, and their notebook tooling
- [LaTeX Paper Import](Backlog/LaTeXPaperImport.md) — round-trip a real paper; figures carry their generating code
- [Springer Journal Sample PDF](Backlog/SpringerJournalSample.md) — blocked on a manual `svjour3.cls` download
- [First Public Release](Backlog/Release.md) — tutorial and palette review, then publish; the README's install URL is dead until then
- [Repo Organization](Backlog/RepoOrganization.md) — root cleanup, and the `Wiki/` yes-or-no decision
- [Stylesheet Font Fidelity](Backlog/StylesheetFontFidelity.md) — TeX Gyre vs system fonts; why `ArXivArticle` substitutes in the browser
- [Cross-Platform TeX and Font Support](Backlog/CrossPlatformTeX.md) — the Windows and Linux branches have never run
