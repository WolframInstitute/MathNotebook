# First Reading Defects

*[ LLM Generated ]*

> Type: defect
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Pavel read the imported causal-graphs paper (`main.nb`, 0.1.17 import, 0.1.19 installed) and reported
six defects — the reading `ImportDisplayDefects` T4 was waiting on, and its output. All six were
triaged this session; four have measured root causes, one is a design gap, one needs a live front end
to reproduce. As before, the round trip is byte-exact through every one of them: these are display,
navigation and interaction defects, the classes the census and fidelity tests cannot see.

### The defects, triaged

1. **`\varnothing` renders as nothing.** The paper writes `\varnothing` (5 uses; never `\emptyset`).
   `Convert`TeX`TeXToBoxes["\\varnothing"]` answers U+F3A0 — a private-use character with **no
   Wolfram name**, which the front end cannot draw — and measured through `texToBoxes`,
   `U \neq \varnothing` came back as `RowBox[{"U", "≠"}]`: the glyph is not wrong, it is *gone*.
   (`\emptyset` alone happens to survive — the expression path parses it as a symbol named ∅,
   U+2205, the right glyph.) Same family as the `E`/`I` sweep: the box path emits characters the
   front end has no glyph for, and nothing detects it because ink was never measured for these
   macros. Fix: map the box path's private-use outputs to named characters (`\[EmptySet]` here), and
   **sweep** the common macro table for other unnamed private-use outputs rather than fixing one.

2. **`\&` displays verbatim.** `\section{Conclusion \& Further Work}` imports as a Section cell
   reading literally `Conclusion \& Further Work`; same for `Introduction \& Motivation`, the
   `[Light Rays \& Particles]` environment title, and prose (`Johnson \& Johnson \& 100\% \_x.`
   measured verbatim). No import pass unescapes the TeX character escapes (`\&`, `\%`, `\_`, `\#`,
   `\$`), so they reach displayed text raw. The export side must re-escape symmetrically or the
   byte-exact round trip of both specimens breaks — this is an import-unescape *plus*
   export-reescape pair, applied to displayed text only (stored-source tagging rules stay verbatim).

3. **Displayed and inline mathematics scale differently, tied to text scaling.** Two halves,
   both real, from `View.wl`'s design: `InlineFormula` is *relative* (1.05 × the host cell), so the
   **document** slider moves inline math while `DisplayFormula` (absolute, moved only by the
   **math** slider) stands still; and when *both* sliders are set, inline math **double-scales** —
   its ratio is scaled by the math control and its host by the document control, so at doc 14→21 and
   math 16→24 an inline island renders ~33 pt beside display math at 24. Proposed model (needs
   Pavel's nod): with `MathFontSize` untouched, the math styles and MaTeX follow the **document**
   ratio, so one slider scales the whole page coherently; an explicit `MathFontSize` overrides; and
   the inline ratio is scaled by mathScale/docScale so inline tracks display, not the product.

4. **A copied reference to `Axiom 3.1.3` pastes as `Theorem 0.0`.** Measured end to end: the paper's
   `\newtheorem{axiom}{Axiom}[subsection]` lands as style `Theorem` whose *cell* carries the dingbat
   `Axiom Section.Subsection.TheoremAxiom.` — word and chain both per-cell, both deviating from the
   style. `CopyCellReference` ignores the cell: it looks the *style* up in `$referenceLabelSpec`,
   getting `{"Theorem ", {"Section", "Theorem"}, ""}` — wrong word, and counters the cell never
   increments, which read 0. This is the same defect the imported `\ref` already had fixed ("read
   the chain off the target cell, not the target's style") and `CopyCellReference` never got: it
   must take the word and the counter names from the target's own `CellDingbat` (or
   `CellFrameLabels` for a display formula), falling back to the spec only for a cell carrying no
   number of its own.

5. **Refreshing labels, and sometimes clicking references afterwards, freezes.** Not reproduced
   headless yet. `LabelReferences` is `NotebookPut[labelReferenceCells @ NotebookGet[nb], nb]` — a
   whole-notebook rewrite to relabel 14 `Reference` cells, forcing the front end to re-typeset all
   167 cells and 238 inline-math islands, which on this paper can present as a freeze; and rewriting
   every cell is also the prime suspect for reference clicks misbehaving *after* a refresh. Fix
   direction: rewrite only the `Reference` cells (`Cells[nb, CellStyle -> "Reference"]` +
   `NotebookWrite` per cell), never the notebook; then reproduce the click-freeze on the real paper
   with the rewrite in place before believing it gone.

6. **A composed citation is one dead button.** `\cite{marzke1959measurement, marzke1964gravitation}`
   becomes a single `ButtonBox` labelled `[marzke1959measurement, marzke1964gravitation]` whose
   `ButtonData` is the compound key string — `NotebookLocate` finds no cell tagged with the compound,
   so the click silently does nothing. Fix: one button per key (`[a], [b]` with literal separators
   between), each navigating; the exporter recomposes adjacent citation buttons into the one
   `\cite{…}` with the source's own spacing, so both specimens stay byte-exact. `mergedButtons`
   (the reopen-split repair), `citationTeX`'s optional-argument arithmetic and `citedTags` all read
   the current shape and move with it.

### Requirements

- Every fix verified the way its defect was found: rendered ink for the glyph, cell text for the
  escapes, rendered sizes for the scaling, the pasted button's own boxes for the copy, wall-clock on
  the real paper for the freeze, a resolvable `ButtonData` per key for the citations.
- The round trip of both specimens and all four samples stays byte-exact through every task, and
  `Tests/Specimens.wlt`'s census counts move only where a fix legitimately moves them (the split
  citation buttons will move `Cites`-adjacent counts if any key on them; re-measure, never guess).
