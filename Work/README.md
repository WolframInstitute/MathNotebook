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

Nothing. Start the next item from `Backlog/`, or `/work` a new one.

[Conversion and MaTeX UX](Done/2026-07-28-ConversionUX.md) closed on 2026-07-28, the last item to:
the palette's four near-identical conversion labels became six verbs under three headings that carry
the direction, each with a tooltip, and `Import .tex file…` / `Export to .tex…` joined them — the
whole-paper route had no palette presence at all, which is what made the per-selection buttons look
like the only way out to LaTeX. Closed with one clause waived: Pavel has not yet read the new palette
on a real paper. **The tutorial changed with it, so the cloud copy is a version behind and the next
release must run `Scripts/DeployPreviews.wls`.**

[First Public Release](Done/2026-07-27-Release.md) closed on 2026-07-27: **0.1.11 is
published**, the version marker agrees, and the README's `PacletInstall` line installs it from the
cloud onto a machine with no local copy. The cloud previews and the linked tutorial were re-deployed
with it. [Repo Organization](Done/2026-07-27-RepoOrganization.md) closed the same day: the root holds
five files beside `Images/`, `LaTeX/`, `MathNotebook/`, `Notebooks/`, `Resources/`, `Scripts/` and
`Work/`, and there is deliberately no `Wiki/` — durable knowledge is `CLAUDE.md`.

## Backlog

Reduced from eight items to three on 2026-07-27 — the four in `Dropped/` each carry a note saying
why and what would reopen them. The one remaining item is parked rather than queued: it blocks
nothing.

- [Complex Systems Stylesheet and Submission Buttons](Backlog/JournalSubmission.md) — *parked.* A fifth
  template from the journal's own class file, and a "publish to Complex Systems / arXiv" bundle;
  Pavel's explicit request, so kept, but it is feature expansion and the bundle half wants the export
  path proven in real use first
