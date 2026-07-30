# Bibliography Display

*[ LLM Generated ]*

> Type: defect
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Three defects found in the tail of `FirstReadingDefects` S6, while answering Pavel's report that the
entry labels were invisible in the deployed samples. That report was `Scripts/DeployPreviews.wls` and is
fixed; these three are the paclet's, they are all about how a bibliography *looks*, and each was
measured rather than inferred.

1. **`PlainArticle`'s `Reference` renders in a face belonging to no part of the document.** Measured
   Times 12 against prose of Source Sans Pro 15; `AMSArticle`'s is Palatino 13, exactly its prose. The
   base sheet declares `StyleData["Reference", StyleDefinitions -> StyleData["Text"]]` and the four
   templates keep that inheritance, but `PlainArticle` reaches `Reference` through
   `geometryStyleCell`, which emits a bare `StyleData["Reference"]` carrying only `CellMargins` and
   `ParagraphIndent` — so it falls through to **Default's own `Reference`**, which is nothing but a
   66 pt margin and resolves its typography from the front end's base. The sheet's rule is "Default's
   typography with the paper's structure added"; Default's *prose* is that typography, and Default's
   `Reference` is a style for something else.

2. **The bibliography anchor prints the previous section's number.** `CounterIncrements -> { }`
   suppresses the *increment*, not the *printing*: the sheets draw a section number from a
   `CellDingbat` holding a `CounterBox`, so the heading `InsertReference` writes reads **"3.
   References"** three sections into a document — measured under both sheets, and exactly the
   "6 References" that option's comment claims it prevents.

3. **An imported bibliography gets no heading at all.** `bibliographyAnchorCell` is written by
   `InsertReference` and by nothing else, so an imported paper's bibliography has no "References" above
   it in the notebook where the compiled paper has one from the environment. Both import routes are
   affected — the `.bib` one and the `thebibliography` one.

### Requirements

- Each fix verified the way its defect was found: resolved face and size for the sheet, a rendered page
  for the number, cell structure plus a rendered page for the heading.
- The round trip of both specimens and all four samples stays byte-exact. The anchor is a suppressed
  cell, so it reaches no exporter — but the specimen census **gains a cell and a `Section` in each
  paper that imports a bibliography**, and those counts must be **re-measured, never guessed**.
- Each fix lands with a test that bites.

### Out of scope

- `$bibliographyAnchorTag` is documented as "how the sort finds where the block begins" and
  `sortBibliographyCells` in fact finds the block by `Position[ cells, Cell[ _, "Reference", ___ ] ]`.
  The tag is a marker `citationChoices` drops and nothing reads. Noted, not touched.
- Whether the samples should show anything further than the two citations added in S6.

## Tasks

- [x] **T1 — The sheet.** (S1) `geometryStyleCell` carries the base cell's own `StyleData` head, so
  `PlainArticle`'s `Reference` inherits `Text` as every other sheet's does — asserted for all six as the
  resolved face against that sheet's own `Text`. It pulled the gutter with it: the key measures 190 at
  Source Sans Pro 15 against 173 at the widest template face, so the shared margin went 185 → **205**,
  keeping the same 15 pt clearance.
- [x] **T2 — The unnumbered heading.** (S1) The anchor carries `CellDingbat -> None` beside its
  `CounterIncrements -> { }` — it takes both, the sheets drawing the number from the dingbat. Asserted on
  a rendered page three sections in, the heading's presence and its numberlessness apart.
- [x] **T3 — The heading on import.** (S1) Both routes head their block through `headedBibliography`.
  Census re-measured: the causal paper's `Cells` 167 → 168, `Section` 8 → 9, `Tagged` 39 → 40.

## Hand-off

**STOPPED, uncommitted, because a second agent is editing the same files.** Confirmed by Pavel
2026-07-30 ~03:50. `MathNotebook/Kernel/Document.wl` carries **both** this item's three fixes and that
agent's in-progress `EnvironmentBlocks` work (`environmentWrapped`, `environmentRuns`,
`environmentSourceName`, +5 `PackageScope` declarations), and `Document.wlt`, `Referencing.wl`,
`Usage.wl`, `Palette.wlt`, `BuildPalette.wls`, `MathNotebook.nb` and `Images/Palette.png` are that
agent's alone. A `git add -A` here would commit its half-finished work under this item's message, so
nothing was committed. Resume only when the tree is quiet.

Snapshot of this item's own files: `/tmp/mine-bibdisplay/` (`BuildStyleSheets.wls`, `PlainArticle.nb`,
this file, and `Document.wl.MIXED.diff` — mixed, do not apply wholesale).

The three edits to re-apply to `Document.wl`, all in the bibliography section, none of them anywhere
near the other agent's:

1. `bibliographyAnchorCell[ ]` gains `CellDingbat -> None` beside its `CounterIncrements -> { }`.
2. `bibliographyCells[ entries, block ]` wraps its result in `headedBibliography @ …`.
3. `entryRules[ ]`'s RHS wraps `entryCells[ … ]` in `headedBibliography @ …`.
4. A new `headedBibliography[ cells_List ] := Prepend[ cells, bibliographyAnchorCell[ ] ]` after
   `$bibliographyAnchorTag`.

