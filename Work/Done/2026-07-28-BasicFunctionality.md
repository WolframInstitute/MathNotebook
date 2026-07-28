# Basic Functionality Shakedown

*[ LLM Generated ]*

> Type: verification
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: Pavel, 2026-07-28, on finding every work item closed and the suite green — "Please close all existing work items or tell me what is necessary to do." then "We need to concentrate on tweeking the existing and making the basic functionality work."

Nothing was left to close: `Active/` and `Backlog/` were empty, all ten `Done/` items carried zero unchecked boxes, the tree was clean at 0.1.13, and all **258 tests passed**.
That is the problem this item exists to address.
A green suite and a shipped release are not evidence that the paclet works, because of what the suite structurally cannot reach.

**Why the tests can be green while basic functionality is broken.**
Eleven of the twelve `.wlt` files are kernel-only and stub their front-end reads; `Tests/FrontEnd.wlt` is the one exception and measures resolved style values, tag-resolved styles, ink areas and a MaTeX width — not user actions.
`Tests/Palette.wlt` asserts the palette **as text**: seven tests pinning labels, group headings and tooltips of the generated artifact.
No test in the repo has ever *clicked* anything.
And `CLAUDE.md` already records the exact failure mode that gap admits: a palette button's code is **stored verbatim** in the `.nb`, so a button referencing a symbol the front end's kernel does not have — a build-script helper, an undeclared cross-file `PackagePrivate` symbol — **silently does nothing**: no message, no failure, no dialog.
Both documented instances of that shape (`kernelButton["Import .tex file…", importDocument[]]`, and the `PackageScope` rule in *Conventions*) were found by reasoning, not by a test.
So the palette is the paclet's whole user interface and is verified only to *read* correctly.

The same reasoning extends past the palette.
The repo's own record names functional gaps that no test asserts as failures — a Complex Systems paper cannot route to its own template (`documentStyleSheet` reads the `\documentclass` alone, and such a paper is `\documentclass{article}`), an edited `.bib` entry in a notebook never reaches the `.tex`, `CopyCellReference` cannot share a `CounterBox`.
Each is recorded as a known property rather than as a defect, and none is a test.

**What this item does.**
Drive the real workflows end to end — a fresh install, the palette opened in a live front end, every button exercised, a paper imported and exported and bundled, a stylesheet swapped, the view controls moved — and catalogue every break and rough edge as it is found.
Findings become tasks, one fix per session, most-severe first.
The catalogue is the deliverable of T1 and the input to everything after it; the Tasks list below is therefore deliberately short, because what needs fixing is not yet known and guessing it is what this item refuses to do.

Done when every defect the shakedown finds is either fixed or recorded with a reason it was not, the suite has a test that bites for each fix, and Pavel confirms the core workflows on a real paper.

### Requirements

- Every palette button is verified to **do what its label says when clicked**, not merely to read correctly. A button whose stored code references a symbol that does not resolve in the front end's kernel is a defect even though it raises nothing.
- Verification runs against an **installed** paclet, not the working tree loaded by `PacletDirectoryLoad` — the install path is where the `FrontEnd/` extension and the stylesheet-by-name resolution differ, and `CLAUDE.md` records both directions of that having been read wrongly before.
- Each defect fixed gets a test that **bites**, confirmed by reintroducing the defect and watching it fail — never by watching it pass. `CLAUDE.md`'s three recorded probe faults and three silent-`perl` incidents all presented as "the test does not bite".
- No fix regresses the byte-exact round trip or the structure census on either specimen paper; both detectors run before a task closes.
- Findings that are design decisions rather than defects are surfaced to Pavel, not decided silently.

### Edge cases & out of scope

- Buttons carrying a `SystemDialogInput` cannot be driven headless; their code is verified by symbol resolution and by calling the wrapped operation directly with a path.
- MaTeX paths need `InstallMaTeX[]` to have run on the machine, and read their `pdfLaTeX`/`Ghostscript` paths from persistent config; absent those, measurements quietly read 0. Guard rather than assert.
- The two specimen papers are gitignored and may be absent; a shakedown step that needs one reports it and moves on, as `Tests/Specimens.wlt` does.
- Never stage a stylesheet into `$UserBaseDirectory/SystemFiles/FrontEnd/StyleSheets/` to make it resolve by name — `CLAUDE.md` records that wedging every subsequent front end launch on the machine.
- Out of scope: new features. This item only makes what exists work. A gap that needs new machinery is recorded and left for its own item.

