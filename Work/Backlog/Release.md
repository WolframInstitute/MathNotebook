# First Public Release

*[ LLM Generated ]*

> Type: refactor
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: "give me some tutorial to check out before publishing".

Everything the README promises exists except the paclet itself: `PacletInstall["…/MathNotebook.paclet"]` currently redirects to an HTML page, because the paclet has never been deployed.
The stylesheet samples, the LaTeX PDFs, and the tutorial are all live in the cloud already; only the install URL is dead.

This item is the release gate: Pavel reads the tutorial and drives the palette on a real document first, and publishing happens after that, not before.

Done when `PacletInstall` from the README works on a machine that has never seen the paclet, and the marketplace entry matches.

### Requirements

- Tutorial reviewed by Pavel — it is nine sections of LLM-written prose making claims about his design, and those claims should be his before they go out.
- Palette reviewed on a real document (see `PaletteUsability`); a release before that is a release of an interface known to be uncomfortable.
- `run_tests.wls` green, paclet built and installed from a clean archive, front end menus reset.
- `publish-paclet`, then verify the README's `PacletInstall` line on a fresh kernel.
- Version bumped in `MathNotebook/PacletInfo.wl` and, per the global convention, in the marketplace repo's `.claude-plugin/marketplace.json` with `description`/`keywords` synced; both repos committed and pushed.
- `Scripts/DeployPreviews.wls` re-run so the published previews match the released paclet.

### Edge cases & out of scope

- The paclet ships `MathNotebook/Assets/MathNotebookTutorial.nb`, so `OpenTutorial[]` shows whatever was current at build time — rebuild the tutorial before archiving, not after.
- First install needs a front end restart or `FrontEnd`ResetMenusPacket` before the palette and stylesheet menus appear; the README says so and the release notes should too.
- Out of scope: a GitHub remote for this repo (there is none yet) and any CI.

## Tasks

- [ ] T1 — Tutorial review with Pavel; fold in corrections.
- [ ] T2 — Rebuild all generated artifacts, run the tests, build and install from a clean archive, smoke-test the palette buttons cold.
- [ ] T3 — Publish, verify the install URL from a fresh kernel, bump and push the marketplace entry.

### Done

(completed tasks move here with the session that closed them)

## Progress

(no sessions yet)

## Decisions

| Date | Decision | Rationale |
|---|---|---|