What was measured before stopping, and is trustworthy — each read off a run that predates the other
agent's edits:

- T1 is done and correct. `geometryStyleCell` now carries the base cell's own `StyleData` head, and
  only `PlainArticle.nb` really changed (one line; the other six sheets were reverted as `ExpressionUUID`
  churn). Resolved face went from Times 12 to the sheet's own `Text`.
- T2 is done and correct: the anchor cell now reads
  `Cell["References", "Section", CellTags -> "MathNotebookBibliography", CounterIncrements -> {},
  CellDingbat -> None, TaggingRules -> …]`, verified by evaluating it against the loaded working tree.
- T3 is done: an imported `thebibliography` now yields styles `{"Section", "Text", "Section",
  "Reference"}` — the second `Section` is the anchor.

The counts that must be re-pinned, measured but **worth re-measuring once the tree is quiet**, since
the run that produced them raced the other agent:

- `Tests/Specimens.wlt`, the causal paper: `Cells` 167 → **168**, `Styles["Section"]` 8 → **9**,
  `Tagged` 39 → **40**. hodgepaper does not move — it declares a `.bib` it ships without, so it imports
  no bibliography and gets no anchor.
- `Tests/Document.wlt`, four structure lists gain the anchor: the style/tag list gains
  `{"Section", "MathNotebookBibliography"}` at position 2, the dingbat list gains a leading `None`, and
  the separator list gains a leading `{"", ""}`.
- `Tests/FrontEnd.wlt`'s `ReferenceGutter` for `PlainArticle.nb` went **True → False**, and this one is
  a **finding, not a count to bump**: that clause asserts `100 < label < margin`, so the widest BibTeX
  key `[woodhous1973differentiable]` no longer fits the 185 pt gutter now that the entry is set in
  Source Sans Pro 15 instead of Times 12. T1 needs a companion decision — widen `PlainArticle`'s
  `Reference` margin to whatever that key measures, or accept a clipped key. Measure the key at the new
  face first; do not guess the margin.
- A fifth `Document.wlt` failure (`environmentSourceName` answering the style lowercased) is **the other
  agent's, not this item's** — measured at HEAD, where that function has a `PackageScope` declaration in
  its `.wlt` and no definition at all in `Document.wl`, so its tests were never reachable.

## Progress

### Session 1 — 2026-07-30 — T1, T2, T3

- **Prompt:** Pavel: "you need to correct the things you think are wrong", then "commit and push".
- **Did:** All three, each measured before and after. **T1**: `geometryStyleCell` emitted a bare
  `StyleData["Reference"]` and so dropped the base's `StyleDefinitions -> StyleData["Text"]`, sending
  `PlainArticle`'s entries to *Default's own* `Reference` — a style that is nothing but a 66 pt margin,
  resolving to **Times 12** against prose of **Source Sans Pro 15**. Carrying the base cell's own
  `StyleData` head fixes it, and only `PlainArticle.nb` really changed. It then pulled the gutter with
  it, which is the part that could not be guessed: `[woodhous1973differentiable]` measures **190** at
  the new face against 173 at Palatino 13, so the shared 185 no longer cleared the key and every
  sheet's `Reference` went to **205** — the same 15 pt of clearance. **T2**: the anchor's
  `CounterIncrements -> { }` suppresses the *increment* and not the *printing*, so the heading read
  "3. References" three sections in; it now carries `CellDingbat -> None` too, and a rendered page reads
  `1.ONEProseone.REFERENCES[smith]`. **T3**: `headedBibliography` heads both import routes, so an
  imported paper shows the heading its compiled PDF has; suppressed, so the round trip is untouched.
  Suite green: `Document.wlt` 101, `FrontEnd.wlt` 58, `Specimens.wlt` 32, `StyleSheets.wlt` 14. Each fix
  was watched failing its own assertion before the pin moved, which is the bite from the other side.
- **Learned:** Two environment facts, both in CLAUDE.md. A measurement that inserts a bibliography and
  exports a PDF has to be **last** in `FrontEnd.wlt`'s one `$measured` association — mid-association it
  left the service front end answering `$Failed` for everything after it, four tests failing on a dead
  front end rather than on what they assert, and six extra `CreateDocument`s were enough to do it alone.
  And the probe faults cost real time: `Cases[ list, _ /; f & ]` takes the `Function` as a condition,
  never matches, and reported **0 failures** for three files that had seven; and `pgrep -f name` inside a
  polling shell matches the polling shell itself, so every wait loop ran until its own timeout.
- **Note on the tree:** this session ran alongside a second agent working `EnvironmentBlocks` in the same
  files. Its work is complete and green beside this item's, but the two are interleaved in
  `Document.wl`, `Document.wlt` and `FrontEnd.wlt`, so they could not be split into separate commits.
