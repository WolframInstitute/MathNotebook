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
- **R3 (front matter).** Decided by Pavel in Session 3, each option traded editability for display
  and he took display every time:
  - Title: the `\vspace{…}` prefix goes in a tagging rule and the cell displays the text alone.
    Editing the title still reaches the export, because the prefix is a *prefix* and not the whole
    argument.
  - Author: the block is stored verbatim and the cell displays the names alone. This is the `.bib`
    trade and it is accepted — an author edited in the notebook does **not** reach the `.tex`, which
    is pinned by a test asserting the negative so a later session cannot mistake it for a bug.
  - `\maketitle`/`\sloppy`/`\tableofcontents` and comment-only paragraphs: **no cell at all**, carried
    verbatim on the neighbouring cell. Chosen over a dim/monospace style; they are invisible and
    uneditable in the notebook.
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

## Hand-off

Closed 2026-07-29: Pavel read `main.nb` and reported six defects, which are
`Work/Active/FirstReadingDefects.md`. Nothing else remains here.

The four extra requests he made in Session 3 are all closed: the citation face became T5 here (and the
answer was that the stylesheets were never at fault), and the other three were palette and view work,
which is `Work/Active/PaletteAndViewUX.md` — the group is now **`Blocks`** at his choice, and inline
mathematics follows the math slider. What is left there is the Reference-entry button and the
`Insert Reference` picker, neither started, neither blocked on him.

**0.1.17 is installed** (Session 5) and is the only installed version, so what he opens now really does
carry T1, T2, T3, T5 and the inline-math control. `main.nb` was re-imported through the installed
paclet, not the working tree. The previous file is kept beside it as `main-before-0.1.17.nb`.

The one question for him, answerable by looking: does a `Definition` cell show a bold
`Definition 2.1.1.` label? `main.nb` asks for `PlainArticle.nb` **by name**, which is the resolution
path this repo cannot verify headless, so a *plain* label means the notebook fell back to `Default.nb`
and `BasicFunctionality`'s outstanding clause is a real defect rather than a measurement gap.

## Tasks

### Done

- [x] **T4 (the reading half) — Pavel read `main.nb` on screen** (Session 6, 2026-07-29). The
  reading happened and its output is a six-point defect report — `\varnothing` rendering blank,
  literal `\&`, math scaling incoherence, `CopyCellReference` reading `Theorem 0.0` for an Axiom,
  a freeze around `LabelReferences`, and compound `\cite` buttons that navigate nowhere — now
  triaged and tracked as `Work/Active/FirstReadingDefects.md`. The Definition-dingbat question
  stays **unanswered**: an imported paper's dingbats are written per-cell by the importer, so a
  bold label here would not have exercised by-name stylesheet resolution anyway — that clause
  remains `BasicFunctionality`'s, answerable only by applying a sheet from the palette menu.

- [x] **T5 — The reference's face, which was not the stylesheets** (Session 4). The hypothesis in this
  task as written — that `Citation` inherits `Link`'s Times 12 and needs pinning to each sheet's face —
  is **false**, and was disproved before any sheet was touched. A `Citation` run inside a `Text` cell
  already renders in the cell's own face. What is real: `InsertCitation` at a cell-bracket selection
  destroyed the cell's content and produced a `BoxData` cell, which renders in the box face. One bug,
  both symptoms; fixed in `citationInsertionPoint`.
- [x] **T3 — Front matter display** (Session 3). All three R3 decisions taken by Pavel and
  implemented: the title's `\vspace` prefix in `"CommandPrefix"`, the `\author` block verbatim in
  `"CommandTeX"` with the names displayed, and `\maketitle`/`\sloppy`/`\tableofcontents`/comment-only
  paragraphs carried as whitespace with no cell at all. Byte-exact on both specimens and all four
  samples; census updated; three bites confirmed.

- [x] **T2 — Inline font commands** (Session 2). `\textbf`/`\textit`/`\emph` → styled runs split
  before inline math, plain args as native `StyleBox`, rich args as inline `Cell` islands (the shape
  a save preserves — measured), `"TextItalic"` style name distinguishing `\textit`; export rebuilt
  from the run in `inlinePartToTeX`/`fontTeX`. Byte-exact on both specimens and all four samples;
  reopen survival pinned in `FrontEnd.wlt`; three bites confirmed.
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

### Session 2 — 2026-07-29 — T2

