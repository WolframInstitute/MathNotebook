# Inline Math Converter Defects

*[ LLM Generated ]*

> Type: bugfix
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: measured, not reported — [LaTeX Paper Import](LaTeXPaperImport.md) T1, 2026-07-26, running today's pipeline over `Axiomatic_Relativity_from_Causal_Graphs.zip`.

Three defects in `Conversion.wl`, all reproduced on that paper and all reducible to one-line cases.
They are filed apart from the import work because they are wrong behaviour in a shipped, documented feature — `TeX → math` on an ordinary paper — rather than a missing importer.
They should be fixed before that item's T2, which builds on this layer.

**A comma makes the parser fail.**
`texToBoxes` answers `$Failed` for any fragment containing one: `"a, b"`, `"(a, b)"`, `"x_1, x_2"`, `"p,q\in M"`.
`"a; b"` and `"a \in B"` are fine, so it is the comma specifically.
A failing span is left in the cell as literal `$…$`, silently.
On the specimen paper this is every unconverted inline span — 35 of 238, 15% — and they are the ones a reader notices, since `$(V, E)$`-style tuples are what mathematics is written in.

**`equation*` is not recognised.**
As an entire cell it converts to nothing at all, while `equation` becomes `DisplayFormulaNumbered`.
The tutorial says the starred forms convert and stay unnumbered, so the documentation describes behaviour that does not exist.
Both display equations in the specimen paper are starred, so none of its display math converts.
`$$…$$` inside a paragraph splits out correctly, so the paragraph-splitting machinery is not the problem — the environment simply is not matched.

**WL's protected letters vanish.**
`texToBoxes["E"]` and `texToBoxes["I"]` return an empty box, because `E` is 2.718… and `I` is the imaginary unit.
The specimen paper writes `$E$` for its hyperedge set and it renders as a blank.
`V`, `D`, `N`, `C`, `K` are unaffected.
This one is invisible to a round-trip diff — the exporter reads the stored `"SourceTeX"`, not the boxes, so the cell exports perfectly while displaying nothing.

Done when all three convert correctly, each has a test, and the tutorial's claim about starred environments is either true or reworded.

### Requirements

- A comma-bearing fragment converts, and the sequence stays a sequence rather than becoming a single expression.
- `equation*`, and the starred forms of any other supported environment, convert to the unnumbered style; check `align*` while there.
- A single-letter span renders as that letter regardless of what the letter means to the kernel — including `E`, `I`, and anything else `Protected`.
- A test that asserts what a converted cell *displays*, not only that it exports back to the source. T1 established that round-trip fidelity hides display defects entirely.

### Edge cases & out of scope

- The comma fix must not change how `align`'s `&` alignment or `cases` behave.
- Out of scope: everything structural — sectioning, environments, references — which is the import item.

## Tasks

- [ ] T1 — Comma-bearing fragments; test with tuples, subscripted lists, and a comma inside `\{…\}`.
- [ ] T2 — Starred environments, `equation*` and `align*`; reconcile the tutorial sentence with whatever lands.
- [ ] T3 — Protected single letters; sweep the alphabet and assert every one displays itself.

### Done

(completed tasks move here with the session that closed them)

## Progress

(no sessions yet — the reproductions are in LaTeXPaperImport's Session 1)

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-26 | Filed apart from `LaTeXPaperImport` rather than as tasks inside it | these are defects in shipped `TeX → math` behaviour that anyone converting a paper hits today, independent of whether the importer is ever built; the import item depends on them but does not contain them |
