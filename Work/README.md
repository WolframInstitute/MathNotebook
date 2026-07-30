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

*Nothing active.* `Front End Test Isolation` closed on 2026-07-30 with T3; the two open items are in
`Backlog/`, and [Reset View Render](Backlog/ResetViewRender.md) is the one with a measured mechanism
and a repair left to write.

## Recently closed

[Front End Test Isolation](Done/2026-07-30-FrontEndTestIsolation.md) — **closed 2026-07-30 with T3**: a
front end that does not survive a measurement group now aborts `Tests/FrontEnd.wlt` with
`frontEndGroup::died`, naming the group and the measurements carrying `$Failed`, so a dead front end can
never again be read as a content mismatch about the paclet. `ownFrontEnd` reads the link id either side
of its group *and* scans for `$Failed`, because the id catches a transparent relaunch while reading
**equal** when the front end answered and the measurement did not — which is the shape
`BibliographyHeading` had. Bitten by injecting one `$Failed`: `TestReport` answers `$Aborted` and emits
**no tests**. Two silent faults fixed on the way, both now in `CLAUDE.md`: a message string is a
`StringForm` template, so the markdown backticks around a shell command became **slots** and printed
`StringForm::sfr` twice ahead of the real text; and `run_tests.wls` would have exited **0** on a
non-reporting file, since `$Aborted["TestsFailedCount"]` is not a number and `Boole` never evaluates —
loud in the log, green at the shell. Suite **384/0**.

**0.1.21 published and verified against the cloud install, 2026-07-30.** Marker `0.1.21`, paclet
installs, 25 public symbols against 24 declared (the gap being `$LastHyperlinkCell`, as recorded), all
25 carrying usage strings; an imported paper round-trips byte-exact, a typed notebook's blocks export
as real `\begin{definition}`/`\begin{theorem}` and its bibliography as a `thebibliography`, and the
citation chooser driven over a notebook `InsertReference` **built** offers the two entries and not the
anchor's marker tag — the 0.1.18 cross, clean. The check's own first two readings were probe faults of
kinds `CLAUDE.md` already names (a trailing newline, and a `PackageScope` symbol reached in the wrong
context), both now written down there. Nothing in `Kernel/` changed in this release: it is the test
harness, the runner and the record.

**T4 closed on 2026-07-30 in both
directions.** The shape is the product's — `SetDocumentFontSize` + `ResetDocumentView` + `NotebookClose`
on a document whose stylesheet is a **name** kills the next whole-notebook render **4/5**, and **5/5** on
the paclet's own sheet name, against 0/5 for the sheet embedded with `Get`, 0/5 for either call alone, 0/5
with the document left open and 0/5 with no render — but the feared symptom is not: an author who opens a
paper on that named sheet, drags **either** slider, resets the view and prints *that paper* loses nothing,
0/5 deaths with the PDF written 5/5. So the palette's font slider does not crash the front end on the next
print; what remains is reset, **close**, then print a second paper, which is
[Reset View Render](Backlog/ResetViewRender.md). S3's culprit is corrected rather than confirmed —
`viewMeasurements["Default.nb"]` survives **0/6** under repetition, so the entry it named is not the killer
and a single-shot sweep of twenty controls could never have told a 4/5 rate from a certainty. **And the
wedge that cost S1 a whole session is solved and was never ours**: it is AppKit's "reopen windows after a
crash?" modal, raised on a headless front end where nobody can see or click it — `sample` shows the main
thread in `-[NSAlert runModal]` under `promptToIgnorePersistentStateWithCrashHistory:`, the history being
24 identical `EXC_BAD_ACCESS` reports in `~/Library/Logs/DiagnosticReports/` back to 2026-07-25, and one
`defaults write com.wolfram.WolframApp ApplePersistenceIgnoreState -bool true` took `UsingFrontEnd[1 + 1]`
from three hangs in a row to answering in **one second**. That retires the reboot, the `pkill` ritual as a
cure, the RSS heuristic (103–117 MB here, not 94–99) and the `-code`/`-file` axis. Suite **384/0**.

