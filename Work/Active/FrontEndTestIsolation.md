# Front End Test Isolation

*[ LLM Generated ]*

> Type: defect
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

**`Tests/FrontEnd.wlt` has one permanently red test, and 0.1.20 shipped with it red.** Measured
2026-07-30 on an idle machine with no other Wolfram process alive — in the full suite (383/1) and with
the file run alone (57/1), the same test both times:

- **TestID** `t0v83dcroxjjzb` — the `BibliographyHeading` assertion, `{ "Heading", "Numbered" }` against
  `{ True, False }`.
- **Actual** `{ StringContainsQ[ StringDelete[ $Failed, Whitespace ], "three.References", … ],
  StringContainsQ[ StringDelete[ $Failed, Whitespace ], DigitCharacter ~~ ".References", … ] }`.
- **The log names the cause in order**: `LinkObject::linkd` — "unable to communicate with closed link
  `MathematicaServer`" — then `Import::nffil` on
  `$TemporaryDirectory/MathNotebookBibliographyHeading.pdf`, a file the export never wrote, then
  `FrontEndObject::notavail`.

**The measurement is not at fault, which is what makes this an isolation defect rather than a
bibliography one.** Driven standalone in its own `UsingFrontEnd` against `PlainArticle.nb`, all three
stages pass: a PDF export with no `InsertReference` writes its file, `InsertReference[ nb, "smith" ]`
leaves `{ Text, Section, Reference }`, and the two together write a PDF whose plaintext contains
`References`. So the front end does not survive the **whole** `$measured` association — 34 entries, 27
notebooks opened over 23 `NotebookPut` and 4 `CreateDocument`, 4 PDF exports — and `BibliographyHeading`
being last only decides which measurement discovers the corpse. `CLAUDE.md` already records that six
extra `CreateDocument`s were once enough to kill it unaided; moving this one last bounded the blast
radius from four tests to one without making the one assert anything.

**Two things follow, and the second is the expensive one.** A `1 failed` here is not a tolerable
baseline: the unnumbered bibliography heading is currently **unasserted**, so `BibliographyDisplay`'s
central display claim rests on a test that has never once run. And the failure was written off as an
environment artifact **twice** — another agent's kernels were genuinely saturating a core at the time,
which made the wrong diagnosis fit — so the rule this item should leave behind is that a failure in this
file gets identified by TestID before it gets attributed to load.

**Not in scope:** reordering `$measured` again. That is the fix that has already been tried and it is
what produced the current state.

## Tasks

- [ ] T3 — make a dead front end fail loudly rather than as a content mismatch: a measurement that
      returns `$Failed` where a string was expected should abort the file with a named message, so this
      cannot be mistaken for an assertion about the paclet again.

### Done

- [x] T4 (S4) — the shape is the product's and the feared symptom is not: `ResetDocumentView` after
      `SetDocumentFontSize` on a *named*-sheet document, once closed, kills the next page render 4/5
      (5/5 on a paclet sheet name), while the author's own paper printed after either slider is 0/5.
      Split out as `Work/Backlog/ResetViewRender.md`.

- [x] T1 (S2) — give the PDF-exporting measurements a front end of their own, and prove it by the
      TestID going green on an idle machine.
- [x] T2 (S3) — neither a leak nor a ceiling: one entry poisons the front end for the next page
      render, and it is named in the test file and in `CLAUDE.md`.

## Hand-off

**T2 is answered and the Spec's own question was the wrong one, which is the fact worth carrying: the
27 notebooks are neither a leak nor a ceiling.** One entry poisons the front end for the next page
render — `"Default" -> viewMeasurements[ "Default.nb" ]`, the only one of the 34 whose stylesheet parent
is a *name* — and everything the count hypothesis predicted is false. The durable form, with the three
probe faults that hid it, is in `CLAUDE.md` § *Build & test*, and the test file names the entry at the
entry. So T1's split is right for a narrower reason than it claimed, and the rule it leaves is in the
group comment: do not move a page renderer into the live group.

