Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

$styleSheetDirectory = FileNameJoin[ { PacletObject[ "WolframInstitute/MathNotebook" ][ "Location" ], "FrontEnd", "StyleSheets", "MathNotebook" } ];
$templateNames = { "AMSArticle", "ArXivArticle", "SpringerJournal", "RevTeXAPS" };
styleNames[ sheet_Notebook ] := Cases[ First[ sheet ], Cell[ StyleData[ name_String, ___ ], ___ ] :> name, { 1 } ];
$sharedInventory = Join[ Keys @ $theoremEnvironments,
  { "Title", "Author", "Date", "Abstract", "Section", "Subsection", "Subsubsection", "Text",
    "DisplayFormula", "DisplayFormulaNumbered", "Proof", "Reference" } ];

VerificationTest[
  AllTrue[ Map[ FileNameJoin[ { $styleSheetDirectory, # <> ".nb" } ] &, Append[ $templateNames, "LaTeXBase" ] ], FileExistsQ ],
  True
]

$baseSheet = Get[ FileNameJoin[ { $styleSheetDirectory, "LaTeXBase.nb" } ] ];

VerificationTest[
  SubsetQ[ styleNames[ $baseSheet ], Join[ $sharedInventory, { "Hyperlink", "Citation", "URL", "Notebook", "DisplayFormulaEquationNumber" } ] ],
  True
]

VerificationTest[
  Count[ First[ $baseSheet ], Cell[ StyleData[ _String, ___ ], ___, CounterIncrements -> "Theorem", ___ ], { 1 } ],
  Length @ $theoremEnvironments
]

VerificationTest[
  ! FreeQ[ Cases[ First[ $baseSheet ], Cell[ StyleData[ "Section", ___ ], ___ ], { 1 } ], { "Theorem", 0 } ],
  True
]

VerificationTest[
  AllTrue[ $templateNames,
    With[ { sheet = Get[ FileNameJoin[ { $styleSheetDirectory, # <> ".nb" } ] ] },
      SubsetQ[ styleNames[ sheet ], $sharedInventory ] &&
      ! FreeQ[ First[ sheet ], StyleData[ StyleDefinitions -> "Default.nb" ] ] &&
      Count[ First[ sheet ], Cell[ StyleData[ _String, ___ ], ___, CounterIncrements -> "Theorem", ___ ], { 1 } ] === Length @ $theoremEnvironments ] & ],
  True
]
