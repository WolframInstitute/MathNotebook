# Import Display Defects

*[ LLM Generated ]*

> Type: defect
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Pavel imported the causal-graphs specimen (`Resources/Axiomatic_Relativity_from_Causal_Graphs/main.tex`,
the second specimen `Tests/Specimens.wlt` already pins) into `main.nb` and reported the import "not
fully successful", naming one defect concretely: the bibliography sits too far left, its labels clipped
at the window edge. Measured this session: the kernel round trip of that paper is **byte-exact** —
every defect below is a *display* defect, the class `CLAUDE.md` records as invisible to round-trip
fidelity and to the structure census both.

The census of the import is otherwise right: 169 cells, the ten `axiom`s styled `Theorem` with an
"Axiom" dingbat (designed), the two `constr`s on the `Construction` style (one of the twelve), 20
`Definition`s, 7 figures as `Caption` + `Input`, 14 `Reference` cells from the `.bib`.

### The defects, measured

1. **Bibliography alignment** (Pavel's screenshot). Every imported `Reference` cell carries its
   BibTeX key as a `CellDingbat` (`[einstein2013principle]`), and a dingbat draws to the *left* of the
   cell margin. Under `PlainArticle` the `Reference` style is in `$plainDeferred` — deferred whole to
   `Default.nb`, whose margin is far too small for a hanging label ~130 pt wide, so the key hangs off
   the window and the entry's body starts left of the prose around it. The base sheet's own
   `{{90, 10}, {3, 3}}` also clips keys this long; the fix has to pick a margin that clears a real
   BibTeX key, not just move the deferred style across. This is the same clipping argument that made
   the twelve environments carry `CellMargins` into `PlainArticle`.
2. **`\textbf`/`\emph`/`\textit` render literally in prose.** 22 cells of this paper display raw
   TeX like `the \textbf{light cone} at p`. `inlineContent` splits inline math and `\cite` only; a
   font command needs the same treatment — a styled run that displays bold/italic and exports back to
   the exact source. Reaches prose, environment bodies, captions and `.bib`-generated references alike,
   since all four go through `inlineContent`.
3. **Front matter displays raw.** The `Title` cell shows the literal `\vspace{-1.5cm}` prefix; the
   `Author` cell shows the raw authblk block — three brace groups *and* the `% Enter author(s) here`
   comment; a `\maketitle`/`\sloppy` Text cell and a `%\printbibliography` comment-only Text cell
   render as visible prose junk.

### Requirements

- **R1 (alignment).** `Reference` gets a left `CellMargins` in every sheet that clears a realistic
  hanging key (this paper's widest is `[kronheimer1967structure]`), screen and `"Printout"` both, with
  the continuation lines at the margin — LaTeX's own hanging-label layout. Verified by rendered ink
  (left ink edge of a Reference cell ≥ 0 and its body edge at the margin), not by style names. The
  four templates and `PlainArticle` all get whatever value survives measurement; `ComplexSystems`
  keeps its journal-measured 100/84 only if a long key survives there too, else it moves with reasons
  recorded.
- **R2 (font commands).** `\textbf{…}`, `\textit{…}`, `\emph{…}` become styled runs; the argument is
  matched brace-balanced (`$braceBody`, the `\title{\vspace{…}…}` lesson); nested commands recurse;
  the exporter writes the command back from the run so the round trip of both specimens stays
  byte-exact and `Tests/Specimens.wlt`'s counts stay where they are. The styled run must survive
  `Export`/`NotebookOpen`/`NotebookGet` (the ButtonBox-splitting reopen is the precedent to check).
- **R3 (front matter).** Decided with Pavel before implementation — the options trade editability
  for display:
  - Title: carry the `\vspace{…}` prefix in a tagging rule (the `FigurePrefix` shape) and display the
    text alone; editing the title still reaches the export.
  - Author: either display the raw block (status quo, editable) or store the block verbatim and
    display the names alone (the `.bib` precedent: pretty, but notebook edits stop reaching the
    `.tex`).
  - `\maketitle`/`\sloppy` and comment-only paragraphs: leave visible as now, or give them a
    dedicated dim/monospace style so they read as carried source rather than prose.
- Every fix lands in the paclet (`Document.wl` / `BuildStyleSheets.wls` + regenerated sheets), is
  bitten in a test before it is believed, and `main.nb` is re-imported at the end so Pavel sees the
  paper, not a patch.

### Open question this item can answer

Pavel's screenshot is the first sight of an imported paper on a real front end. Whether a
`Definition` cell in `main.nb` shows a bold "Definition 2.1.1." label answers `BasicFunctionality`'s
outstanding clause — whether by-name stylesheet resolution works in a real front end at all. If it
does not, the imported notebook is rendering under `Default.nb` and a sixth defect (the sheet itself)
goes ahead of everything above. Ask before T1.

### Out of scope

- `\textsc`, `\texttt`, `\underline`, sizes, colors — add commands only when a specimen shows them.
- The Complex Systems importer routing gap (recorded in `SubmissionBundle`).
- Anything about the seven `Input` figure cells — designed behaviour.

## Tasks

- [ ] **T2 — Inline font commands.** `\textbf`/`\textit`/`\emph` → styled runs in `inlineContent`,
  export clause in `inlinePartToTeX`'s family, byte-exact on both specimens, reopen-survival measured,
  tests in `Document.wlt` bitten before trusted.
- [ ] **T3 — Front matter display.** Settle R3's three decisions with Pavel, implement what he picks,
  tests accordingly.
- [ ] **T4 — Re-import and confirm.** Re-import `main.tex` over `main.nb` with the fixed paclet,
  Pavel reads the paper on screen; record his by-name stylesheet answer in `CLAUDE.md` and close
  `BasicFunctionality`'s outstanding clause if it resolves.

### Done

- [x] **T1 — Bibliography alignment** (Session 1). Measure a hanging `[key]` dingbat's geometry under
  the chain, pick the margin that clears the specimen's widest key, write it into `Reference` (screen +
  print) in `BuildStyleSheets.wls` for all sheets including `PlainArticle`'s carried-across set,
  regenerate, extend `Tests/StyleSheets.wlt`, verify by rendered ink on the causal-graphs bibliography.

## Progress

### Session 0 — 2026-07-28 — scoping

- **Prompt:** "I imported …/main.tex into …/main.nb and it was not fully successful. Can you check
  and improve the pipeline? Another task would be to modify the alignment of the literature because
  now it is too much to the left."
- **Did:** Ran the import headless against the working tree: byte-exact round trip, census right,
  zero messages — every defect is display-side. Traced the alignment defect to the `[key]`
  `CellDingbat` on `Reference` cells hanging left of a margin `PlainArticle` defers whole to
  `Default.nb`; found the literal `\textbf` family (22 cells), the raw authblk `Author` block, the
  literal `\vspace{-1.5cm}` in the `Title`, and the visible `\maketitle`/`\sloppy` and
  `%\printbibliography` cells. Wrote this item.
- **Learned:** `Construction` is one of the twelve environments, so `constr` maps to a style of its
  own while `axiom` correctly rides `Theorem` with an "Axiom" dingbat. The causal-graphs paper *is*
  the second specimen, so every fix here is already pinned by `Tests/Specimens.wlt`.
- **Next:** T1 after Pavel approves the Spec and answers the Definition-dingbat question.

### Session 1 — 2026-07-28 — T1

- **Prompt:** "yes" to the Spec and to starting T1; the Definition-dingbat question is still open.
- **Did:** Measured the failure and the fix, both in pixels. The front end anchors a `CellDingbat`
  wider than the cell's left margin at the window edge — clipped — and pushes the body right of the
  margin; reproduced the user's screenshot exactly from his `main.nb` cells under `PlainArticle`.
  The widest specimen key `[woodhous1973differentiable]` measures 173 pt at Palatino 13 (the widest
  template face), 146 pt at Default's Times 12, so `Reference` now reserves 185 pt in every sheet:
  base cell in `BuildStyleSheets.wls`, `ComplexSystems` overrides moved 100→185 screen and 84→125
  print (its journal-measured values fit the journal's numbered labels, not a key — deviation
  recorded in the script), and `PlainArticle` carries the geometry across via the new
  `$plainGeometry`/`geometryStyleCell`, the same exception the environments already are. The style's
  `ParagraphIndent -24` (hanging indent for hand-written entries) moves a dingbat with the first
  line, so `referenceDingbat` now writes `ParagraphIndent -> 0` beside the label — per-cell is right
  because "this cell hangs its own label" is true under every sheet — and `labelReferenceCells`
  excepts `ParagraphIndent` from the options it copies so relabelling cannot stack a second one.
  Regenerated all seven sheets. Tests: `StyleSheets.wlt` pins 185/-24 across base + five sheets and
  CS print 125, and drops `Reference` from the styles PlainArticle must not declare;
  `Referencing.wlt` pins the indent in every `labelReferenceCells` expected plus an idempotence
  test; `Document.wlt`'s pinned bibliography cells carry it; `FrontEnd.wlt` gains `ReferenceGutter`,
  which rasterizes the widest key at each sheet's *resolved* Reference face and asserts
  `100 < label < margin` — the invariant that breaks silently if a font or size outgrows the gutter.
  All three bites confirmed: the indent stub failed 4+1 tests, the old sheets failed 3, one stale
  template failed the gutter. Suite 270 → 274, green. Rendered the causal-graphs bibliography under
  the rebuilt `PlainArticle`: labels right-aligned to a common margin, brackets intact, bodies and
  wrapped lines flush at 185 — LaTeX's own hanging-label layout.
- **Learned:** A too-wide dingbat is not drawn at negative x: the front end anchors it at the window
  edge and pushes the body, so "clipped label" and "body off the prose margin" are one defect.
  `ParagraphIndent` moves the dingbat with the first line, so a margin sized for the label is eaten
  by a negative indent unless the labelled cell zeroes it. Rasterize at this machine's front end is
  1 px = 1 pt (calibrated against `ImageSize`), which is what makes the width-vs-margin invariant
  measurable at all.
- **Next:** T2 (inline font commands). The fix reaches Pavel's `main.nb` only through a rebuilt
  paclet — his installed 0.1.16 still carries the old sheets — so T4 must build and install before
  he looks.
