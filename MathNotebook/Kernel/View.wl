Package["WolframInstitute`MathNotebook`"]

PackageExport[SetDocumentFontSize]
PackageExport[SetMathFontSize]
PackageExport[SetContentWidth]
PackageExport[ResetDocumentView]

PackageScope["$mathStyleNames"]
PackageScope["$viewSettingKeys"]
PackageScope["baseStyleCells"]
PackageScope["baseFontSizes"]
PackageScope["baseCellMargins"]
PackageScope["columnStyleNames"]
PackageScope["contentWidthCells"]
PackageScope["documentFontSizeAnchor"]
PackageScope["mathFontSizeAnchor"]
PackageScope["viewSettings"]
PackageScope["viewStyleSheet"]
PackageScope["parentStyleSheet"]
PackageScope["viewStyleCells"]
PackageScope["mergedStyleCells"]
PackageScope["maTeXFontSize"]
PackageScope["rescaleMaTeXCells"]
PackageScope["resizedMaTeXCell"]

SetDocumentFontSize[ size : _?NumericQ | Automatic ] :=
  SetDocumentFontSize[ InputNotebook[], size ]

SetDocumentFontSize[ notebook_NotebookObject, size : _?NumericQ | Automatic ] :=
  applyViewSettings[ notebook, <| "DocumentFontSize" -> size |> ]

SetMathFontSize[ size : _?NumericQ | Automatic ] :=
  SetMathFontSize[ InputNotebook[], size ]

SetMathFontSize[ notebook_NotebookObject, size : _?NumericQ | Automatic ] :=
  ( applyViewSettings[ notebook, <| "MathFontSize" -> size |> ];
    rescaleMaTeXCells[ notebook ] )

SetContentWidth[ width : _?NumericQ | Automatic ] :=
  SetContentWidth[ InputNotebook[], width ]

(* The width is the fraction of the page the content column occupies, not a point width: the
   Scaled margins it becomes are resolved against PageWidth, so the column follows a window
   resize on screen and the printable width in print. It is rounded so the palette's readout
   shows the slider step rather than its floating point residue. *)
SetContentWidth[ notebook_NotebookObject, width : _?NumericQ | Automatic ] :=
  applyViewSettings[ notebook, <| "ContentWidth" -> Replace[ width, size_?NumericQ :> Round[ size, 0.01 ] ] |> ]

ResetDocumentView[] :=
  ResetDocumentView[ InputNotebook[] ]

ResetDocumentView[ notebook_NotebookObject ] :=
  ( applyViewSettings[ notebook, AssociationMap[ Automatic &, $viewSettingKeys ] ];
    rescaleMaTeXCells[ notebook ] )

$viewSettingKeys = { "DocumentFontSize", "MathFontSize", "ContentWidth" }

$mathStyleNames = { "DisplayFormula", "DisplayFormulaNumbered", "DisplayFormulaEquationNumber" }

applyViewSettings[ notebook_NotebookObject, changes_Association ] :=
  With[ { parent = parentStyleSheet[ notebook ] },
    KeyValueMap[
      { key, value } |-> ( CurrentValue[ notebook, { TaggingRules, "MathNotebook", key } ] = Replace[ value, Automatic -> Inherited ] ),
      changes ];
    With[ { settings = viewSettings[ notebook ] },
      If[ documentTaggingRules[ notebook ] === <||>,
        CurrentValue[ notebook, { TaggingRules, "MathNotebook" } ] = Inherited ];
      SetOptions[ notebook,
        StyleDefinitions -> If[ settings === <||>, parent, viewStyleSheet[ parent, settings ] ] ] ] ]

documentTaggingRules[ notebook_NotebookObject ] :=
  Replace[ CurrentValue[ notebook, { TaggingRules, "MathNotebook" } ], Except[ _Association ] -> <||> ]

viewSettings[ notebook_NotebookObject ] :=
  KeyTake[ documentTaggingRules[ notebook ], $viewSettingKeys ]

(* The private sheet is marked by a hidden style cell so that a sheet the user installed
   themselves is never unwrapped — without a marker a second call would nest the sheets and
   reset could not recover the original. The marker cannot live in the sheet's notebook options:
   the front end drops TaggingRules from a stylesheet notebook whatever shape it is given. *)
parentStyleSheet[ notebook_NotebookObject ] :=
  Replace[ CurrentValue[ notebook, StyleDefinitions ],
    Notebook[ cells_, ___ ] /; ! FreeQ[ cells, StyleData[ $viewStyleSheetMarker ] ] :>
      FirstCase[ cells, Cell[ StyleData[ StyleDefinitions -> parent_ ] ] :> parent ] ]

