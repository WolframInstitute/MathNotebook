# Repo Organization

*[ LLM Generated ]*

> Type: refactor
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: "Can you please organize the repo similarly to computational research plugin?"

The plugin's **paclet** layout is already what this repo is: a repo root holding `MathNotebook/`, `run_tests.wls`, `README.md`, `CLAUDE.md`, `.gitignore`.
What it does not have is the research infrastructure of a **paclet-dev** repo — the shape `InfraCausality` has: `Wiki/`, `Work/`, `Notebooks/`, `NotebooksLLM/`, `Notes/`, `Resources/`, `Code/`, `Tour/`.

`Work/` exists as of this item.
The rest is a judgement call, and this item is where it gets made rather than assumed: a `Wiki/` on a repo nobody is doing research in is process for its own sake, while the parts that address a real mess — four loose files in the root, and a home for downloads — are worth taking now.

Done when the root holds only what belongs there and the layout decision is recorded.

### Requirements

- `Notebooks/` for the prototypes now sitting in the root: `Referencing.nb`, `Infrageometry.nb`, `TikZ.nb`. They are reference material, explicitly not to be modified, and `CLAUDE.md` says so — that note moves with them.
- A home for incoming material: `Axiomatic_Relativity_from_Causal_Graphs.zip` and `hodgepaper.tex` are in the root right now as inputs to `LaTeXPaperImport`. `Resources/` with a gitignore entry, so specimens do not enter history.
- A decision on `Wiki/`: yes and it gets seeded and maintained by `update-wiki`, or no and knowledge stays in `CLAUDE.md` plus these work items. Half a wiki is worse than none.
- `.serena/` is untracked and unignored; decide.
- `CLAUDE.md`'s Layout section updated to whatever results — it currently describes the old root.
- Moves use `git mv`, so history follows the files.

### Edge cases & out of scope

- `MathNotebook/` is the paclet root named by `PacletInfo.wl`; it does not move, and neither do `Scripts/`, `LaTeX/`, or `Images/`, which the README and build scripts reference by path.
- Anything moved must be re-checked in `Scripts/*.wls` and `README.md` — `LaTeX/` and `Images/Palette.png` are both linked from the README.
- Out of scope: paclet submodules and worktrees, which only make sense for a multi-paclet dev repo.

## Tasks

**Parked 2026-07-27** in the backlog reduction — cosmetic, and it blocks nothing. T1's main question is answered below rather than left open, because leaving a decided question on a checklist is what makes a backlog unreadable.

(none — both tasks are done)

### Done

- [x] T1 — Decide `Wiki/` yes or no. **No.** *(2026-07-27 — see Decisions)*
- [x] T2 — `git mv` the prototypes into `Notebooks/`, add `Resources/` with its gitignore entry, move the paper specimens there, update `CLAUDE.md` and any path references. Also settle `.serena/`, tracked or ignored — still open, and genuinely trivial. *(Session 1)*

## Progress

### Session 1 — 2026-07-27 — T2
- **Prompt:** `/next-session` with no item named; no item was active, so the three parked backlog items were put up and this one chosen.
- **Did:** The root now holds five files — `.gitignore`, `CLAUDE.md`, `LICENSE`, `README.md`, `run_tests.wls` — beside `Images/`, `LaTeX/`, `MathNotebook/`, `Notebooks/`, `Resources/`, `Scripts/` and `Work/`, which is the whole of "the root holds only what belongs there".
  The three prototypes went into `Notebooks/` with `git mv`, so history follows them, and nothing references them by path: `CLAUDE.md`'s Layout line was the only mention in the repo, `Scripts/*.wls` name only `MathNotebook/`, `LaTeX/` and `Images/`, and the README links neither.
  `Resources/` holds the two specimen papers and is **gitignored except its `.gitkeep`** — a rule on the directory rather than on two file names, so anything downloaded there later is out of history by default rather than by being remembered.
  The directory itself is tracked, which is what keeps a fresh clone's `DirectoryQ` check meaningful.
  `.serena/` needed no decision: it has been in `.gitignore` since `d989e42`, so T2's "still open" was stale, and `.claude/` is ignored beside it.
  `CLAUDE.md`'s Layout section now describes all six directories, says why `LaTeX/` and `Images/` do not move, and carries T1's no-`Wiki/` decision so the layout is readable without this item.
- **Learned:** `Tests/Specimens.wlt`'s `$specimenDirectory` was doing **two jobs** — the specimen home *and* the repo root — and moving the papers into `Resources/` silently paid for it in the other one.
  Pointing it at `Resources/` left both papers found and took the **LaTeX samples group** down with it, because `$samples` globbed `$specimenDirectory/LaTeX`: 22 tests became 14, all passing, with the samples' own "not found" notice the only sign.
  That is the third detector-blindness of the kind this repo keeps hitting — the papers' notice named nothing, the suite was green, and the count was the only evidence.
  Split into `$repoDirectory` (parent of the paclet location, what the samples want) and `$specimenDirectory` (`MATHNOTEBOOK_SPECIMENS`, else `$repoDirectory/Resources`), and the two are now independent: pointing `MATHNOTEBOOK_SPECIMENS` at an empty directory drops the two papers with their notice and **keeps the 8 sample tests**, which is what a fresh clone must do.
  Baseline and final are both 218 passed / 0 failed, and the intermediate 14 is why a count is worth recording before a move and not only after.
- **Next:** none — T2 was the last task, so the item is complete and moves to `Done/`.

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-27 | `Resources/` is gitignored as a **directory** (`Resources/*` with `!Resources/.gitkeep`), not as the two specimen file names | the Spec asked only that the specimens stay out of history, but the directory's purpose is *incoming* material, so naming files means every future download depends on someone remembering to add a line. `PublishPaclet.wls` stages `Tests/`, so a tracked specimen would also ship. The `.gitkeep` is tracked so a fresh clone has the directory and `Specimens.wlt`'s `DirectoryQ` check means what it says |
| 2026-07-27 | `.serena/` stays **ignored**; no change needed | it has been in `.gitignore` since `d989e42` ("keep .serena out of the paclet repo"), so the Spec's "untracked and unignored" was already out of date when this session opened — recorded rather than silently skipped, since a checklist item that answers itself is worth saying so |
| 2026-07-27 | **No `Wiki/`.** Durable knowledge stays in `CLAUDE.md`, with `Work/` items holding the per-effort record | not a judgement made in advance but one read off twelve sessions of practice: every durable finding this project produced went into `CLAUDE.md`'s Conventions section and was read back from there by the next session, and it worked. The Spec's own warning decides the rest — "half a wiki is worse than none", and a wiki nobody is doing research *in* would be exactly that. `Work/README.md` already says durable knowledge lives in `CLAUDE.md` and the tutorial; this makes that the decision rather than the default |
