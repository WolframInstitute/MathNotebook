Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

(* These must pass on a machine with no TeX distribution at all, so they assert shape
   unconditionally and contents only where a missing TeX makes the claim vacuous. The lookups are
   the platform-dependent half of the paclet — TEXMF trees, the OpenType font trees inside them,
   and the per-OS user font store — and only the macOS branch of any of them has ever run. *)

VerificationTest[ (* no TeX must still give a list, not unevaluated RunProcess junk *)
  MatchQ[ texmfDirectories[], { ___String } ],
  True
]

VerificationTest[
  MatchQ[ texliveFontDirectories[], { ___String } ],
  True
]

VerificationTest[ (* vacuous with no TeX, a real assertion with one *)
  AllTrue[ texliveFontDirectories[], DirectoryQ ],
  True
]

VerificationTest[ (* no kpsewhich implies no font directories, on any platform *)
  texPresentQ[] || texliveFontDirectories[] === { },
  True
]

VerificationTest[ (* every platform names a user font store, and it is an absolute path *)
  With[ { target = userFontDirectory[] },
    { StringQ[ target ], StringStartsQ[ target, $HomeDirectory ] } ],
  { True, True }
]

VerificationTest[ (* the three outcomes really are three messages: reporting "Installed 0 fonts"
                     for a machine with no TeX is the defect *)
  DuplicateFreeQ @ { fontInstallMessage[ False, 0, "/fonts" ],
    fontInstallMessage[ True, 0, "/fonts" ], fontInstallMessage[ True, 12, "/fonts" ] },
  True
]

VerificationTest[ (* neither failure claims an install, and each names what to do *)
  { StringContainsQ[ fontInstallMessage[ False, 0, "/fonts" ], "Installed" ],
    StringContainsQ[ fontInstallMessage[ True, 0, "/fonts" ], "Installed" ],
    StringContainsQ[ fontInstallMessage[ False, 0, "/fonts" ], "InstallLaTeXFonts[]" ],
    StringContainsQ[ fontInstallMessage[ True, 0, "/fonts" ], "InstallLaTeXFonts[]" ] },
  { False, False, True, True }
]

VerificationTest[ (* the success message still carries the count and the destination *)
  StringContainsQ[ fontInstallMessage[ True, 12, "/fonts" ], # ] & /@ { "12", "/fonts", "Restart" },
  { True, True, True }
]

VerificationTest[ (* an executable lookup answers a path or Missing, never an unevaluated call *)
  MatchQ[ findExecutable[ "kpsewhich" ], _String | _Missing ],
  True
]

VerificationTest[ (* a name no platform has must be Missing, not a fabricated path *)
  MatchQ[ findExecutable[ "definitelyNotAnExecutable" ], _Missing ],
  True
]