- **Prompt:** `/next-session ImportDisplayDefects`.
- **Did:** The three font commands now convert to styled runs, and the representation was chosen by
  measurement rather than taste. Surveyed first: causal-graphs carries 26 `\textbf` + 3 `\emph`, all
  plain strings; hodgepaper 162 `\emph` + 3 `\textit`, many holding inline math
  (`\emph{IBL$_\infty$ structure}`, `\emph{$\mathrm{A}_\infty$-homotopy transfer}` opens with math);
  no nesting, no cites inside args, and — checked by extracting every `$…$` span — no font command
  inside genuine math, so the split can safely run *before* `splitInlineMath`, which it must, or a
  math-holding argument is broken across parts before the command can be seen. Reopen measurement
  (Export/NotebookOpen/NotebookGet) decided the shapes: a `StyleBox` with a plain string survives, a
  style *name* on it survives, but a `StyleBox` with **list** content is split into one run per part
  with the math cell escaping the style and dropping it — the ButtonBox-splitting defect's sibling —
  while an inline `Cell[TextData[…]]` island returns byte-identical. So: `fontSplit`/`fontBox` in
  `Document.wl` (plain arg → `StyleBox`, rich arg → `Cell` island, `\textit` marked `"TextItalic"`,
  empty arg left literal), argument recursing through the full inline pipeline (`inlineParts`, which
  `inlineContent` now fronts); export clauses in `inlinePartToTeX`'s family + `fontTeX` in
  `Conversion.wl`, the command rebuilt from the run so an author's edit — or a hand-styled run, bare
  italic reading as `\emph` — reaches the `.tex`. Both specimens and all four samples round-trip
  byte-exact; zero literal font commands left in any prose cell. Tests: 4 new in `Document.wlt`
  (StyleBox census, both island shapes + literal `\emph{}`, round trip, hand-styled export), the
  pinned caption test updated to expect the styled run, and a `FontRuns` save-survival measurement
  in `FrontEnd.wlt` beside the ButtonBox one. Three bites confirmed: import stubbed → 3 failures;
  `fontTeX` forced to `\emph` → 5 round-trip failures; rich runs as `StyleBox[list]` → the
  `FrontEnd.wlt` test alone catches it (`Islands -> 0, Exported -> False`) — the kernel round trip
  does *not*, which is why the save test exists. Suite 274 → 279, green.
