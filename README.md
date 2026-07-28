> ⚠️ **Actively developed, experimental research code.** It undergoes frequent cleanings and refactors, and the API may change without notice.

# MathNotebook

Write mathematics papers in Wolfram notebooks — referencing palette, LaTeX journal stylesheets, and conversion between LaTeX source and typeset math.

## ✨ Usage

Install from the Wolfram Cloud:

```wolfram
PacletInstall["https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook.paclet", ForceVersionInstall -> True]
Needs["WolframInstitute`MathNotebook`"]
```

Restart the front end, then open **Palettes ▸ MathNotebook**.

Start with the **[Tutorial](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Tutorial.nb)**, or `OpenTutorial[]`.

Every exported symbol has a reference page. They ship inside the paclet, so once it is installed they are in the Documentation Center (F1) and `?ExportLaTeXBundle` shows the same usage in a kernel.

After that, **Setup ▸ Update from cloud** in the palette — or `UpdateMathNotebook[]` — checks the published version and installs it only when it is newer, then rebuilds the menus and reopens the palette so the new palette and stylesheets are live without a restart.

## 🎨 Stylesheets

The same sample document in each template — as a notebook, and as the LaTeX it imitates:

| Stylesheet | LaTeX class | Type | Notebook | LaTeX |
|---|---|---|---|---|
| `AMSArticle` | [amsart](https://ctan.org/pkg/amscls) | Palatino | [sample](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Sample-AMSArticle.nb) | [tex](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Sample-AMSArticle.tex) · [pdf](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Sample-AMSArticle.pdf) |
| `ArXivArticle` | article | Latin Modern | [sample](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Sample-ArXivArticle.nb) | [tex](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Sample-ArXivArticle.tex) · [pdf](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Sample-ArXivArticle.pdf) |
| `SpringerJournal` | [svjour3](https://www.springernature.com/gp/authors/campaigns/latex-author-support) | Times | [sample](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Sample-SpringerJournal.nb) | [tex](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Sample-SpringerJournal.tex) |
| `RevTeXAPS` | [revtex4-2](https://ctan.org/pkg/revtex) | Times | [sample](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Sample-RevTeXAPS.nb) | [tex](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Sample-RevTeXAPS.tex) · [pdf](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Sample-RevTeXAPS.pdf) |
| `ComplexSystems` | [ComplexSystems.sty](https://www.complex-systems.com/contribute/) | Sabon · Univers | [sample](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Sample-ComplexSystems.nb) | [pdf](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Sample-ComplexSystems.pdf) |

`ComplexSystems` is the one template measured from a journal's own files rather than styled to resemble a class: *Complex Systems* publishes both a `.sty` and a Wolfram stylesheet, and they agree on a 6″ × 9″ page carrying a 306 pt column, display math flush left, and **one counter per environment running straight through the document** — so a definition and a theorem are each numbered `1`, not `1.1` and `1.2`. Its two typefaces are commercial and licensed by the journal, so screen falls back to Times and Helvetica and only the printout asks for Sabon and Univers; the geometry is right either way, the faces substitute if you do not have them. Its sample PDF is a notebook printout rather than pdfTeX output, because the journal's class file carries no licence grant and so is not vendored here.

A sixth sheet, `PlainArticle`, is not a template: it is the notebook's own `Default.nb` typography with the paper structure added — the twelve environments, `Proof`, `Caption` and the citation styles, and the counters that number them. It is what an imported paper opens on when its `\documentclass` names no journal above.

Generated from [`LaTeXBase`](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/LaTeXBase.nb); sources and PDFs in [`LaTeX/`](LaTeX). [`svjour3`](https://www.springernature.com/gp/authors/campaigns/latex-author-support) comes from Springer rather than TeX Live, so that sample has no PDF until you install the class.

## 📤 Submission

**Document ▸ Export submission…** — or `ExportLaTeXBundle[notebook, "directory"]` — writes the whole paper into a directory as an arXiv upload: the `.tex` beside every figure file its `\includegraphics` commands name, every `.bib` its preamble declares, and, where a local pdfLaTeX is found, the `.bbl` that arXiv needs because it runs LaTeX but not BibTeX. **Export to .tex…** beside it writes the `.tex` alone, which compiles only in the paper's own directory. Nothing arXiv excludes goes in — no `.aux`, `.log` or compiled PDF — and anything the paper names but disk does not have is reported rather than dropped.

## 🖱 Palette

<img src="Images/Palette.png" alt="MathNotebook palette" width="215">

What the buttons do is in the [Tutorial](https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook/Tutorial.nb).

## 📦 Requirements

Referencing, stylesheets, and conversion need nothing installed. The MaTeX and font buttons need a TeX distribution — [TeX Live](https://tug.org/texlive/), [MacTeX](https://tug.org/mactex/), [MiKTeX](https://miktex.org/) — and [MaTeX](https://github.com/szhorvat/MaTeX) also needs [Ghostscript](https://www.ghostscript.com/); the fonts installed are [Latin Modern](https://ctan.org/pkg/lm) and [TeX Gyre](https://ctan.org/pkg/tex-gyre). Programs are found through `PATH` and font directories through `kpsewhich`, so the distribution may live anywhere; only macOS with TeX Live is tested.

## 🙏 Credits

The referencing scheme and the MaTeX integration are originally due to **Nik Murzin** ([@sw1sh](https://github.com/sw1sh)).