**T4 is answered in both directions, and the negative is the one to carry: the palette's font slider does
not crash the front end on the author's next print.** Open a paper on the paclet's own named sheet, drag
either slider, reset the view and print *that paper* — 0/5 deaths, PDF written 5/5. What does kill a
render is the same three calls with the document **closed** first, and only when the sheet is a *name*:
4/5 for `"Default.nb"`, **5/5** for `FrontEnd`FileName[{"MathNotebook"}, …]`, against 0/5 for the sheet
embedded with `Get`, 0/5 for either call alone, 0/5 with the document left open and 0/5 with no render.
The table is in [`CLAUDE.md` § *Build & test*](../../CLAUDE.md); the product half is its own item,
[Reset View Render](../Backlog/ResetViewRender.md). **S3's attribution is corrected rather than
confirmed**: `viewMeasurements[ "Default.nb" ]` survives 0/6 under repetition, so the entry it named is
not the killer — the *shape* it shares with the killer is — and a single-shot sweep of twenty controls
cannot tell a 4/5 rate from a certainty. What immunises that entry is unexplained.

**The wedge is solved and it was never ours: it is AppKit's "reopen windows after a crash?" modal, raised
on a headless front end where nobody can see or click it.** `sample` on the hung process puts its main
thread in `-[NSPersistentUIRestorer promptToIgnorePersistentStateWithCrashHistory:]` → `-[NSAlert
runModal]`, and the crash history feeding it is 24 identical `EXC_BAD_ACCESS` reports in
`~/Library/Logs/DiagnosticReports/WolframNB-*.ips` back to 2026-07-25 — a Wolfram 15.0 service front-end
bug, nothing of this repo's. **One call clears it**: `defaults write com.wolfram.WolframApp
ApplePersistenceIgnoreState -bool true`, after which `UsingFrontEnd[ 1 + 1 ]` answered in **one second**
where it had hung three times running. That retires the reboot, the `pkill` ritual as a *cure*, the RSS
heuristic (hung front ends measured 103–117 MB here, not 94–99) and the `-code`/`-file` axis — with the
alert up, both hang identically. S1's `sample` was already the right detector, read one frame too
shallow: the modal sits *below* `NSApplicationMain`, so the whole call graph has to be read.

**What T3 inherits is unchanged, and its case is now stronger rather than cheaper.** A *dead* front end is
what T3 was written for, and T4 produced a reliable way to make one — the 4/5 sequence above — so the
reporting improvement can finally be bitten instead of argued. An **external** wall-clock guard is still
needed for a *wedged* one (`perl -e 'alarm N; exec @ARGV'`; `timeout` is not installed on this machine),
and the first thing a front-end session should run is that trivial `UsingFrontEnd[ 1 + 1 ]`.

**The S2 probe fault still applies, S3 added three of its own, and S4 two more** — reading `sample` only
as far as `NSApplicationMain`, and `CurrentValue[ $FrontEnd, "VersionNumber" ]` as a liveness probe, which
answers non-numerically on a *healthy* front end and so asserts nothing; the link id changing is the only
reading that detects a death.
`TestReport[…]["TestsFailed"]` is not a property — it answers `Missing["KeyAbsent", …]` per test and
prints phantom failures even on a fully green run, which reads exactly like a broken reporter; the
working read is `Select[ Values @ report["TestResults"], #["Outcome"] =!= "Success" & ]`. And a killed
`wolframscript` leaves its `MathematicaServer` and `WolframKernel` children alive, contending for the
next run — `pkill -9 -f MathematicaServer` **between** attempts is what made S2's runs reproducible
where S1's were not; during one it is the wedge above. S3's three — `Length @ Notebooks[]`,
``MathLink`LinkConnectedQ`` and a `ps` line that reads its own `grep` wrapper — are in `CLAUDE.md`, and
the first of them is why this took three sessions to reach.

## Decisions

| decision | rationale | evidence |
|---|---|---|
| Isolate with `Developer`UninstallFrontEnd[]` between groups, not with a second `UsingFrontEnd`. | A second `UsingFrontEnd` is a no-op — the task's own suggested fix. | Two sequential blocks report the identical `LinkObject[…, 106, 3]`; after the uninstall the link goes 109, 112, 115, each fresh and each answering. |
| Three groups — dialogs, live notebooks, page renderers — rather than one front end per entry. | The membership rule is checkable by reading one line of a helper ("does it `Export` the whole notebook"), where a per-entry split is 34 front-end launches for a file that measures in ~17 s. | Suite 384/0 with the split; the rendering group's eleven entries survive one front end. |
| `BibliographyHeading` is an ordinary member of its group, not pinned last. | Being last only decided which measurement discovered the corpse; a group of its own is what the ordering was standing in for. | The TestID is green with it mid-group, and red for the *right* reason under the bite. |
| The three-group split stays, and the leak the Spec asked about is not one. | The cause is a single poisoning entry, so the split works because it separates `Default` from the renderers — not because it caps a cost. Closing more notebooks would have changed nothing. | Each of the twenty other live entries alone before a render leaves the link unchanged; `Default` alone replaces it (3098 → 3163). RSS grows 1 MB an entry (259 → 289 over 32) and resets per front end. |
| The finding is recorded as a warning at the entry rather than as a test. | What a future session can get wrong is *adding a renderer to the live group*, which no assertion over the current file would catch; the comment sits where that edit is made. | `Tests/FrontEnd.wlt`, the `Default` entry and the `ownFrontEnd` block. |
| A front-end death is measured as a **rate** over repetitions with a fresh front end each, never as one run. | S3's twenty single-shot controls named an entry that measures 0/6, and the real 4/5 sequence would have looked like a certainty from one observation either way; the whole T4 answer turns on the counts. | `Default` 0/6 against the hand-rolled three calls 4/5; the author sequence 0/5 with the PDF written 5/5. |
| The product defect gets its own Backlog item rather than a task here. | This item is about the suite's isolation, and the suite is already fixed; a repair to `ResetDocumentView` is a different deliverable with a different bite. | `Work/Backlog/ResetViewRender.md`. |

## Progress

- **S1** 2026-07-30 T1 — **not completed.** Spec reproduced on the first command (57/1,
  `BibliographyHeading`, `Import::nffil`); every front-end run after it hung rather than failed, so T1
  was unreachable and `Tests/FrontEnd.wlt` is untouched. Diagnosis and the `needs-human:` clearing
  question are in `## Hand-off`; the durable half — a wedged front end hangs where a dead one fails, and
  `TimeConstrained` cannot convert it — went to `CLAUDE.md` § *Build & test*, and it narrows T3.
- **S2** 2026-07-30 T1 — `$measured` is three associations, each measured in a front end of its own and
  torn down with `Developer`UninstallFrontEnd[]`; the permanently red `BibliographyHeading` (TestID
  `t0v83dcroxjjzb`) is green and the suite is **384/0**, up from 383/1. The task's own suggested fix was
  measured to be a no-op and the wedge S1 could not clear turned out to be one call away from it — both
  in [`CLAUDE.md` § *Build & test*](../../CLAUDE.md), which the two front-end bullets there now correct
  rather than repeat.
- **S3** 2026-07-30 T2 — neither: `"Default" -> viewMeasurements[ "Default.nb" ]` poisons the front end
  so the next whole-notebook `Export` kills it, and it is the only one of the 34 passing its stylesheet
  by name. Named at the entry in `Tests/FrontEnd.wlt` (comment only, no assertion changed); the
  measurement, the three probe faults that hid it and the wedge's second trigger are in
  [`CLAUDE.md` § *Build & test*](../../CLAUDE.md). Opened **T4** — a named-sheet document is what an
  author has, so this may be the palette's defect and not the suite's.
- **S4** 2026-07-30 T4 — the shape is the product's, the feared symptom is not, and S3's culprit is
  the wrong one: `SetDocumentFontSize` + `ResetDocumentView` + `NotebookClose` on a *named*-sheet
  document kills the next page render **4/5** (5/5 on a paclet sheet name) against 0/5 for six
  controls, while the author's own paper printed after either slider is **0/5** and the entry S3 named
  is 0/6. Split out as [Reset View Render](../Backlog/ResetViewRender.md). The session's larger find is
  the wedge: it is AppKit's crash-restore modal on a headless front end, cleared by one `defaults
  write`, which retires the reboot, the RSS heuristic and the `-code`/`-file` axis — all in
  [`CLAUDE.md` § *Build & test*](../../CLAUDE.md), whose two front-end bullets it corrects.
