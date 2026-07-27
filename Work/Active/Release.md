# First Public Release

*[ LLM Generated ]*

> Type: refactor
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: "give me some tutorial to check out before publishing".

**Revised 2026-07-27 — the original premise was inverted and is corrected here.**
It said the paclet had never been deployed and the install URL was dead.
It is not: `https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook.paclet` answers **HTTP 200 with 60 KB**, and the version marker reads **0.1.10**, published in `ViewAndReferenceDefects` Session 5.
The problem is the opposite one — the URL is live and **stale**.

The working tree is **0.1.11**, and everything since that publish exists only on this machine:
`ImportLaTeXDocument`/`ExportLaTeXDocument` and the whole of `Kernel/Document.wl` (twelve sessions of `LaTeXPaperImport`), citations that render `Theorem 1.1` and renumber themselves, the fifth stylesheet `PlainArticle`, and `Tests/FrontEnd.wlt`.
A user installing from the README today gets a paclet that can do none of it, while the README describes all of it — `PlainArticle` is in the stylesheet table and the importer is in the palette.
So this is no longer "publish for the first time"; it is "the published paclet and the documented paclet have diverged, and the documentation is the one telling the truth".

The gate is unchanged: Pavel reads the tutorial and drives the palette on a real document first.
The palette half of that gate is now **met** — `ViewAndReferenceDefects` closed on 2026-07-27 with Pavel's re-check on the document that produced the report.

Done when `PacletInstall` from the README installs 0.1.11 on a machine that has never seen the paclet, the version marker agrees, and the marketplace entry matches.

### Requirements

- Tutorial reviewed by Pavel — it is nine sections of LLM-written prose making claims about his design, and those claims should be his before they go out.
- ~~Palette reviewed on a real document~~ — **met 2026-07-27**, `ViewAndReferenceDefects` T6.
- **A `LICENSE` file at the repo root.** `PacletInfo.wl` declares `"License" -> "MIT"` and no such file exists, which is the one defect here that is legal rather than technical. Carried over from `WolframInstituteTools Practices` when that item was dropped; the open question is the copyright line, since `"Creator"` is `Pavel Hajek` and `"PublisherID"` is `WolframInstitute` — that attribution is Pavel's to state, not a default to guess.
- **The tutorial's uncommitted hand edits are resolved before anything is rebuilt.** `MathNotebook/Assets/MathNotebookTutorial.nb` carries 352 changed lines that `Scripts/BuildTutorial.wls` does not produce, and the paclet ships that file, so `OpenTutorial[]` shows whatever was archived. Regenerating discards them silently. Decide first: discard, or fold into the build script.
- `run_tests.wls` green, paclet built and installed from a clean archive, front end menus reset.
- `Scripts/PublishPaclet.wls` — it publishes the archive and the version marker in one step, and unlike the generic `publish-paclet` recipe it ships `FrontEnd/` and `Assets/`.
  Then verify the README's `PacletInstall` line on a fresh kernel.
- Version bumped in `MathNotebook/PacletInfo.wl` and, per the global convention, in the marketplace repo's `.claude-plugin/marketplace.json` with `description`/`keywords` synced; both repos committed and pushed.
- `Scripts/DeployPreviews.wls` re-run so the published previews match the released paclet.

### Edge cases & out of scope

