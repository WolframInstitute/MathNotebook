repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];
styleSheetDirectory = FileNameJoin[ { repoDirectory, "MathNotebook", "FrontEnd", "StyleSheets", "MathNotebook" } ];

$theoremEnvironments = <|
  "Theorem" -> "Plain", "Lemma" -> "Plain", "Proposition" -> "Plain",
  "Corollary" -> "Plain", "Conjecture" -> "Plain", "Claim" -> "Plain",
  "Definition" -> "Definition", "Example" -> "Definition", "Construction" -> "Definition",
  "Remark" -> "Remark", "Question" -> "Remark", "Observation" -> "Remark"
|>;

$templates = <|
  "AMSArticle" -> <|
    "TextFont" -> "Palatino", "MathFont" -> "Palatino",
    "TitleAlignment" -> Center, "TitleWeight" -> "Bold",
    "SectionAlignment" -> Left, "SectionWeight" -> "Plain",
    "SectionVariations" -> { "CapsType" -> "SmallCaps" }
  |>,
  "ArXivArticle" -> <|
    "TextFont" -> "Latin Modern Roman", "MathFont" -> "Latin Modern Math",
    "TitleAlignment" -> Center, "TitleWeight" -> "Bold",
    "SectionAlignment" -> Left, "SectionWeight" -> "Bold",
    "SectionVariations" -> {}
  |>,
  "SpringerJournal" -> <|
    "TextFont" -> "Times New Roman", "MathFont" -> "STIX Two Math",
    "TitleAlignment" -> Left, "TitleWeight" -> "Bold",
    "SectionAlignment" -> Left, "SectionWeight" -> "Bold",
    "SectionVariations" -> {}
  |>,
  "RevTeXAPS" -> <|
    "TextFont" -> "Times New Roman", "MathFont" -> "STIX Two Math",
    "TitleAlignment" -> Center, "TitleWeight" -> "Bold",
    "SectionAlignment" -> Left, "SectionWeight" -> "Plain",
    "SectionVariations" -> { "CapsType" -> "SmallCaps" }
  |>
|>;

$proseStyles = Join[
  { "Title", "Author", "Date", "Abstract", "Section", "Subsection", "Subsubsection",
    "Text", "Item", "ItemNumbered", "ItemParagraph", "Reference", "Proof" },
  Keys[ $theoremEnvironments ] ];

$mathStyles = { "DisplayFormula", "DisplayFormulaNumbered", "DisplayFormulaEquationNumber" };

theoremStyleCells[ environment_ -> class_, index_ ] := {
  Cell[ StyleData[ environment, StyleDefinitions -> StyleData[ "Text" ] ],
    CellDingbat -> Cell[ TextData[ { environment <> " ", CounterBox[ "Section" ], ".", CounterBox[ "Theorem" ], "." } ],
      FontWeight -> If[ class === "Remark", "Plain", "Bold" ],
      FontSlant -> If[ class === "Remark", "Italic", "Plain" ] ],
    CounterIncrements -> "Theorem",
    FontSlant -> If[ class === "Plain", "Italic", "Plain" ],
    CellMargins -> { { 130, 10 }, { 8, 8 } },
    MenuSortingValue -> 2600 + 10 index ],
  Cell[ StyleData[ environment, "Printout" ], FontSize -> 10 ] }

