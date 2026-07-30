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

Empty. `EnvironmentBlocks` closed on 2026-07-30 with all three tasks done, and its two remaining clauses
are Pavel's — see its Hand-off.

[Environment Blocks](Done/2026-07-30-EnvironmentBlocks.md) closed on 2026-07-30. A theorem-like
environment is one block that may span several cells, and until T1 nothing but the importer could make
one: prose typed after a display equation inside a definition landed at the sheet's `Text` margin **64 pt**
to the left of the block's own, and grouping cannot fix it — measured, a `CellGroupData` leaves every
resolved `CellMargins` identical, so what holds a block together is the **style**. `Continue block`
repeats it with the label and the counter suppressed, carrying the QED square and the `\end{…}` onto
whichever cell is now last. T2 was the bigger of the two: `cellToLaTeX` is keyed on the importer's own
two tagging rules and on nothing else, so a block the author typed exported as **bare prose** — no
`\begin{definition}` anywhere — which had made all twelve palette environment buttons **screen-only**;
the repair writes those same two rules onto a hand-written run, so one path serves an imported block and
a typed one and separators, labels and nesting all apply unchanged. T3 filed the durable half into
`CLAUDE.md` (two bullets) and found the tutorial stale in **five** passages where one was predicted, two
of them predating `ComplexSystems` by two days rather than belonging to this item at all — which is why
that bullet now prescribes a two-directional audit of both build scripts instead of a grep. Suite 383/1
— and the one failure turned out **not** to be the environment artifact two passes had called it, but
`FrontEnd.wlt`'s `BibliographyHeading` dying on a silent machine as well, now
[Front End Test Isolation](Backlog/FrontEndTestIsolation.md). The preamble-less export it exposed became
[Hand-Written Preamble](Backlog/HandWrittenPreamble.md).

[Bibliography Display](Done/2026-07-30-BibliographyDisplay.md) closed on 2026-07-30, three defects found
in the tail of `FirstReadingDefects` S6 while answering Pavel's report that the entry labels were
invisible in the deployed samples. That report was the deploy script and is fixed separately; these were
the paclet's. `PlainArticle`'s `Reference` resolved **Times 12** against prose of **Source Sans Pro 15**,
having fallen through to Default's own `Reference` because `geometryStyleCell` dropped the base cell's
`StyleDefinitions -> StyleData["Text"]` — and fixing it widened the shared gutter 185 → **205**, the key
measuring 190 at the new face. The bibliography anchor printed **"3. References"** three sections in,
`CounterIncrements -> { }` suppressing the increment and not the drawing, so it carries `CellDingbat ->
None` too. And an imported bibliography had **no heading at all**; both routes head it now, suppressed,
so the round trip is untouched — the causal paper's census `Cells` 167 → 168, `Section` 8 → 9,
`Tagged` 39 → 40.

`FirstReadingDefects` closed on 2026-07-30 with all six tasks done; the two clauses it left are
Pavel's, not a session's — see its Hand-off.

[First Reading Defects](Done/2026-07-30-FirstReadingDefects.md) — Pavel read the imported causal-graphs paper
and reported six defects, all triaged with measured causes on 2026-07-29. Done: `\varnothing` and the
178 other glyphless macros draw their characters (T1, S1, suite 329 → 334); the character escapes
unescape into displayed text and re-escape on export through one shared segmentation that carries
every raw-TeX span verbatim (T2, S2, suite 334 → 341, both specimens byte-exact); a compound
`\cite{a, b}` is one navigating button per key with the command's bytes riding in `ButtonNote` and the
export recomposing them byte-exact — the causal paper's dangling citations went to zero and its
Buttons census 14 → 21 (T3, S3, suite 341 → 345); and a copied reference reads its word and counter
chain off the target cell and keys on the cell's tag rather than on a `CellID` an imported cell does
not have — the reported `Theorem 0.0` was two defects in one string, and the specimen's axiom now
pastes as `Axiom 1.3.3` on the rendered page and navigates (T4, S4, suite 345 → 358); and the two font
sliders now agree about mathematics — an untouched math slider means "scale with the page", so one
slider carries prose, display and inline mathematics and MaTeX together while an explicit math size
overrides it, and the reported double-scaling turned out to sit on top of a front-end fact nothing here
knew, that a *relative* `FontSize` on `InlineFormula` renders at the **square** of its ratio, so the
shipped control drew 4.41 × the host where it meant 2.1 (T5, S5, suite 358 → 364); and `LabelReferences`
now writes the bibliography's own cells and nothing else, which turned out to be a correctness fix before
a speed one — the old whole-notebook `NotebookPut` killed **174 of 174** `CellObject`s and reassigned
every `CellID`, so a reference clicked after a refresh was pointing at a cell that no longer existed
(T6, S6, suite 364 → 368; 22 MB over 486 cells handed to the front end became 4.6 kB over 14, and 0.076 s
became 0.0014 s). Closed with two clauses that are Pavel's: the freeze on a real window, which has no
headless measurement, and the sample bibliographies his reading turned up — the invisible entry labels
are in `Scripts/DeployPreviews.wls`, whose sample `Reference` cells carry neither a tag nor a label, and
not in the paclet, whose importer was measured to rule it out.

