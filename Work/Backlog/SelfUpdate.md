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

- [ ] T1 — Publish the version marker from the publish script; `$MathNotebookCloudVersion` reads it.
- [ ] T2 — `UpdateMathNotebook[]` with the three outcomes, plus the post-install menu reset and palette reopen; decide the kernel-restart question.
- [ ] T3 — Palette button in Setup; rebuild palette and screenshot; document in the tutorial.
- [ ] T4 — Test the real path: install an older version, update from the button, confirm the new stylesheets and buttons are live.

### Done

(completed tasks move here with the session that closed them)

## Progress

(no sessions yet)

## Decisions

| Date | Decision | Rationale |
|---|---|---|
