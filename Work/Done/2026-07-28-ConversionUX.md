# Conversion and MaTeX UX

*[ LLM Generated ]*

> Type: refactor
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: Pavel, 2026-07-26, driving the palette in `PaletteUsability` T6's feedback round — "I have no idea what each of these is doing: Math → MaTeX, MaTeX → LaTeX, MaTeX → math etc. When converting to MaTeX it should produce the matex code cell that is folded and evaluated, or just graphics box. And for the inline thing it has to produce the graphics box or something like that. I also dont know why to convert to LaTeX in the notebook... it is relevant when exporting the entire thing right, why do we even have that."

The palette offers four conversion buttons across two groups and the author cannot tell them apart.
They are `TeX → math` (`ConvertLaTeXCells`), `Math → TeX` (`ConvertMathCells`), `Math → MaTeX` (`ConvertToMaTeX`) and `MaTeX → math` (`ConvertFromMaTeX`) — four labels built from three interchangeable words, two of which (`TeX`, `MaTeX`) differ by one letter.
The naming is only the surface problem.
Underneath there are two unresolved questions: what a MaTeX conversion should actually leave in the notebook, and whether per-selection LaTeX conversion belongs in a notebook at all.

**What the four buttons do today.**
`ConvertLaTeXCells` reads selected cells as LaTeX source and replaces them with typeset Wolfram boxes.
`ConvertMathCells` is its inverse: typeset boxes become a LaTeX string.
`ConvertToMaTeX` replaces the selection with a MaTeX-rendered *image*, storing the source TeX in `TaggingRules` under `"SourceTeX"`.
`ConvertFromMaTeX` recovers Wolfram boxes from that stored TeX.

**What a MaTeX conversion should leave behind.**
Pavel wants either a MaTeX *code* cell that is folded and already evaluated, or just the graphics box — and for inline mathematics, the graphics box.
Today it is always a bare image with the TeX hidden in tagging rules, which is invisible and not editable: to change the formula the author has to convert back, edit, and convert again.
A folded, evaluated code cell would make the TeX the editable source of truth and the image its output, which is how a notebook normally works.
Decide between the two forms — or offer both and say which is the default — and handle inline separately, since an inline cell has no code-cell affordance.

**Why per-cell LaTeX conversion exists at all — answered 2026-07-27, and the answer changed.**
The Spec said the valuable operation, exporting the whole document, **does not exist**.
It does now: `ExportLaTeXDocument` shipped in `LaTeXPaperImport` T2 and is an exported symbol in `PacletInfo.wl`, and by T12 both specimen papers and all four repo samples round-trip byte-identically through it.
So the original T4 — "decide whether the button survives *once whole-document export exists*, and spec that export as a separate item" — is answered on both halves: the export exists, and it needed no decision from this item.
What is left of the question is small and belongs with the labelling: `Math → TeX` on a selection is now a *convenience* beside a real export path rather than a stand-in for a missing one, and the palette should say which is which.

Done when an author who has never read the source can tell from the palette what each conversion does, a MaTeX conversion leaves the form Pavel asked for, the fate of per-selection LaTeX conversion is decided and recorded, and Pavel confirms on a real document.

### Requirements

- Each conversion is labelled so its direction and its result are unambiguous without the tutorial; four near-identical labels is the defect, so grouping or renaming must actually separate them.
- `ConvertToMaTeX` on a display cell produces either a folded, already-evaluated MaTeX code cell or a plain graphics box, per the decision taken.
- `ConvertToMaTeX` on inline mathematics produces a graphics box.
- A newly converted MaTeX cell honours the document's current math size. It does not today: `ConvertToMaTeX` renders at the hardcoded `$maTeXBaseFontSize` of 14 until the math slider is touched again, a rough edge left open by `PaletteUsability` T3.
- Round-tripping stays lossless — the stored `"SourceTeX"` contract that `SetMathFontSize`'s re-render depends on must survive whatever form is chosen.
- The tutorial section on conversion is rewritten to match.

### Edge cases & out of scope

- MaTeX is optional and may not be installed; every path needs to behave when it is absent.
- `writeCells` is shared across `Conversion.wl`, `MaTeX.wl` and `View.wl` and needs its `PackageScope` declaration intact — an undeclared cross-file helper silently does nothing in the `Package[]` format.
- A folded code cell changes what `rescaleMaTeXCells` has to walk; the re-render must not unfold or re-evaluate the whole document.
- Out of scope here: implementing whole-document LaTeX export. This item decides the *fate* of the per-selection buttons and specs the gap; the export itself is its own item alongside `LaTeXPaperImport` and `CrossPlatformTeX`.

## Tasks

**Trimmed 2026-07-27** from five tasks to two, in the backlog reduction. What survives is the defect Pavel actually reported — four labels he could not tell apart — and the one rough edge that is a bug rather than a design question. The MaTeX *display form* (T2 below, now dropped from scope) is a design decision needing Pavel at a notebook, not a session; it goes back on the pile if he still wants it after the labels are readable.

*Both tasks are done and the item is closed. See the closing note at the end of Progress for the one clause of the Spec's "done when" that was waived.*