## Tasks


### Done

- [x] **T1** — Catalogue: exercise every palette button's stored code against an installed paclet in a live front end. *Session 1.*
- [x] **T2** — Guard the five selection-driven entry points against `InputNotebook[] === $Failed` and give each a notebook-argument overload. *Session 2.*
- [x] **T3** — `GoBack[]` with no hyperlink followed, and with a stale one. *Session 3.*
- [x] **T5** — The same `$Failed` hole in the seven entry points T2 did not touch, and in the palette's own stored code. *Session 3.*
- [x] **T6** — The stylesheets' own `First[ SelectedCells[] ]`, which wrote the hyperlink record wrong at the source. *Session 3.*
- [x] **T7** — `GoBack` raises the notebook it returns to. *Session 3.*
- [x] **T4** — The conversion and submission halves driven live: import, export, bundle, the six-sheet menu, the MaTeX round trip. *Session 3.*

## Progress

### Session 1 — 2026-07-28 — T1

- **Prompt:** "Please close all exsiting work items or tell me what is necessary to do." / "We need to concentrate on tweeking the existing and making the basic functionality work." — the shakedown scope was chosen from three options offered.
- **Did:**

Nothing needed closing.
`Active/` and `Backlog/` were empty, all ten `Done/` items carried zero unchecked boxes, the tree was clean at `af18210`, and the full suite ran **258 passed, 0 failed**.
This item was written because that is the state in which Pavel reported basic functionality not working, so the suite is not the instrument that will find it.

Built and installed the working tree as **0.1.13** — the machine was carrying **0.1.11**, so any shakedown against the installed paclet would have measured a two-release-old artifact.

**The documented silent-no-op mode is absent from the palette.**
Read the installed palette as text (never as an expression — `Get`/`Import` re-evaluates it), undid the wrap and box escapes, and resolved every symbol its stored button code references: **20 of 20 `WolframInstitute`MathNotebook`` symbols resolve**.
Swept every lowercase-initial identifier in the file as a build-script-leak candidate and found only tooltip prose and UUIDs — no `kernelButton`, no `importDocument`, no `setter`.
So the failure `CLAUDE.md` warns about, a button calling a helper that exists only in `BuildPalette.wls`, is not present in 0.1.13.
The palette references 20 of the 23 public symbols; `LabelReferences`, `$MathNotebookCloudVersion` and `$LastHyperlinkCell` have no button, which is by design for the last two and worth a thought for the first.

**No test in the repo has ever called the referencing entry points, and now they have been called.**
Counted the occurrences: `Referencing.wlt` and `FrontEnd.wlt` between them exercise only the private helpers — `citationButton` (9), `labelReferenceCells` (5), `referenceDingbat`, `referenceButton`, `citationTargetStyle` — and **zero** of `InsertEnvironment`, `CopyCellReference`, `TagSelectedCell`, `InsertCitation`, `GoBack`, `LabelReferences`, `writeEnvironmentCell`.
That is six of the 23 public symbols, and it is the whole selection-driven layer the palette buttons hit.
Driven live for the first time, every one of them is **functionally correct**: `InsertEnvironment` landed `{Theorem, Lemma, Definition, Proof, DisplayFormulaNumbered}` with the Theorem counter resolving 1, 2, 3 and `Proof`/`DisplayFormulaNumbered` correctly not incrementing it; `CopyCellReference` put the `Dynamic` reference button on the clipboard; `TagSelectedCell` set `CellTags -> "Thm:key"`; `InsertCitation` wrote `RowBox[{"Theorem ", CounterBox["Section", "Thm:key"], ".", CounterBox["Theorem", "Thm:key"]}]`; `LabelReferences` gave the `Reference` cell the dingbat `[Sm09]`; `SetDocumentFontSize`/`ResetDocumentView` moved `Text` 13 → 20 → 13.

**The defect: with no document open, all five selection-driven entry points do nothing and say nothing.**
`InputNotebook[]` answers `$Failed` when there is no input notebook — a palette open with no document, which is an ordinary state and the state a new author is in.
Measured, each call then returns an **unevaluated expression with zero messages**:

