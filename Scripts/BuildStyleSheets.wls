repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];
styleSheetDirectory = FileNameJoin[ { repoDirectory, "MathNotebook", "FrontEnd", "StyleSheets", "MathNotebook" } ];

$theoremEnvironments = <|
  "Theorem" -> "Plain", "Lemma" -> "Plain", "Proposition" -> "Plain",
  "Corollary" -> "Plain", "Conjecture" -> "Plain", "Claim" -> "Plain",
  "Definition" -> "Definition", "Example" -> "Definition", "Construction" -> "Definition",
  "Remark" -> "Remark", "Question" -> "Remark", "Observation" -> "Remark"
|>;

(* JournalSubmission T2: the fifth template is the first one measured from a journal's own artifacts
   rather than styled to resemble a class file. Complex Systems publishes both ComplexSystems.nb and
   ComplexSystems.sty, and they agree to the point: a 432 x 648 page (6in x 9in, confirmed against the
   sample PDF's MediaBox) carrying a 306 pt column, which is 63 pt each side and the .sty's
   \textwidth=25.5pc; Sabon LT Std over Univers LT Std headings; display math flush left at a 2 pc
   indent rather than centred; and one counter per environment running straight through the document.
   Neither file is redistributable -- Copyright (c) 2014-2018, Complex Systems, Inc., with no licence
   grant -- so nothing below is copied from them. These are measurements, which is also why they are
   written out as a literal table rather than derived: the journal chose them.

   Both fonts are commercial and on no stock machine, so the journal's own answer is adopted with the
   numbers: Times and Helvetica on screen, Sabon and Univers in the "Printout" variant, which is the
   one that reaches the PDF. That is what "PrintFont" and "PrintOverrides" exist for; the other four
   templates set neither key and generate exactly as before. *)

$complexSystemsHeadings = { "Author", "Section", "Subsection", "Subsubsection" };

(* The journal gives every environment its own counter with no section prefix, where this repo's four
   templates share one Theorem counter reset by Section and print Section.Theorem. The tell in
   ComplexSystems.nb is that Lemma is declared standalone with CounterIncrements -> "Lemma" while
   fifteen siblings inherit TheoremLike. Numbering is the document's and not the sheet's, so an
   imported paper still overrides this per cell -- but a paper written from the first cell in this
   template has to number the way the journal prints, and Section must therefore not reset it. The
   .sty sets theorem heads \sffamily\bfseries and the body \normalfont, so unlike the base sheet no
   environment is italic and the Remark class gets no separate treatment. *)
$complexSystemsEnvironments =
  AssociationMap[
    environment |-> {
      CellDingbat -> Cell[ TextData[ { environment <> " ", CounterBox[ environment ], "." } ],
        FontFamily -> "Helvetica", FontWeight -> "Bold", FontSlant -> "Plain" ],
      CounterIncrements -> environment,
      FontSlant -> "Plain",
      CellMargins -> { { 67, 24 }, { 8, 10 } } },
    Keys @ $theoremEnvironments ];

$complexSystemsOverrides = Merge[ {
  <|
    "Notebook" -> { PrintingOptions -> { "PaperSize" -> { 432, 648 },
        "PrintingMargins" -> { { 0, 0 }, { 54, 54 } }, "FacingPages" -> True,
        "FirstPageHeader" -> False, "PageHeaderMargins" -> { 36, 36 },
        "PageFooterMargins" -> { 24, 24 } } },
    "Title" -> { FontSize -> 36, CellMargins -> { { 54, 24 }, { 0, 15 } } },
    "Author" -> { FontWeight -> "Bold", FontVariations -> { }, FontSize -> 14,
      CellMargins -> { { 54, 24 }, { 0, 6 } } },
    "Abstract" -> { FontSize -> 14, CellMargins -> { { 54, 86 }, { 4, 25 } } },
    "Section" -> { FontSize -> 18, CellMargins -> { { 54, 12 }, { 16, 27 } },
      CounterAssignments -> { { "Subsection", 0 }, { "Subsubsection", 0 } } },
    "Subsection" -> { FontSize -> 15, CellMargins -> { { 54, 12 }, { 6, 23 } } },
    "Subsubsection" -> { FontSize -> 12, CellMargins -> { { 54, 12 }, { 6, 12 } } },
    "Text" -> { FontSize -> 14, ParagraphIndent -> 18, CellMargins -> { { 54, 24 }, { 4, 4 } } },
    "DisplayFormula" -> { TextAlignment -> Left, FontSize -> 14, CellMargins -> { { 90, 24 }, { 6, 6 } } },
    "DisplayFormulaNumbered" -> { TextAlignment -> Left, FontSize -> 14, CellMargins -> { { 90, 24 }, { 6, 6 } } },
    "Caption" -> { FontSize -> 12, CellMargins -> { { 67, 24 }, { 10, 18 } } },
    "Reference" -> { FontSize -> 14, CellMargins -> { { 100, 25 }, { 3, 3 } } },
    "Proof" -> { FontSlant -> "Plain", CellMargins -> { { 67, 24 }, { 8, 10 } } }
  |>,
  $complexSystemsEnvironments,
  AssociationMap[ { FontFamily -> "Helvetica" } &, $complexSystemsHeadings ]
  }, Apply[ Join ] ];

$complexSystemsPrintOverrides = Merge[ {
  <|
    "Title" -> { FontSize -> 16, CellMargins -> { { 63, 63 }, { 22, 6 } } },
    "Author" -> { FontFamily -> "Univers LT Std", FontSize -> 8, CellMargins -> { { 63, 63 }, { -4, 6 } } },
    "Date" -> { FontSize -> 9, CellMargins -> { { 63, 63 }, { 2, 6 } } },
    "Abstract" -> { FontSize -> 9, CellMargins -> { { 87, 63 }, { 0, 6 } } },
    "Section" -> { FontFamily -> "Univers LT Std", FontSize -> 9, CellMargins -> { { 72, 63 }, { 8, 30 } } },
    "Subsection" -> { FontFamily -> "Univers LT Std", FontSize -> 9, CellMargins -> { { 74, 63 }, { 2, 16 } } },
    "Subsubsection" -> { FontFamily -> "Univers LT Std", FontSize -> 9, CellMargins -> { { 63, 63 }, { 2, 14 } } },
    "Text" -> { FontSize -> 10, ParagraphIndent -> 12, CellMargins -> { { 63, 63 }, { 2, 0 } } },
    "DisplayFormula" -> { FontSize -> 10, CellMargins -> { { 87, 63 }, { 6, 4 } } },
    "DisplayFormulaNumbered" -> { FontSize -> 10, CellMargins -> { { 87, 63 }, { 6, 4 } } },
    "Caption" -> { FontSize -> 9, CellMargins -> { { 63, 63 }, { 18, 4 } } },
    "Reference" -> { FontSize -> 9, CellMargins -> { { 84, 63 }, { 2, 4 } } }
  |>,
  (* A CellDingbat declared on the bare style *is* inherited into the "Printout" variant -- the label
     prints -- but it is a Cell carrying its own FontFamily, and the variant's FontFamily does not
     reach inside it. Measured: with the dingbat declared only on the bare style, the sample PDF set
     every "Definition 1." in Helvetica-Bold, the screen heading face, while the body around it came
     out in the print face; the journal sets its labels in Univers at 8 pt. So the whole dingbat has to
     be restated here, counter and all, and the print face written into it. *)
  AssociationMap[
    environment |-> {
      CellDingbat -> Cell[ TextData[ { environment <> " ", CounterBox[ environment ], "." } ],
        FontFamily -> "Univers LT Std", FontSize -> 8, FontWeight -> "Bold", FontSlant -> "Plain" ],
      FontSize -> 10, ParagraphIndent -> 0, CellMargins -> { { 63, 63 }, { 2, 4 } } },
    Keys @ $theoremEnvironments ],
  <| "Proof" -> { FontSize -> 10, ParagraphIndent -> 0, CellMargins -> { { 63, 63 }, { 2, 4 } } } |>
  }, Apply[ Join ] ];

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
  |>,
  "ComplexSystems" -> <|
    "TextFont" -> "Times", "MathFont" -> "Times",
    "PrintFont" -> "Sabon LT Std", "PrintMathFont" -> "Sabon LT Std",
    "TitleAlignment" -> Left, "TitleWeight" -> "Bold",
    "SectionAlignment" -> Left, "SectionWeight" -> "Bold",
    "SectionVariations" -> { },
    "Overrides" -> $complexSystemsOverrides,
    "PrintOverrides" -> $complexSystemsPrintOverrides
  |>
|>;

$proseStyles = Join[
  { "Title", "Author", "Date", "Abstract", "Section", "Subsection", "Subsubsection",
    "Text", "Item", "ItemNumbered", "ItemParagraph", "Caption", "Reference", "Proof" },
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

  (* A figure caption numbers itself from its own counter, which article numbers straight through the
     document rather than per section, and the dingbat is what an imported \ref{fig:...} resolves
     against. An explicit FontSize is what lets the view controls reach it: a style declared with a
     Text parent inherits its size inside this sheet and would then carry none of its own. *)
  Cell[ StyleData[ "Caption", StyleDefinitions -> StyleData[ "Text" ] ],
    CellDingbat -> Cell[ TextData[ { "Figure ", CounterBox[ "Caption" ], "." } ], FontWeight -> "Bold" ],
    CounterIncrements -> "Caption",
    ParagraphIndent -> 0, FontSize -> 11, FontSlant -> "Plain",
    CellMargins -> { { 130, 110 }, { 4, 14 } },
    MenuSortingValue -> 1280 ],
  Cell[ StyleData[ "Caption", "Printout" ], FontSize -> 9 ],

  Cell[ StyleData[ "Reference", StyleDefinitions -> StyleData[ "Text" ] ],
    CellMargins -> { { 90, 10 }, { 3, 3 } }, ParagraphIndent -> -24,
    MenuSortingValue -> 2750 ],
  Cell[ StyleData[ "Reference", "Printout" ], FontSize -> 10 ]
  },
  StyleDefinitions -> "PrivateStylesheetFormatting.nb" ]

