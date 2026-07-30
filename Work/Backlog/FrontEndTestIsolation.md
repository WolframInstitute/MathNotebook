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

Nothing started. The reproduction is one command on a quiet machine —
`wolframscript -file run_tests.wls`, or `TestReport` on `FrontEnd.wlt` alone — and the probe that
isolated the three stages is worth rewriting rather than recovering, since its own liveness column was a
probe fault (`CurrentValue[ $FrontEnd, "Version" ]` is not a property and reads as not-alive
unconditionally, which is why the three stages appear to fail in its output while every real check in
them passed).

## Decisions

| decision | rationale | evidence |
|---|---|---|

## Progress
