# Reset View Render

*[ LLM Generated ]*

> Type: defect
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

**`ResetDocumentView` on a paper whose stylesheet is a *name* leaves the front end unable to render a
page, once that paper is closed.** Measured 2026-07-30 (`FrontEndTestIsolation` T4) with a fresh front
end per repetition — `UsingFrontEnd` then `Developer`UninstallFrontEnd[]`, which is what makes a rate
measurable at all:

| sequence | deaths |
|---|---|
| `SetDocumentFontSize` + `ResetDocumentView` + `NotebookClose`, sheet named `"Default.nb"` | **4/5** |
| the same, sheet named `FrontEnd`FileName[{"MathNotebook"}, "AMSArticle.nb"]` | **5/5** |
| the same, sheet **embedded** with `Get` (`Default.nb`, and `PlainArticle.nb`) | 0/5, 0/5 |
| `SetDocumentFontSize` alone, named sheet | 0/5 |
| `ResetDocumentView` alone, named sheet | 0/5 |
| both calls, document left **open** | 0/5 |
| both calls, closed, and **no** render afterwards | 0/5 |

A "death" is the front-end `LinkObject`'s id changing across the next whole-notebook `Export`, and it
comes with the PDF simply never being written. The render target does not matter — a named sheet dies
4/5 and an embedded one 5/5 — so what is corrupted is the front end and not the second notebook.

**The author's own sequence is *not* this, which is why the item is Backlog and not Active.** Open a
paper on the paclet's named sheet, drag either slider, reset the view, and print **that paper**: 0/5
deaths and the PDF written 5/5, for `SetDocumentFontSize` and `SetMathFontSize` alike. So the palette's
font slider does not crash the front end on the next print. What is left is reachable but narrower —
reset a paper's view, **close it**, then print a second paper in the same front-end session.

**What is not known**, and T1 should establish before any repair: whether the damage is the private
stylesheet's *removal* (`ResetDocumentView` assigns the recovered parent back) or the by-name resolution
of that parent at a moment when the document is going away. The `Get`-embedded control failing 0/5 says
the name is necessary; it does not say which of the two the name breaks. Note that by-name resolution
is separately unmeasurable in this environment for a locally installed paclet (`BasicFunctionality`'s
outstanding clause), so a repair verified only headless may not be a repair.

## Tasks

- [ ] T1 — narrow to the mechanism: is it the parent's removal or its by-name re-resolution? Bisect
      `ResetDocumentView` (assign the parent back vs. delete the private sheet vs. both) against the
      4/5 rate, and check whether assigning the parent back as an embedded `Get` of the same sheet
      survives where the name does not.
- [ ] T2 — repair, and pin it with a rate rather than a single run: the fixed sequence must measure
      0/5 where it now measures 4/5, in a test that reads the front-end link id across a render.

## Hand-off

Opened by `FrontEndTestIsolation` T4, which measured all of the above and stopped there — the item was
to find out whether the suite's poison was the product's, and it is, in a narrower form than feared.
The suite is unaffected either way: `Tests/FrontEnd.wlt` already renders in a front end of its own.

Two things a session here will need. The machine's front end must be working before anything is
believed — `defaults write com.wolfram.WolframApp ApplePersistenceIgnoreState -bool true` and a trivial
`UsingFrontEnd[ 1 + 1 ]`, per `CLAUDE.md` § *Build & test*. And every run needs an **external** wall
clock (`perl -e 'alarm N; exec @ARGV'`), because a blocked front end does not take an abort.

## Decisions

| decision | rationale | evidence |
|---|---|---|
| Backlog rather than Active. | The reported fear — the font slider killing the next print — is measured false, so this is a defect an author reaches by closing a paper first, not on the common path. | Author sequence 0/5 with the PDF written 5/5, both sliders. |
| A rate, not a single run, is the unit of evidence here. | The single-shot sweep that named `viewMeasurements["Default.nb"]` cannot distinguish a 4/5 rate from a certainty, and that entry measures 0/6 under repetition. | `FrontEndTestIsolation` S3 against T4. |

## Progress
