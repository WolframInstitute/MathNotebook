Package["WolframInstitute`MathNotebook`"]

PackageExport[InstallLaTeXFonts]

PackageScope["texliveFontDirectories"]

texliveFontDirectories[] :=
  FileNames[ "lm" | "lm-math" | "tex-gyre" | "tex-gyre-math",
    FileNames[ "/usr/local/texlive/*/texmf-dist/fonts/opentype/public" ] ]

InstallLaTeXFonts[] :=
  With[ { fonts = FileNames[ "*.otf", texliveFontDirectories[] ] },
    Scan[ CopyFile[ #, FileNameJoin[ { $HomeDirectory, "Library", "Fonts", FileNameTake[ # ] } ], OverwriteTarget -> True ] &, fonts ];
    MessageDialog[ ToString @ StringForm[ "Installed `` fonts. Restart the front end to use them.", Length[ fonts ] ] ]
  ]