Before that, T2 closed on 2026-07-30 by answering its own question with a no: the 27
notebooks are **neither a leak nor a ceiling**. Exactly one entry poisons the front end — `"Default" ->
viewMeasurements[ "Default.nb" ]`, the only one of the 34 passing its stylesheet **by name** where every
sibling embeds one with `Get` — and after it the next whole-notebook `Export` kills the front end
(3098 → 3163), while each of the twenty other live entries leaves the link untouched, `Copied` alone
survives, and 32 entries survive one front end. Which makes T1's split right for a narrower reason than it
claimed, and raises **T4**: a named-sheet document under `SetDocumentFontSize` is what an *author's* paper
is, so the palette's font slider may crash the front end on the next print. Three probe faults hid this
for three sessions — a dead front end is **relaunched transparently**, so `Length @ Notebooks[]` answers
`1` straight across a death; ``MathLink`LinkConnectedQ`` answers `False` on a healthy link; and a `ps` line
grepping for `MathematicaServer` matches its own `bash -c` wrapper. The machine ended S3 wedged, by
`pkill -9` of a front end a running script still held — this file's own hygiene applied one step too
early. T1 had closed earlier the same day and the suite is **384/0**: the permanently red
`BibliographyHeading` (TestID `t0v83dcroxjjzb`) is green, and 0.1.20 had shipped with it red.
Two measurements did it, and the first says the task's own suggested
fix was a no-op — **`UsingFrontEnd` does not give you a second front end**, two sequential blocks in one
kernel reporting the identical `LinkObject`, while `Developer`UninstallFrontEnd[]` does (link 106 → 109
→ 112 → 115, each fresh). The second answers S1's `needs-human:` outright: **`LinkClose` on `$FrontEnd`
is what wedges the machine**, leaving the kernel unable to launch another front end so the next
`UsingFrontEnd` hangs forever — a twenty-line reproduction with no paclet loaded, which retires the
ruled-out list S1 spent a session building. `$measured` is now three associations in three front ends
(dialogs, live notebooks, page renderers), so a front end killed by one group cannot take the others with
it, and both orderings that used to be load-bearing dissolve. Bitten by restoring the anchor's missing
`CellDingbat -> None`: `{True, False}` → `{False, True}`, "Numbered" flipping true with no front-end
death in the log, which is the Spec's central point — the heading claim is asserted now rather than
resting on a test that had never once run.

`EnvironmentBlocks` closed on 2026-07-30 with all three tasks done, and its two remaining clauses
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

[Reset View Render](Backlog/ResetViewRender.md) — `ResetDocumentView` after `SetDocumentFontSize` on a
paper whose stylesheet is a *name*, once that paper is **closed**, leaves the front end unable to render a
page: measured 2026-07-30 at 4/5 for `"Default.nb"` and 5/5 for the paclet's own sheet name, with the PDF
simply never written, against 0/5 for the same sheet embedded with `Get`, for either call alone, and with
the document left open. Backlog rather than Active because the author's common path is clean — printing the
paper you just reset is 0/5 — so this is reached by closing a paper and printing a second one. **T1 closed
2026-07-30 and it is the *name*, not the removal**: `SetOptions[ nb, StyleDefinitions -> "Default.nb" ]`
alone, tagging rules left in place, kills the next render **5/5**, while deleting the tagging rules and
leaving the private sheet installed is 0/5 and the same assignment embedded with `Get` is 0/5. Two things
that follow — the lethal clause is reachable **without** `ResetDocumentView` and is lethal more often
without it (5/5 against the whole reset's 2/5, on a sequence that contains it), so the defect is wider
than the exported function; and the obvious repair is ruled out on other grounds, an embedded parent
letting every unoverridden style fall through to `Default.nb` and leaving the Format menu. T2 is the
repair, and it has to keep the name and change *when* it is re-resolved.

[Hand-Written Preamble](Backlog/HandWrittenPreamble.md) — a notebook that was never imported exports a
body and nothing else, so it compiles nowhere: measured 2026-07-30, a typed six-cell paper comes out as
229 bytes with `\documentclass` 0, `\begin{document}` 0 and `\newtheorem` 0, its three blocks all
correct LaTeX with nothing to resolve them against. `EnvironmentBlocks` T2 is what makes it worth an
item — before it the blocks were bare prose and a missing `\newtheorem` was moot. **T1 closed 2026-07-30
with Pavel's four calls**: `\documentclass{article}` always, with the sheet named in a `%` comment;
`\newtheorem` only for the styles the notebook uses, numbered as the sheet draws them (`[section]` on one
shared counter for six sheets, one counter per environment for `ComplexSystems`);
`amsmath`/`amssymb`/`amsthm` unconditionally with `graphicx`, `hyperref` and `enumitem` on a scan; and
`thebibliography` in place with no `\bibliographystyle`. Three of the four are "look at the notebook"
rather than a constant, so T2 is now a writing task — and it must leave an imported paper's stored
preamble byte for byte.

Before that: reduced from eight items to three on 2026-07-27 — the four in `Dropped/` each carry a note
saying why and what would reopen them — the one item left was activated and closed on 2026-07-28, and
the item its scoping task proposed was written, worked and closed the same day.
