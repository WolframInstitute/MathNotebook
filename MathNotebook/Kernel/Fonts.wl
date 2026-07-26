Package["WolframInstitute`MathNotebook`"]

PackageExport[InstallLaTeXFonts]

PackageScope["texliveFontDirectories"]
PackageScope["texmfDirectories"]
PackageScope["userFontDirectory"]
PackageScope["texPresentQ"]
PackageScope["fontInstallMessage"]

InstallLaTeXFonts[] :=
  With[ { fonts = FileNames[ "*.otf", texliveFontDirectories[] ], target = userFontDirectory[] },
    If[ fonts =!= { },
      If[ ! DirectoryQ[ target ], CreateDirectory[ target, CreateIntermediateDirectories -> True ] ];
      Scan[ CopyFile[ #, FileNameJoin[ { target, FileNameTake[ # ] } ], OverwriteTarget -> True ] &, fonts ] ];
    MessageDialog @ fontInstallMessage[ texPresentQ[], Length[ fonts ], target ]
  ]

(* Three outcomes, and only one of them is an install. The old code reported "Installed 0 fonts"
   for all three, so a machine with no TeX at all looked like a successful run that found nothing. *)
fontInstallMessage[ False, _, _ ] :=
  "No TeX distribution found: kpsewhich is not on PATH or in the usual TeX directories. \
Install TeX Live, MacTeX or MiKTeX and run InstallLaTeXFonts[] again."

fontInstallMessage[ True, 0, _ ] :=
  "Found a TeX distribution, but no OpenType Latin Modern or TeX Gyre fonts in it. \
Add the lm, lm-math, tex-gyre and tex-gyre-math packages to it and run InstallLaTeXFonts[] again."

fontInstallMessage[ True, count_Integer, target_String ] :=
  ToString @ StringForm[ "Installed `` fonts into ``. Restart the front end to use them.", count, target ]

texPresentQ[] :=
  StringQ @ findExecutable[ "kpsewhich" ]

texliveFontDirectories[] :=
  FileNames[ "lm" | "lm-math" | "tex-gyre" | "tex-gyre-math",
    FileNameJoin[ { #, "fonts", "opentype", "public" } ] & /@ texmfDirectories[] ]

(* findExecutable answers Missing["NotFound"] when there is no TeX, which RunProcess cannot take:
   without this guard the whole chain returns unevaluated junk instead of an empty list. *)
texmfDirectories[] :=
  With[ { kpsewhich = findExecutable[ "kpsewhich" ] },
    If[ ! StringQ[ kpsewhich ], { },
      Select[
        StringSplit[
          StringTrim @ RunProcess[
            { kpsewhich, "--expand-var", "$TEXMFDIST;$TEXMFLOCAL;$TEXMFHOME" }, "StandardOutput" ],
          ";" ],
        DirectoryQ ] ] ]

userFontDirectory[] :=
  Switch[ $OperatingSystem,
    "MacOSX", FileNameJoin[ { $HomeDirectory, "Library", "Fonts" } ],
    "Windows", FileNameJoin[ { $HomeDirectory, "AppData", "Local", "Microsoft", "Windows", "Fonts" } ],
    "Unix", FileNameJoin[ { $HomeDirectory, ".local", "share", "fonts" } ] ]
