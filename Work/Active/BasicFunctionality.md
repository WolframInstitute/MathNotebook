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

- [ ] **T2** — Guard the five selection-driven entry points against `InputNotebook[] === $Failed`, and give each a notebook-argument overload so it can be tested at all — the shape `LabelReferences` already has. `CopyCellReference`, `TagSelectedCell`, `InsertCitation`, `InsertEnvironment` (via `writeEnvironmentCell`) and the `Replace` guards that never fire. The two that prompt first must not consume the author's input before discarding it. Tests that bite by reintroducing the defect.
- [ ] **T3** — `GoBack[]` before any hyperlink has been followed: `$LastHyperlinkCell` has no value, so the call returns unevaluated with no message. Different cause from T2 (an unset symbol, not a `$Failed` notebook) and reachable *with* a document open, hence its own task.
- [ ] **T4** — Continue the shakedown into what T1 did not drive live: the three dialog-carrying buttons (`Import .tex file…`, `Export to .tex…`, `Export submission…`) driven with explicit paths, the stylesheet menu against all six shipped sheets, and the MaTeX conversions. T1 covered the referencing and view halves; this covers the conversion and submission halves.

### Done

- [x] **T1** — Catalogue: exercise every palette button's stored code against an installed paclet in a live front end. *Session 1.*

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
