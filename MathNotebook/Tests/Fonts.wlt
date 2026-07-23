Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

VerificationTest[
  MatchQ[ texliveFontDirectories[], { ___String } ],
  True
]

VerificationTest[
  AllTrue[ texliveFontDirectories[], DirectoryQ ],
  True
]
