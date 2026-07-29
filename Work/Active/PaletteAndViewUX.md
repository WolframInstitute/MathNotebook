# Palette and View UX

*[ LLM Generated ]*

> Type: feature
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Everything about the surfaces an author touches while writing: the palette's groups and buttons, the
referencing entry points, and the math font-size control. It began as three requests made during
`ImportDisplayDefects` Session 3 (T1 and T2, both closed) and was **re-scoped on 2026-07-29** when
Pavel reviewed the whole palette group by group and named what should change.

### The review, 2026-07-29

He read the palette back and asked for, verbatim in substance:

1. **A way to add a literature entry, in `Blocks`.** "In Blocks there should be something to add new
   reference literature right. Tagged cell with content."
2. **The bibliography orderable.** "It should automatically appear in the references the best sorted
   by usage — or there could be some function for that in the palette (different sorts) of the
   bibliography." Placed in `Referencing`, at his direction.
3. **`Tag cell` off the palette.** "There is an internal mechanism to do that and we do not want to do
   it from the palette."
4. **`Insert citation` becomes a chooser.** "Should become a combobox with tags of the literature cells
   or something like that." Settled as a **dialog** chooser, not a palette-level combobox.
5. **The groups reordered**, and `Import & Export` above `Setup` holding what was `Whole paper (LaTeX)`.
6. **The two conversion groups merged** into one `Selection`, with labels that stand without a heading.
7. **The per-selection LaTeX buttons dropped.** "Do not put latex right. There is the entire export of
   the document to latex right so why individual cells."
8. **A marker where the bibliography starts.** "There should be a special tagged cell where the
   references start. It is created after the first call of that reference add."

### The palette as decided

```
▾ Blocks              Insert environment ▾ / Proof / Equation / Equation (n) / Reference
▾ Referencing         Copy reference / Insert citation / ↑ Go back / Refresh labels /
                        Sort bibliography ▾
▾ Selection           math → MaTeX / MaTeX → math
▾ Document view       Apply stylesheet ▾ / Text size / Math size / Reset view
▾ Import & Export     Import .tex file… / Export to .tex… / Export submission…
▾ Setup               Install LaTeX fonts / Install MaTeX / MaTeX preferences /
                        Update from cloud / Tutorial
```

Six groups. `Tag cell`, `Typeset` and `Show source` come off; `TagSelectedCell`,
`ConvertLaTeXCells` and `ConvertMathCells` stay exported, documented and tested, so each is one line
in `BuildPalette.wls` to restore. `Stylesheet` merged into `Document view` on the LLM's call, taken
because applying a sheet already clears `{TaggingRules, "MathNotebook"}` and so **resets both
sliders** — the two are coupled in behaviour, not merely adjacent in theme. The heading `Selection`
is kept over `MaTeX` because the buttons already name MaTeX and what a heading must supply is the
scope: these act on selected cells where every group above acts on the document.

### What is already known