### Dropped from scope 2026-07-27

- ~~Decide and implement the MaTeX display form (folded evaluated code cell vs graphics box), inline included.~~ Pavel's request, and still a fair one, but it is a design call that needs him driving a notebook; reopen it when that is what the session is for.
- ~~Resolve the fate of per-selection LaTeX conversion; spec whole-document export as a separate item.~~ Answered by `LaTeXPaperImport` — see the Spec above.

### Done

- [x] T1 — Settle the labelling and grouping of the conversions, give `ImportLaTeXDocument`/`ExportLaTeXDocument` a place on the palette, and rewrite the tutorial's conversion section (Session 2).
- [x] T2 — Make a newly converted MaTeX cell honour the document's current math size (Session 1).

## Progress

### Session 1 — 2026-07-27 — T2

- **Prompt:** `/next-session` with no item named; nothing was active, so the choice of item and task was put to Pavel, who took T2 over T1 (a design conversation) and over `JournalSubmission` T1.
- **Did:** `ConvertToMaTeX` now reads `maTeXFontSize[notebook]` — the same function `SetMathFontSize`'s re-render already used — instead of the fixed `$maTeXBaseFontSize`, on all three overloads (`InputNotebook[]`, a notebook, a selection, the last via `ParentNotebook @ First[cells]`).
  `toMaTeXCell` and `toMaTeXNotebook` are parameterised by the size to carry it in.
  The actual repair is structural rather than a changed literal: `toMaTeXCell` and `View.wl`'s `resizedMaTeXCell` were two independent constructions of the same cell that happened to differ on the size, and both now go through one `maTeXCell[tex, style, options, size]` in `MaTeX.wl`, so converting and re-rendering cannot drift apart on it again.
  `maTeXFontSize` gained a pure two-argument core `maTeXFontSize[parent, settings]` with the `NotebookObject` form as its wrapper, which is what lets the arithmetic be asserted kernel-only.
  Measured live on an `AMSArticle` document: converting an untouched one renders at 14 (image 15.1 pt wide) and converting one whose math control is at twice the anchor renders at 28 (26.9 pt) — and moving the slider before or after the conversion now lands on the same image.
  Four tests: three in `View.wlt` on the size arithmetic (base, scaled, and that the *prose* control does not reach it) and one in `Tests/FrontEnd.wlt` on the wiring, guarded on MaTeX, pdflatex and Ghostscript being present so a machine without them gets no tests here rather than failing ones.
  The bite check is a real one: reintroducing the hardcoded size takes `FrontEnd.wlt` from 26 to 25 passing.
  Suite green at 222.
- **Learned:**
  - **`Tests/FrontEnd.wlt`'s `notebookInk` was silently broken and the suite was red before this session started** — 24 passed / 1 failed on a clean tree, and the failing assertion was the T2 display-ink one from `InlineMathConverterDefects`, not anything of this item's.
    The cause is the dark-appearance trap `CLAUDE.md` already records, but the note has the failure mode backwards and it takes **both** options, not one.
    `Background -> White` alone forces white paper and leaves the prose drawn in the dark appearance's *light* foreground, so a `Text` cell measures exactly **0** ink and every comparison against it inverts — the whole-page-counts-as-ink failure the note describes is what happens when the background is *not* pinned.
    With `LightDark -> "Light"` beside it the numbers come back to exactly the ones the file has always claimed: 2440 for the paragraph, 1268 and 1368 for the two formulas.
    Fixed in `notebookInk` and `notebookImageInk`; suite is green again.
    The general lesson is that an ink measurement is only reproducible if it pins **both** ends of the contrast, and that a number of 0 should have been an assertion rather than a comparand.
  - The size a MaTeX cell should be rendered at is not a property of the cell, so it cannot be recovered from one — a conversion has to be told, which is why the fix is an argument threaded through `toMaTeXCell` rather than a lookup inside it.
    `ConvertToMaTeX[{cell, ...}]` gets it from `ParentNotebook @ First[cells]`, the only overload with no notebook of its own.
  - MaTeX renders fine in a bare `wolframscript` kernel — no front end needed — and reads its `pdfLaTeX`/`Ghostscript` paths from persistent config, so a test that has never run `InstallMaTeX[]` on that machine renders nothing at all and every ink or width measurement quietly reads 0.
    The guard therefore writes the same configuration `InstallMaTeX` does before measuring.
  - `Default.nb` resolves `DisplayFormula` to a numeric 14, screen and printout alike, so making `ConvertToMaTeX` depend on the chain-read anchor does not break a document that is not on a MathNotebook sheet.
- **Next:** T1 — settle the labelling and grouping of the four conversions with Pavel, and where `ExportLaTeXDocument` belongs in the palette. It is a design conversation, so it wants him at a notebook rather than a headless session.

### Session 2 — 2026-07-27 — T1

