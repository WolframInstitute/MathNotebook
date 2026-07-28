Package["WolframInstitute`MathNotebook`"]

PackageExport[ConvertLaTeXCells]
PackageExport[ConvertMathCells]

PackageScope["texToBoxes"]
PackageScope["boxesToTeX"]
PackageScope["splitInlineMath"]
PackageScope["splitDisplayMath"]
PackageScope["mergeStrings"]
PackageScope["alignBoxes"]
PackageScope["displayParse"]
PackageScope["displayBodyBoxes"]
PackageScope["storedSourceTeX"]
PackageScope["cellBoxes"]
PackageScope["retainedCellOptions"]
PackageScope["convertLaTeXNotebook"]
PackageScope["convertMathNotebook"]
PackageScope["mapCells"]
PackageScope["convertLaTeXCell"]
PackageScope["convertMathCell"]
PackageScope["convertCells"]
PackageScope["writeCells"]

(* T5: convertCells[ transform, $Failed ] stays unevaluated exactly as the overloads do. *)
ConvertLaTeXCells[] :=
  withInputNotebook[ { notebook } |-> convertCells[ convertLaTeXCell, notebook ] ]

ConvertLaTeXCells[ notebook_NotebookObject ] :=
  NotebookPut[ convertLaTeXNotebook[ NotebookGet[ notebook ] ], notebook ]

ConvertLaTeXCells[ cells : { __CellObject } ] :=
  writeCells[ convertLaTeXCell, cells ]

