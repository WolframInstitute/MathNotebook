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

*All tasks complete.*

### Done

- [x] T2 (S2) — `applyViewSettings` makes **one** assignment and never a bare stylesheet name: the new
      sheet is installed directly onto the recovered parent, and a reset installs a *neutral* sheet
      (every style at its own base size) rather than removing the private sheet. **0/10 deaths against
      the shipped shape's 6/10–9/10**, with the resolved sizes of eight styles identical to the bare
      parent's on all ten runs; pinned in `Tests/FrontEnd.wlt` as a 5-repetition rate.

- [x] T1 (S1) — the by-**name** re-resolution, not the private sheet's removal:
      `SetOptions[ nb, StyleDefinitions -> "Default.nb" ]` after a size call, closed, kills the next
      render **5/5** on its own, while deleting the tagging rules and leaving the private sheet
      installed is **0/5**.

## Hand-off

**Closed. The repair is to never assign a bare stylesheet name at all, and the old intermediate
assignment turned out to be unnecessary as well as lethal.** `applyViewSettings` used to put the
recovered parent back by name, unconditionally, and only then install the new private sheet; its
comment said that was to stop a second call nesting inside the first call's sheet, but nesting is
already prevented by using the *recovered* parent as the new sheet's parent. So there is now one
`SetOptions`, always of a private sheet, and a reset installs a **neutral** sheet — every style
restated at its own base size, the "scale exactly 1" state `View.wl` already distinguished from
`Automatic` — instead of removing the sheet. Measured with a fresh front end per repetition: **0/10
deaths, the PDF written 10/10, and the resolved sizes of eight styles identical to the bare parent's on
all ten runs**, against the shipped shape's 6/10 in the same script.

**Four candidate repairs were measured and rejected, and two of them are the interesting ones.**
Taking the private sheet off first (`Inherited`, or `Automatic`), assigning the name twice, and
resetting the front end's menus before the close all still die — 6/8 to 8/8 — so the name is the
clause and not the ordering. `CurrentValue[ nb, StyleDefinitions ] = parent` measures **0/10 by being a
silent no-op**: the private sheet survives, the document stays at the overridden size, and "reset"
stops resetting. That one was nearly shipped, and the lesson is the item's own: **a death rate cannot
distinguish a repair from a function that quietly stopped working**, so every candidate here was
measured for *both* the rate and what the styles resolve to. A pass-through private sheet with no
override cells is the other false positive — 0/10, and `Theorem` resolves 15 where the parent says 12.

**What the repair costs, and what it does not fix.** A document keeps a private sheet after a reset
rather than returning to a bare name, so the Format menu no longer shows its stylesheet selected; the
page is identical, `parentStyleSheet` still recovers the real sheet, and a second reset is idempotent.
And the hazard is **not** gone from the product: choosing a stylesheet from the Format menu is the front
end making that same assignment itself. It is gone from every path this paclet controls, which is as
far as a paclet can reach — the defect is Wolfram 15.0's.

**T1 established the mechanism, and it is the name, not the removal — and the defect is wider than
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
| Every candidate is measured for what the styles resolve to as well as for its death rate. | A rate alone cannot distinguish a repair from a function that stopped working, and the candidate that nearly shipped was exactly that. | `CurrentValue[ nb, StyleDefinitions ] = parent` — 0/10 deaths, private sheet still installed, document still at 20 pt. |
| A reset installs a neutral sheet rather than removing the private one. | It is the only shape that never assigns a bare name, and the neutral sheet is the state the file already had a name for — every style at its own base size, which is what `fontSizeCells` writes at scale exactly 1. | 0/10 deaths with eight styles resolving identically to the bare parent, 10/10 runs. |
| The Format-menu cost is accepted rather than worked around. | The page is identical, the real sheet is still recoverable, and the alternative is a front end that cannot print. A document already carried a private sheet whenever a size was set; this extends that to after a reset. | `parentStyleSheet` recovers the name from the marker cell; a second reset is idempotent. |

## Progress

- **S1** 2026-07-30 T1 — the **name**, not the removal. `SetOptions[ nb, StyleDefinitions -> name ]`
  on a document carrying a private sheet, closed, kills the next render **5/5** where deleting the
  tagging rules and leaving the sheet installed is 0/5 and the same assignment embedded with `Get` is
  0/5. The table and the three consequences are in `## Hand-off`; the one that changes T2 is that the
  lethal clause is reachable without `ResetDocumentView`, and that the embedded form — the obvious
  repair — is ruled out on stylesheet grounds rather than on this measurement.
- **S2** 2026-07-30 T2 — repaired: `applyViewSettings` makes one assignment and never a bare name,
  and a reset installs a neutral sheet instead of removing the private one. **0/10 against 6/10**,
  with eight styles resolving exactly as the bare parent on all ten runs; pinned as a 5-repetition
  rate in `Tests/FrontEnd.wlt`, deliberately outside `ownFrontEnd` because that guard's job is to
  abort on a death and here a death is the quantity. Four candidates rejected, two of them 0/10 false
  positives — the `CurrentValue` route is a silent no-op and a pass-through sheet moves the styles —
  which is why every candidate was measured for resolution as well as rate. Item complete.
