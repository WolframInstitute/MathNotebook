Package["WolframInstitute`MathNotebook`"]

PackageExport[InstallLaTeXFonts]

PackageScope["texliveFontDirectories"]
PackageScope["texmfDirectories"]
PackageScope["userFontDirectory"]

InstallLaTeXFonts[] :=
  With[ { fonts = FileNames[ "*.otf", texliveFontDirectories[] ], target = userFontDirectory[] },
    If[ ! DirectoryQ[ target ], CreateDirectory[ target, CreateIntermediateDirectories -> True ] ];
    Scan[ CopyFile[ #, FileNameJoin[ { target, FileNameTake[ # ] } ], OverwriteTarget -> True ] &, fonts ];
    MessageDialog[ ToString @ StringForm[ "Installed `` fonts into ``. Restart the front end to use them.", Length[ fonts ], target ] ]
  ]

texliveFontDirectories[] :=
  FileNames[ "lm" | "lm-math" | "tex-gyre" | "tex-gyre-math",
    FileNameJoin[ { #, "fonts", "opentype", "public" } ] & /@ texmfDirectories[] ]

texmfDirectories[] :=
  Select[
    StringSplit[
      StringTrim @ RunProcess[
        { findExecutable[ "kpsewhich" ], "--expand-var", "$TEXMFDIST;$TEXMFLOCAL;$TEXMFHOME" }, "StandardOutput" ],
      ";" ],
    DirectoryQ ]

userFontDirectory[] :=
  Switch[ $OperatingSystem,
    "MacOSX", FileNameJoin[ { $HomeDirectory, "Library", "Fonts" } ],
    "Windows", FileNameJoin[ { $HomeDirectory, "AppData", "Local", "Microsoft", "Windows", "Fonts" } ],
    "Unix", FileNameJoin[ { $HomeDirectory, ".local", "share", "fonts" } ] ]