[Import Display Defects](Done/2026-07-29-ImportDisplayDefects.md) closed on 2026-07-29 — all five
display defects fixed, 0.1.17 installed, `main.nb` re-imported through it, and the reading half of T4
finally happened: its output is the six-point report that became First Reading Defects above. The
Definition-dingbat question turned out unanswerable from an imported paper (its dingbats are per-cell),
so the by-name stylesheet clause stays with `BasicFunctionality`.

[Palette and View UX](Done/2026-07-29-PaletteAndViewUX.md) closed on 2026-07-29 with all seven tasks
done and **0.1.19 published**, in one run after Pavel reviewed the palette group by group. T1 renamed
`Environments` to **`Blocks`** and found that nothing in the suite watched the group headings; T2 made
inline mathematics follow the math slider by scaling the `"InlineFormula"` **ratio** rather than writing
a size. The review then added five: **T3** `InsertReference`, whose surgery is a pure core over the
`Notebook` expression because moving a `\end{thebibliography}` between cells is not something a
selection can express; **T4** `InsertCitation` as a chooser dialog over the document's own tags, a
dialog and not a palette combobox because the palette needs no kernel to display; **T5**
`SortBibliography` in four orders, turning on the split between the block's *positional* parts and its
*travelling* one; **T6** the palette rebuilt as six groups — `Blocks`, `Referencing`, `Selection`,
`Document view`, `Import & Export`, `Setup` — losing `Tag cell` and the two per-selection LaTeX
buttons and gaining a tooltip on all 24 items; **T7** two reference pages, eleven stale passages of the
tutorial, and the release. Suite 292 → 329. The one clause left is Pavel's: reading the palette on a
real paper.

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

**0.1.20 is the published version** (2026-07-30) — `Scripts/PublishPaclet.wls` then
`Scripts/DeployPreviews.wls`, and driven from the cloud install before being believed: the marker reads
0.1.20, an imported paper comes back as `{Section, Text, Section, Reference}` with the anchor heading its
bibliography, the entry carries its `[smith]` label, and `LabelReferences` leaves every cell of the
document alive. The one read that looks wrong is the known unmeasurable — a `Reference` margin of 66
rather than 205, because by-name stylesheet resolution falls through to `Default.nb` for a locally
installed paclet in this environment (`BasicFunctionality`'s outstanding clause). It carries
`FirstReadingDefects` T6 and all of `BibliographyDisplay`, plus the second session's `EnvironmentBlocks`.

0.1.16 (2026-07-28) — **270 tests green**, `Scripts/PublishPaclet.wls` then
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

[Front End Test Isolation](Backlog/FrontEndTestIsolation.md) — `Tests/FrontEnd.wlt` has one
**permanently red** test and 0.1.20 shipped with it red: `BibliographyHeading` (TestID `t0v83dcroxjjzb`)
fails on an idle machine, in the suite and alone, because the service front end link dies before its
export and the PDF is never written. The measurement is correct standalone, so it is the association's
27 notebooks it does not survive — being last only decides which measurement finds the corpse. The cost
of not knowing this: the unnumbered bibliography heading is **unasserted**, and the failure was written
off as load twice before anyone read the TestID.

[Hand-Written Preamble](Backlog/HandWrittenPreamble.md) — a notebook that was never imported exports a
body and nothing else, so it compiles nowhere: measured 2026-07-30, a typed six-cell paper comes out as
229 bytes with `\documentclass` 0, `\begin{document}` 0 and `\newtheorem` 0, its three blocks all
correct LaTeX with nothing to resolve them against. `EnvironmentBlocks` T2 is what makes it worth an
item — before it the blocks were bare prose and a missing `\newtheorem` was moot. Its T1 is a four-part
**decision** (which class, which `\newtheorem` lines, which packages, where a bibliography goes) and is
Pavel's to take, not a session's; T2 must leave an imported paper's stored preamble byte for byte.

Before that: reduced from eight items to three on 2026-07-27 — the four in `Dropped/` each carry a note
saying why and what would reopen them — the one item left was activated and closed on 2026-07-28, and
the item its scoping task proposed was written, worked and closed the same day.