(* A duplicated option in one StyleData cell resolves to its FIRST occurrence -- measured, both for a
   FontSize and for a CounterIncrements -- which is what makes every override here a prepend rather
   than a rewrite of the base options, and what lets "Overrides" carry a counter as safely as a font.
   It goes first so a per-style measurement beats the blanket TextFont the same spec asks for. *)
templateOverrides[ spec_ ] := Merge[ {
  Lookup[ spec, "Overrides", <| |> ],
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

(* The "Printout" variant is a separate cell carrying only a FontSize, and it is the one that reaches
   the PDF, so a print font or a print margin has to be merged into it rather than into the bare
   style. Absent a "PrintFont" this is empty and every cell passes through untouched. *)
templatePrintOverrides[ spec_ ] :=
  If[ ! KeyExistsQ[ spec, "PrintFont" ], <| |>,
    Merge[ {
      Lookup[ spec, "PrintOverrides", <| |> ],
      AssociationMap[ { FontFamily -> spec[ "PrintFont" ] } &, $proseStyles ],
      AssociationMap[ { FontFamily -> spec[ "PrintMathFont" ] } &, $mathStyles ]
      }, Apply[ Join ] ] ]

mergePrintCell[ overrides_Association ][ Cell[ StyleData[ name_String, "Printout" ], options___ ] ] /; KeyExistsQ[ overrides, name ] :=
  Cell[ StyleData[ name, "Printout" ], Sequence @@ overrides[ name ], options ]

mergePrintCell[ _ ][ cell_ ] := cell

templateStyleSheet[ spec_ ] :=
  Module[ { overrides = templateOverrides[ spec ], printOverrides = templatePrintOverrides[ spec ],
      baseCells = First @ baseStyleSheet[], baseNames },
    baseNames = Cases[ baseCells, Cell[ StyleData[ name_String, ___ ], ___ ] :> name, { 1 } ];
    Notebook[ Join[
      Map[ mergePrintCell[ printOverrides ] @* mergeCell[ overrides ], baseCells ],
      KeyValueMap[ Cell[ StyleData[ #1 ], Sequence @@ #2 ] &, KeyDrop[ overrides, baseNames ] ] ],
      StyleDefinitions -> "PrivateStylesheetFormatting.nb" ]
  ]

(* The fifth sheet is Default.nb with the paper's structure added and its typography left alone. It is
   what an imported paper lands on when its \documentclass names no journal this repo has a template
   for: the environments are live and a cross-reference resolves, but nothing pretends to be a
   journal. It is generated from the same base cell list as the four templates and contributes only
   the styles Default has no notion of — the twelve environments, Proof, Caption, Date and the three
   character styles — plus, for the styles Default does declare, the number or label the document
   prints and nothing else. Every explicit FontSize is dropped and the "Printout" variants with them,
   so an environment inherits Default's Text rather than the templates' 13 pt. *)

$defaultSheetFile = FileNameJoin[ { $InstallationDirectory, "SystemFiles", "FrontEnd", "StyleSheets", "Default.nb" } ];

(* Styles Default.nb already declares, written out rather than scanned: a future Default that gains a
   name would otherwise silently take that style away from this sheet. Tests/StyleSheets.wlt asserts
   the two lists together cover every style the base sheet declares. *)
$plainDeferred = { "Notebook", "Title", "Author", "Text", "Item", "ItemNumbered", "ItemParagraph",
  "Reference", "DisplayFormula", "DisplayFormulaNumbered", "DisplayFormulaEquationNumber" };

(* Also declared by Default, but the number or the word in front of them is the document's and not the
   sheet's: Default numbers no heading, and an unnumbered Section beside a \ref that reads "Section 3"
   is worse than no numbering at all. *)
$plainLabelled = { "Section", "Subsection", "Subsubsection", "Abstract" };

styleOptions[ cells_List, style_String ] :=
  FirstCase[ cells,
    Cell[ StyleData[ style ] | StyleData[ style, StyleDefinitions -> _ ], options___ ] :> { options },
    { }, { 1 } ]

(* A per-style CounterAssignments replaces the parent's rather than adding to it, so Default's own
   resets have to be carried across or a Section would stop resetting the item counters. *)
labelledStyleCell[ base_List, default_, style_String ] :=
  With[ { options = styleOptions[ base, style ],
      inherited = Lookup[ styleOptions[ Cases[ default, _Cell, Infinity ], style ], CounterAssignments, { } ] },
    With[ { assignments = Union[ inherited, Lookup[ styleOptions[ base, style ], CounterAssignments, { } ] ] },
      Cell[ StyleData[ style ],
        Sequence @@ FilterRules[ options, { CellDingbat, CounterIncrements } ],
        Sequence @@ If[ assignments === { }, { }, { CounterAssignments -> assignments } ] ] ] ]

plainCell[ Cell[ StyleData[ _String, _String ], ___ ] ] := Nothing
plainCell[ cell_Cell ] := DeleteCases[ cell, FontSize -> _ ]

plainStyleSheet[] :=
  Module[ { base = First @ baseStyleSheet[], default = Get[ $defaultSheetFile ], skipped },
    skipped = Join[ $plainDeferred, $plainLabelled ];
    Notebook[ Flatten @ {
      Cell[ StyleData[ StyleDefinitions -> "Default.nb" ] ],
      Cell[ StyleData[ "Notebook" ], CreateCellID -> True, DefaultNewCellStyle -> "Text" ],
      Map[ labelledStyleCell[ base, default, # ] &, $plainLabelled ],
      Map[ plainCell,
        Select[ base, MatchQ[ Cell[ StyleData[ name_String, ___ ], ___ ] /; ! MemberQ[ skipped, name ] ] ] ] },
      StyleDefinitions -> "PrivateStylesheetFormatting.nb" ]
  ]

Export[ FileNameJoin[ { styleSheetDirectory, "LaTeXBase.nb" } ], baseStyleSheet[], "NB" ];
KeyValueMap[ Export[ FileNameJoin[ { styleSheetDirectory, #1 <> ".nb" } ], templateStyleSheet[ #2 ], "NB" ] &, $templates ];
Export[ FileNameJoin[ { styleSheetDirectory, "PlainArticle.nb" } ], plainStyleSheet[], "NB" ];
Print[ "Stylesheets written to ", styleSheetDirectory ]