- The paclet ships `MathNotebook/Assets/MathNotebookTutorial.nb`, so `OpenTutorial[]` shows whatever was current at build time — rebuild the tutorial before archiving, not after.
- First install needs a front end restart or `FrontEnd`ResetMenusPacket` before the palette and stylesheet menus appear; the README says so and the release notes should too.
- ~~Out of scope: a GitHub remote for this repo (there is none yet)~~ — **stale.** `origin` is `git@github.com:WolframInstitute/MathNotebook.git` and `main` tracks it. CI remains out of scope.
- **The 21 symbol reference pages ship with 0.1.11.** They landed on `origin/main` in a parallel session (`3735912`), together with the `PublishPaclet.wls` fix (`e088d72`) that stages `Documentation/` — without which this release would have published the extension and none of the pages. Smoke-testing an installed build (T2) now has to include F1 / `paclet:` URI resolution, not only the palette buttons.

## Tasks

- [ ] T1 — **Two of three parts done (2026-07-27, see Progress).** Tutorial hand edits resolved and `LICENSE` added. What remains is Pavel's and only Pavel's: read the regenerated tutorial, and confirm the copyright line.
- [x] T2 — Rebuild all generated artifacts, run the tests, build and install from a clean archive, smoke-test the palette buttons cold. *(2026-07-27)*
- [ ] T3 — Publish 0.1.11, verify the install URL and the version marker from a fresh kernel, re-run `Scripts/DeployPreviews.wls`, bump and push the marketplace entry.

### Done

(completed tasks move here with the session that closed them)

## Progress

### 2026-07-27 — T1, the two parts that are not Pavel's

- **Prompt:** "commit and push and go on."
- **The tutorial's hand edits were scratchpad and are discarded.** Four cells of filler — `"A graph is blalbab"`, `"Two graphs are blalbal"`, `"Let G and H be two graphs."` and a bare `\sum _{i=1}^kn(i)^2` string — plus an evaluated `Output` and a live reference button, left from testing the environments and the referencing palette against a real document. The paclet ships `Assets/MathNotebookTutorial.nb`, so `OpenTutorial[]` was one build away from showing filler to users. A copy of the scratchpad state was kept outside the repo before regenerating, in case any of it is wanted back.
- **Regenerating mattered for a second reason nobody had noticed: the committed `.nb` was stale against its own build script.** T8–T11 edited `Scripts/BuildTutorial.wls` and never rebuilt, so the shipped tutorial described neither `PlainArticle` nor what the importer does with `\label`, `\ref` and `\cite`. 133 non-UUID diff lines, all of them the script catching up. This is the failure mode Session 8 of `ViewAndReferenceDefects` predicted — "a behaviour change silently ages the tutorial, and nothing in the build or the suite notices" — arriving on schedule. **Worth a guard:** nothing checks that `MathNotebookTutorial.nb` matches what `BuildTutorial.wls` currently produces, and a test could.
- **`LICENSE` added**, MIT, closing the one defect here that is legal rather than technical. The copyright line reads `Pavel Hajek`, matching `PacletInfo.wl`'s `"Creator"` — the only attribution the repo actually states. The repo lives under the `WolframInstitute` org and `"PublisherID"` is `WolframInstitute`, so if the copyright belongs to the institute this is a one-line change and belongs before publishing, not after.
- 218 tests pass. Pushed to `origin/main` (`439416c`).
- **Next:** T1 closes when Pavel reads the regenerated tutorial and confirms the copyright line. T2 — build and install from a clean archive and smoke-test cold — needs neither.

### 2026-07-27 — T2

- **Prompt:** "do that then."
- **Did:** built 0.1.11 from a clean staging copy and exercised it from the installed location, with no `PacletDirectoryLoad` anywhere — the point being that the importer and `PlainArticle` had only ever run from the working tree.

  | check | result |
  |---|---|
  | generated artifacts vs their build scripts | **already in sync** — regenerating all 8 gave UUID-only churn, reverted |
  | archive | 250,175 bytes, 5 directories staged incl. `Documentation` |
  | install location | `.../Paclets/Repository/WolframInstitute__MathNotebook-0.1.11`, not the repo |
  | exported symbols | 21 / 21, each with a usage string |
  | `paclet:` doc URIs | **21 / 21 resolve to a real file** — F1 works from an installed build |
  | stylesheets shipped | all six, `PlainArticle.nb` among them; palette and tutorial ship |
  | importer, cold | `Sample-ArXivArticle.tex` → 20 cells, opens on **PlainArticle**, round-trip byte-identical |
  | installed test suite | **196 passed, 0 failed** |
  | palette buttons | 17 actions, 15 distinct symbols, **all exported**; `Needs` and `Method -> "Queued"` present |

  **The 22-test gap between 218 and 196 is entirely `Specimens.wlt`, and it is worth knowing rather than shrugging at.** It locates documents relative to `PacletObject[…]["Location"]`, which from an installed build is the Paclets Repository directory — so it finds neither absent specimen paper *nor* the four committed `LaTeX/Sample-*.tex`, because `LaTeX/` is not staged into the archive. The shipped fixtures therefore assert **nothing**; they only bite from the working tree. That is not a regression and the printed notice makes it visible, but "the paclet ships its tests" and "the shipped tests cover the converter" are different claims and only the first is true.

  **The palette audit is the check that matters cold**, because the failure mode is silent: a button naming a `PackagePrivate` helper stays unevaluated with no message. Every fully qualified symbol the 17 actions name is one of the 21 exported.
- **Learned:** two of my own probes reported false defects before I caught them, both worth recognising since each *reads* exactly like a paclet fault.
  - **`MessageName` is `HoldFirst`**, so `MessageName[ Symbol[ name ], "usage" ]` raises `Message::name` and returns unevaluated rather than reading the usage — it reported all 21 symbols as having no usage string. `ToExpression[ name <> "::usage" ]` is the working form; all 21 do have one.
  - A `Shortest[ a__ ] ~~ "Method"` capture **excludes everything from `Method` onward**, so counting `"Queued"` inside the captured span answered 0 of 17. The option is there 19 times; the probe had cut the string immediately before it.
- **Next:** T3, the publish — outward-facing, and waiting on Pavel's go-ahead plus the two T1 confirmations.

## Decisions

| Date | Decision | Rationale |
|---|---|---|