- **Prompt:** `/next-session` with no item named; `ConversionUX` was the single Active item and T1 its only open task.
- **Did:** Put the labelling and grouping to Pavel as three drawn layouts before touching anything; he took the one where **the group heading carries the direction and the button is named by its verb alone**, plus tooltips on every conversion and a file dialog inside each document button.
  Two conversion groups became three: `Whole paper (LaTeX)` with `Import .tex file…` and `Export to .tex…`, `Selection: LaTeX ⇄ math` with `Typeset` and `Show source`, `Selection: math ⇄ MaTeX` with `Render` and `Restore`.
  `MaTeX preferences` and `Install MaTeX` moved down to `Setup`, which is what they are, leaving the MaTeX group to hold only the conversion pair.
  Each of the six carries a sentence on hover, `Export to .tex…`'s saying in as many words that the selection buttons are a convenience beside it.
  Both document buttons get their path from a `SystemDialogInput` of their own — `FileOpen` from the current notebook's directory, `FileSave` defaulting to the notebook's name with `.tex` — so neither needed a new exported symbol and the kernel API is unchanged.
  Tutorial's conversion section rewritten to lead with the whole-paper route and name the new buttons; the MaTeX section and two Best Practices items renamed with it.
  New `Tests/Palette.wlt`, six tests, pinning the six labels, the three headings, the six tooltips, the absence of the four old labels, and the two dialogs.
  Bite check: dropping the `Tooltip` wrapper from `kernelButton` and rebuilding takes it from 6 passing to 4.
  Suite green at 228.
- **Learned:**
  - **The four labels were the reported defect but not the real one.** `ImportLaTeXDocument` and `ExportLaTeXDocument` have been exported symbols since `LaTeXPaperImport` T2 and had **no palette presence at all**, so the two per-selection buttons were the only LaTeX exit an author could see — which is exactly why Pavel asked "why do we even have that". The answer to his question was a missing button, not a better word.
  - **A palette button's code is stored verbatim and cannot call a helper from the build script.** `kernelButton` is `HoldRest`, so a `importDocument[]` written there lands in the `.nb` as an undefined call and the button silently does nothing — the `Package[]` cross-file trap in a second guise. The dialogs are therefore written out literally.
  - **A generated palette can be regression-tested as text**, which is the only safe way to read one back: undo the exporter's `\`-and-newline line wrapping and its `\<\"…\"\>` string escaping and the labels and tooltips match plainly. A named character in a label stays as its own escape, so the test spells `\\[Ellipsis]`.
  - `CLAUDE.md`'s warning that `MathNotebookTutorial.nb` carries hand edits the build script does not produce is **stale** — the file is back in sync, and a regeneration removed only the section being rewritten. Verified by filtering the diff for non-`ExpressionUUID` lines rather than by trusting the line count.
- **Next:** nothing to build. Pavel drives the new palette on a real paper; if it reads, the item closes, and the dropped MaTeX display-form question goes back on the pile only if he still wants it. One thing this session leaves stale for whoever releases next: the tutorial changed, so the cloud copy `Scripts/DeployPreviews.wls` publishes is now a version behind — the same trap that nearly shipped in 0.1.11.

### Closed — 2026-07-28

Closed at Pavel's call, with one clause of the Spec's "done when" waived: he has **not** driven the new palette on a real document. Everything else is met — the labels and headings separate the conversions, `ImportLaTeXDocument`/`ExportLaTeXDocument` are on the palette, the fate of the per-selection buttons is decided and recorded here and in the tutorial, and the MaTeX size bug is fixed. The MaTeX *display form* stays dropped.

What that waiver leaves at risk is only readability, and it is cheap to test: open a paper, look at the three conversion groups, hover a button. If the wording does not read, this is a labelling change in `Scripts/BuildPalette.wls` and its six assertions in `Tests/Palette.wlt` — reopen rather than patch the generated `.nb`.

One thing this item leaves for the next release: the tutorial changed, so the cloud copy `Scripts/DeployPreviews.wls` publishes is a version behind — the trap that nearly shipped in 0.1.11.

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-28 | Closed without the live confirmation the Spec asked for | Pavel's call. Nothing was left to build, and the only clause outstanding was his own reading of the new palette — which he can do at any time, and which reopens the item cheaply if the wording does not work |
| 2026-07-27 | The group heading carries the direction; each conversion button is named by its verb alone | Pavel's choice of three layouts put to him. Four labels built from three interchangeable words is the defect, and the shortest fix that removes the ambiguity entirely is to stop repeating the nouns on the buttons: `Typeset`, `Show source`, `Render`, `Restore` share no word with each other, and the heading above them says what they move between |
| 2026-07-27 | Every conversion button carries a hover tooltip | costs nothing in palette width and answers "what does this one do" where the question is actually asked, rather than in the tutorial |
| 2026-07-27 | `Import .tex file…` and `Export to .tex…` get their path from a dialog inside the button | the kernel functions take paths and the palette needed the whole-document route visible; a dialog in the button gives it one with no new exported symbol and no kernel API change |
| 2026-07-26 | Filed as its own item rather than revised inside `PaletteUsability` T6 | the labelling is a palette-usability point but the MaTeX cell form and the fate of LaTeX conversion are design questions about the conversion subsystem, and both need Pavel's decision before any code changes |