$viewStyleSheetMarker = "MathNotebookView"

viewStyleSheet[ parent_, settings_Association ] :=
  Notebook[
    Join[
      { Cell[ StyleData[ StyleDefinitions -> parent ] ],
        Cell[ StyleData[ $viewStyleSheetMarker ], StyleMenuListing -> None, MenuSortingValue -> None ] },
      viewStyleCells[ parent, settings ] ],
    StyleDefinitions -> "PrivateStylesheetFormatting.nb" ]

viewStyleCells[ parent_, settings_Association ] :=
  With[ { sizes = baseFontSizes[ parent ] },
    mergedStyleCells @ Join[
      fontSizeCells[ sizes, Complement[ styleFontSizeNames[], $mathStyleNames ],
        Lookup[ settings, "DocumentFontSize", Automatic ], documentFontSizeAnchor[ parent ] ],
      fontSizeCells[ sizes, $mathStyleNames,
        Lookup[ settings, "MathFontSize", Automatic ], mathFontSizeAnchor[ parent ] ],
      contentWidthCells[ parent, Lookup[ settings, "ContentWidth", Automatic ] ] ] ]

(* Of two cells carrying the same StyleData head the front end keeps the first and discards the
   second outright — it does not merge their options. Nearly every style the size control writes
   also gets a margin from the width control, so emitting them as separate cells would let a text
   size silently cancel the column width; one cell per style and environment is the only safe form. *)
