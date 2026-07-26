Package["WolframInstitute`MathNotebook`"]

PackageExport[ConvertLaTeXCells]
PackageExport[ConvertMathCells]

PackageScope["texToBoxes"]
PackageScope["boxesToTeX"]
PackageScope["splitInlineMath"]
PackageScope["alignBoxes"]
PackageScope["displayParse"]
PackageScope["displayBodyBoxes"]
PackageScope["storedSourceTeX"]
PackageScope["cellBoxes"]
PackageScope["retainedCellOptions"]
PackageScope["convertLaTeXNotebook"]
PackageScope["convertMathNotebook"]
PackageScope["mapCells"]
PackageScope["convertCells"]
PackageScope["writeCells"]

ConvertLaTeXCells[] :=
  convertCells[ convertLaTeXCell, InputNotebook[] ]

ConvertLaTeXCells[ notebook_NotebookObject ] :=
  NotebookPut[ convertLaTeXNotebook[ NotebookGet[ notebook ] ], notebook ]

ConvertLaTeXCells[ cells : { __CellObject } ] :=
  writeCells[ convertLaTeXCell, cells ]

ConvertMathCells[] :=
  convertCells[ convertMathCell, InputNotebook[] ]

ConvertMathCells[ notebook_NotebookObject ] :=
  NotebookPut[ convertMathNotebook[ NotebookGet[ notebook ] ], notebook ]

ConvertMathCells[ cells : { __CellObject } ] :=
  writeCells[ convertMathCell, cells ]

convertLaTeXNotebook[ notebook_Notebook ] :=
  mapCells[ convertLaTeXCell, notebook ]

convertMathNotebook[ notebook_Notebook ] :=
  mapCells[ convertMathCell, notebook ]

convertCells[ cellTransform_, notebook_NotebookObject ] :=
  Replace[ SelectedCells[ notebook ],
    { {} :> NotebookPut[ mapCells[ cellTransform, NotebookGet[ notebook ] ], notebook ],
      cells_List :> writeCells[ cellTransform, cells ] } ]

writeCells[ cellTransform_, cells_List ] :=
  Scan[ { cell } |-> NotebookWrite[ cell, cellTransform @ NotebookRead[ cell ], All ], cells ]

