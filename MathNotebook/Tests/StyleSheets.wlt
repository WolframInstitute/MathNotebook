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

(* JournalSubmission T2: ComplexSystems is a template — same base cell list, same style names, chained
   to Default — but it is the one that breaks the shared-counter clause above, and deliberately. The
   journal declares one counter per environment with no section prefix (ComplexSystems.nb declares
   Lemma standalone with CounterIncrements -> "Lemma"), so exactly one cell in this sheet increments
   "Theorem" where the other four have twelve, and Section must not reset it. Numbering is the
   document's, so an imported paper still overrides this per cell; a paper written from the first cell
   in this template numbers the way the journal prints. *)

$complexSheet = Get[ FileNameJoin[ { $styleSheetDirectory, "ComplexSystems.nb" } ] ];

counterOf[ sheet_, style_ ] :=
  FirstCase[ First[ sheet ],
    Cell[ StyleData[ style ] | StyleData[ style, StyleDefinitions -> _ ], options___ ] :>
      Lookup[ { options }, CounterIncrements, None ], None, { 1 } ]

VerificationTest[
  { FileExistsQ[ FileNameJoin[ { $styleSheetDirectory, "ComplexSystems.nb" } ] ],
    SubsetQ[ styleNames[ $complexSheet ], $sharedInventory ],
    ! FreeQ[ First[ $complexSheet ], StyleData[ StyleDefinitions -> "Default.nb" ] ],
    AllTrue[ Keys @ $theoremEnvironments, counterOf[ $complexSheet, # ] === # & ],
    Count[ First[ $complexSheet ], Cell[ StyleData[ _String, ___ ], ___, CounterIncrements -> "Theorem", ___ ], { 1 } ],
    MemberQ[ FirstCase[ First[ $complexSheet ], Cell[ StyleData[ "Section" ], options___ ] :>
      Lookup[ { options }, CounterAssignments, { } ], { }, { 1 } ], { "Theorem", 0 } ] },
  { True, True, True, True, 1, False }
]

(* The geometry is the journal's and it is measured, not chosen: a 432 x 648 page carrying a 306 pt
   column, which is what 63 pt each side comes to and what the .sty's \textwidth=25.5pc comes to.
   Display math is flush left at a 2 pc indent rather than centred as in the other four. *)
VerificationTest[
  With[ { notebookOptions = FirstCase[ First[ $complexSheet ], Cell[ StyleData[ "Notebook" ], options___ ] :> { options }, { }, { 1 } ],
      printMargins = style |-> FirstCase[ First[ $complexSheet ],
        Cell[ StyleData[ style, "Printout" ], options___ ] :> Lookup[ { options }, CellMargins, None ], None, { 1 } ] },
    { Lookup[ Lookup[ notebookOptions, PrintingOptions, { } ], "PaperSize" ],
      printMargins[ "Text" ],
      432 - Total @ First @ printMargins[ "Text" ],
      First @ printMargins[ "DisplayFormula" ],
      FirstCase[ First[ $complexSheet ], Cell[ StyleData[ "DisplayFormula" ], options___ ] :>
        Lookup[ { options }, TextAlignment, None ], None, { 1 } ] } ],
  { { 432, 648 }, { { 63, 63 }, { 2, 0 } }, 306, { 87, 63 }, Left }
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


(* BasicFunctionality T6: the record GoBack follows is written by the sheets, not by the kernel, and a
   click made with nothing selected left SelectedCells[] empty — a bare First then stored an
   unevaluated First[{}], which is a record no guard can follow. Every sheet that declares Hyperlink
   must carry the default and none may carry the bare form. A click cannot be driven headless, so the
   generated artifact is the only thing there is to assert.

   Both patterns are wrapped in HoldPattern: written bare, SelectedCells[] would evaluate as the test
   file is read — and First[ SelectedCells[], None ] would then quietly answer None, matching nothing.
   Getting a sheet does not evaluate the button function either, RuleDelayed holding its right side. *)
$hyperlinkSheets = FileNames[ "*.nb", $styleSheetDirectory ];

VerificationTest[
  Length[ $hyperlinkSheets ],
  7
]

VerificationTest[
  Map[
    { file } |-> With[ { sheet = Get[ file ] },
      { ! FreeQ[ sheet, HoldPattern[ First[ SelectedCells[ ], None ] ] ],
        FreeQ[ sheet, HoldPattern[ First[ SelectedCells[ ] ] ] ] } ],
    $hyperlinkSheets ],
  ConstantArray[ { True, True }, Length[ $hyperlinkSheets ] ]
]