mergedStyleCells[ cells_List ] :=
  KeyValueMap[ { style, options } |-> Cell[ style, Sequence @@ options ],
    Merge[ Map[ First[ # ] -> Rest[ List @@ # ] &, cells ], Catenate ] ]

fontSizeCells[ _, _, Automatic, _ ] :=
  { }

(* Both the bare style and its "Printout" variant must be written: LaTeXBase gives every prose
   and math style an explicit printout size, and the environment-specific definition wins across
   the whole chain, so a bare override alone never reaches the PDF. *)
fontSizeCells[ sizes_Association, styles_List, size_, anchor_ ] :=
  Join[
    KeyValueMap[ { style, base } |-> Cell[ StyleData[ style ], FontSize -> Round[ base size / anchor ] ],
      KeyTake[ sizes[ "Screen" ], styles ] ],
    KeyValueMap[ { style, base } |-> Cell[ StyleData[ style, "Printout" ], FontSize -> Round[ base size / anchor ] ],
      KeyTake[ sizes[ "Printout" ], styles ] ] ]

contentWidthCells[ _, Automatic ] :=
  { }

(* A symmetric Scaled inset is what centers the column: the front end resolves Scaled in
   CellMargins against PageWidth, the window width on screen and the printable width in print.
   Each style then keeps its own indent as a point offset added to that inset, which the front end
   resolves too — the section numbers and the theorem and abstract dingbats are drawn in the left
   margin, so one margin pair for every style would let them protrude past the column. The offsets
   are measured from the smallest base margin, so none of them is negative and no dingbat can be
   pushed off the page even at full width. *)
contentWidthCells[ parent_, width_ ] :=
  With[ { margins = baseCellMargins[ parent ] },
    With[ { anchor = MapThread[ Min, Map[ First, Values @ margins ] ],
        inset = Scaled[ N[ ( 1 - width ) / 2 ] ] },
      Catenate @ KeyValueMap[
        { style, base } |-> With[ { value = { inset + First[ base ] - anchor, Last @ base } },
          { Cell[ StyleData[ style ], CellMargins -> value ],
            Cell[ StyleData[ style, "Printout" ], CellMargins -> value ] } ],
        margins ] ] ]

(* The base geometry is read out of the document's own stylesheet chain rather than out of
   LaTeXBase.nb: it is the one channel that resolves the list styles, which no MathNotebook sheet
   declares, and that also fits a document still on Default.nb. Reading from the parent rather than
   from the document keeps a second call from compounding its own override. *)
baseCellMargins[ parent_ ] := baseCellMargins[ parent ] =
  With[ { document = CreateDocument[ { }, Visible -> False, StyleDefinitions -> parent ] },
    With[ { margins = Select[
        AssociationMap[ CurrentValue[ document, { StyleDefinitions, #, CellMargins } ] &, columnStyleNames[] ],
        MatchQ[ { { _?NumericQ, _?NumericQ }, { _?NumericQ, _?NumericQ } } ] ] },
      NotebookClose[ document ];
      margins ] ]

(* The column styles are those the base sheet gives an explicit CellMargins — which leaves out the
   character styles and the equation number, a CellFrameLabels label whose margins sit inside the
   label — plus the list styles, which the templates style but the base sheet leaves to Default.nb. *)
columnStyleNames[] := columnStyleNames[] =
  Join[
    Union @ Cases[ baseStyleCells[],
      Cell[ StyleData[ style_String ] | StyleData[ style_String, StyleDefinitions -> _ ], options___ ] /;
        ! FreeQ[ { options }, CellMargins ] :> style, { 1 } ],
    { "Item", "ItemNumbered", "ItemParagraph" } ]

baseStyleCells[] := baseStyleCells[] =
  First @ Get @ FileNameJoin[ { PacletObject[ "WolframInstitute/MathNotebook" ][ "Location" ],
    "FrontEnd", "StyleSheets", "MathNotebook", "LaTeXBase.nb" } ]

(* The base sizes are read out of the document's own stylesheet chain, for the same reason the
   margins are: it is the only channel that resolves a style whose declaration carries no bare
   FontSize of its own. LaTeXBase declares the theorem environments, Proof and Reference as
   StyleData[ name, StyleDefinitions -> StyleData[ "Text" ] ] with a "Printout" size but no screen
   size, and does not declare the list styles at all — so extracting the sizes from the file left
   those styles with no screen override and they never changed size. { style, "Printout" } in the
   path resolves the print environment through the chain; StyleData[ style, "Printout" ] does not,
   it silently returns the screen value. Non-numeric results are dropped: Default.nb gives the
   equation number a symbolic "-1 + Inherited". *)
baseFontSizes[ parent_ ] := baseFontSizes[ parent ] =
  With[ { document = CreateDocument[ { }, Visible -> False, StyleDefinitions -> parent ] },
    With[ { read = environment |-> Select[
          AssociationMap[
            CurrentValue[ document, { StyleDefinitions, environment[ # ], FontSize } ] &,
            styleFontSizeNames[] ],
          NumericQ ] },
      With[ { sizes = <| "Screen" -> read[ # & ], "Printout" -> read[ { #, "Printout" } & ] |> },
        NotebookClose[ document ];
        sizes ] ] ]

(* The styles to scale are those LaTeXBase gives an explicit FontSize in either environment, plus
   the list styles it leaves to Default.nb. Deriving the list from the file rather than from the
   chain is deliberate: it keeps the character styles — Hyperlink, Citation, URL — out, so an
   inline citation goes on inheriting the size of the cell it sits in instead of being pinned. *)
styleFontSizeNames[] := styleFontSizeNames[] =
  Join[
    Union @ Cases[ baseStyleCells[],
      Cell[ StyleData[ style_String ] | StyleData[ style_String, StyleDefinitions -> _ ] |
          StyleData[ style_String, "Printout" ], options___ ] /;
        ! FreeQ[ { options }, FontSize ] :> style, { 1 } ],
    { "Item", "ItemNumbered", "ItemParagraph" } ]

documentFontSizeAnchor[ parent_ ] :=
  baseFontSizes[ parent ][ "Screen", "Text" ]

mathFontSizeAnchor[ parent_ ] :=
  baseFontSizes[ parent ][ "Screen", "DisplayFormula" ]

(* MaTeX cells are images rendered at a fixed size, so they cannot inherit a style change.
   The TeX survives in TaggingRules, so they are re-rendered at the scaled size instead. *)
maTeXFontSize[ notebook_NotebookObject ] :=
  With[ { anchor = mathFontSizeAnchor @ parentStyleSheet[ notebook ] },
    Round[ $maTeXBaseFontSize Lookup[ viewSettings[ notebook ], "MathFontSize", anchor ] / anchor ] ]

rescaleMaTeXCells[ notebook_NotebookObject ] :=
  With[ { cells = Select[ Cells[ notebook ], maTeXCellQ @ NotebookRead[ # ] & ] },
    If[ cells =!= { },
      Needs[ "MaTeX`" ];
      writeCells[ resizedMaTeXCell[ maTeXFontSize[ notebook ] ], cells ] ] ]

resizedMaTeXCell[ size_ ][ cell : Cell[ _, style_String, options___ ] ] :=
  With[ { tex = storedSourceTeX[ cell ] },
    Cell[ BoxData[ ToBoxes @ MaTeX`MaTeX[ tex, "DisplayStyle" -> True, FontSize -> size ] ], style,
      Sequence @@ retainedCellOptions[ { options } ],
      TaggingRules -> <| "MathNotebook" -> <| "SourceTeX" -> tex, "MaTeX" -> True |> |> ] ]
