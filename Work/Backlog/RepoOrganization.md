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

- [ ] T1 — Decide `Wiki/` yes or no, and `.serena/` tracked or ignored; record both.
- [ ] T2 — `git mv` the prototypes into `Notebooks/`, add `Resources/` with its gitignore entry, move the paper specimens there, update `CLAUDE.md` and any path references.

### Done

(completed tasks move here with the session that closed them)

## Progress

(no sessions yet)

## Decisions

| Date | Decision | Rationale |
|---|---|---|
