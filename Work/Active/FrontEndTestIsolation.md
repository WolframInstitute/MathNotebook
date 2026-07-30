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
- [ ] T4 — find whether the `Default` poison is the *product's* and not the suite's. A named
      stylesheet parent under `SetDocumentFontSize` + `ResetDocumentView` is what an author's own paper
      is; the other 33 entries embed their sheet with `Get` and none of them poisons anything. Narrow
      it to the call (open/close alone, the size call, the reset, the chain read), and if a real
      document reproduces it, the palette's font slider crashes the front end on the next print.

### Done

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

**T4 is what this session found rather than what it set out to do, and it is the one that might not be
about the suite at all.** Every entry but `Default` embeds its sheet with `Get`; `Default` passes a name,
which is what a real document has. If `SetDocumentFontSize` + `ResetDocumentView` on a named-sheet
document is what poisons the front end, the palette's font slider crashes the front end on the author's
next print and the suite was merely the first place it showed. **Unmeasured** — the narrowing probe was
written and never ran, because the machine wedged first (below). Take it before T3: T3 is a reporting
improvement, T4 is possibly a shipping defect.

**What T3 inherits is unchanged from S2, and one thing is now cheaper.** A *dead* front end is what T3
was written for; a *wedged* one returns nothing at all and `TimeConstrained` cannot convert it (a blocked
MathLink read does not take an abort, 120 s in S1), so an **external** wall-clock guard is still needed —
`perl -e 'alarm N; exec @ARGV'` works and is what S2 and S3 both used (`timeout` is not installed on this
machine; `gtimeout` and `perl` are the options). What is cheaper: a wedged front end is now identifiable
**from `ps` alone**, sitting at 94–99 MB of RSS where a working one reaches ~260 MB, so the guard has
something to report rather than only a timeout.

**The machine is wedged as of the end of S3, and the trigger is now known: `pkill -9` of a front end that
a *running* script still holds.** That is this file's own hygiene applied one step too early — between
attempts it is what makes runs reproducible, during one it is the wedge. It did not clear by killing the
orphan and waiting, three times, and S1's record says a reboot cleared it. **A fresh session should
expect to clear the machine before its first front-end run**, and should confirm with a trivial
`UsingFrontEnd[ 1 + 1 ]` under `-file` before attributing anything to the paclet. Nothing here needs a
human decision — only a working machine.

**The S2 probe fault still applies, and S3 added three of its own.**
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