| call | returns | messages |
|---|---|---|
| `CopyCellReference[]` | `SelectedCells[$Failed]` | 0 |
| `TagSelectedCell[]` | `SelectedCells[$Failed]` | 0 |
| `InsertCitation[]` | `NotebookWrite[$Failed, ButtonBox[…]]` | 0 |
| `InsertEnvironment["Theorem"]` | `SelectionMove[$Failed, All, CellContents]` | 0 |
| `GoBack[]` | `SelectionMove[$LastHyperlinkCell, All, Cell]` | 0 |

The `"Select a cell!"` dialog that `CopyCellReference` and `TagSelectedCell` were written to show **never fires**, and the reason is a pattern: `SelectedCells[$Failed]` stays unevaluated, so it matches neither `{ cell_, ___ }` nor `{ }`, and the `Replace` falls through and hands back its own argument.
The guard is written for "no cell selected" and there is none for "no notebook".
Two of them are worse than silent: `TagSelectedCell` and `InsertCitation` call `InputString` **first**, so the author is prompted for a tag, types it, and it is discarded with no indication.

- **Learned:**

`InputNotebook[]` is `$Failed` in a headless `UsingFrontEnd`, and `SetSelectedNotebook` does not change that — so the five entry points are not merely untested, they are **untestable as written**, which is why no test exists.
`LabelReferences` is the counter-example that shows the fix: it is the only one carrying a `[ notebook_NotebookObject ]` overload, and it is the only one that drove headless without help.
That is the repo's own stated convention — "pure cores … with thin `NotebookGet`/`NotebookPut` wrappers" — and `Referencing.wl` is where it was not followed.
To measure the rest, `Block[ { InputNotebook = ( nb & ) }, … ]` after `Unprotect` works and is the right probe until the overloads exist.

Two probe faults of my own, both the shapes `CLAUDE.md` already names.
`Cases[ NotebookGet[ nb ], Cell[ _, s_String, ___ ] :> s, Infinity ]` descends into the **embedded stylesheet** — `StyleDefinitions -> Get[ sheet ]` inlines it, so the walk reported 81 cells and the styles `{Title, DisplayFormulaEquationNumber}`, none of them the document's.
Restricting the levelspec to `{ 1, 2 }` then reported `{ }` for a notebook that demonstrably had six cells, because writing cells **groups** them into `CellGroupData` and pushes them below level 2 — the grouping trap, met here without a reopen.
Read styles off live cell objects instead: `First @ Flatten @ { CurrentValue[ #, CellStyle ] } & /@ Cells[ nb ]`.
Both faults read exactly like "`InsertEnvironment` is broken", and it is not.

- **Next:** T2 — guard the five entry points and give them notebook-argument overloads.

### Session 2 — 2026-07-28 — T2

- **Prompt:** `/next-session` — the first unchecked box, taken as written.
- **Did:**

One `PackageScope` guard in `Referencing.wl` and a notebook argument on each of the five.
`withInputNotebook` resolves `InputNotebook[]` once and answers `MessageDialog["Open a notebook first!"]` when there is none; the argumentless forms now do nothing else.
The overloads are `CopyCellReference[nb]`, `TagSelectedCell[nb]` and `[nb, tag]`, `InsertCitation[nb]` and `[nb, tag]`, `InsertEnvironment[nb, style]`, `LabelReferences[nb]` (which already had it) and `writeEnvironmentCell[nb, cell]`.
The two-argument forms are the ones that matter for testing: a notebook alone still reaches `InputString`, so it is the *tag* that makes those two drivable, and the prompting forms are now thin wrappers over them.
`InsertCitation` also stopped prompting before it resolves the notebook, which is the half of the defect that discarded the author's typing.
Usage strings updated for the four symbols that gained a form; the 22 reference pages still show the old ones and are left for a release task.

**Five tests in `Tests/FrontEnd.wlt`, and the bite check ran twice.**
A headless `UsingFrontEnd` has no input notebook, so it reproduces the reported state for free — the same fact that made these untestable is what makes the guard assertable, once the guard exists.
The dialog is read back by its own text rather than by the head of the return, because a *successful* call can also answer a `NotebookObject`.
Bite A, `withInputNotebook[ operation_ ] := operation[ InputNotebook[] ]`: **30 passed, 1 failed**, and driven directly the five answer `CopyCellReference[$Failed]`, `TagSelectedCell[$Failed]`, `InsertCitation[$Failed]`, `InsertEnvironment[$Failed, "Theorem"]`, `LabelReferences[$Failed]` with zero messages — the reported shape, restored on purpose.
Bite B, the whole pre-fix `Referencing.wl` from `HEAD`: **26 passed, 5 failed**, so all five new tests bite on the fix and 26 is the file's own previous count.
Restored from a scratchpad copy both times, never `git checkout --`.
Full suite green after the restore: **263 passed, 0 failed** (258 + 5), `Specimens.wlt` at 32 covering both the byte-exact round trip and the structure census.