- **A palette button's code is stored verbatim**, so everything a new button does must be written out
  literally in `System`` symbols plus fully qualified public paclet ones — it cannot call a helper in
  `BuildPalette.wls`, and it cannot call a `PackageScope` symbol either.
- **`Tests/Palette.wlt` asserts the palette as text**, deriving the stylesheet menu from the
  stylesheet directory and pinning labels, group headings and tooltips. Every line of the layout
  above lands there.
- **`InputNotebook[]` is `$Failed` with no document open**, so any new entry point takes the notebook
  as an argument and goes through `withInputNotebook`, as the twelve existing ones do.
- **`Reference` is a real style in all seven sheets**, with a `[key]` dingbat driven off `CellTags`
  and a 185 pt left margin reserved for it; `tagCell` sets that dingbat, and `LabelReferences`
  rebuilds every one of them from tags. Nothing creates such a cell — that is R2.
- **The two bibliography routes differ over who owns the entries.** A `thebibliography` paper: the
  `\begin` rides on the **first** entry cell's `"EnvironmentOpen"`, each `\bibitem[label]{key}` in
  that cell's own slot, the `\end` on the **last** cell's `"EnvironmentClose"`. A `.bib` paper: the
  **last** `Reference` cell carries the `\bibliography{…}` commands verbatim and every earlier one
  carries `"Suppressed"`, which `notebookToLaTeX` filters out — and the `.bib`, not the notebook, is
  the source of truth.
- **A citation is `ButtonBox[…, BaseStyle -> "Citation", ButtonData -> tag]`**, so usage order is a
  scan of the cells in order for `ButtonData`.

### Requirements

- **R2 (Reference-entry button).** `InsertReference` writes a tagged `Reference` cell carrying the
  `[key]` dingbat, which `CopyCellReference`/`InsertCitation` can then target. It appends **after the
  last `Reference` cell**; with no bibliography in the notebook it writes at the **end of the
  document**, preceded by an anchor cell created **once** (R6). `Tag cell` comes off the palette in
  the same change.
- **R3 (citation chooser).** `InsertCitation` opens a dialog listing the tags the document actually
  carries, grouped **Literature** (tags on `Reference` cells) and **Blocks** (numbered environments,
  display formulas, sections), with a filter field and free text for a key not yet present. A
  palette-level combobox is **rejected**: the palette needs no kernel to display — the property the
  view sliders were built around — and a live tag list can only come from a kernel query on the
  focused notebook, so it would launch a kernel on every repaint and go stale between them.
- **R5 (bibliography sort).** `SortBibliography[nb, method]` reorders the block: `"FirstUse"` (order
  of first citation — BibTeX's `unsrt`, the default), `"Key"`, `"Entry"` (alphabetical on the printed
  text), and `"Uncited"`, which sorts nothing and **reports** entries nothing cites together with
  citations having no entry. It must re-attach the `thebibliography` delimiters to whatever ends up
  first and last, and keep a `.bib` paper's command-carrying cell **last**.
- **R6 (bibliography anchor).** A `Section`-styled cell reading `References`, created by the first
  `InsertReference` into a notebook that has none, carrying: `CounterIncrements -> {}` so it is
  **unnumbered**, matching the `\section*` that `thebibliography` prints — a plain `Section` would
  read "6 References" in the notebook where the PDF has no number; a `"Suppressed"` tagging rule so
  it emits **nothing** into the `.tex`, since `thebibliography` prints its own heading and without
  suppression the compiled paper carries it twice; and a `CellTags` that `SortBibliography` reads to
  find where the block starts. An imported paper already has `Reference` cells and gets no anchor.
- **R7 (palette reorganization).** The six groups above, in that order, with a tooltip on every
  button — `Blocks`, `Referencing` and `Setup` have none today.

### Out of scope

- The `Citation`/`Hyperlink` face (`ImportDisplayDefects` T5, closed).
- Any change to what `SetDocumentFontSize` covers.
- Re-adding a content-width control: withdrawn in 0.1.8 at Pavel's call and not to be revived.
- Auto-sorting on insert. Reordering cells as a side effect of adding one is right once and alarming
  every other time; insert appends, sorting is an explicit action.

## Tasks


### Done

- [x] **T7 — Documentation and release** (Session 8). Two reference pages, the tutorial brought
  back into line with the palette, 0.1.18 published.

- [x] **T6 — The palette reorganized** (Session 7). Six groups in Pavel's order, three buttons
  gone, three arrived, a tooltip on all 24 items, and `Tests/Palette.wlt` now asserting the group
  **order** and not only the names.

- [x] **T5 — `SortBibliography`** (Session 6). Four orders. Three parts of the block are
  **positional** — the `\begin`, the `\end` and each recorded separator — and only the `\bibitem`
  marker travels with its cell.

- [x] **T4 — `InsertCitation` becomes a chooser dialog** (Session 5). The tag list is a pure
  function of the `Notebook` expression, grouped Literature / Blocks; the filter field doubles as
  the free-text entry for a key the document does not carry yet.

- [x] **T3 — `InsertReference` and the bibliography anchor** (Session 4). Three cases, told apart by
  what the block's last cell carries. A pure core over the `Notebook` expression, because moving a
  `\end{thebibliography}` between cells is not something a selection can express.

- [x] **T1 — Rename the group** (Session 2). `Environments` → **`Blocks`**, Pavel's choice. Heading and
  fold-state key both, the palette regenerated. The rename was invisible to the whole suite, so
  `Tests/Palette.wlt` now pins the four group headings and asserts the old name **absent**.

- [x] **T2 — Inline math scales with the math font size** (Session 1). The island is styled
  `"InlineFormula"`, which resolves through the chain as `1.05*Inherited`; `SetMathFontSize` scales that
  **ratio** rather than writing an absolute size, so inline mathematics follows the slider *and* keeps
  tracking the cell it sits in. No stylesheet change was needed. Asserted on a rendered page.

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

### Session 1 — 2026-07-29 — T2

- **Prompt:** continuing unsupervised; "it would be great if the size of INLINE math content would also
  change with the change of math font size".
- **Did:** The cause was as scoped — an inline island had no style, so there was nothing for an
  override to be written on. The fix is smaller than expected and needed no stylesheet change at all:
  the island is styled `"InlineFormula"`, a style **no MathNotebook sheet declares** but which resolves
  through the chain from front-end resources as `1.05*Inherited`. That relativity turned out to be the
  design point rather than an obstacle. Measured: an island renders at 1649 ink in a `Title` cell
  against 420 in a `Text` cell, so inline mathematics tracks the cell it sits in — and an **absolute**
  override reaches the island but destroys that tracking, a `Title`'s inline mathematics *shrinking* to
  1577. So `SetMathFontSize` scales the **ratio** (`1.05 x size/anchor`, screen and `"Printout"`) rather
  than writing a size, and inline mathematics both follows the slider and keeps tracking its cell.
  `inlineMathCells` in `View.wl`, one line in `inlineMathCell` in `Conversion.wl`.
- **Learned:** The intended control for the rendered test — "prose does not move under a math-only
  call" — is **not available**, and asserting it was wrong: measured, prose goes 1186 → 1526 ink and
  `Text` 13 → 15. That is the embedded-parent trap `CLAUDE.md` already records, not the control
  leaking: the private sheet's parent is an embedded notebook, so every style it does not itself
  override falls through to `Default.nb`, whose `Text` is 15. It is now pinned *as the trap* so a later
  session does not read it as a bug, and the claim that isolates the math control is the two **ratios**
  — inline mathematics must grow by more than that document-wide perturbation, which needs no threshold.
  Also, `$inlineMathStyleName` had to become `PackageScope`: as a file-private symbol it stayed
  unresolved in the test and two assertions matched nothing, silently.
- **Next:** T1 still needs a group name from Pavel. T3 and T4 (the Reference-entry button and the
  picker) are untouched.

### Session 2 — 2026-07-29 — T1

- **Prompt:** "Instead Statements better something like Blocks or something like that."
- **Did:** `Environments` → `Blocks`, heading and fold-state key together, palette regenerated. Only
  the group was renamed: the `Insert environment` button keeps its label, because he named the group
  and the LaTeX word is the right one for what that menu inserts.
- **Learned:** The rename left the **entire suite green** — `Tests/Palette.wlt` pinned the three
  conversion headings (`Whole paper (LaTeX)` and the two `Selection:` ones) and none of the other four,
  so a group could be renamed, or lost, with no test noticing. It now pins all four and asserts
  `Environments` **absent** rather than only `Blocks` present, so a heading left behind somewhere else
  fails too. Suite 291 → 292.
- **Next:** T3 and T4 — the Reference-entry button and the `Insert Reference` picker. Nothing here is
  blocked on Pavel any more.

### Session 3 — 2026-07-29 — re-scoping

- **Prompt:** "Before we start working and finishing, can we go through what is on the palette? I want
  to review and modify" — then the eight decisions above, ending "make the work items and auto run
  them all".
- **Did:** Re-scoped this item from four requirements to seven and from two open tasks to five. Two
  new public symbols (`InsertReference`, `SortBibliography`) where the old T3/T4 implied one, an
  anchor cell nobody had thought of, and a whole-palette reorganization that was not in the item at
  all. No new item: this one is already `Palette and View UX`, and its T3/T4 were the same two
  buttons under narrower terms.
- **Learned:** Two decisions were taken against Pavel's first instinct and are recorded as decisions,
  not omissions — the citation chooser is a **dialog** rather than a palette combobox (the palette's
  no-kernel display property), and `Stylesheet` was **merged** into `Document view` (applying a sheet
  already resets both sliders). He dropped the two per-selection LaTeX buttons over the LLM's
  recommendation to keep `LaTeX → math` for the paste case; the functions stay exported, so it is one
  line to reverse.
- **Next:** T3, then T4, T5, T6, T7 in order — he asked for them run without stopping between.

### Session 4 — 2026-07-29 — T3

- **Prompt:** "Make the work items and auto run them all", continuing the re-scoping above.
- **Did:** `InsertReference` as the 24th public symbol, with the surgery as a pure core
  (`insertReferenceCells` in `Document.wl`) over the `Notebook` expression rather than
  `SelectionMove`/`NotebookWrite` — partly because moving a `\end{thebibliography}` from one cell to
  another is not a thing a selection can express, and partly because that is what makes any of it
  testable with no front end. Three cases: a notebook with **no** `Reference` cell gets the anchor
  heading plus a first entry carrying **both** delimiters; a `thebibliography` paper gets the entry
  appended with the `\end` **moved** onto it; a `.bib` paper's entry is suppressed, goes **before**
  the command-carrying last cell, and raises `InsertReference::bibfile` saying it will not reach the
  `.tex`. Positions are taken with `Position` at any depth, so an insert does not cost the document
  its `CellGroupData`. Suite 292 → 306.
- **Learned:** Two things worth keeping.
  - **`Position` at any depth is the right tool for cell surgery on a live document**, and the
    obvious alternative is worse than it looks: `notebookCellList` flattens, so editing a flattened
    list and putting it back would silently discard every `CellGroupData` the front end had built —
    a reopened notebook is *all* groups, so this would un-collapse the whole paper on every insert.
  - **The `cellTagging` trap fired again, in a test rather than in code.** It was file-private to
    `Document.wl`, so in `Referencing.wlt` — which puts only `PackageScope` on the `$ContextPath` —
    it resolved to a definition-less symbol and every `cellTagging[cell, key] =!= ""` was silently
    True. Three tests failed with the *right* shape and wrong values, which reads exactly like a
    converter bug. It is `PackageScope` now. The lesson is the one this repo already records from
    the other side: the same trap that makes a helper silently do nothing makes an assertion
    silently mean nothing.
  - The bite check was the delimiter move: not clearing `"EnvironmentClose"` off the old last cell
    fails two tests, one of them counting **two** `\end{thebibliography}` in the exported source.
- **Next:** T4, the citation chooser dialog.

### Session 5 — 2026-07-29 — T4

- **Prompt:** the same run.
- **Did:** `InsertCitation`'s `InputString` prompt is a chooser. `citationChoices` is a pure
  function of the `Notebook` expression — literature is what a `Reference` cell carries, everything
  else is a block, all of a cell's tags are citable rather than only the first, literature sorts
  alphabetically and blocks stay in document order — and only the panel around it needs a dialog.
  The filter field doubles as the free-text entry, so a key the document does not carry yet is
  offered as its own row rather than needing a second field. Suite 306 → 314.
- **Learned:** Three things.
  - **A bare `DialogReturn[tag_]` as `Cases`' pattern is EVALUATED before any matching**, and the
    call then answers `{ }` — five assertions passed nothing and read exactly like a chooser that
    builds no buttons. `HoldPattern` is the fix, and this is the same silent-empty failure as
    `Cases[opts, FontSize -> _]`, from a different direction: there the pattern is a `Rule` and is
    read as a replacement, here it is an ordinary head that simply has a value. Worth generalising
    in `CLAUDE.md`: **any** pattern argument whose head evaluates needs `HoldPattern`.
  - **"Offer this as a new key" must be conditioned on there being no matches, not on no exact
    tag.** `eq:` is nobody's tag and everybody's prefix, so the exact test offered to invent a key
    from a filter that was busily narrowing a real list. That is the bite check: it fails the
    heading test with a spurious `New key` group.
  - A dialog built at runtime **may** call `PackageScope` helpers from its `Dynamic`, unlike a
    palette button, whose code is stored verbatim in a `.nb` and re-read in a kernel that has none
    of them. So the filtering can live in the paclet instead of being written out inline.
- **Next:** T5, `SortBibliography`.

### Session 6 — 2026-07-29 — T5

- **Prompt:** the same run.
- **Did:** `SortBibliography` as the 25th public symbol, in four orders: `"FirstUse"` (BibTeX's
  `unsrt`, and the default), `"Key"`, `"Entry"`, and `"Uncited"`, which sorts nothing and answers
  the question a sort cannot. The reorder turns on one distinction — three parts of the block are
  **positional** and only one **travels**. Positional: the `\begin{thebibliography}` prefix, which
  belongs to whichever entry is first; the `\end`, which belongs to whichever is last; and each
  recorded `"Separator"`, which describes a gap at a place in the source rather than anything about
  the entry before it. Travelling: the cell's own `\bibitem` marker, text, tag and dingbat. A `.bib`
  paper is pinned at both ends — its last cell carries the `\bibliography` commands verbatim, so it
  stays last and the rest sort around it. Suite 314 → 323.
- **Learned:** Three things.
  - **The first entry's opening and its own `\bibitem` are one string**, because
    `environmentOpened` composes them rather than keeping two keys, so the sort has to tell them
    apart at the **last** `\bibitem` in it. That is the only place the two halves are separable.
  - **Counting the delimiters cannot detect a wrong split, and neither can the round trip.** The
    bite check left the opening travelling on its original cell: the exported source still holds
    exactly **one** `\begin` and **one** `\end`, both simply at the end of the list, so every
    count-based assertion passed and only the per-cell delimiter reading failed. A source-level
    assertion of the *order* of the delimiters was added for that reason — it is the cheap check
    that a later session will actually think to write.
  - **`referenceKey`, then `cellTagging` before it, then `$inlineMathStyleName` before that.** Three
    sessions running, a helper needed by a test was file-private and the assertion silently compared
    against an unevaluated expression. This is now predictable enough to be a rule: **anything a
    `.wlt` names must be `PackageScope`**, and the symptom is always a failure with the right shape
    and impossible values rather than a message.
- **Next:** T6, the palette itself.

### Session 7 — 2026-07-29 — T6

- **Prompt:** the same run.
- **Did:** `Blocks`, `Referencing`, `Selection`, `Document view`, `Import & Export`, `Setup` — six
  groups where there were eight. `Stylesheet` folded into `Document view`; the two conversion groups
  merged into `Selection`, having between them lost the LaTeX pair; `Tag cell` gone; `Reference`,
  `Refresh labels` and `Sort bibliography` arrived. `LabelReferences` had been exported since the
  first release and reachable from nothing — dropping `Tag cell` is what made it necessary, since
  the front end's own Cell Tags menu sets a tag and not the `[key]` label. A tooltip on all 24
  items, where seven had one. Suite 323 → 326.
- **Learned:** Three things.
  - **A group that moves is as invisible as a group that was renamed**, which is T1's finding one
    level up: the heading assertions T1 added would all have passed with the groups shuffled into
    any order, and the order is the whole of what Pavel asked for. `Tests/Palette.wlt` now asserts
    `Ordering` over the headings' first positions is `Range[6]`; the bite check swaps two groups,
    regenerates, and reads `{1, 2, 4, 3, 5, 6}`.
  - **"Gone from the palette" must not be allowed to become "gone from the paclet."** Three
    functions lost their buttons and stay public, so the test reads a usage string off each of
    `TagSelectedCell`, `ConvertLaTeXCells` and `ConvertMathCells` — otherwise a later session
    tidying up "unused" code has nothing telling it these are deliberate.
  - **A menu item can be guarded in the kernel instead of in the artifact.** The nine literal
    `"Open a notebook first!"` guards written into the `.nb` exist because a button's stored code
    cannot call `withInputNotebook`; T5's four sort orders add none, because `SortBibliography[
    method_String ]` is a one-string form the kernel guards. That is the cheaper shape, and the
    stylesheet menu is the one place it is not available — the items set an option rather than call
    a paclet symbol.
- **Next:** T7, documentation and release.

### Session 8 — 2026-07-29 — T7

- **Prompt:** the same run.
- **Did:** Usage strings for the two new symbols, both declared in `PacletInfo.wl`, two reference
  pages transformed from siblings (`InsertCitation` → `InsertReference`, `LabelReferences` →
  `SortBibliography`), the tutorial rewritten in eleven passages, 0.1.18.
- **Learned:** Four things, three of them costly.
  - **A blanket `s_String :> StringReplace[s, …]` over a reference page inserts UNEVALUATED calls
    into the examples section.** `ReplaceAll` puts its right-hand side in place unevaluated, and the
    `PrimaryExamplesSection` cell is an `InterpretationBox`, which is `HoldAllComplete` — so every
    string inside it came out as a literal `StringReplace["Basic", {"TagSelectedCell" -> …}]` in the
    written page, nested twice where two passes ran. It is the mirror of the `HoldPattern` trap from
    T4: there an argument evaluated when it should not have, here it did not when it should.
    Symbol renaming on a page is safest as **text** surgery on the file.
  - **A page's identifiers are line-wrapped, and a regex that misses that silently inherits them.**
    `ExpressionUUID->` is followed by a newline in most of these pages, so
    `ExpressionUUID->"[0-9a-f-]+"` matched only a minority and the new page shared **39** UUIDs with
    its template — precisely the failure the "regenerate every one" rule exists to prevent, arrived
    at while following that rule. The check that caught it counts UUIDs shared *across* pages.
  - **The 22 shipped pages already share one UUID between 21 of them**, a boilerplate cell, and that
    was the pre-existing duplicate count this measurement had to be read against. It is not a
    regression and is not fixed here.
  - **The tutorial is the thing that goes stale, because nothing tests it.** Eleven passages named
    buttons and group headings that T6 had changed — the whole "three palette groups convert"
    paragraph, both dropped conversion buttons in four places, `Tag cell`, and `Render`/`Restore`.
    `Tests/Palette.wlt` reads the palette and no test reads the tutorial, so this is `.wlt`-invisible
    exactly as `Scripts/RegenerateUsage.wls`'s audit found the reference pages to be.
- **Next:** the item's remaining clause is Pavel's — reading the palette on a real paper.
