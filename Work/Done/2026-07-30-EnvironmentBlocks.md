# EnvironmentBlocks

## Spec

A theorem-like environment is one block that may span several cells, and until now nothing but the
LaTeX importer could make one. Two consequences, both reported by Pavel on 2026-07-30:

1. Prose typed after a display equation inside a definition lands at the sheet's `Text` margin
   instead of the block's, so the block visibly falls apart.
2. A block the author typed exported as bare prose — no `\begin{definition}` anywhere — which made
   all twelve palette environment buttons screen-only.

Measured, so the size of (1) is not an impression:

| sheet | `Text` | environment body | `DisplayFormula` |
|---|---|---|---|
| AMSArticle, ArXivArticle, RevTeXAPS, SpringerJournal, PlainArticle | 66 | 130 | 66 |
| ComplexSystems | 54 | 67 | 90 |

The 130 is reserving room for the label, which hangs to the **left** of the cell margin:
"Definition 1.1." rasterizes at **79 pt** at Palatino 13, so the indent cannot simply be lowered to
`Text`'s 66 without the documented dingbat clipping.

**Grouping is not the mechanism, and that is measured too.** Writing four cells as a `CellGroupData`
leaves every resolved `CellMargins` identical — `{130, 66, 130, 66}` grouped and ungrouped. A group
bracket carries no typography. What carries a block is the **style**, which is what the importer
already relies on: a continuation cell repeats the environment style with `CellDingbat -> None` and
`CounterIncrements -> {}`, suppressed on the cell rather than declared as a continuation style,
because "this cell continues the one above" is true under every stylesheet.

## Tasks

- [x] T1 — `InsertEnvironment[Automatic]` plus a "Continue block" palette button.
- [x] T2 — export a hand-written block as a real environment.
- [x] T3 — the loose ends, once the tree is quiet.

## Hand-off

**The re-run happened, and the artifact was not one.** `Tests/FrontEnd.wlt` is **57/1** on an idle
machine with no other Wolfram process alive — both in the full suite (383/1) and run alone — and the
failure is always `BibliographyHeading` (TestID `t0v83dcroxjjzb`). The service front end link dies
before the export (`LinkObject::linkd`, then `Import::nffil` on a PDF never written), so the assertion
receives `StringContainsQ[StringDelete[$Failed, Whitespace], …]`. Driven standalone the measurement is
**correct**, so it is the association's accumulated 27 notebooks it does not survive, not its own
content. Filed as [Front End Test Isolation](../Backlog/FrontEndTestIsolation.md) and recorded in
`CLAUDE.md`; it is `BibliographyDisplay`'s test, not this item's, and it means the unnumbered
bibliography heading is currently **unasserted**.

Two further clauses, and neither is a session's:

- **`PlainArticle`'s `DisplayFormula` is left-flush**, so an equation inside a body sits 64 pt left of
  the block's own prose on the very sheet an imported paper lands on. The four journal templates centre
  theirs and read correctly. Changing it is a typography change to the one sheet that deliberately
  holds none — **Pavel's call**.
- **A hand-written notebook exports a body with no preamble.** Measured this session: a typed six-cell
  paper comes out as 229 bytes with `\documentclass` 0, `\begin{document}` 0 and `\newtheorem` 0, its
  three blocks all correct. Scoped out as [Hand-Written Preamble](../Backlog/HandWrittenPreamble.md),
  whose T1 is the four-part decision it needs.

## Progress

### T1, 2026-07-30 — the continuation form

`InsertEnvironment[notebook, Automatic]` in `Referencing.wl`. `enclosingEnvironment` walks up from
the selected cell through the cells a body may contain (`$bodyStyles`: display math and the item
family) and takes the nearest cell of an environment style. The walk is a `TakeWhile` and **not** a
`FirstCase`: a `Text` cell above means the block ended there, and reaching past it would continue the
wrong block.

Two things travel to whichever cell is now last, and neither is optional:

- **The QED square.** `Proof` is the one environment whose style carries a `CellFrameLabels`, so the
  cell it used to end on has to suppress it explicitly or the square prints mid-proof.
- **The `\end{...}`.** An imported block closes on its last cell (T7 of `LaTeXPaperImport`). Left
  there, the author's new prose exports *after* the environment closed, as bare text — silently, with
  the notebook looking perfectly right.

Written per-cell (`SetOptions`, `CurrentValue`, `NotebookWrite`), never `NotebookPut`: rewriting the
notebook to change two cells kills every `CellObject` in the document (`FirstReadingDefects` T6).

The wrapper had to become `InsertEnvironment[style : _String | Automatic]`. Left at `_String` the
one-argument call stays unevaluated with no message — the exact shape `withInputNotebook` exists to
close — so `FrontEnd.wlt`'s no-document association gained an entry of its own for it.

### T2, 2026-07-30 — the export