- Each fix lands with a test that **bites** (reintroduce the defect, watch it fail), per the repo
  rule; display claims go in `Tests/FrontEnd.wlt`.
- Defect 3's model changes what two shipped controls do — confirm the proposed model with Pavel
  before or at T5, and record his call in this file. **Confirmed by Pavel 2026-07-29 (S4): the
  proposed model as stated in defect 3 above, unamended.** So T5 implements rather than asks: with
  `MathFontSize` untouched the math styles and MaTeX follow the *document* ratio, an explicit
  `MathFontSize` overrides it, and the inline ratio is scaled by mathScale/docScale so inline math
  tracks display instead of double-scaling.

### Out of scope

- The by-name stylesheet question (`BasicFunctionality`'s outstanding clause) — nothing in this
  report answers it either way, since an imported paper's dingbats are per-cell.
- New TeX macros beyond what the private-use sweep of the existing table surfaces.

## Tasks

- [x] **T1 — The unnamed glyphs.** Map `presentationBoxes`' private-use outputs to named characters
  (`\varnothing` → `\[EmptySet]`), sweeping the common-macro table for every other unnamed
  private-use character rather than patching one. Assert by rendered ink (a `\varnothing` island
  measures > 0 against the blank it is today) and by character code kernel-side; round trip stays
  byte-exact (inline math re-exports from `"SourceTeX"`).
- [x] **T2 — The character escapes.** Unescape `\&`, `\%`, `\_`, `\#`, `\$` into displayed text on
  import — prose, section titles, environment titles, captions, wherever `inlineContent` reaches —
  and re-escape on export so both specimens stay byte-exact. Watch the specimen census: cell counts
  must not move.
- [x] **T3 — Split the composed citations.** One button per key with the separators as literal text,
  export recomposing adjacent citation buttons to the source's own `\cite{…}` bytes;
  `citationTeX`, `mergedButtons` and `citedTags` move together. Assert a compound citation's every
  key resolves through `NotebookLocate` on the imported specimen, and the reopen-split
  (`FrontEnd.wlt`) still merges right.
- [x] **T4 — Copy reference reads the cell.** (S4) The word and the counter chain come from the
  target's own `CellDingbat`/`CellFrameLabels`, spec only as fallback — and the button keys on the
  cell's **tag** rather than on a `CellID` an imported cell does not have, which was the second
  defect inside the one reported string. An untagged cell is tagged automatically (Pavel's call).
  The specimen's axiom pastes as `Axiom 1.3.3` on the rendered page and each fragment resolves to
  the copied cell.
- [ ] **T5 — One coherent scale for mathematics.** The model is **confirmed** (Pavel, 2026-07-29 —
  see Requirements), so this task implements it and does not ask: math follows the document slider
  when `MathFontSize` is `Automatic`; an explicit math size overrides; the inline ratio is scaled by
  mathScale/docScale so inline tracks display instead of double-scaling. Implement in
  `viewStyleCells`/`inlineMathCells`/`maTeXFontSize` and measure rendered sizes under all four
  slider states.
- [ ] **T6 — The freeze.** Rewrite `LabelReferences` to touch only the `Reference` cells, time it on
  the real `main.nb` before and after, then chase the click-after-refresh freeze on the installed
  paclet with the rewrite in place. This task ends with a measured number, not "feels fast".

## Progress

### Session 0 — 2026-07-29 — triage

- **Prompt:** Pavel's six-point defect report against the imported causal-graphs paper.
- **Did:** Triaged all six headless against the working tree. Measured: `\varnothing` → U+F3A0
  (unnamed, undrawable, and dropped outright inside a `RowBox`); `\&` verbatim in Section, Text and
  environment-title cells of a minimal import; the `axiom` environment landing as style `Theorem`
  with per-cell dingbat `Axiom S.SS.TheoremAxiom.`, so `CopyCellReference`'s style-spec lookup
  produces exactly the reported `Theorem 0.0`; the compound `\cite`'s single `ButtonBox` with an
  unresolvable compound `ButtonData`. Read `View.wl` end to end for defect 3 and found the
  double-scaling corner beyond what was reported. Wrote this item; closed `ImportDisplayDefects`
  (its T4 reading half is this report).
- **Learned:** The probe trap again, in a new coat: `Symbol["…PackageScope`importedNotebook"]`
  *created* the symbol it went looking for, and the next probe found it in `Names` — the entry
  point is `latexToNotebook`. And `\emptyset` vs `\varnothing` differ in kind: the expression path
  parses `\emptyset` to a *symbol named ∅* (right glyph, by luck), while the box path's
  `\varnothing` is an unnamed private-use character — so a sweep must test both pipeline halves.
- **Next:** T1.

### Session 1 — 2026-07-29 — T1, the glyphless macros

- **Prompt:** `/next-session`.
- **Did:** Measured the mechanism under the triage's finding: U+F3A0 is not unnamed — it is
  `\[Null]`, the named character *drawn as nothing*, the importer's fallback for any `\@unicode`
  codepoint the front end's own table lacks. The sweep source is the importer's macro table
  (`$InstallationDirectory/SystemFiles/IncludeFiles/TeX/Import/*.tns`): **179 of its 207 `\@unicode`
  macros** collapse to `\[Null]`, and inside a `RowBox` the character is dropped outright — so the
  planned "map the outputs" fix is impossible in compounds and the repair moved to the TeX:
  `glyphSentinelTeX` rewrites each offender to a braced digit sentinel before
  `Convert`TeX`TeXToBoxes` (braces so a script position keeps one token), `namedGlyphBoxes` maps
  the sentinels back to drawable characters after, and `texToBoxes` routes any fragment naming an
  offender straight to the presentation path, because the expression path drops the glyph even when
  it parses. `$glyphlessMacros` (PackageScope, 179 entries) pairs each macro with its glyph — the
  table's own intended codepoint where the front end draws it, hand-chosen standard equivalents for
  the 47 whose intended codepoint is a legacy unnamed private-use slot (`leqslant` → E2FA became
  `\[LessSlantEqual]`). Validated all 179 standalone and in compounds before editing; four kernel
  tests in `Conversion.wlt` (the pair the paper writes, the whole-table sweep, the script position,
  the `\varnothingness` boundary) and a `GlyphInk` measurement in `FrontEnd.wlt` (`\varnothing` ink
  equals `\[EmptySet]` ink exactly; the compound strictly outweighs the `U ≠` it extends). Suite
  329 → 334, green; census and both specimen round trips untouched. Bite: sentinel rewrite patched
  to `"$0"` identity fails exactly the four new glyph assertions and nothing else; restored
  byte-identical from the copy.
- **Learned:** `texToBoxes` is `PackageScope`, not file-private — probing
  `Conversion`PackagePrivate`texToBoxes` created a junk symbol, and the confirmation probe was
  itself a probe fault twice over: `DownValues` is `HoldAll`, so `Length @ DownValues @ Symbol[…]`
  reads 1 for anything, and in a UTF-8 kernel `ToString[char, InputForm]` prints a named character
  *raw*, so a named-character test needs `CharacterEncoding -> "PrintableASCII"` — without it the
  first sweep flagged 684 "unnamed" characters of which two thirds were named. And the shared MCP
  kernel's `Global`` shadows from old sessions survive every reload; fresh `wolframscript` per
  probe was what made the measurements trustworthy.
- **Next:** T2.

### Session 2 — 2026-07-29 — T2, the character escapes

- **Prompt:** `/next-session`.
- **Did:** Measured first, and the measurement killed the planned blanket inverse: the importer
  deliberately leaves raw TeX in displayed text, and raw TeX is full of the five characters —
  hodgepaper *displays* 49 bare `%`s (39 line-initial comment lines, 10 line-final continuations,
  0 mid-line), a `#1` macro parameter inside a table its `%`-continuation glues to a Proof
  paragraph, and a failed `\begin{equation}` still wearing its `_`. So both directions scan a run
  with the **same segmentation** (`rawSegments` in `Document.wl`: complete environments by
  back-reference, `$…$`/`$$…$$` failed spans, comment lines, the lone continuation `%`) and touch
  only the plain segments — `unescapedRun` on the final prose runs of `inlineParts`,
  `escapedRun` via `escapedTextCell` ahead of `referencesToTeX` in `cellBodyLaTeX`/`cellTeXText`.
  `\$` is masked to a private-use sentinel before `splitInlineMath` reads its dollar as a
  delimiter (T1's pattern), restored per segment, and `\$` inside a converted span restores in
  the island's `SourceTeX`. Three corners taken as decisions, each pinned by a test: `#` beside a
  digit is a macro parameter and is never touched; `%` is a percent only strictly mid-line; and
  every rule list opens with identity rules for the escaped forms, so a missed unescape can never
  double-escape and still round-trips byte-exact. `referenceSplit` now keeps a `\ref` inside a
  failed math span in the span — button-splitting it stranded the span's dollars in separate runs
  where the export escape read each as a loose `\$`. Suite 334 → 341 green, both specimens
  byte-exact, census untouched; both halves bitten separately (import bite fails exactly the 3
  display assertions, export bite exactly the 6 pair tests).
- **Learned:** Binding a regex to a pattern variable (`span : RegularExpression[…]`) wraps it in
  a capture group of its own, silently renumbering a numeric back-reference — `\1` matched the
  wrapper and the environment alternative matched nothing; `(?P<name>…)`/`(?P=name)` is immune.
  Now in CLAUDE.md. Also: Pavel's reported "environment title displays `\&`" could not be
  reproduced because environment titles are not displayed at all — the `[…]` title rides verbatim
  in `EnvironmentOpen` — so the escape fix covers it for free if titles ever display; and a
  `\ref` whose target is absent now merges into its neighbouring prose run (the old test asserted
  it as a standalone `TextData` part; amended to assert the content, plus that no button exists).
- **Next:** T3.

### Session 3 — 2026-07-29 — T3, the composed citations

- **Prompt:** `/next-session`.
- **Did:** Measured the design's one unknown first — `ButtonNote` survives a save exactly as
  `ButtonData` does, the reopen-split copying every option onto every fragment — and that measurement
  is what the whole shape stands on: a compound `\cite{a, b}` is now one button per key (`ButtonData`
  the trimmed key, label `[key]`, literal `", "` between) with the command's bytes riding in the
  notes, the opener's `\cite[opt]{` through its raw key and each continuation's comma plus raw key,
  and `recomposedCitations` folds a run back into the one command byte for byte — keyed on the notes,
  never the separators, since the `", "` between members is indistinguishable from prose between two
  separate `\cite` commands. `mergedButtons` keeps the first fragment's whole option sequence (else
  the first save loses the bytes); the `TextData` pass in `referencesToTeX` became a levelled
  `Replace` so an island's citation (`\emph{…\cite{a, b}…}`) merges and recomposes too; a key list
  `StringSplit` cannot reconstruct keeps the old single-button shape; a pre-split notebook's compound
  button still exports byte-exact through `citationTeX`'s key count. Degradations pinned: an opener
  alone closes over its own key, an orphaned continuation exports its own `\cite`. Tests: per-key
  shapes and notes, the dangling audit now empty on the `.bib` fixture (kernel-side "every key
  navigates"), legacy and degraded shapes, the reopen simulation re-cut to the new fragments;
  `FrontEnd.wlt` gained `SplitCitations` — through a real save, `NotebookFind` reaches each key's own
  entry and the reopened paper still exports the one `\cite{ehlers, andreka}`. Census re-measured,
  never guessed: the causal paper's Buttons 14 → 21 with **Dangling 0** — the compound `ButtonData`
  was the only dangling citation in a paper that ships its `.bib` — and hodgepaper moves nowhere,
  writing no compound `\cite`; `Dangling` is a census key now, hodge's 15 being T10's missing `.bib`.
  Suite 341 → 345 green, both specimens and all four samples byte-exact. Three bites, each restored
  from a copy: import split off fails exactly the 3 import assertions + the census; recomposition
  off exactly the 3 export assertions; option-dropping `mergedButtons` exactly the reopen simulation.
- **Learned:** `specimenProse` read every string in a cell's *content*, and a `ButtonBox`'s options
  live inside the content — so the notes' carried bytes counted as "literal `\cite{` in the prose"
  until the census stripped buttons to their labels, the same mirror rule the figure markup already
  had. And the level matters more than it reads: `content /. TextData[…] :> …` never reaches a
  TextData *inside* the replacement, so island citations had been outside the merge since T5.
- **Next:** T4.

### Session 4 — 2026-07-29 — T4, the copied reference

- **Prompt:** `/next-session`.
- **Did:** Reproduced the report and found **two** defects wearing one string. The one the triage
  named: the word and the chain were looked up from the *style*, so an imported `axiom` — style
  `Theorem` with a per-cell dingbat `Axiom S.SS.TheoremAxiom.` — cited as `Theorem` over `Section`
  and `Theorem`. The one it did not: an imported cell has **no `CellID`**, `CurrentValue[cell,
  CellID]` reads 0, and `Cells[nb, CellID -> 0]` answers the **whole document**, so the old
  `Dynamic` resolved both counters at the paper's *first* cell — which is where the reported two
  zeros come from — and `NotebookFind[nb, 0, All, CellID]` navigated nowhere. Measured that a
  `CellID` cannot be repaired onto an existing cell either (`SetOptions` and `CurrentValue[…] =`
  both silent no-ops, option list stays empty), so the copy path keys on the cell's **tag** and the
  CellID-keyed `referenceButton` is retired: `citationSpecButton[tag, spec]` is now the one
  rendering, shared with `\ref` and `InsertCitation`, needing no kernel and right in the PDF.
  `cellReferenceSpec` reads the label in three cases, the third being new — a dingbat carrying no
  `CounterBox` is *unnumbered* (a starred environment, a bibliography entry) and must read `[tag]`
  rather than fall back to a spec whose counters that cell suppresses. The clipboard payload was
  measured rather than chosen: a `Cell[BoxData[…]]` pastes in the box face at height 29 against the
  prose's 19 (T5's wrong-font defect again) and a bare `ButtonBox` pastes as its own boxes spelled
  out as text, so it is a `Cell[TextData[…]]`. Nine kernel tests in `Referencing.wlt` and five
  `FrontEnd.wlt` measurements — the CellID cause itself, the rendered `Axiom 1.3.3` with no
  `Theorem 0.0` and no `XXX` anywhere on the page, every fragment's key resolving to the copied
  cell, the `\ref` on export, and the auto-tag with its reuse. Suite 345 → 358, green; both
  specimens and all four samples byte-exact, census untouched. Two bites, each restored from a copy
  and verified byte-identical: the style-spec read fails exactly 4 kernel assertions plus the
  rendered page, and dropping the tag write fails exactly the auto-tag measurement — which is why
  that one is a measurement of its own rather than a clause of the navigation test.
- **Decision (Pavel, 2026-07-29):** a cell with neither tag nor `CellID` is **tagged
  automatically** — first unused `ref:n` — rather than prompted for or refused, so the control never
  interrupts; the generated tag is also what makes the reference exist in the exported `.tex`.
- **Learned:** A button count is the wrong assertion for anything on the clipboard — the clipboard
  alone cuts a two-counter button into 4 fragments and the paste cuts a three-counter one into 6, so
  the older `Clipboard -> 1` assertion was measuring the splitter; it now reads the distinct
  `ButtonData` keys, which also pins the auto-tag from that drive's side. Also: `freshReferenceTag`
  named in a `.wlt` while file-private stayed unevaluated and the test failed with its own input as
  the actual value — the repo's mechanical trap, hit for the fourth session running.
- **Also:** added the tutorial line Pavel asked for — `Cmd+9` on a fresh cell inserts an `Input`
  cell, the one to reach for when replacing an imported figure's `Import` with generating code
  (`Scripts/BuildTutorial.wls`, regenerated; the diff is that item and nothing else).
- **Next:** T5 — and it needs Pavel's nod on the scaling model before it is implemented.
