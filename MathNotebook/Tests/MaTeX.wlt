Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

VerificationTest[
  FileExistsQ @ findExecutable[ "pdflatex" ],
  True
]

VerificationTest[
  FileExistsQ @ findExecutable[ "gs" ],
  True
]

VerificationTest[
  mathTeX[ Cell[ BoxData[ FormBox[ SuperscriptBox[ "x", "2" ], TraditionalForm ] ], "DisplayFormula" ] ],
  "x^2"
]

VerificationTest[
  mathTeX[ Cell[ "", "DisplayFormulaNumbered",
    TaggingRules -> <| "MathNotebook" -> <| "SourceTeX" -> "\\begin{align}a&=b\\\\c&=d\\end{align}" |> |> ] ],
  "\\begin{aligned}\na&=b\\\\c&=d\n\\end{aligned}"
]

VerificationTest[
  maTeXCellQ[ Cell[ "", "DisplayFormula",
    TaggingRules -> <| "MathNotebook" -> <| "SourceTeX" -> "x", "MaTeX" -> True |> |> ] ],
  True
]

VerificationTest[
  maTeXCellQ[ Cell[ "plain", "Text" ] ],
  False
]

VerificationTest[
  MatchQ[
    fromMaTeXNotebook[ Notebook[ { Cell[ "rendered", "DisplayFormulaNumbered", CellID -> 7,
      TaggingRules -> <| "MathNotebook" -> <| "SourceTeX" -> "x^2", "MaTeX" -> True |> |> ] } ] ],
    Notebook[ { Cell[ BoxData[ FormBox[ SuperscriptBox[ "x", "2" ], TraditionalForm ] ], "DisplayFormulaNumbered", CellID -> 7, ___ ] } ] ],
  True
]

VerificationTest[
  StringFreeQ[ userInitFile[], "Documents" ] && StringMatchQ[ userInitFile[], ___ ~~ "Kernel" ~~ $PathnameSeparator ~~ "init.m" ],
  True
]

VerificationTest[
  Head @ Quiet @ ToExpression[ $maTeXPreferences, InputForm, HoldComplete ],
  HoldComplete
]

VerificationTest[
  StringContainsQ[ $maTeXPreferences, "$MaTeXPreamble" ] && StringContainsQ[ $maTeXPreferences, "$useMaTeXQ = False" ],
  True
]
