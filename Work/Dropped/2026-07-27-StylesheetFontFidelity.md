# Stylesheet Font Fidelity

*[ LLM Generated ]*

> Type: investigation
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: flagged while writing the LaTeX samples — `InstallLaTeXFonts` installs Latin Modern *and* TeX Gyre, but no stylesheet asks for TeX Gyre.

The four templates name `Palatino`, `Times New Roman`, `STIX Two Math`, `Latin Modern Roman`, and `Latin Modern Math`.
Three of those are macOS system fonts or ship with Mathematica; only Latin Modern comes from TeX.
Meanwhile TeX Gyre — Pagella, the free Palatino clone, and Termes, the free Times clone — is copied onto the machine and then never used.

The LaTeX counterparts in `LaTeX/` make the gap visible: `Sample-AMSArticle.tex` sets Palatino through `mathpazo` (URW Palladio), so the notebook and the PDF are not in the same typeface, only in the same *style* of typeface.
This item decides whether the stylesheets should ask for the TeX fonts — matching the LaTeX output metric for metric — or keep the system fonts, which are present without any installation step.

Done when the decision is recorded with a side-by-side comparison behind it, and the stylesheets and README agree with whatever was decided.

### Requirements

- A visual comparison, notebook against PDF, for each of the four templates: Palatino vs TeX Gyre Pagella, Times New Roman vs TeX Gyre Termes, STIX Two Math vs the TeX math fonts.
- An explicit answer to the fallback question: if a stylesheet names a TeX font that is not installed, what does the reader see? `ArXivArticle` already has this problem — its sample renders in a substituted serif in the browser, since the Wolfram Cloud has no Latin Modern.
- Whatever is decided, the deployed samples and the README's Type column must match it.

### Edge cases & out of scope

- Font substitution is silent; a document that looks right on this machine may not elsewhere. If the stylesheets do depend on installed TeX fonts, the tutorial has to say so where the reader will see it.
- STIX Two Math ships with Mathematica, so the Springer and RevTeX math is already reasonable; the prose is the open question there.
- Out of scope: shipping fonts inside the paclet (see `CrossPlatformTeX`).

## Tasks

- [ ] T1 — Build the comparison: same sample, each template, notebook and PDF side by side, TeX fonts against system fonts.
- [ ] T2 — Decide and record; update `Scripts/BuildStyleSheets.wls`, the README Type column, and the tutorial if fonts become a prerequisite.

### Done

(completed tasks move here with the session that closed them)

## Progress

(no sessions yet)

## Decisions

| Date | Decision | Rationale |
|---|---|---|

## Dropped — 2026-07-27

- **Prompt:** "we should probably reduce, and concentrate on doing what is needed to have a working paclet."
- **Why:** typeface matching is the last thing wrong with this paclet, not the first. The templates already look like the journals they imitate — the gap is Palatino against TeX Gyre Pagella, which is a metric-compatible clone of the same design. Nothing here blocks writing, importing, exporting or publishing a paper.
- **The one real defect it names is kept, downgraded to a sentence:** `ArXivArticle`'s deployed sample renders in a substituted serif in the browser, because the Wolfram Cloud has no Latin Modern. That is a preview blemish with a one-line README fix, not a two-task investigation. Whoever next touches the README should add it beside the existing Springer caveat.
- **Reopen if:** a journal rejects a submission over typography, or the decision is ever needed to answer "which fonts must a reader install" in the tutorial.
