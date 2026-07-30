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

- [ ] T1 — give the PDF-exporting measurements a front end of their own (a second `UsingFrontEnd`, or
      one `$measured` per front end), and prove it by the TestID going green on an idle machine.
- [ ] T2 — decide whether the 27 notebooks are a leak or a ceiling: close what is opened, and find
      whether the association survives to 34 entries once it does. `NotebookClose` appears 27 times
      already, so a naive count says they are closed and something still accumulates.
- [ ] T3 — make a dead front end fail loudly rather than as a content mismatch: a measurement that
      returns `$Failed` where a string was expected should abort the file with a named message, so this
      cannot be mistaken for an assertion about the paclet again.

## Hand-off

**T1 is not started, and it is blocked on the machine rather than on the test file.** S1 reproduced the
Spec exactly on its first command — `FrontEnd.wlt` alone gave **57 passed, 1 failed**, the failure being
`BibliographyHeading` with `Import::nffil` on `/tmp/MathNotebookBibliographyHeading.pdf` followed by
`FrontEndObject::notavail`, which is the Spec's reading confirmed on a machine whose only other Wolfram
process was the Wolfram MCP server's own front end. **Every front-end run after that one hung instead of
failing**, eight attempts, and the machine never recovered — so T1's acceptance criterion (the TestID
going green on an idle machine) was unreachable and nothing was changed in `Tests/FrontEnd.wlt`.

`needs-human:` the wedge needs clearing before T1 can be attempted, and the two candidates left both
touch machine state that is not a session's to change — a reboot, or clearing
`~/Library/Wolfram/FrontEnd/15.0 Caches`. Confirm which, or confirm the suite runs again, and T1 is then
a normal session.

What the wedge **is**, measured, so the next session recognises it in one command rather than eight:

- It hangs at `UsingFrontEnd[ 1 + 1 ]` — the minimal case, no paclet loaded, nothing exported.
- **`TimeConstrained` does not break it.** A blocked MathLink read is not interruptible by an abort, so
  a 120 s constraint around the call never returned. This is the fact that bears on **T3**: see below.
- **Neither process is crashed; they are waiting on each other.** `sample` puts the front end's main
  thread in `NSApplicationMain` with every MathLink thread alive, while the driving kernel sits at
  ~0.2 s CPU indefinitely. A healthy-looking front end is not evidence of a working one.
- Ruled out, each by measurement: a second service front end on the machine (killed all, still hangs);
  stdin (`< /dev/null`, still hangs — this was the best hypothesis, since `noDocumentDialogs` reaches
  `InputString`); the script's directory (ran from `/tmp`, still hangs); a lock file or a stylesheet
  staged in `$UserBaseDirectory` (neither present, and the `StyleSheets/Wolfram` directory there is
  empty); leaked shared-memory segments (`ipcs -m` is empty); and `~/Library/Wolfram/Kernel/init.m`,
  which does `Needs["MaTeX`"]` at every kernel start but loads identically under both drivers.
- **One probe fault cost most of the session and is worth naming.** `wolframscript -code` answered a
  trivial `UsingFrontEnd[ 1 + 1 ]` several times *interleaved* with `-file` hangs, which made
  `-code` vs `-file` look like the axis for six measurements. It is not: the same `-code` driver hung on
  the real suite, and the trivial case hangs under `-file` too. The confound was trivial-vs-real
  payload, not the driver. Do not re-derive that split.
- `timeout` is **not installed** on this machine, so an external wall-clock guard needs `gtimeout`,
  `perl`, or a `sleep`-then-`kill` pattern.

**T3's scope is wrong as written, and this is the session's one substantive finding.** It asks that a
measurement returning `$Failed` where a string was expected abort the file with a named message — which
covers the *dead* front end that produces the current red test, and does not cover a *wedged* one, which
returns nothing at all and cannot be converted into a failure from inside the kernel. Whatever T1 does
about isolation, the file needs an **external** wall-clock timeout to make this state reportable; a
`TimeConstrained` wrapper would have looked like a fix and silently kept hanging.

## Decisions

| decision | rationale | evidence |
|---|---|---|

## Progress

- **S1** 2026-07-30 T1 — **not completed.** Spec reproduced on the first command (57/1,
  `BibliographyHeading`, `Import::nffil`); every front-end run after it hung rather than failed, so T1
  was unreachable and `Tests/FrontEnd.wlt` is untouched. Diagnosis and the `needs-human:` clearing
  question are in `## Hand-off`; the durable half — a wedged front end hangs where a dead one fails, and
  `TimeConstrained` cannot convert it — went to `CLAUDE.md` § *Build & test*, and it narrows T3.
