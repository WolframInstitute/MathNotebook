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

- [x] T1 — give the PDF-exporting measurements a front end of their own (a second `UsingFrontEnd`, or
      one `$measured` per front end), and prove it by the TestID going green on an idle machine.
- [ ] T2 — decide whether the 27 notebooks are a leak or a ceiling: close what is opened, and find
      whether the association survives to 34 entries once it does. `NotebookClose` appears 27 times
      already, so a naive count says they are closed and something still accumulates.
- [ ] T3 — make a dead front end fail loudly rather than as a content mismatch: a measurement that
      returns `$Failed` where a string was expected should abort the file with a named message, so this
      cannot be mistaken for an assertion about the paclet again.

## Hand-off

**T1 is done and the wedge is no longer a mystery — S1's `needs-human:` is discharged and both halves of
it turned out to be the same fact.** The reboot cleared the machine, and the cause is now a twenty-line
reproduction rather than a mood: `LinkClose` on `$FrontEnd` leaves the kernel unable to launch another
front end, and the next `UsingFrontEnd` hangs forever. See `CLAUDE.md` § *Build & test* for the durable
form. Nothing here needs a human before T2.

**What T2 inherits.** The suite is 384/0, so the file no longer has a failure to hide behind, but the
Spec's leak question is untouched: the rendering group still holds eleven measurements and every one of
them writes a whole notebook to disk. What T1 changed is only that a front end killed there cannot take
the other two groups with it. The measurement worth making first is per-entry — evaluating the 34
entries one at a time inside a single front end and reading `Length @ Notebooks[]` after each answered a
constant **1** throughout, which says the notebooks *are* being closed and that the accumulation, if
there is one, is inside the front end rather than in open documents.

**What T3 inherits, and its scope is still wrong as written but for a smaller reason now.** It asks that
a measurement returning `$Failed` where a string was expected abort the file with a named message. That
covers the *dead* front end. A *wedged* one returns nothing at all, and `TimeConstrained` cannot convert
it — a blocked MathLink read does not take an abort, measured at 120 s in S1. So the file still needs an
**external** wall-clock guard for that state; `perl -e 'alarm N; exec @ARGV'` is what this session used
throughout and it works (`timeout` is not installed on this machine, `gtimeout` and `perl` are the
options). The new fact that narrows it: the wedge now has a known trigger, so T3 can *assert* against it
rather than only report it.

**Two probe faults, both of which cost time here and neither of which is about the paclet.**
`TestReport[…]["TestsFailed"]` is not a property — it answers `Missing["KeyAbsent", …]` per test and
prints phantom failures even on a fully green run, which reads exactly like a broken reporter; the
working read is `Select[ Values @ report["TestResults"], #["Outcome"] =!= "Success" & ]`. And a killed
`wolframscript` leaves its `MathematicaServer` and `WolframKernel` children alive, contending for the
next run — `pkill -9 -f MathematicaServer` between attempts is what made this session's runs
reproducible where S1's were not.

## Decisions

| decision | rationale | evidence |
|---|---|---|
| Isolate with `Developer`UninstallFrontEnd[]` between groups, not with a second `UsingFrontEnd`. | A second `UsingFrontEnd` is a no-op — the task's own suggested fix. | Two sequential blocks report the identical `LinkObject[…, 106, 3]`; after the uninstall the link goes 109, 112, 115, each fresh and each answering. |
| Three groups — dialogs, live notebooks, page renderers — rather than one front end per entry. | The membership rule is checkable by reading one line of a helper ("does it `Export` the whole notebook"), where a per-entry split is 34 front-end launches for a file that measures in ~17 s. | Suite 384/0 with the split; the rendering group's eleven entries survive one front end. |
| `BibliographyHeading` is an ordinary member of its group, not pinned last. | Being last only decided which measurement discovered the corpse; a group of its own is what the ordering was standing in for. | The TestID is green with it mid-group, and red for the *right* reason under the bite. |

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