mapCells[ cellTransform_, Notebook[ cells_List, options___ ] ] :=
  Notebook[ Map[ mapCells[ cellTransform, # ] &, cells ], options ]

mapCells[ cellTransform_, Cell[ CellGroupData[ cells_List, state___ ], options___ ] ] :=
  Cell[ CellGroupData[ Map[ mapCells[ cellTransform, # ] &, cells ], state ], options ]

mapCells[ cellTransform_, cell_Cell ] :=
  cellTransform[ cell ]

texToBoxes[ tex_String ] :=
  Replace[ Quiet @ ToExpression[ tex, TeXForm, HoldComplete ],
    { HoldComplete[ $Failed ] :> presentationBoxes[ tex ],
      HoldComplete[ expression_ ] :> MakeBoxes[ expression, TraditionalForm ],
      _ :> presentationBoxes[ tex ] } ]

presentationBoxes[ tex_String ] :=
  If[ StringContainsQ[ tex, "\\ref" | "\\eqref" | "\\pageref" ],
    $Failed,
    Replace[ Quiet @ Convert`TeX`TeXToBoxes[ tex ],
      { FormBox[ boxes_, TraditionalForm ] :> boxes, _ :> $Failed } ] ]

boxesToTeX[ TemplateBox[ association_Association, "TeXAssistantTemplate", ___ ] ] :=
  association[ "input" ]

boxesToTeX[ boxes_ ] :=
  Quiet @ Check[ Convert`TeX`BoxesToTeX[ boxes ], $Failed ]

inlineMathCell[ tex_String ] :=
  Replace[ texToBoxes[ tex ],
    { $Failed -> "$" <> tex <> "$",
      boxes_ :> Cell[ BoxData[ FormBox[ boxes, TraditionalForm ] ],
        TaggingRules -> <| "MathNotebook" -> <| "SourceTeX" -> tex |> |> ] } ]

splitInlineMath[ text_String ] :=
  StringSplit[ text,
    { Shortest[ "$" ~~ tex__ ~~ "$" ] /; StringFreeQ[ tex, "$" ] :> inlineMathCell[ tex ],
      Shortest[ "\\(" ~~ tex__ ~~ "\\)" ] :> inlineMathCell[ tex ] } ]

alignBoxes[ body_String ] :=
  GridBox[
    Map[ { row } |-> Map[ { chunk } |-> Replace[ texToBoxes[ chunk ], $Failed -> chunk ], StringSplit[ row, "&" ] ],
      StringSplit[ body, "\\\\" ] ],
    GridBoxAlignment -> { "Columns" -> { { Right, Left } } } ]

displayParse[ trimmed_String ] :=
  First[ StringCases[ trimmed,
    { StartOfString ~~ "$$" ~~ body__ ~~ "$$" ~~ EndOfString :> { body, False, "Single" },
      StartOfString ~~ "\\[" ~~ body__ ~~ "\\]" ~~ EndOfString :> { body, False, "Single" },
      StartOfString ~~ "\\begin{equation*}" ~~ body__ ~~ "\\end{equation*}" ~~ EndOfString :> { body, False, "Single" },
      StartOfString ~~ "\\begin{equation}" ~~ body__ ~~ "\\end{equation}" ~~ EndOfString :> { body, True, "Single" },
      StartOfString ~~ "\\begin{align*}" ~~ body__ ~~ "\\end{align*}" ~~ EndOfString :> { body, False, "Align" },
      StartOfString ~~ "\\begin{align}" ~~ body__ ~~ "\\end{align}" ~~ EndOfString :> { body, True, "Align" } } ],
    $Failed ]

displayBodyBoxes[ tex_String ] :=
  First[ StringCases[ StringTrim[ tex ],
    StartOfString ~~ "\\begin{aligned}" ~~ body__ ~~ "\\end{aligned}" ~~ EndOfString :>
      alignBoxes[ StringTrim[ body ] ] ],
    Replace[ texToBoxes[ tex ], $Failed -> tex ] ]

displayTeXQ[ text_String ] :=
  StringMatchQ[ StringTrim[ text ],
    ( "$$" ~~ __ ~~ "$$" ) | ( "\\[" ~~ __ ~~ "\\]" ) | ( "\\begin{equation" ~~ __ ) | ( "\\begin{align" ~~ __ ) ]

displayCell[ original_String ] :=
  Replace[ displayParse[ StringTrim[ original ] ],
    { { body_, numbered_, "Single" } :>
        Replace[ texToBoxes[ StringTrim[ body ] ],
          { $Failed -> $Failed,
            boxes_ :> displayFormulaCell[ boxes, numbered, original ] } ],
      { body_, numbered_, "Align" } :>
        displayFormulaCell[ alignBoxes[ StringTrim[ body ] ], numbered, original ],
      $Failed -> $Failed } ]

displayFormulaCell[ boxes_, numbered_, sourceTeX_String ] :=
  Cell[ BoxData[ FormBox[ boxes, TraditionalForm ] ],
    If[ TrueQ[ numbered ], "DisplayFormulaNumbered", "DisplayFormula" ],
    TaggingRules -> <| "MathNotebook" -> <| "SourceTeX" -> sourceTeX |> |> ]

convertLaTeXCell[ cell : Cell[ text_String, style_String /; StringFreeQ[ style, "Input" | "Code" | "Output" | "Program" | "Message" | "Print" ], options___ ] ] :=
  Which[
    displayTeXQ[ text ],
      Replace[ displayCell[ text ],
        { $Failed -> cell,
          Cell[ content_, newStyle_, tagging___ ] :> Cell[ content, newStyle, tagging, options ] } ],
    StringContainsQ[ text, "$" | "\\(" ],
      Replace[ splitInlineMath[ text ],
        { { unchanged_String } :> cell,
          parts_List :> Cell[ TextData[ parts ], style, options ] } ],
    True,
      cell
  ]

convertLaTeXCell[ Cell[ TextData[ parts_ ], style_String, options___ ] ] :=
  Cell[ TextData[ Flatten @ Map[ Replace[ part_String :> splitInlineMath[ part ] ], Flatten @ { parts } ] ], style, options ]

convertLaTeXCell[ cell_ ] :=
  cell

convertMathCell[ cell : Cell[ _, "DisplayFormula" | "DisplayFormulaNumbered", options___ ] ] :=
  Replace[ displayTeXString[ cell ],
    { $Failed -> cell,
      tex_String :> Cell[ tex, "Text", Sequence @@ retainedCellOptions[ { options } ] ] } ]

convertMathCell[ Cell[ TextData[ parts_ ], style_String, options___ ] ] :=
  Replace[ mergeStrings[ Map[ inlinePartToTeX, Flatten @ { parts } ] ],
    { { text_String } :> Cell[ text, style, options ],
      merged_List :> Cell[ TextData[ merged ], style, options ] } ]

convertMathCell[ cell_ ] :=
  cell

displayTeXString[ cell : Cell[ _, style_String, ___ ] ] :=
  With[ { stored = storedSourceTeX[ cell ] },
    If[ StringQ[ stored ],
      stored,
      Replace[ boxesToTeX @ cellBoxes[ cell ],
        { $Failed -> $Failed,
          tex_String :> If[ style === "DisplayFormulaNumbered",
            "\\begin{equation}\n" <> tex <> "\n\\end{equation}",
            "\\[ " <> tex <> " \\]" ] } ] ]
  ]

inlinePartToTeX[ part : Cell[ BoxData[ FormBox[ boxes_, TraditionalForm ] ], ___ ] ] :=
  Replace[ storedSourceTeX[ part ],
    { tex_String :> "$" <> tex <> "$",
      $Failed :> Replace[ boxesToTeX[ boxes ], { $Failed -> part, tex_String :> "$" <> tex <> "$" } ] } ]

inlinePartToTeX[ part_ ] :=
  part

mergeStrings[ parts_List ] :=
  FixedPoint[ Replace[ { before___, first_String, second_String, after___ } :> { before, first <> second, after } ], parts ]

storedSourceTeX[ Cell[ ___, TaggingRules -> tagging_, ___ ] ] :=
  Lookup[ Association @ Lookup[ Association @ tagging, "MathNotebook", <||> ], "SourceTeX", $Failed ]

storedSourceTeX[ _ ] :=
  $Failed

cellBoxes[ Cell[ BoxData[ FormBox[ boxes_, TraditionalForm ] ], ___ ] ] :=
  boxes

cellBoxes[ Cell[ BoxData[ boxes_ ], ___ ] ] :=
  boxes

retainedCellOptions[ options_List ] :=
  Select[ options, MatchQ[ ( CellID | CellTags | CellLabel ) -> _ ] ]
