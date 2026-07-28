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

[Import Display Defects](Active/ImportDisplayDefects.md) — the causal-graphs import round-trips
byte-exact but displays wrong. T1 closed the bibliography alignment (every sheet's `Reference` reserves
a 185 pt gutter for the hanging `[key]` dingbat), T2 the literal `\textbf`/`\emph`/`\textit` (styled
runs whose shape was chosen by what survives a save), and T3 the front matter: the title's `\vspace`
prefix and the whole `\author` block ride in tagging rules while `\maketitle`, `\sloppy`,
`\tableofcontents` and comment-only paragraphs produce **no cell at all** — carried as whitespace in
the preceding cell's `"Separator"`, which is why that needed no export clause. T5 closed Pavel's
"the fonts are different" screenshot by **disproving** its own hypothesis: a `Citation` run already
renders in its cell's face, and the culprit was `InsertCitation` at a cell-bracket selection, which
destroyed the cell's content and left a `BoxData` cell that renders in the box face — one bug wearing
two symptoms. Next: T4, the only task needing him at a screen.

[Palette and View UX](Active/PaletteAndViewUX.md) — the three things Pavel asked for that are not
import defects: the palette's `Environments` group renamed (he rejected the name without giving one,
so T1 is blocked on him), `Tag Cell` replaced by a button that inserts a `Reference` entry with
`Insert Reference` becoming a picker over equations/theorems/literature, and inline math scaling with
the math font size. That last cause is already known: an inline math island carries **no style name**,
so it inherits the enclosing `Text` cell and no math-style override can reach it. Next: T2.

[Basic Functionality Shakedown](Done/2026-07-28-BasicFunctionality.md) closed on 2026-07-28
with all seven tasks done and **one clause outstanding that is Pavel's, not a session's**: applying a
stylesheet from the palette menu, and Go back after following a reference into a new window, cannot be
verified anywhere but a real front end — by-name stylesheet resolution reads Default's sizes headless
however the front end is reset or restarted, and window focus has no headless measurement at all.

[Submission Bundle](Done/2026-07-28-SubmissionBundle.md) closed on 2026-07-28, the last item to, and in
one session across all four of its tasks: `ExportLaTeXBundle` is the 23rd public symbol and writes a
**directory** where `ExportLaTeXDocument` writes a file. Measured on the causal-graphs specimen, the
one-file export left `main.tex` alone in an empty directory while that `.tex` named seven
`\includegraphics` files and `\bibliography{references}` — byte-exact, and compilable nowhere but the
paper's own directory. The bundle now carries all seven PNGs, the `.bib` and a `main.bbl`, with nothing
arXiv excludes in it: the LaTeX run happens in a scratch copy so the `.aux`, `.log` and PDF stay out.
Its two open decisions were taken rather than revised with Pavel, at his instruction, and are recorded
in the item: a figure the paper names but disk lacks is **reported, never evaluated**, and **no PDF goes
in the bundle, ever**. `Tests/Bundle.wlt` and a bundle group in `Tests/Specimens.wlt` took the suite from
228 to 258.

[Complex Systems Stylesheet and Submission Buttons](Done/2026-07-28-JournalSubmission.md) closed the same
day. `ComplexSystems.nb` is the **fifth template**, a 432 × 648 page with a 306 pt column, display math
flush left, and one counter per environment — proved in a rendered PDF that reads `Definition 1.` /
`Theorem 1.` then `Definition 2.` / `Theorem 2.`, where the other four read `1.1` and `1.2`. It is the
first template measured from a journal's own files rather than styled to resemble a class, and the first
with a screen/print font split, both faces being commercial. Neither the `.sty` nor the `.nb` carries a
licence grant, so neither is vendored — they live in gitignored `Resources/` and the sample PDF is a
notebook printout. Its T3 was a scoping task whose output became the item above.

[Conversion and MaTeX UX](Done/2026-07-28-ConversionUX.md) closed on 2026-07-28: the palette's four
near-identical conversion labels became six verbs under three headings that carry the direction, each
with a tooltip, and `Import .tex file…` / `Export to .tex…` joined them — the whole-paper route had no
palette presence at all, which is what made the per-selection buttons look like the only way out to
LaTeX. Closed with one clause waived: Pavel has not yet read the new palette on a real paper.

**0.1.16 is the published version** (2026-07-28) — **270 tests green**, `Scripts/PublishPaclet.wls` then
`Scripts/DeployPreviews.wls`, installed and driven headless against the installed copy: it is the whole
`BasicFunctionality` shakedown. Twelve entry points that returned unevaluated with no message now answer
`"Open a notebook first!"`; `GoBack` reports its two empty states and raises the notebook it returns to;
the seven stylesheets stopped storing an unevaluated `First[{}]` as the hyperlink record; the palette
carries nine literal guards of its own, since a button's stored code cannot call a `PackageScope` one;
and the 22 reference pages are generated from `Kernel/Usage.wl` by `Scripts/RegenerateUsage.wls`.
**The documentation is deployed nowhere but inside the paclet** — the browser mirror was deleted at
Pavel's call on 2026-07-28. 0.1.13 (2026-07-28) was the submission bundle, the `ComplexSystems`
template that 0.1.12 generated but did not ship, and a 22nd reference page.
[First Public Release](Done/2026-07-27-Release.md) closed on 2026-07-27 with **0.1.11**, the version
marker agreeing and the README's `PacletInstall` line installing it from the cloud onto a machine with
no local copy. [Repo Organization](Done/2026-07-27-RepoOrganization.md) closed the same day: the root
holds five files beside `Images/`, `LaTeX/`, `MathNotebook/`, `Notebooks/`, `Resources/`, `Scripts/` and
`Work/`, and there is deliberately no `Wiki/` — durable knowledge is `CLAUDE.md`.

## Backlog

Empty. Reduced from eight items to three on 2026-07-27 — the four in `Dropped/` each carry a note
saying why and what would reopen them — the one item left was activated and closed on 2026-07-28, and
the item its scoping task proposed was written, worked and closed the same day.