**A finding, recorded as T5 rather than fixed.**
Seven more entry points carry the identical hole — `SetDocumentFontSize`, `SetMathFontSize`, `ResetDocumentView`, `ConvertLaTeXCells`, `ConvertMathCells`, `ConvertToMaTeX`, `ConvertFromMaTeX` — each handing `InputNotebook[]` straight into a `notebook_NotebookObject` overload or into `convertCells`.
So does the palette's own stored code: the stylesheet menu, the two view sliders and the two export buttons all write `InputNotebook[]` bare.
These were found by reading, not by driving, so T5 says to drive each first and confirm the no-op before touching it.

- **Learned:**

`MessageDialog` in a headless front end returns its `NotebookObject` **promptly** and does not block, so the text the author would see is readable — `FirstCase[ NotebookGet[ dialog ], s_String /; StringEndsQ[ s, "!" ], None, Infinity ]` — and the dialog can be closed before the next call.
Without closing it between calls the dialog itself would become the input notebook and the state under test would be gone; for the same reason the whole "no document" measurement has to be **first** in `FrontEnd.wlt`'s single `$measured` association, ahead of every measurement that opens a notebook.
`InputString` headless answers `$Failed` immediately with `InputString::ninit` rather than hanging, which is what made bite B safe to run against code whose first act is a prompt.

A citation's boxes read back off a live notebook are not the boxes that were written: the prefix `"Theorem "` came back as `RowBox[{"Theorem", " "}]`, so the assertion is on the `CounterBox` chain and not on the whole `RowBox` — the same family as the reopen splitting a `ButtonBox[RowBox[…]]` into one button per run.

Serena's `replace_content` in regex mode needs `needle`, not `pattern`, and a needle quoting `\[Placeholder]` did not match however it was escaped; splitting the edit so the named character falls *outside* the matched span is the way through, and it keeps the replacement free of backslashes too.

- **Next:** T3 — `GoBack[]` with no hyperlink followed, whose cause is the unset `$LastHyperlinkCell` and not a `$Failed` notebook.

### Session 3 — 2026-07-28 — T3

- **Prompt:** `/next-session` — the first unchecked box, taken as written.
- **Did:**

Drove `GoBack[]` against the **installed 0.1.13** before touching it, which is what turned one task into two states and a third that is not mine to fix.
Unset, it answers `SelectionMove[ $LastHyperlinkCell, All, Cell ]` with **zero messages** — T1's reading, now reproduced against the installed paclet rather than the tree.
Given a live cell it is correct: the selection leaves the last cell and lands on the recorded one.
Given a `CellObject` whose cell has been **deleted**, or whose notebook has been **closed**, `SelectionMove` answers `Null` and does nothing — silently, and a `cell_CellObject` pattern would have accepted it, so the guard needed a liveness test and not just a head.
`ParentNotebook` is that test: `$Failed` for a deleted cell, the notebook for a live one (`CurrentValue[ cell, CellStyle ]` answers `$Failed` too and would do as well).

The fix is one `Replace` in `Referencing.wl` with two dialogs, because the two states are two different things to tell an author: `"Follow a hyperlink first!"` and `"The cell that link was followed from is gone!"`.
`GoBack` needs no notebook argument — it reads a global, not `InputNotebook[]` — so unlike T2's five it was always drivable headless, and the reason no test existed was simply that nothing had been called.

**Two tests in `Tests/FrontEnd.wlt`, and the bite check ran twice in opposite directions.**
`goBackDrive[]` measures four states plus `ValueQ` of the symbol, and sits second in `$measured`, right after `"NoDocument"`; it records `ValueQ` so a kernel arriving with the symbol already set fails a test instead of passing the "Unset" one for the wrong reason.
Bite A, the original one-line body: **32 passed, 1 failed** — the guard test bites, the live-cell test correctly does not, since that half always worked.
Bite B, an over-broad guard (`GoBack[] := MessageDialog["Follow a hyperlink first!"]`): **31 passed, 2 failed** — so the second test bites too, on a fix that refuses instead of guarding.
Restored from a scratchpad copy both times.
Full suite green: **265 passed, 0 failed** (263 + 2), `Specimens.wlt` at 32 with the byte-exact round trip and the census intact.

