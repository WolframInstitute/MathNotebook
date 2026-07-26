# Update From Cloud Button

*[ LLM Generated ]*

> Type: refactor
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: "Add a work item to add updating of the pallete/paclet via a button. The paclet is going to be located in my wolfram cloud, you can already deploy it."

Updating today means finding the `PacletInstall` line in the README, pasting it into a notebook, and restarting the front end.
Since the paclet lives at a stable public cloud URL, the palette can do all of that itself: a button that asks the cloud what the current version is, installs it when it is newer than the installed one, and says so when it is not.

The awkward part is not the download but everything after it.
A paclet that is already loaded in the running kernel does not simply become the new version, and new stylesheets and palettes are not visible to the front end until its menus are rebuilt.
So this item is as much about being honest and orderly after the install as about performing it — the button must leave the user in a known state, not a half-updated one.

Done when a stale install can be brought current from the palette alone, with a clear message in all three outcomes (updated, already current, unreachable), and the publish step keeps the version marker in step with the archive.

### Requirements

- **Version check without downloading.** Compare the installed `PacletObject["WolframInstitute/MathNotebook"]["Version"]` against a published marker — a small public cloud object holding the current version — so the button does not pull a megabyte to discover there is nothing to do.
- **Install** via `PacletInstall[ url, ForceVersionInstall -> True ]`, the same URL the README documents.
- **Afterwards**, do what can be done and state what cannot: rebuild the front end menus (`FrontEnd`ResetMenusPacket`) so new stylesheets and palette entries appear, reopen the palette so the running one is not the old build, and say plainly when a front end restart is genuinely required rather than pretending it is not.
- **Three outcomes, three messages:** updated (with old → new version), already current, and cloud unreachable. Never silence.
- **Publishing side:** whatever publishes the archive must publish the version marker in the same step, or the button will lie. Cross-reference `Release.md`; the marker belongs in the publish script, not in a human's memory.
- The button belongs in the palette's Setup group, next to `Tutorial`.

### Design / API

```
UpdateMathNotebook[]              (* check, install if newer, report *)
$MathNotebookCloudVersion         (* version published in the cloud, or Missing[...] *)
```

The marker can be a one-line cloud object (`…/MathNotebook-version.txt`) written by the publish script from `PacletInfo.wl`, so there is exactly one source of truth for the version and no second place to forget.

### Edge cases & out of scope

- A loaded paclet cannot be swapped underneath a running kernel; the reliable sequence is install, reset menus, reopen palette, and tell the user to restart the front end for kernel-side changes. Decide whether the button offers to quit the kernel.
- The palette is deleting and reopening *itself* — sequence that carefully, and only after the install has succeeded.
- Offline, cloud outage, or a stale CDN copy of the marker; a marker that parses as a version but is newer than the archive actually deployed.
- Development installs from `PacletDirectoryLoad` must not be clobbered by a cloud install — check whether a local dev paclet is shadowing and refuse rather than confuse.
- Out of scope: automatic update checks on load (nobody wants a paclet phoning home at startup), and any downgrade path.

## Tasks

*(all tasks complete)*

### Done

- [x] T1 — Publish the version marker from the publish script; `$MathNotebookCloudVersion` reads it. *(Session 1)*
- [x] T2 — `UpdateMathNotebook[]` with the three outcomes, plus the post-install menu reset and palette reopen; decide the kernel-restart question. *(Session 2)*
- [x] T3 — Palette button in Setup; rebuild palette and screenshot; document in the tutorial. *(Session 3)*
- [x] T4 — Test the real path: install an older version, update from the button, confirm the new stylesheets and buttons are live. *(Session 4)*

## Progress

### Session 1 — 2026-07-26 — T1

- **Prompt:** "automatic update" — start the Update From Cloud Button item.
- **Did:** Added `Scripts/PublishPaclet.wls` and `MathNotebook/Kernel/Update.wl`.
  The script stages `PacletInfo.wl` + `Kernel/` + `FrontEnd/` + `Assets/` + `Tests/` (dropping `.DS_Store`), archives, uploads the archive, and *then* writes the marker, so a failed archive upload cannot leave the marker ahead of what is deployed.
  The kernel side exports `$MathNotebookCloudVersion`, backed by `cloudVersion[url]`, `versionStringQ` and the two `PackageScope` URLs the script reads back — one source of truth for where the paclet lives.
  Verified end to end against a staging URL pair (`MATHNOTEBOOK_PACLET_URL` / `MATHNOTEBOOK_VERSION_URL` → `…/MathNotebook/Staging/`): the archive published public and fetched 200, the marker read back as `0.1.8`, and both staging objects were deleted afterwards.
  `Tests/Update.wlt` (4 tests) covers the version predicate, the unreachable branch and the live symbol; the whole suite is green at 51 tests.
  `Release.md` now names this script for its publish step, since the generic `publish-paclet` recipe copies only `Kernel/` and `Tests/` and would ship a paclet with no palette and no stylesheets.
- **Learned:** `URLRead[request, {"StatusCode", "Body"}]` returns an Association, not a list — the first `cloudVersion` matched neither branch and reported everything as unreachable.
  `$CloudBase` is `None` under `wolframscript`, so `CloudConnect[]` dies with `invbase` until it is set.
  A pattern argument that already has a value is not a `_Symbol` — passing the URL symbols to a helper matched nothing and the call sat there unevaluated, the same silent failure mode as the `PackageScope` trap.
  A marker read immediately after `CloudExport` came back unreachable once and correct a minute later; the cloud serves `cache-control: public, max-age=60`, so one failed read right after publishing is not a broken marker.
- **Next:** T2 — `UpdateMathNotebook[]` with the three outcomes, the post-install menu reset and palette reopen, and the kernel-restart decision.

### Session 2 — 2026-07-26 — T2

- **Prompt:** `/next-session` — work the next task; force-install the paclet first.
- **Did:** `UpdateMathNotebook[]` in `Kernel/Update.wl`, split the way the repo splits conversion: a pure decision core plus a thin front-end wrapper.
  `updateAction[location, version, cloud]` returns one of `"Development"`, `"Unreachable"`, `"Install"`, `"Current"`, and `updateMessage[action, ...]` turns any outcome — those four plus `"Updated"` and `"Failed"` — into the sentence the user reads; both are pure and headless-testable.
  The wrapper reads the installed paclet and `$MathNotebookCloudVersion`, and on `"Install"` calls `installUpdate`: `PacletInstall[$pacletCloudURL, ForceVersionInstall -> True]`, then ``FrontEnd`ResetMenusPacket``, then `reopenPalette` — which closes every open notebook whose file is named `MathNotebook.nb` and reopens the palette from the *new* paclet's location, so the running palette is not the old build.
  A development install shadowing the cloud one is refused before anything is downloaded, by location: `developmentPacletQ` is true when the paclet does not live under `$UserBasePacletsDirectory` or `$BasePacletsDirectory`.
  Exported in `PacletInfo.wl` and given a usage string.
  `Tests/Update.wlt` grew from 4 to 14 tests (version ordering, the location predicate, all four actions, every message renders); the suite is green at 61.
  Verified live against a staging marker at `…/MathNotebook/Staging/`, since the real marker is still unpublished: `"Install"` off a `0.1.9` marker, `"Current"` off `0.1.8`, `"Unreachable"` off the real (absent) marker URL, and a marker reading `not-a-version` came back `Missing["MalformedVersionMarker", …]`. The staging object was deleted afterwards.
- **Learned:** `Order[a, b]` is `-1` when `a` sorts *after* `b`, so "cloud is newer" is `Order[cloudList, installedList] === -1`; versions compare correctly only as padded integer lists (`PadRight[ToExpression @ StringSplit[v, "."], 4]`), otherwise `"0.1.12"` sorts before `"0.1.9"`.
  Do not call `cloudVersion` twice in one probe: two reads of the same marker seconds apart disagreed — the cloud's own `max-age=60` means a freshly rewritten marker serves the old body, the new body, or nothing depending on the moment. Read once, bind, then use.
  `Notebooks[]` throws `FrontEndObject::notavail` under `wolframscript`, so `reopenPalette` cannot be exercised headless; it is front-end-only by construction, as are `MessageDialog` and `FrontEndExecute`. T4 covers the live path.
- **Next:** T3 — the palette button in Setup, rebuild and screenshot the palette, document it in the tutorial.

### Session 3 — 2026-07-26 — T3

- **Prompt:** `/next-session` — work the next task; three tasks this run, committing and pushing after each.
- **Did:** `Update from cloud` is now the middle button of the palette's Setup group, between `Install LaTeX fonts` and `Tutorial`, built by the same cold-kernel-safe `kernelButton` as every other button — `Needs` plus the fully qualified `UpdateMathNotebook[]`, `Method -> "Queued"`.
  Rebuilt `FrontEnd/Palettes/MathNotebook.nb` and `Images/Palette.png` from `Scripts/BuildPalette.wls`; the button needs no `dual` stand-in because it is static, so it shows in the screenshot as it does in the palette.
  The tutorial's *Getting Started* section gained three items: what the button does and why the check is cheap (a marker read, not a download), the three outcomes and the kernel-restart caveat, and the development-install refusal plus the `UpdateMathNotebook[]` call.
  Suite green at 61.
- **Learned:** Nothing new fought back — the Setup group is plain `kernelButton`s, so the addition was one line and a rebuild.
  Worth recording that the raster is honest here only because the button is static; anything `Dynamic` still needs its `dual` partner or the screenshot shows a placeholder.
- **Next:** T4 — the live path: install an older version, update from the button, confirm the new stylesheets and buttons are live.

### Session 4 — 2026-07-26 — T4

- **Prompt:** `/next-session`, continued — and "build the paclet and reinstall and redeploy".
- **Did:** Ran the update for real, against the real cloud URLs rather than a staging pair.
  Built and force-installed 0.1.8 from the working tree so the *installed* copy carried the T3 button, bumped `PacletInfo.wl` to 0.1.9, and published archive + marker with `Scripts/PublishPaclet.wls`.
  With 0.1.8 installed and 0.1.9 in the cloud, a probe read the marker once, got `updateAction -> "Install"`, and drove `installUpdate` inside `UsingFrontEnd` with the 0.1.8 palette open: the message came back `0.1.8 → 0.1.9`, the open palette was closed and reopened from the 0.1.9 directory, `PacletObject` resolved to 0.1.9, and `updateAction` then said `"Current"`.
  All seven front-end files — palette, five stylesheets, tutorial asset — are present under the new install, the new palette carries the Update button and the new tutorial the sentence describing it, which is the check that the archive really shipped `FrontEnd/` and `Assets/`.
  Separately settled whether the stylesheets are *live*: with MathNotebook fully uninstalled, `FrontEnd`FileName[{"MathNotebook"}, "AMSArticle.nb"]` resolves Title at 45 (`Default.nb`); after installing from the cloud and running `ResetMenusPacket` **in the same front end session** it is 26.
  The development refusal was exercised live too — `PacletDirectoryLoad` of the repo, and the action is `"Development"` with the path in the message.
  Finally redeployed the previews so the published Tutorial matches the shipped one, and added the update sentence to the README.
  Suite green at 61.
- **Learned:** `UpdateMathNotebook[]` is not as untestable as Session 2 concluded: `Notebooks[]`, `NotebookOpen` and `FrontEndExecute` all work inside `UsingFrontEnd`, so `reopenPalette` and the menu reset are drivable from `wolframscript`. Only the `MessageDialog` wrapper stays manual.
  A file-private helper is reachable as `Symbol["WolframInstitute`MathNotebook`Update`PackagePrivate`installUpdate"]`, so exercising the install path cost no widening of scope.
  `ResetMenusPacket` genuinely makes a fresh paclet's stylesheets resolve by name in the running front end — the older CLAUDE.md claim that the service front end never picks them up was wrong, and is corrected.
  Running a `Scripts/*.wls` with `-code` + `Get` instead of `-file` silently mis-resolves the repo root, because `$ScriptCommandLine` is non-empty but meaningless there; `DeployPreviews.wls` published four samples with `$Failed` stylesheets before I caught it. It now sets `$CloudBase` itself so `-file` always suffices.
- **Next:** none — the item is complete.

## Decisions

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-26 | Publishing moves into the repo as `Scripts/PublishPaclet.wls`, not the `publish-paclet` skill. | The marker has to go up in the same step as the archive, and the generic recipe also omits `FrontEnd/` and `Assets/`. |
| 2026-07-26 | The button never quits the kernel; it says the kernel must be restarted and stops there. | The button's own evaluation runs in that kernel, so `Quit[]` would abort the menu reset, the palette reopen and the message it is in the middle of producing — and the user's session state is theirs to discard, not the updater's. Everything that *can* be made live without a restart (menus, palette, stylesheets, tutorial) already is. |
| 2026-07-26 | A development install shadowing the cloud one is refused by **location**, not by asking the user. | `PacletObject` already resolves to whichever copy wins, so its `"Location"` is exactly the shadowing question; installing underneath a `PacletDirectoryLoad` would download a paclet that never loads. |
| 2026-07-26 | The real marker is **not** published yet — only the staging pair was, and it was deleted. | Publishing the marker before the archive would have the button announce 0.1.8 while the README's `PacletInstall` URL is still dead; the first real run belongs to `Release.md` T3. |
| 2026-07-26 | Superseded: 0.1.9 archive **and** marker are published at the real URLs. | T4 cannot test the real path against a staging pair — "install an older version and update from the button" needs the button's own URL to serve a newer paclet. `Release.md` T3 is now a review-and-announce step, not the first publish. |