- **Learned:** The probe trap struck again before the work started: `latexToNotebook` is reachable
  as `` WolframInstitute`MathNotebook`PackageScope`latexToNotebook `` but `bibliographyEntries` is
  file-private, so the first probe silently returned its own input — use the exported
  `ImportLaTeXDocument`. The dingbat cells the sheets write are themselves
  `Cell[TextData[…], FontWeight -> "Bold"]`, so any census of styled runs must count cell *content*,
  not cells at `Infinity`, or every theorem label reads as a bold run (32 phantoms on the
  causal-graphs paper).
- **Next:** T3 needs Pavel's three R3 decisions before any code; T4 rebuilds and installs the paclet
  (his 0.1.16 predates both T1 and T2) and re-imports `main.tex`, and should record his answer to
  the Definition-dingbat/by-name-stylesheet question.

### Session 3 — 2026-07-29 — T3

- **Prompt:** `/next-session`, then Pavel's three R3 answers, then four further requests and "please
  continue doing all work items without my supervision".
- **Did:** Probed both specimens' front matter first so the three decisions were asked with real
  options on the table, and he took the pretty end of each trade. The title carries its
  `\vspace{-1.5cm}` in a `"CommandPrefix"` tagging rule and displays its text; the `\author` block —
  a comment and three brace groups, the paper's second line — rides verbatim in `"CommandTeX"` and
  the cell shows `Carlos Zapata-Carratala, Pavel Hajek, Nicolay Murzin`; `\maketitle`, `\sloppy`,
  `\tableofcontents` and comment-only paragraphs produce **no cell**. The third of those is the one
  worth recording as design: a vanished paragraph becomes a `separatorMark` carrying its own source,
  which lands in the preceding cell's `"Separator"` — a rule that already holds arbitrary source — so
  it needed **no export clause at all** and the export stayed a plain `StringJoin`. Only content-free
  commands are listed, which is why `\printbibliography` is absent despite the specimen carrying one.
  Both specimens and all four samples round-trip byte for byte. The census moved and was re-measured
  rather than guessed: causal graphs 169 → 167 cells, hodgepaper 378 → 368 with its literal counts
  falling too (29 references → 26, 6 `\item`s → 4) because commented-out draft paragraphs are no
  longer shown. Suite 279 → 286, green.
- **Learned:** Two findings beyond the mechanism. `environmentPieces` already handles the case that
  would have lost source — a carried paragraph *ending* an environment body would be the cell holding
  the `\end{…}`, and it folds trailing marks into the closing delimiter instead; both specimens
  round-trip byte-exact whether or not that works, so it is asserted on a synthetic body in
  `Document.wlt`. And the second bite showed the census's blind spot from a new direction: disabling
  the Author clause left `Specimens.wlt` **fully green** while `Document.wlt` failed three, because a
  change to what a cell *contains* moves no count. The `FrontEnd.wlt` `\maketitle` clause inverted
  from 1 to 0 and is now the only assertion that a carried paragraph is really invisible — a cell
  count says a cell is gone, only a rendered page says nothing was drawn in its place.
- **Next:** T5 (citation face), then `PaletteAndViewUX`, then T4 last.

### Session 4 — 2026-07-29 — T5

- **Prompt:** continuing unsupervised from Session 3's instruction; the input was Pavel's screenshot,
  "the fonts are different. They should not".
- **Did:** Measured before changing anything, and the task's own hypothesis did not survive it. The
  chain read says `Citation` resolves to Times 12 in every one of the seven sheets against prose of
  Palatino 13, Latin Modern 13, Times New Roman 13, Times 14 and Source Sans Pro 15 — which looks
  exactly like the reported defect. It is not: rendered, a `Citation` run inside a `Text` cell under
  `AMSArticle` measures **406 ink at height 15** where plain prose is 409/15 and a deliberate Times 12
  run is 365/12. So the run already takes the cell's face, and
  `CurrentValue[{StyleDefinitions, "Citation", FontFamily}]` is the chain's abstract resolution rather
  than what happens inside a cell. The sheets were left alone. What actually reproduces the screenshot
  is `Cell[BoxData[button], "Text"]` — **482 ink at height 17**, 113 px wide because it does not wrap —
  and that is what `InsertCitation` produced when a cell was selected by its bracket, *replacing the
  cell's content in the process*. So the wrong font and a silent data loss were one bug.
  `citationInsertionPoint` now moves the insertion point inside the cell's contents when a whole cell
  is selected, and makes an empty `Text` cell when there is no cell to insert into at all.
- **Learned:** Two things worth keeping. A resolved-style read cannot answer "what face does this run
  render in" — the character styles resolve one way through the chain and another inside a cell, which
  is the same trap as reading a print size off the bare style path, and it would have sent this session
  to rewrite seven stylesheets for nothing. And `NotebookWrite` at a **cell-bracket** selection
  replaces the cell rather than inserting into it, which no test in the repo covered: the four
  selection states an author can be in — insertion point, contents selected, nothing selected, bracket
  — behave differently and only the third had ever been driven. `"Selected" -> False` is pinned
  deliberately, because writing over a genuine selection is what every editor does.
- **Next:** `PaletteAndViewUX` T2 (inline math size), then T4 last.

### Session 5 — 2026-07-29 — T4 (the building half)

- **Prompt:** "I go ahead for install and re-import."
- **Did:** Bumped to 0.1.17, staged exactly what `PublishPaclet.wls` stages (`PacletInfo.wl`, `Kernel`,
  `FrontEnd`, `Assets`, `Tests`, `Documentation`), archived, installed with `ForceVersionInstall`, and
  re-imported `main.tex` over `main.nb` **through the installed paclet rather than the working tree** —
  deliberately, since a `PacletDirectoryLoad` would have hidden any staging or install fault. 0.1.17 is
  now the only installed version. The previous `main.nb` is kept as `main-before-0.1.17.nb`.
- **Measured on the result:** 167 cells, round trip byte-exact, sheet `PlainArticle.nb`. Zero literal
  `\textbf`/`\emph`/`\textit` anywhere. The title displays its text with `\vspace{-1.5cm}` in
  `"CommandPrefix"`, the author cell shows the three names with the block in `"CommandTeX"`, and
  `\maketitle`/`\sloppy` sit in the `Date` cell's `"Separator"` with no cell of their own — each of those
  three commands occurring exactly **once** in the file, all three inside tagging rules and none in
  displayed content. 238 inline math islands carry the new `"InlineFormula"` style, so the math slider
  reaches them. 14 `Reference` cells carry the hanging `[key]` dingbat against T1's 185 pt gutter.
- **Next:** nothing here is a session's work — only Pavel reading the paper, and the by-name stylesheet
  question he answers by looking at a `Definition` label.