**Two findings, recorded as T6 and T7 rather than fixed.**
The record of the last hyperlink is written wrong at the source: all six sheets assign `$LastHyperlinkCell = First[ SelectedCells[] ]` unguarded, so a click made with nothing selected stores an unevaluated `First[{}]`.
T3's guard now reports that honestly — it is the `"NonCell"` state in the test — but "Go back" still cannot go anywhere, and fixing it means `BuildStyleSheets.wls` plus a regeneration of six sheets, asserted as text because a click is not drivable.
And `GoBack` moves the selection without bringing the parent notebook forward, so a link followed into a new window leaves the selection changing out of sight; `SetSelectedNotebook @ ParentNotebook[ cell ]` is the whole fix and is left out deliberately, because it cannot be asserted here.

- **Learned:**

**Window focus has no headless measurement**, which is the constraint that kept T7 out of this session's diff.
`SetSelectedNotebook[nb]` leaves `SelectedNotebook[] === nb` **False**, the same way it leaves `InputNotebook[]` at `$Failed` — so "the right window came forward" is unassertable, and under this item's own bite rule anything depending on it would ship untested.

A deleted `CellObject` is a **live-looking** object: it still has the right head and prints the same, and every operation on it fails by doing nothing. `ParentNotebook` and `CurrentValue[ …, CellStyle ]` are the two reads that answer `$Failed` for it.

The `perl` note in `CLAUDE.md` generalises — the bite patch went in through a Python script asserting `count == 1` before writing and printing the replacement, which is the same discipline in a language where the quoting of Wolfram code with `$` and `[` in it is not at risk in the first place.

**Released and shipped in the same session, at Pavel's direction** — the shakedown's fixes were sitting in the tree while every installed and published copy still carried the defects.
0.1.14 is T2's and T3's guards (bumped, pushed, published, installed, and each guard driven from the *installed* paclet: `"Follow a hyperlink first!"` and `"Open a notebook first!"` ×3).
0.1.15 is the documentation, which Pavel then ruled on: **the reference pages ship inside the paclet and are deployed nowhere else**, so the browser mirror was deleted — 21 cloud notebooks, the HTML index, the directory, and the README link.
It had already drifted both ways, 21 pages against the paclet's 22 and every usage line one release stale, which is the argument for having one copy.
`Scripts/RegenerateUsage.wls` now rebuilds a page's Usage cell from the symbol's usage string, and with no arguments audits all 22 against `Kernel/Usage.wl`; that audit found a fifth stale page and one page **ahead** of the code — `ExportLaTeXBundle`'s page documents the options form its usage string never mentioned.
`GoBack`'s notes had also gone false with T3: they said the function does nothing before a link is followed.
All 22 now agree, all five edited pages open in a live front end with zero messages, and the suite is 265.

Not fixed, and not this item's: `LaTeX/Sample-SpringerJournal.pdf` does not exist while the README links a PDF for the other three samples, and a `MathNotebook/Staging` object from an old dry run is still on the cloud.

### Session 3, T5 — 2026-07-28

All seven confirmed before being touched, as the task required: with no document open each returned an unevaluated expression with **zero messages** — `SetDocumentFontSize[$Failed, 20]`, `ResetDocumentView[$Failed]`, `convertCells[…, $Failed]` four times.
One `withInputNotebook` each; `ConvertToMaTeX`'s guard answers *before* its `Needs["MaTeX`"]`, which is what makes it safe to drive on a machine without MaTeX.

**The palette was the other half and could not take the same fix.**
A button's code is stored verbatim, so it may hold only `System`` symbols and fully qualified public ones — never a `PackageScope` guard — so `BuildPalette.wls` writes the `Replace` out literally and it lands in the artifact **nine** times: once per stylesheet menu item including `Default`, and once in each export button, where it has to come *before* the dialog or an author with no document is asked where to save and the answer is discarded, which is the half of the referencing defect that wasted the author's typing.
The two view sliders needed the opposite fix: they passed `InputNotebook[]` explicitly, so `setter[nb, #]` reached the two-argument overload with `$Failed` and the kernel guard could never fire — they now call the argumentless form.

