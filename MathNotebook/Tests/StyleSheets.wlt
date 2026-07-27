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

(* LaTeXPaperImport T11: the fifth sheet is not a template. It is Default.nb with the paper's
   structure added, so it declares the twelve environments and their counter and chains to Default,
   but claims none of the typography. *)

$plainSheet = Get[ FileNameJoin[ { $styleSheetDirectory, "PlainArticle.nb" } ] ];

VerificationTest[
  { FileExistsQ[ FileNameJoin[ { $styleSheetDirectory, "PlainArticle.nb" } ] ],
    SubsetQ[ styleNames[ $plainSheet ],
      Join[ Keys @ $theoremEnvironments, { "Proof", "Caption", "Date", "Citation", "Hyperlink", "URL" } ] ],
    ! FreeQ[ First[ $plainSheet ], StyleData[ StyleDefinitions -> "Default.nb" ] ],
    Count[ First[ $plainSheet ], Cell[ StyleData[ _String, ___ ], ___, CounterIncrements -> "Theorem", ___ ], { 1 } ] },
  { True, True, True, Length @ $theoremEnvironments }
]

(* A per-style CounterAssignments replaces the parent's rather than adding to it, so declaring the
   Theorem reset on Section has to carry Default's own eight resets across with it. *)
VerificationTest[
  With[ { assignments = FirstCase[ First[ $plainSheet ],
      Cell[ StyleData[ "Section" ], options___ ] :> Lookup[ { options }, CounterAssignments, { } ], { }, { 1 } ] },
    { MemberQ[ assignments, { "Theorem", 0 } ], MemberQ[ assignments, { "ItemNumbered", 0 } ],
      MemberQ[ assignments, { "Subsection", 0 } ] } ],
  { True, True, True }
]

(* "Default's typography" is the whole point of the sheet, and it is one assertion: no size and no
   font family anywhere in it, and not one cell for a style whose look it defers to Default. The
   styles it does declare for a name Default already has — the three sectioning levels and Abstract —
   carry only the number or the word the document prints. *)
VerificationTest[
  { FreeQ[ First[ $plainSheet ], FontSize -> _ ],
    FreeQ[ First[ $plainSheet ], FontFamily -> _ ],
    Sort @ Complement[ styleNames[ $baseSheet ], styleNames[ $plainSheet ] ],
    Sort @ Flatten @ Cases[ First[ $plainSheet ],
      Cell[ StyleData[ "Section" | "Subsection" | "Subsubsection" | "Abstract" ], options___ ] :>
        Complement[ Keys @ { options },
          { CellDingbat, CounterIncrements, CounterAssignments, ExpressionUUID } ], { 1 } ] },
  { True, True,
    { "Author", "DisplayFormula", "DisplayFormulaEquationNumber", "DisplayFormulaNumbered",
      "Reference", "Text", "Title" },
    { } }
]
