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

- [ ] T1 — Resolve the tutorial's uncommitted hand edits (discard or fold into `BuildTutorial.wls`), then tutorial review with Pavel; fold in corrections. Add the `LICENSE` file with the copyright line Pavel names.
- [ ] T2 — Rebuild all generated artifacts, run the tests, build and install from a clean archive, smoke-test the palette buttons cold — the importer and `PlainArticle` have never been exercised from an installed build, only from `PacletDirectoryLoad` on the working tree.
- [ ] T3 — Publish 0.1.11, verify the install URL and the version marker from a fresh kernel, re-run `Scripts/DeployPreviews.wls`, bump and push the marketplace entry.

### Done

(completed tasks move here with the session that closed them)

## Progress

(no sessions yet)

## Decisions

| Date | Decision | Rationale |
|---|---|---|
