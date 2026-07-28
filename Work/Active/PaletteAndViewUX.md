# Palette and View UX

*[ LLM Generated ]*

> Type: feature
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Three things Pavel asked for during `ImportDisplayDefects` Session 3, none of which is an import
defect, so they are not that item's.
They are all about the surfaces an author touches while writing: the palette's referencing buttons,
the name of one of its groups, and the math font-size control.

### The requests, verbatim in substance

1. **The `Environments` group must not be called that.**
   He did not say what to call it instead, so the name is the one open decision here.
2. **`Tag Cell` goes; a Reference-entry button arrives.**
   His words: "We dont need Tag Cell. We need a button for adding reference cell ( like bibliographic
   reference). This will be referenced by Copy reference."
   So the palette should insert a `Reference` cell — a bibliography entry — and `Copy reference` is
   what then points at it.
3. **`Insert Reference` becomes a picker.**
   "InsertReference should have some dropdown or some automcompletion or whatever that lists equaiton
   reference, theorems, and literature reference."
   The three kinds are exactly the three the document already distinguishes: a `DisplayFormula`'s
   number, a theorem-like environment's number, and a literature key.
4. **Inline math must scale with the math font size.**
   `SetMathFontSize` moves the display and math styles and leaves inline math where it was.

### What is already known about each

- **Inline math has no style of its own.** An imported inline span is
  `Cell[BoxData[FormBox[…]], TaggingRules -> <|"MathNotebook" -> <|"SourceTeX" -> …|>|>]` — measured in
  Session 3's front-matter probe — with **no style name at all**, so it inherits the enclosing `Text`
  cell and no override written on a math style can reach it. That is the whole defect. The fix is
  either to give the island a style the control writes, or to have the control write the inline size
  too; which of those is right has to be decided against the fact that a style on the island must
  survive `Export`/`NotebookOpen`/`NotebookGet` (T2's measurement showed a `StyleBox` with list
  content does not, while a `Cell` island does).
- **`Citation` is not this item.** The face mismatch in Pavel's screenshot is
  `ImportDisplayDefects` T5.
- **A palette button's code is stored verbatim**, so everything a new button does must be written out
  literally in `System`` symbols plus fully qualified paclet ones — it cannot call a helper in
  `BuildPalette.wls`, and it cannot call a `PackageScope` symbol either.
- **`Tests/Palette.wlt` asserts the palette as text**, deriving the stylesheet menu from the
  stylesheet directory and pinning labels, group headings and tooltips. Renaming a group and adding or
  removing a button both land there.
- **`InputNotebook[]` is `$Failed` with no document open**, so any new entry point takes the notebook
  as an argument and goes through `withInputNotebook`, as the twelve existing ones now do.

### Requirements

- **R1 (group name).** One name, applied in `Scripts/BuildPalette.wls`, the palette regenerated, and
  `Tests/Palette.wlt` updated. Needs Pavel: he rejected `Environments` without naming a replacement.
- **R2 (Reference-entry button).** A button that inserts a `Reference` cell carrying a key, which
  `CopyCellReference`/`InsertCitation` can then target. `Tag Cell` is removed in the same change —
  including its entry point, if nothing else calls it.
- **R3 (Insert Reference picker).** `InsertCitation` gains a way to choose from what the document
  actually contains, grouped as equations / theorem-like environments / literature. The list is
  derived from the open notebook's cells, not typed.
- **R4 (inline math size).** `SetMathFontSize` reaches inline math, `ResetDocumentView` puts it back,
  and the claim is measured as rendered width or ink at two sizes — not as a resolved style option,
  since the island has no style to resolve.

### Out of scope

- The `Citation`/`Hyperlink` face (`ImportDisplayDefects` T5).
- Any change to what `SetDocumentFontSize` covers.
- Re-adding a content-width control: withdrawn in 0.1.8 at Pavel's call and not to be revived.

## Tasks

- [ ] **T1 — Rename the group.** Get the name from Pavel, apply it in `BuildPalette.wls`, regenerate
  the palette, update `Tests/Palette.wlt`. Blocked on him; everything else here is not.
- [ ] **T2 — Inline math scales with the math font size.** Decide island-style vs control-writes-inline
  by measurement, implement, and assert by rendered width at two sizes.
- [ ] **T3 — Reference-entry button, `Tag Cell` removed.**
- [ ] **T4 — `Insert Reference` becomes a picker** over the three reference kinds in the document.

## Progress

### Session 0 — 2026-07-29 — scoping

- **Prompt:** Four requests made mid-session during `ImportDisplayDefects` T3, with "please continue
  doing all work items without my supervision".
- **Did:** Wrote this item, keeping the citation-face request in `ImportDisplayDefects` as T5 because
  an imported cross-reference in the wrong face is an import display defect while these four are the
  author's own working surfaces.
- **Learned:** The inline-math cause was already in hand from T3's probe — an inline math island
  carries no style name, so it inherits the enclosing `Text` cell and no math-style override can
  reach it.
- **Next:** T2, which needs nothing from Pavel. T1 needs a name from him.