ConvertMathCells[] :=
  withInputNotebook[ { notebook } |-> convertCells[ convertMathCell, notebook ] ]

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
  Notebook[ Flatten @ Map[ mapCells[ cellTransform, # ] &, cells ], options ]

mapCells[ cellTransform_, Cell[ CellGroupData[ cells_List, state___ ], options___ ] ] :=
  Cell[ CellGroupData[ Flatten @ Map[ mapCells[ cellTransform, # ] &, cells ], state ], options ]

mapCells[ cellTransform_, cell_Cell ] :=
  cellTransform[ cell ]

texToBoxes[ tex_String ] :=
  Replace[ Quiet @ ToExpression[ tex, TeXForm, HoldComplete ],
    { HoldComplete[ $Failed ] :> presentationBoxes[ tex ],
      held : HoldComplete[ expression_ ] /; FreeQ[ held, HoldPattern[ E ] | HoldPattern[ I ] ] :>
        MakeBoxes[ expression, TraditionalForm ],
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

(* The island carries the style "InlineFormula" so that the math font-size control can reach it: an
   unstyled island has nothing for an override to be written on, which is why SetMathFontSize moved
   every display formula and left inline mathematics where it was (PaletteAndViewUX T2). The style is
   not declared by any MathNotebook sheet and does not need to be — it resolves through the chain from
   front-end resources, as 1.05*Inherited, and that *relativity* is the point: measured, an island in a
   Title cell renders at 1649 ink against 420 in a Text cell, so inline mathematics tracks the cell it
   sits in. The control therefore scales the ratio rather than writing an absolute size, which would
   break that tracking — at an absolute 26 the Title island *shrinks* to 1577. The exporters match
   Cell[ BoxData[ ... ], ___ ], so the added style needs no change there. *)
inlineMathCell[ tex_String ] :=
  Replace[ texToBoxes[ tex ],
    { $Failed -> "$" <> tex <> "$",
      boxes_ :> Cell[ BoxData[ FormBox[ boxes, TraditionalForm ] ], "InlineFormula",
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

$displayDelimiters = {
  { "$$", "$$", False, "Single" },
  { "\\[", "\\]", False, "Single" },
  { "\\begin{equation*}", "\\end{equation*}", False, "Single" },
  { "\\begin{equation}", "\\end{equation}", True, "Single" },
  { "\\begin{align*}", "\\end{align*}", False, "Align" },
  { "\\begin{align}", "\\end{align}", True, "Align" } }

displayParse[ trimmed_String ] :=
  First[ StringCases[ trimmed,
    Map[ Apply[ { open, close, numbered, kind } |->
        ( StartOfString ~~ open ~~ Shortest[ body__ ] ~~ close ~~ EndOfString :> { body, numbered, kind } ) ],
      $displayDelimiters ] ],
    $Failed ]

splitDisplayMath[ text_String ] :=
  StringSplit[ text,
    Map[ Apply[ { open, close, numbered, kind } |->
        ( span : ( open ~~ Shortest[ body__ ] ~~ close ) :> displaySpanCell[ span, body, numbered, kind ] ) ],
      $displayDelimiters ] ]

displaySpanCell[ span_String, body_String, numbered_, "Single" ] :=
  Replace[ texToBoxes[ StringTrim[ body ] ],
    { $Failed -> span,
      boxes_ :> displayFormulaCell[ boxes, numbered, span ] } ]

displaySpanCell[ span_String, body_String, numbered_, "Align" ] :=
  displayFormulaCell[ alignBoxes[ StringTrim[ body ] ], numbered, span ]

displayBodyBoxes[ tex_String ] :=
  First[ StringCases[ StringTrim[ tex ],
    StartOfString ~~ "\\begin{aligned}" ~~ body__ ~~ "\\end{aligned}" ~~ EndOfString :>
      alignBoxes[ StringTrim[ body ] ] ],
    Replace[ texToBoxes[ tex ], $Failed -> tex ] ]

displayFormulaCell[ boxes_, numbered_, sourceTeX_String ] :=
  Cell[ BoxData[ FormBox[ boxes, TraditionalForm ] ],
    If[ TrueQ[ numbered ], "DisplayFormulaNumbered", "DisplayFormula" ],
    TaggingRules -> <| "MathNotebook" -> <| "SourceTeX" -> sourceTeX |> |> ]

convertLaTeXCell[ cell : Cell[ text_String, style_String /; StringFreeQ[ style, "Input" | "Code" | "Output" | "Program" | "Message" | "Print" ], options___ ] ] :=
  Replace[
    Replace[ mergeStrings @ splitDisplayMath[ text ],
      { { _String } :> inlineTextCell[ cell, text, style, { options } ],
        parts_List :> MapIndexed[
          { part, position } |-> convertedPartCell[ part, style, If[ position === { 1 }, { options }, { } ] ],
          DeleteCases[ Replace[ parts, chunk_String :> StringTrim[ chunk ], { 1 } ], "" ] ] } ],
    { single_Cell } :> single ]

convertLaTeXCell[ Cell[ TextData[ parts_ ], style_String, options___ ] ] :=
  Cell[ TextData[ Flatten @ Map[ Replace[ part_String :> splitInlineMath[ part ] ], Flatten @ { parts } ] ], style, options ]

convertLaTeXCell[ cell_ ] :=
  cell

inlineTextCell[ cell_Cell, text_String, style_String, options_List ] :=
  If[ StringContainsQ[ text, "$" | "\\(" ],
    Replace[ splitInlineMath[ text ],
      { { _String } :> cell,
        parts_List :> Cell[ TextData[ parts ], style, Sequence @@ options ] } ],
    cell ]

convertedPartCell[ Cell[ content_, displayStyle_String, tagging___ ], _, options_List ] :=
  Cell[ content, displayStyle, tagging, Sequence @@ options ]

convertedPartCell[ text_String, style_String, options_List ] :=
  Replace[ splitInlineMath[ text ],
    { { unchanged_String } :> Cell[ unchanged, style, Sequence @@ options ],
      parts_List :> Cell[ TextData[ parts ], style, Sequence @@ options ] } ]

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

(* The font command is rebuilt from the run itself, not from stored source, so an edit to the
   styled text reaches the .tex. The style name marks \textit; a bare italic — the Format menu's
   own — exports as \emph, the semantic default. Both the StyleBox and the inline-Cell shape of a
   run serialize here, their contents recursing through the same clauses. *)
inlinePartToTeX[ StyleBox[ content_, "TextItalic", ___ ] ] :=
  fontTeX[ "textit", content ]

inlinePartToTeX[ Cell[ TextData[ content_ ], "TextItalic", ___ ] ] :=
  fontTeX[ "textit", content ]

inlinePartToTeX[ StyleBox[ content_, ___, FontWeight -> "Bold", ___ ] ] :=
  fontTeX[ "textbf", content ]

inlinePartToTeX[ Cell[ TextData[ content_ ], ___, FontWeight -> "Bold", ___ ] ] :=
  fontTeX[ "textbf", content ]

inlinePartToTeX[ StyleBox[ content_, ___, FontSlant -> "Italic", ___ ] ] :=
  fontTeX[ "emph", content ]

inlinePartToTeX[ Cell[ TextData[ content_ ], ___, FontSlant -> "Italic", ___ ] ] :=
  fontTeX[ "emph", content ]

inlinePartToTeX[ part_ ] :=
  part

fontTeX[ command_String, content_ ] :=
  "\\" <> command <> "{" <> StringJoin[ inlinePartToTeX /@ Flatten @ { content } ] <> "}"

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
