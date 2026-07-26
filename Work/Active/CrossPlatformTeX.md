# Cross-Platform TeX and Font Support

*[ LLM Generated ]*

> Type: investigation
<!-- Status is the folder: Active/ Backlog/ Done/ Dropped/. Move the file to change it. -->

## Spec

Origin: "Is this working for any MaTeX or texlive or whatever on any system?"

The answer was no, and half of it is now fixed: font directories come from `kpsewhich --expand-var '$TEXMFDIST;$TEXMFLOCAL;$TEXMFHOME'` instead of a hardcoded `/usr/local/texlive/*` glob, executables are looked up along `PATH` with a `.exe` variant on Windows, and the font destination switches on `$OperatingSystem`.
None of the non-macOS branches has ever run.
This item verifies them on real machines, or narrows the claim in the README to what is actually true.

Done when `InstallLaTeXFonts` and `InstallMaTeX` are known to work on Windows and Linux, or the README says explicitly which platforms are unsupported and the code fails with a clear message rather than a wrong path.

### Requirements

- Linux: fonts land in `~/.local/share/fonts` and the front end sees them — this very likely needs `fc-cache -f` after copying, which the code does not do.
- Windows: `%LOCALAPPDATA%\Microsoft\Windows\Fonts` is the per-user font store, but a font dropped there is not registered for applications without a registry entry under `HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts`. Confirm whether the Wolfram front end picks up unregistered user fonts; if not, decide whether to write the registry entry or to tell the user to right-click ▸ Install.
- MiKTeX: `kpsewhich --expand-var` exists but its variable names and quoting differ from TeX Live's — verify, and check whether MiKTeX even ships the OpenType Latin Modern and TeX Gyre trees.
- `findExecutable` must find `pdflatex` and `gs` when the front end kernel has a minimal `PATH` — the case the old `zsh -lc which` hack existed to handle. Verify on each platform that the explicit directory list plus `PATH` is enough.
- A test that does not assume macOS: `Tests/Fonts.wlt` currently asserts the font directories exist, which fails on a machine with no TeX at all. It should assert shape, and only assert contents when TeX is present.

### Edge cases & out of scope

- TinyTeX and Docker TeX images put `kpsewhich` outside the usual directories.
- A machine with no TeX distribution at all must give a comprehensible message, not an empty list of fonts and a cheerful "Installed 0 fonts".
- Out of scope: bundling fonts with the paclet (licensing is fine — GUST fonts are freely redistributable — but it changes the paclet's size and purpose).

## Tasks

- [ ] T2 — Linux: verify end to end, add `fc-cache` if needed.
- [ ] T3 — Windows: verify the font store question, decide on registry vs manual install, verify `findExecutable` with MiKTeX and TeX Live.
- [ ] T4 — Update the README's platform sentence to whatever T2 and T3 established.

### Done

- [x] T1 — Make `Tests/Fonts.wlt` platform-neutral and add a no-TeX-present path with a clear message. *(Session 1)*

## Progress

### Session 1 — 2026-07-26 — T1

- **Prompt:** work the backlog autonomously overnight, committing after each task.
- **Did:** `Tests/Fonts.wlt` asserted that the TeX font directories *exist*, so the suite failed on any machine without a TeX install and asserted nothing about the platform branches.
  It is now 10 tests that pass with or without TeX: shape unconditionally (`texmfDirectories`, `texliveFontDirectories` are `{___String}`), contents only where a missing TeX makes the claim vacuous, `texPresentQ[] || texliveFontDirectories[] === {}` on any platform, `userFontDirectory[]` an absolute path under `$HomeDirectory` on whichever branch is running, and `findExecutable` answering a path or `Missing` for a name no platform has.
  The no-TeX path also needed code. `findExecutable` answers `Missing["NotFound"]`, which `RunProcess` cannot take, so `texmfDirectories[]` returned unevaluated junk rather than `{}`; it now guards on the lookup.
  `InstallLaTeXFonts` reported "Installed 0 fonts into ..." for a machine with no TeX at all, which reads like a successful run — the Spec's "cheerful" case.
  It now has three outcomes through a pure `fontInstallMessage[texPresent, count, target]`: no TeX at all, a TeX with no OpenType trees, and a real install; the first two name the packages or distributions to install and neither says "Installed".
  It also no longer creates the user font directory when it has nothing to put in it.
  Verified all three against the real exported function with the lookups stubbed: no TeX gives the distribution message with no stray directory and no messages raised, a TeX with no font trees gives the packages message, and this machine still reports "Installed 111 fonts into ~/Library/Fonts". Suite 89.
- **Learned:**
  - `Internal`InheritedBlock[{fe}, fe[x_String] := ...]` where `fe` is a *variable* holding the symbol does not do what it looks like: `InheritedBlock` is `HoldAll`, so it localises `fe` itself, while the `SetDelayed` resolves through `fe`'s own value and attaches the definition to the real symbol — which is therefore **not** restored on exit. The stub leaked into the rest of the script and silently invalidated the second case. Stub through the real symbol, or use a fresh kernel per case.
  - A stub whose pattern is more general than the real definition never fires: `fe[_] := Missing[...]` sits behind the existing `findExecutable[name_String]`. Match the existing pattern exactly to replace it.
- **Next:** T2, Linux end to end — which needs a Linux machine and cannot be done from here.

## Decisions

| Date | Decision | Rationale |
|---|---|---|