Tests: the no-document measurement is one association over all **twelve** entry points, so one that stops answering cannot hide behind the eleven that do; `Palette.wlt` counts the nine stored guards and asserts no bare two-argument setter survives.
Both bite — reverting the three kernel files fails `FrontEnd.wlt`, swapping the pre-change palette artifact back in fails `Palette.wlt` (**266 passed** restored).

- **Next:** T4 — the three dialog-carrying buttons driven with explicit paths, the stylesheet menu against all six sheets, and the MaTeX conversions. Note that T4's stylesheet half now has a live question waiting for it: driven headless against the installed 0.1.15, `FrontEnd`FileName[{"MathNotebook"}, sheet]` resolved to **Default.nb** (Title 45, not 26) for all three sheets tried, even after a menu reset — the fallback `CLAUDE.md` records for `wolframscript`, but it means the palette's own "Apply stylesheet" route is still unverified against an installed paclet.

### Session 3, T4 — 2026-07-28

Built and installed the working tree as **0.1.16** first, since T4's own requirement is that verification runs against an installed paclet and everything T3, T5, T6 and T7 fixed was still only in the tree.

Four of the five halves are **correct**, driven with the paths the dialogs would have supplied:

| driven | result |
|---|---|
| `Import .tex file…` | `Sample-AMSArticle.tex` → a 20-cell notebook, styles `Abstract, Text, Section, Definition, Theorem, DisplayFormulaNumbered, Proof, DisplayFormula` |
| `Export to .tex…` | written, and **byte-exact** against the source |
| `Export submission…` | `paper.tex` alone, which is right — the sample carries a `thebibliography`, so no `.bib` is declared and no BibTeX run is attempted |
| MaTeX buttons | render → one `GraphicsBox`, unrender → none |

The MaTeX round trip is now a test (`"Rendered"` / `"Unrendered"` in `maTeXMeasurements`), because the notebook overloads those two buttons call were driven by nothing: it bites with the unrender stubbed to `Null` (34/1).

**The fifth half cannot be verified here, and that is the finding.**
The palette's stylesheet menu sets the sheet **by name**, and by-name resolution gives Default's Title 45 where an embedded `Get` of the same file gives 26 — for all six sheets, before a reset, after `ResetMenusPacket` in the same session, and with the service front end killed and freshly launched.
`CLAUDE.md` carried a note that a cloud install plus a same-session reset *does* resolve; that does not reproduce for a paclet installed from a local archive, and the note is now amended rather than trusted.
`ImportLaTeXDocument` sets its sheet the same way — the imported notebook's `StyleDefinitions` reads back as exactly that `FrontEnd`FileName` — so the same doubt covers the importer's typography.
This is the one thing left for Pavel to confirm by clicking, and it is why the item's last Done clause is not mine to tick.

One probe fault of my own, the shape `CLAUDE.md` names: I read the bundle's result under a `"Written"` key it does not have (`"Directory"`, `"Files"`, `"Missing"`), so a correct bundle first reported writing nothing.

- **Next:** nothing in this item but Pavel's confirmation. See the closing note below.

### Closing — 2026-07-28

Seven tasks, six of them fixes, all seven closed.
Twelve entry points that did nothing and said nothing now answer; `GoBack` reports both of its empty states and raises the window it returns to; the stylesheets stopped writing an unevaluated `First[{}]` as the hyperlink record; the palette carries nine literal guards of its own because a button's stored code cannot call a `PackageScope` one; the reference pages agree with `Kernel/Usage.wl` and are generated from it; the documentation is deployed nowhere but inside the paclet.
The suite went **258 → 270**, every new test confirmed by reintroducing the defect and watching it fail, and `Specimens.wlt` held at 32 throughout — the byte-exact round trip and the structure census never moved.

**Closed with one clause outstanding, as `ConversionUX` was.**
The Done criterion asks that Pavel confirm the core workflows on a real paper, and two things in particular cannot be confirmed anywhere but a real front end:

- **Apply stylesheet** on an open paper, for one template and for `PlainArticle` — by-name resolution is unverifiable headless, and it is also how an imported paper gets its typography.
- **Go back** after following a reference into a new window — the raise has no headless measurement at all.

Both are named in `CLAUDE.md` so the next session cannot mistake them for verified.
