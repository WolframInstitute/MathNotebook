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

- [ ] T1 — decide the four questions above with Pavel, and record them as `## Decisions` rows.
- [ ] T2 — generate the preamble and postamble when the stored ones are empty, leaving an imported
      paper's bytes untouched.
- [ ] T3 — a test that a typed notebook's export compiles, and that both specimens are still byte-exact.

## Hand-off

Nothing started. The measurement above is the whole of what is known; `EnvironmentBlocks` T3 is where
it was found.

## Decisions

| decision | rationale | evidence |
|---|---|---|

## Progress
