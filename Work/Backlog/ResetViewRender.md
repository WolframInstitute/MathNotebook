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

- [ ] T2 — repair, and pin it with a rate rather than a single run: the fixed sequence must measure
      0/5 where the bare `SetOptions[ nb, StyleDefinitions -> name ]` measures 5/5, in a test that
      reads the front-end link id across a render. **The obvious repair is ruled out already**:
      assigning the parent back as an embedded `Get` measures 0/5 and is not available to the
      product, because an embedded parent lets every unoverridden style fall through to `Default.nb`
      and takes the sheet out of the Format menu (`CLAUDE.md` § *Style overrides*). So the repair has
      to keep the name and change *when* or *whether* it is re-resolved — re-resolving while the
      document is still open, or leaving the option untouched when it already is the parent, are the
      two candidates T1 did not distinguish.

### Done

- [x] T1 (S1) — the by-**name** re-resolution, not the private sheet's removal:
      `SetOptions[ nb, StyleDefinitions -> "Default.nb" ]` after a size call, closed, kills the next
      render **5/5** on its own, while deleting the tagging rules and leaving the private sheet
      installed is **0/5**.

## Hand-off

**T1 is answered and it is the name, not the removal — and the defect is wider than
`ResetDocumentView`.** Measured 2026-07-30 with a fresh front end per repetition
(`UsingFrontEnd` then `Developer`UninstallFrontEnd[]`), five repetitions per variant, a death being the
front-end `LinkObject`'s id changing across the next whole-notebook `Export`:

| after `SetDocumentFontSize[ nb, 20 ]` on a `"Default.nb"`-named paper, then `NotebookClose` | deaths | PDF written |
|---|---|---|
| `SetOptions[ nb, StyleDefinitions -> "Default.nb" ]` — the parent back **by name**, tagging rules left | **5/5** | 0/5 |
| the whole `ResetDocumentView` (tagging rules deleted **and** the name back) | 2/5 | 3/5 |
| tagging rules deleted, private sheet **left installed** | 0/5 | 5/5 |
| tagging rules deleted, parent back **embedded** with `Get` of the same file | 0/5 | 5/5 |
| the size call and nothing after it | 0/5 | 5/5 |

**Three things follow.** The killer is the assignment of a stylesheet **name** onto a document
carrying a private sheet — `ResetDocumentView` is merely the shipped caller, and any code doing that
`SetOptions` reaches it, so a repair inside `ResetDocumentView` alone may not be a repair. The private
sheet's *removal* is exonerated outright: deleting the tagging rules and leaving the sheet installed
is 0/5, and `applyViewSettings` cannot separate the two in the reset path because with every setting
`Automatic` no sheet is reinstalled and "remove" and "assign the name back" are literally the same
call. And **the whole reset is *less* lethal than its own `SetOptions`** — 2/5 against 5/5, on a
sequence that strictly contains it — which is either the tagging-rule deletion partly immunising the
document or the rate being genuinely noisy; T4 measured this same control at 4/5, so treat any figure
between 2/5 and 5/5 as the same phenomenon and never read one run.

Two things a session here will need. The machine's front end must be working before anything is
believed — `defaults write com.wolfram.WolframApp ApplePersistenceIgnoreState -bool true` and a trivial
`UsingFrontEnd[ 1 + 1 ]`, per `CLAUDE.md` § *Build & test*. And every run needs an **external** wall
clock (`perl -e 'alarm N; exec @ARGV'`), because a blocked front end does not take an abort.

## Decisions

| decision | rationale | evidence |
|---|---|---|
| Backlog rather than Active. | The reported fear — the font slider killing the next print — is measured false, so this is a defect an author reaches by closing a paper first, not on the common path. | Author sequence 0/5 with the PDF written 5/5, both sliders. |
| A rate, not a single run, is the unit of evidence here. | The single-shot sweep that named `viewMeasurements["Default.nb"]` cannot distinguish a 4/5 rate from a certainty, and that entry measures 0/6 under repetition. | `FrontEndTestIsolation` S3 against T4. |
| The mechanism is named as the by-name assignment, not as `ResetDocumentView`. | The lethal clause is reachable without the reset at all and is lethal *more* often without it, so scoping the defect to the exported function would scope the repair wrongly too. | `SetOptions[ nb, StyleDefinitions -> name ]` alone 5/5 against the whole reset's 2/5. |
| Embedding the parent is ruled out as the repair despite measuring 0/5. | It buys the render back by breaking the sheet: an embedded parent lets every unoverridden style fall through to `Default.nb` and removes the sheet from the Format menu, which is the trap `CLAUDE.md` § *Style overrides* already records from the testing side. | Embedded `Get` 0/5 — correct, and unusable. |

## Progress

- **S1** 2026-07-30 T1 — the **name**, not the removal. `SetOptions[ nb, StyleDefinitions -> name ]`
  on a document carrying a private sheet, closed, kills the next render **5/5** where deleting the
  tagging rules and leaving the sheet installed is 0/5 and the same assignment embedded with `Get` is
  0/5. The table and the three consequences are in `## Hand-off`; the one that changes T2 is that the
  lethal clause is reachable without `ResetDocumentView`, and that the embedded form — the obvious
  repair — is ruled out on stylesheet grounds rather than on this measurement.