baseStyleSheet[] := Notebook[ Flatten @ {
  Cell[ StyleData[ StyleDefinitions -> "Default.nb" ] ],

  Cell[ StyleData[ "Notebook" ],
    CreateCellID -> True,
    DefaultNewCellStyle -> "Text",
    LightDark -> "Light",
    Background -> White,
    PrintingOptions -> { "PaperSize" -> { 595.28, 841.89 }, "PrintingMargins" -> { { 72, 72 }, { 72, 72 } } } ],

  Cell[ StyleData[ "Title" ], TextAlignment -> Center, FontSize -> 26, FontWeight -> "Bold",
    FontColor -> GrayLevel[ 0 ], CellMargins -> { { 80, 80 }, { 12, 40 } } ],
  Cell[ StyleData[ "Title", "Printout" ], FontSize -> 17 ],

  Cell[ StyleData[ "Author", StyleDefinitions -> StyleData[ "Text" ] ], TextAlignment -> Center,
    ParagraphIndent -> 0, FontSize -> 14, FontVariations -> { "CapsType" -> "SmallCaps" },
    CellMargins -> { { 80, 80 }, { 4, 12 } }, MenuSortingValue -> 1250 ],
  Cell[ StyleData[ "Author", "Printout" ], FontSize -> 11 ],

  Cell[ StyleData[ "Date", StyleDefinitions -> StyleData[ "Text" ] ], TextAlignment -> Center,
    ParagraphIndent -> 0, FontSlant -> "Italic", FontSize -> 12,
    CellMargins -> { { 80, 80 }, { 4, 8 } }, MenuSortingValue -> 1260 ],
  Cell[ StyleData[ "Date", "Printout" ], FontSize -> 9 ],

  Cell[ StyleData[ "Abstract", StyleDefinitions -> StyleData[ "Text" ] ],
    CellDingbat -> Cell[ TextData[ "Abstract. " ], FontWeight -> "Bold", FontSlant -> "Plain" ],
    ParagraphIndent -> 0, FontSize -> 12, CellMargins -> { { 130, 110 }, { 8, 24 } },
    MenuSortingValue -> 1270 ],
  Cell[ StyleData[ "Abstract", "Printout" ], FontSize -> 9 ],

  Cell[ StyleData[ "Section" ],
    CellDingbat -> Cell[ TextData[ { CounterBox[ "Section" ], "." } ] ],
    CounterIncrements -> "Section",
    CounterAssignments -> { { "Subsection", 0 }, { "Subsubsection", 0 }, { "Theorem", 0 } },
    FontSize -> 19, FontColor -> GrayLevel[ 0 ], CellFrame -> False,
    CellMargins -> { { 40, 25 }, { 10, 28 } } ],
  Cell[ StyleData[ "Section", "Printout" ], FontSize -> 14 ],

  Cell[ StyleData[ "Subsection" ],
    CellDingbat -> Cell[ TextData[ { CounterBox[ "Section" ], ".", CounterBox[ "Subsection" ], "." } ] ],
    CounterIncrements -> "Subsection",
    CounterAssignments -> { { "Subsubsection", 0 } },
    FontSize -> 16, FontColor -> GrayLevel[ 0 ], CellFrame -> False,
    CellMargins -> { { 48, 25 }, { 8, 20 } } ],
  Cell[ StyleData[ "Subsection", "Printout" ], FontSize -> 12 ],

  Cell[ StyleData[ "Subsubsection" ],
    CellDingbat -> Cell[ TextData[ { CounterBox[ "Section" ], ".", CounterBox[ "Subsection" ], ".", CounterBox[ "Subsubsection" ], "." } ] ],
    CounterIncrements -> "Subsubsection",
    FontSize -> 14, FontColor -> GrayLevel[ 0 ], CellFrame -> False,
    CellMargins -> { { 56, 25 }, { 8, 16 } } ],
  Cell[ StyleData[ "Subsubsection", "Printout" ], FontSize -> 11 ],

  Cell[ StyleData[ "Text" ], TextJustification -> 1., Hyphenation -> True, ParagraphIndent -> 15.,
    FontSize -> 13, CellMargins -> { { 66, 10 }, { 4, 4 } } ],
  Cell[ StyleData[ "Text", "Printout" ], FontSize -> 10 ],

  Cell[ StyleData[ "DisplayFormula" ], TextAlignment -> Center, FontSize -> 13, CellMargins -> { { 66, 10 }, { 6, 6 } } ],
  Cell[ StyleData[ "DisplayFormula", "Printout" ], FontSize -> 10 ],

  Cell[ StyleData[ "DisplayFormulaNumbered" ], TextAlignment -> Center, FontSize -> 13, CellMargins -> { { 66, 10 }, { 6, 6 } },
    CounterIncrements -> "DisplayFormulaNumbered",
    CellFrameLabels -> { { None, Cell[ TextData[ { "(", CounterBox[ "DisplayFormulaNumbered" ], ")" } ], "DisplayFormulaEquationNumber" ] }, { None, None } } ],
  Cell[ StyleData[ "DisplayFormulaNumbered", "Printout" ], FontSize -> 10 ],

  Cell[ StyleData[ "DisplayFormulaEquationNumber" ], FontSize -> 12 ],
  Cell[ StyleData[ "DisplayFormulaEquationNumber", "Printout" ], FontSize -> 10 ],

  MapIndexed[ theoremStyleCells[ #1, First[ #2 ] ] &, Normal @ $theoremEnvironments ],

  Cell[ StyleData[ "Proof", StyleDefinitions -> StyleData[ "Text" ] ],
    CellDingbat -> Cell[ TextData[ "Proof." ], FontSlant -> "Italic", FontWeight -> "Plain" ],
    CellFrameLabels -> { { None, Cell[ TextData[ "\[EmptySquare]" ] ] }, { None, None } },
    CellMargins -> { { 130, 10 }, { 8, 8 } },
    MenuSortingValue -> 2740 ],
  Cell[ StyleData[ "Proof", "Printout" ], FontSize -> 10 ],

  Cell[ StyleData[ "Hyperlink", StyleDefinitions -> StyleData[ "Link" ] ],
    ContextMenu -> FEPrivate`FrontEndResource[ "ContextMenus", "Hyperlink" ],
    FontColor -> RGBColor[ 0, 0, 0.7 ],
    ButtonBoxOptions -> {
      ButtonFunction :> ( ( WolframInstitute`MathNotebook`$LastHyperlinkCell = First[ SelectedCells[] ];
        FrontEndExecute[ { NotebookLocate[ #2, "OpenInNewWindow" -> CurrentValue[ "HyperlinkModifierKey" ] ] } ] ) & ),
      Evaluator -> "Local", Method -> "Queued" } ],

  Cell[ StyleData[ "Citation", StyleDefinitions -> StyleData[ "Hyperlink" ] ],
    FontColor -> RGBColor[ 0.7, 0, 0 ] ],

  Cell[ StyleData[ "URL", StyleDefinitions -> StyleData[ "Hyperlink" ] ],
    FontColor -> RGBColor[ 0.8, 0, 0.8 ] ],

  Cell[ StyleData[ "Reference", StyleDefinitions -> StyleData[ "Text" ] ],
    CellMargins -> { { 90, 10 }, { 3, 3 } }, ParagraphIndent -> -24,
    MenuSortingValue -> 2750 ],
  Cell[ StyleData[ "Reference", "Printout" ], FontSize -> 10 ]
  },
  StyleDefinitions -> "PrivateStylesheetFormatting.nb" ]

templateOverrides[ spec_ ] := Merge[ {
  AssociationMap[ { FontFamily -> spec[ "TextFont" ] } &, $proseStyles ],
  AssociationMap[ { FontFamily -> spec[ "MathFont" ] } &, $mathStyles ],
  <| "Title" -> { TextAlignment -> spec[ "TitleAlignment" ], FontWeight -> spec[ "TitleWeight" ] } |>,
  <| "Section" -> { TextAlignment -> spec[ "SectionAlignment" ], FontWeight -> spec[ "SectionWeight" ],
      FontVariations -> spec[ "SectionVariations" ] } |>
  }, Apply[ Join ] ]

mergeCell[ overrides_Association ][ Cell[ StyleData[ name_String ], options___ ] ] /; KeyExistsQ[ overrides, name ] :=
  Cell[ StyleData[ name ], Sequence @@ overrides[ name ], options ]

mergeCell[ overrides_Association ][ Cell[ StyleData[ name_String, StyleDefinitions -> parent_ ], options___ ] ] /; KeyExistsQ[ overrides, name ] :=
  Cell[ StyleData[ name, StyleDefinitions -> parent ], Sequence @@ overrides[ name ], options ]

mergeCell[ _ ][ cell_ ] := cell

templateStyleSheet[ spec_ ] :=
  Module[ { overrides = templateOverrides[ spec ], baseCells = First @ baseStyleSheet[], baseNames },
    baseNames = Cases[ baseCells, Cell[ StyleData[ name_String, ___ ], ___ ] :> name, { 1 } ];
    Notebook[ Join[
      Map[ mergeCell[ overrides ], baseCells ],
      KeyValueMap[ Cell[ StyleData[ #1 ], Sequence @@ #2 ] &, KeyDrop[ overrides, baseNames ] ] ],
      StyleDefinitions -> "PrivateStylesheetFormatting.nb" ]
  ]

Export[ FileNameJoin[ { styleSheetDirectory, "LaTeXBase.nb" } ], baseStyleSheet[], "NB" ];
KeyValueMap[ Export[ FileNameJoin[ { styleSheetDirectory, #1 <> ".nb" } ], templateStyleSheet[ #2 ], "NB" ] &, $templates ];
Print[ "Stylesheets written to ", styleSheetDirectory ]
