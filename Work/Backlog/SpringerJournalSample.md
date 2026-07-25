# Springer Journal Sample PDF

*[ LLM Generated ]*

> Type: refactor
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: "I think svjour3 can be get here https://www.overleaf.com/latex/templates/a-general-template-file-for-the-latex-package-svjour3-for-springer-journals/pbbwqhxxvtbp"

Three of the four stylesheets have a LaTeX counterpart compiled to PDF and linked from the README.
`SpringerJournal` does not, because `svjour3.cls` ships with neither TeX Live nor CTAN — Springer distributes it directly, and every automated route to it is closed: the zip URL on that Overleaf page (`static.springer.com/sgw/documents/468198/…/LaTeX.zip`) now returns Springer's "page does not exist" HTML, Springer's author-support page carries no zip link in its markup, and Overleaf's download endpoints require a login.

So this item is blocked on one manual download, then it is five minutes of work: install the class, compile `LaTeX/Sample-SpringerJournal.tex`, redeploy, and the README link that is already written starts resolving.

Done when `Sample-SpringerJournal.pdf` exists, is publicly reachable, and the README table's Springer row reads like the other three.

### Requirements

- `svjour3.cls` installed where `kpsewhich svjour3.cls` finds it — `~/Library/texmf/tex/latex/svjour3/` is the natural home on this machine (`kpsewhich --var-value TEXMFHOME`).
- `LaTeX/Sample-SpringerJournal.tex` compiles clean with `pdflatex`, twice, for cross-references.
- PDF deployed public by `Scripts/DeployPreviews.wls` alongside the others.
- The README's caveat sentence about Springer removed once the PDF exists.
- A decision recorded on whether the class is vendored into `LaTeX/` — Springer permits redistribution for preparing manuscripts for their journals, but vendoring a publisher's class in a paclet repo is a choice, not a default.

### Edge cases & out of scope

- `svjour3` needs an option (`smallextended` is what the sample uses) and `\smartqed`; the sample already reflects that.
- `mathptmx` supplies Times; if Springer's own class pulls a different font package the sample should follow the class, not fight it.
- Out of scope: supporting `llncs` or other Springer classes.

## Tasks

- [ ] T1 — Install `svjour3.cls` (Pavel downloads; see the navigation notes in this item's Progress), verify with `kpsewhich`, compile, redeploy, drop the README caveat.
- [ ] T2 — Record the vendoring decision.

### Done

(completed tasks move here with the session that closed them)

## Progress

### Blocked — how to get the class

1. Open the Overleaf template, sign in (free), **Menu ▸ Copy Project** or **Open as Template**, then **Menu ▸ Download ▸ Source** — the zip contains `svjour3.cls`.
2. Or, from any Springer journal's *Submission guidelines ▸ Instructions for Authors*, download the LaTeX2e macro package.
3. Or extract it from the source of any arXiv paper that uses the class (`arxiv.org/e-print/<id>` ships the author's `.cls` files).

Then:

```
mkdir -p ~/Library/texmf/tex/latex/svjour3
mv ~/Downloads/svjour3.cls ~/Library/texmf/tex/latex/svjour3/
kpsewhich svjour3.cls
```

## Decisions

| Date | Decision | Rationale |
|---|---|---|
