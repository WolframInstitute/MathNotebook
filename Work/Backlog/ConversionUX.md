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

**Why per-cell LaTeX conversion exists at all.**
Pavel is right that the valuable operation is exporting the whole document.
That operation **does not exist**: the paclet exports no LaTeX, and `Math → TeX` on a selection is the only LaTeX-producing path there is.
So the button is doing duty for a missing feature rather than serving a purpose of its own.
Decide whether it survives as an author-facing button once whole-document export exists, becomes a developer aid, or is dropped.
Note `LaTeXPaperImport` (backlog) is the import direction and `CrossPlatformTeX` (backlog) touches the same area; whole-document export should be specced against both rather than bolted on here.

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

- [ ] T1 — Write down what each of the four conversions does and what an author actually wants, then settle the labelling and grouping with Pavel before touching code.
- [ ] T2 — Decide and implement the MaTeX display form (folded evaluated code cell vs graphics box), inline included, preserving the `"SourceTeX"` contract.
- [ ] T3 — Make a newly converted MaTeX cell honour the document's current math size.
- [ ] T4 — Resolve the fate of per-selection LaTeX conversion; spec whole-document export as a separate item if it survives that decision.
- [ ] T5 — Rewrite the tutorial's conversion section and add tests; Pavel confirms on a real document.

### Done

(completed tasks move here with the session that closed them)

## Progress

(no sessions yet)

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-26 | Filed as its own item rather than revised inside `PaletteUsability` T6 | the labelling is a palette-usability point but the MaTeX cell form and the fate of LaTeX conversion are design questions about the conversion subsystem, and both need Pavel's decision before any code changes |
