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

- [Complex Systems Stylesheet and Submission Buttons](Active/JournalSubmission.md) — activated 2026-07-28 from
  `Backlog/`, where it had been parked. **T1 and T2 done; T3 (the submission bundle) is all that remains.**
  T1 found that the journal publishes a full 213-style production Wolfram stylesheet, not just the class file the
  Spec assumed, so the template became a derivation. T2 generated it: `ComplexSystems.nb` is the **fifth
  template**, a 432 × 648 page with a 306 pt column, display math flush left, and one counter per environment —
  proved in a rendered PDF that reads `Definition 1.` / `Theorem 1.` then `Definition 2.` / `Theorem 2.`, where
  the other four would read `1.1` and `1.2`. It is the first template measured from a journal's own files rather
  than styled to resemble a class, and the first with a screen/print font split, both faces being commercial.
  Neither the `.sty` nor the `.nb` carries a licence grant, so neither is vendored — they live in gitignored
  `Resources/` and the sample PDF is a notebook printout. **Not in published 0.1.12: shipping the template needs
  a release**

[Conversion and MaTeX UX](Done/2026-07-28-ConversionUX.md) closed on 2026-07-28, the last item to:
the palette's four near-identical conversion labels became six verbs under three headings that carry
the direction, each with a tooltip, and `Import .tex file…` / `Export to .tex…` joined them — the
whole-paper route had no palette presence at all, which is what made the per-selection buttons look
like the only way out to LaTeX. Closed with one clause waived: Pavel has not yet read the new palette
on a real paper. Its stale-tutorial warning is **discharged**: 0.1.12 shipped the regenerated tutorial
to the cloud.

**0.1.12 is the published version** (2026-07-28) — 228 tests green, `Scripts/PublishPaclet.wls` then
`Scripts/DeployPreviews.wls`, marker and archive verified from the cloud (255 KB, 63 files,
`"Version" -> "0.1.12"`). It carries no code change: T1 of the active item plus the tutorial the
previous release left behind. [First Public Release](Done/2026-07-27-Release.md) closed on 2026-07-27
with **0.1.11**, the version marker agreeing and the README's `PacletInstall` line installing it from
the cloud onto a machine with no local copy. [Repo Organization](Done/2026-07-27-RepoOrganization.md) closed the same day: the root holds
five files beside `Images/`, `LaTeX/`, `MathNotebook/`, `Notebooks/`, `Resources/`, `Scripts/` and
`Work/`, and there is deliberately no `Wiki/` — durable knowledge is `CLAUDE.md`.

## Backlog

Empty. Reduced from eight items to three on 2026-07-27 — the four in `Dropped/` each carry a note
saying why and what would reopen them — and the one item left was activated on 2026-07-28.