`cellToLaTeX` is keyed on the stored `"EnvironmentOpen"`/`"EnvironmentClose"` rules and on nothing
else, so the repair **writes those same two rules** onto a hand-written run rather than adding a
clause: one export path serves an imported block and a typed one, and separators, labels and nesting
all apply unchanged. `environmentWrapped` runs after the `Select`, so the evaluation family a figure
leaves behind cannot split a block in two.

`environmentRuns` opens a run at a cell of an environment style carrying neither rule and no
`CellDingbat -> None` (the census's own key for "heads a group"), extends it through continuations of
the same style and through `$bodyStyles`, and **ends it at the last cell of the environment style** —
a trailing equation stays outside, being as likely to follow the block as to belong to it.

One trap, and it cost a test: the environment **name** must come off `theoremDeclarations` and not off
`theoremEnvironments`, which is that table joined *onto* the twelve defaults. The inverse lookup there
answered `definition` for a paper whose only declaration is `\newtheorem{defn}{Definition}` — the one
answer that cannot compile, since the document defines `defn` and nothing else.

### Verification

Three bite checks, each by literal replacement with an occurrence count of exactly 1:

| bite | effect |
|---|---|
| drop the `environmentWrapped` call | `Document.wlt` 96/4 → 93/7 |
| continuation cell written as `Text` | `FrontEnd.wlt` 55/1 → 53/3 (margins **and** QED) |
| do not move the `\end` | `FrontEnd.wlt` 55/1 → 54/2 (the imported case, and only it) |

The third bite was run against an **isolated rsync copy of the repo**, not in place: another agent was
working in the tree, and an in-place bite restore would have clobbered whatever it held. Worth keeping
as the procedure — the copy costs one `rsync` and removes the whole hazard.

The bites also showed what each test does *not* cover: `Document.wlt`'s imported-continuation test
asserts the tagging **shape** and survives bite 1, so the live `\end` move is covered only by
`FrontEnd.wlt`. That is the split to keep in mind before trusting either file alone.

Baseline note: 7 failures in the suite (4 `Document`, 2 `Specimens`, 1 `FrontEnd`) are **not** from
this item — they are the in-flight `BibliographyDisplay` work's `headedBibliography`, which adds a
`Section` anchor the census and three `Document.wlt` expectations have not been updated for, and a
`PlainArticle.nb` whose `Reference` gutter no longer clears the widest key.

- **S3** 2026-07-30 T3 — the four parked notes filed to their real destinations and `## T3 — left open`
  deleted, a sixth section being a destination violation. Durable knowledge → `CLAUDE.md`: two new
  bullets beside the T7 environment one (the screen mechanism, and the export), and the
  tutorial-staleness bullet rewritten around what this pass actually found. Tutorial → five passages of
  `Scripts/BuildTutorial.wls`, regenerated. Out of scope → [Hand-Written
  Preamble](../Backlog/HandWrittenPreamble.md). Pavel's → `## Hand-off`.

  Two things worth keeping that fit nowhere else. **The tutorial needed five passages where the note
  predicted one, and only three were about this item** — the other two predated `ComplexSystems` by two
  days ("Four templates"; the shared-counter claim it breaks), which is why the `CLAUDE.md` bullet now
  prescribes a two-directional audit rather than a grep. The regeneration diffed at **74** non-`ExpressionUUID`
  lines: those five passages, the four header offsets, the cell-tags index, nothing else.

  **Suite: 383 passed, 1 failed** — and the recorded baseline of 7 is down to that one, `BibliographyDisplay`
  having closed (`Document` 4 → 0 at 101/0, `Specimens` 2 → 0 at 32/0). The one left is `FrontEnd.wlt`'s
  bibliography-anchor measurement and it is an **environment artifact, not an assertion**: its rendered-page
  read answers `$Failed` with `FrontEndObject::notavail`, so the `StringContainsQ` against `"3. References"`
  is handed `StringDelete[$Failed, Whitespace]`. Another agent was holding four concurrent kernels and three
  `MathematicaServer`s in an unrelated repo throughout, and a re-run of that file alone wedged at 0.4% CPU
  for thirteen minutes rather than finishing. **This session changed no kernel code** — `CLAUDE.md`,
  `BuildTutorial.wls`, the generated `.nb` and `Work/`, none of which any `.wlt` reads — so the failure
  cannot be its doing; but it is recorded as unresolved rather than as green, and it wants one re-run on a
  quiet machine before 0.1.21.

  > Superseded: the re-run was done on a silent machine and it is **not** an environment artifact —
  > `FrontEnd.wlt` is 57/1 there too, always on `BibliographyHeading`, whose front end link dies before
  > the export. The clause above attributing it to another agent's kernels is wrong; the two paragraphs
  > of it that read on the concurrency are a diagnosis I made twice and should have tested once. See
  > `CLAUDE.md` § *Build & test* and [Front End Test
  > Isolation](../Backlog/FrontEndTestIsolation.md).
