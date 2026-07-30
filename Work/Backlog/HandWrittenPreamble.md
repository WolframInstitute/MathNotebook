# Hand-Written Preamble

*[ LLM Generated ]*

> Type: feature
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

**A notebook that was never imported exports a body and nothing else, so it compiles nowhere.**
Measured through `notebookToLaTeX` on a six-cell notebook typed from the palette (Title, Section, a
two-cell Definition, a Theorem, a Proof), 2026-07-30:

```latex
\title{A Small Paper}

\section{Preliminaries}

\begin{definition}
A graph is a pair of sets.

The pair is unordered.
\end{definition}

\begin{theorem}
Every graph is a graph.
\end{theorem}

\begin{proof}
Immediate.
\end{proof}
```

229 bytes, and the counts are `\documentclass` **0**, `\begin{document}` **0**, `\newtheorem` **0**.
`documentTagging` defaults `"Preamble"`, `"Postamble"` and `"BodyPrefix"` to `""`, and only
`ImportLaTeXDocument` ever writes them — so the three commands the body depends on are absent by
construction, not by a bug. `EnvironmentBlocks` T2 is what makes this worth an item: before it the
blocks came out as bare prose and a missing `\newtheorem` was moot, and now every block in the file is
correct LaTeX with nothing to resolve it against.

**The deliverable is a decision before it is code.** Four things have to be chosen, and each has a real
alternative:

1. **What class.** `article` is the only one every environment here is defined for, but the notebook is
   already carrying a stylesheet that names a journal — reading `AMSArticle.nb` off the notebook and
   writing `\documentclass{amsart}` is available and is a guess about the author's target.
2. **Which `\newtheorem` lines.** Twelve, always, is one packet and is wrong for a paper using three;
   only the styles the notebook actually uses is a scan of the cells. The names must agree with
   `environmentSourceName`'s fallback (the style lowercased) or the body will not resolve, and the
   numbering must agree with what the sheet draws — one `Theorem` counter reset by `Section` for six of
   the seven sheets, one counter per environment for `ComplexSystems`.
3. **What travels with `\usepackage`.** `amsmath` and `amssymb` at minimum, `graphicx` the moment a
   figure exists, `hyperref` for the `\ref`s the palette writes.
4. **Where a `thebibliography` goes**, and whether `\bibliographystyle` is written for a notebook whose
   entries the notebook itself owns.

**And the export has two audiences that want different answers**, which is the reason not to collapse
the choice into one constant. `ExportLaTeXDocument` on an imported paper must keep emitting that
paper's own preamble byte for byte — the round trip is the repo's tightest invariant and this item may
not touch it — so a generated preamble is written **only** when the stored one is `""`.
`ExportLaTeXBundle` is the other audience and the harder one: a bundle whose `.tex` has no
`\documentclass` is not a submission whatever else is in the directory, and its `.bbl` step runs
`pdflatex`, which such a file cannot survive.

## Tasks

- [ ] T2 — generate the preamble and postamble when the stored ones are empty, leaving an imported
      paper's bytes untouched.
- [ ] T3 — a test that a typed notebook's export compiles, and that both specimens are still byte-exact.

### Done

- [x] T1 (S1) — all four decided with Pavel, 2026-07-30. `article` always; `\newtheorem` only for the
      styles the notebook uses, numbered as the sheet draws them; `amsmath`/`amssymb`/`amsthm`
      unconditionally with `graphicx`, `hyperref` and `enumitem` conditional; `thebibliography` in
      place with no `\bibliographystyle`.

## Hand-off

**T1 is closed and T2 is now a writing task rather than a design one.** The four rows below are
Pavel's calls of 2026-07-30, and three of them are decisions to *look at the notebook* rather than to
emit a constant — the scan is the work.

**What T2 has to build, in the order the `.tex` needs it.** `\documentclass{article}` unconditionally,
with a `%` comment naming the MathNotebook sheet the notebook was on so the author knows what to
switch to; `\usepackage{amsmath,amssymb,amsthm}` unconditionally, then `graphicx` if any `Caption`
cell or stored `\includegraphics` exists, `hyperref` if any reference or citation button exists, and
`enumitem` if any item carries a bracketed label; one `\newtheorem` per environment **style actually
present**, its name taken from `environmentSourceName`'s fallback (the style lowercased) so the body
resolves, and its numbering matching what the sheet draws — `[section]` on one shared `Theorem`
counter for six of the seven sheets, one counter per environment with no reset for `ComplexSystems`;
then `\begin{document}` and `\end{document}` as the postamble.

**Three traps this inherits from what is already written down, none of them new.** The generated
preamble may be written **only** when the stored one is `""`, or the round trip — the repo's tightest
invariant — stops being byte-exact on both specimens. The `\newtheorem` names must agree with the
export's own fallback rather than with the twelve defaults, which is the `theoremDeclarations` versus
`theoremEnvironments` distinction that already bit `EnvironmentBlocks` T2. And `ComplexSystems` is the
sheet that breaks the shared-counter clause deliberately, so a scan that emits `[section]` for every
sheet is wrong for exactly one of them and wrong invisibly — the notebook and the PDF disagree about
the numbers and nothing structural notices.

`EnvironmentBlocks` T3 is where the measurement in the Spec was made.

## Decisions

| decision | rationale | evidence |
|---|---|---|
| `\documentclass{article}` always, with the sheet named in a `%` comment. | Every one of the twelve environments is definable under `article`, so the emitted body always resolves; the stylesheet is the paclet's *typography* and not a declared submission target, and reading `amsart` off `AMSArticle.nb` would be a guess that also changes equation numbering silently (`amsart` numbers within the section and never says so). The comment costs a line and tells the author what to switch to. | Pavel, 2026-07-30. The `amsart` numbering clause is `CLAUDE.md` § *Conventions*. |
| One `\newtheorem` per environment style the notebook actually uses, numbered as the sheet draws it. | Twelve always is one packet and nine dead lines for a paper using three; letting `amsthm` number its own way is fewer lines and lets the compiled paper print numbers the notebook does not show, which is the one disagreement an author cannot see coming. | Pavel, 2026-07-30. |
| `amsmath`, `amssymb`, `amsthm` unconditionally; `graphicx`, `hyperref`, `enumitem` on a scan. | The first three are what the environments and the display math need in every case. The other three are each implied by a feature the notebook either has or does not, and an absent package is a compile error where a spurious one is only noise — so the scan is cheap insurance in the direction that matters. | Pavel, 2026-07-30. |
| `thebibliography` written in place, no `\bibliographystyle`. | For a notebook that was never imported the notebook owns the entries, so they belong in the `.tex` where the `Reference` cells sit — the `thebibliography` route's own asymmetry, already implemented for an imported paper. `\bibliographystyle` is inert for `thebibliography` and BibTeX never runs, which is also why `ExportLaTeXBundle` needs no `.bbl` step for such a paper. | Pavel, 2026-07-30. The bundle clause is `CLAUDE.md` § *Conventions*. |

## Progress

- **S1** 2026-07-30 T1 — the four questions decided with Pavel and recorded as `## Decisions` rows;
  three of the four are "scan the notebook" rather than a constant, which is what T2's work now is.
  No code written, deliberately — the Spec's own framing is that the deliverable was a decision first.
