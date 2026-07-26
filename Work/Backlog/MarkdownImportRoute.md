# LaTeX via Markdown — Evaluate MarkdownToNotebook as the Import Route

*[ LLM Generated ]*

> Type: investigation
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: Pavel, 2026-07-27 — "Can you evaluate the possibility of using
https://github.com/WolframInstitute/MarkdownToNotebook to convert a latex paper into a notebook by
converting it to markdown first? Perhaps there is some tool for that in the internet."

`LaTeXPaperImport` builds a direct `.tex` → notebook converter inside this paclet (`Kernel/Document.wl`).
The alternative is a two-hop route: an existing LaTeX-to-Markdown tool, then the Wolfram Institute's own
[`MarkdownToNotebook`](https://github.com/WolframInstitute/MarkdownToNotebook), which converts a
literate-markdown document (path, URL or string) into a notebook and already handles frontmatter,
`##` headings, fenced `wl` code blocks and evaluated example cells.

This item decides whether that route should replace, feed, or be dropped in favour of the direct one —
with a measurement behind the decision, not an argument.

The reason it is not obviously a win is that the two routes optimise different things.
`MarkdownToNotebook` targets **documentation** notebooks (Symbol / Guide / TechNote pages, definition
notebooks, plain Default), and the README is explicit that the parsing is "pure Wolfram" with no
CommonMark parser — it says nothing about math, theorem environments, `\label`/`\ref`, `\cite` or a
bibliography, which are exactly the constructs `LaTeXPaperImport` T2–T7 spent seven sessions on.
Markdown as an intermediate format also has no place to *put* most of them: there is no `\label`, no
numbered theorem, and no way to carry the verbatim source that makes this paclet's round trip
byte-identical.
So the likely honest answer is "a good route to a readable notebook, not a route back to compilable
LaTeX" — but that is a hypothesis, and both halves of it are cheap to measure against the two specimen
papers the item already has.

Done when the decision is recorded with measurements behind it: what each route converts, what each
loses, and whether `MarkdownToNotebook` is worth adopting for any part of the pipeline.

### Requirements

- Name the LaTeX → Markdown tool actually used and why. Pandoc is the obvious candidate
  (`pandoc -f latex -t markdown+tex_math_dollars`); if something better exists for *papers*
  specifically — one that keeps `\label`/`\ref`, theorem environments or a bibliography — say so and
  use it. Record what the tool does with each of: sectioning, theorem environments, `\label`/`\ref`,
  `\cite` + `.bib`, `figure` + TikZ, lists, front matter, custom `\newcommand` macros.
- Run the route end to end on both specimen papers (`hodgepaper.tex`, and `main.tex` from
  `Axiomatic_Relativity_from_Causal_Graphs.zip` — see `Tests/Specimens.wlt` for how they are located;
  neither is in the repo).
- A census of the resulting notebook comparable to `Tests/Specimens.wlt`'s: cells, styles, tagged
  cells, counters, buttons, and what is left as literal LaTeX. Compare against
  `ImportLaTeXDocument`'s numbers on the same paper, which the T6/T7 Progress reports record.
- An explicit answer on the round trip: can anything come back out of the Markdown route as
  compilable `.tex`, and if not, is a one-way import still worth having beside the two-way one?
- An explicit answer on the preamble: 45 `\newcommand`s in the causal paper. Whatever the tool does
  with them, say what the reader sees.

### Edge cases & out of scope

- The route is at least three programs deep (LaTeX → tool → Markdown → `MarkdownToNotebook` → `.nb`),
  so a defect can come from any of them; attribute each loss to the hop that caused it or the
  measurement says nothing.
- `MarkdownToNotebook` produces documentation-page and Default-styled notebooks. A paper wants the
  MathNotebook stylesheets and their twelve environment styles, which is `LaTeXPaperImport` T11's
  subject — if the route is adopted, that dependency has to be named.
- A useful third possibility is that the two routes compose rather than compete: Markdown as the
  *authoring* format for a new paper (Pavel already keeps `NotebooksLLM/` markdown sources elsewhere),
  with `ExportLaTeXDocument` as the way out. Evaluate it, but do not build it here.
- Out of scope: adding `MarkdownToNotebook` as a paclet dependency, and any implementation at all.
  This item ends in a recorded decision.

## Tasks

- [ ] T1 — Survey the LaTeX → Markdown tools and read `MarkdownToNotebook`: what each side supports,
      construct by construct, against the requirement list above. No conversion runs yet.
- [ ] T2 — Run the route end to end on both specimens, census the result, and compare with
      `ImportLaTeXDocument` on the same papers.
- [ ] T3 — Decide and record: replace, feed, compose, or drop. Update `LaTeXPaperImport`'s Decisions
      table if the answer changes anything there.

### Done

(completed tasks move here with the session that closed them)

## Progress

(no sessions yet)

## Decisions

| Date | Decision | Rationale |
|---|---|---|
