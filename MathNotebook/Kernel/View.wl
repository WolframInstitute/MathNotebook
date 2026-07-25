Package["WolframInstitute`MathNotebook`"]

PackageExport[SetDocumentFontSize]
PackageExport[SetMathFontSize]
PackageExport[ResetDocumentView]

PackageScope["$mathStyleNames"]
PackageScope["$viewSettingKeys"]
PackageScope["baseFontSizes"]
PackageScope["documentFontSizeAnchor"]
PackageScope["mathFontSizeAnchor"]
PackageScope["viewSettings"]
PackageScope["viewStyleSheet"]
PackageScope["parentStyleSheet"]
PackageScope["viewStyleCells"]
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

ResetDocumentView[] :=
  ResetDocumentView[ InputNotebook[] ]

ResetDocumentView[ notebook_NotebookObject ] :=
  ( applyViewSettings[ notebook, AssociationMap[ Automatic &, $viewSettingKeys ] ];
    rescaleMaTeXCells[ notebook ] )

$viewSettingKeys = { "DocumentFontSize", "MathFontSize" }

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
      viewStyleCells[ settings ] ],
    StyleDefinitions -> "PrivateStylesheetFormatting.nb" ]

viewStyleCells[ settings_Association ] :=
  Join[
    fontSizeCells[ Complement[ styleFontSizeNames[], $mathStyleNames ],
      Lookup[ settings, "DocumentFontSize", Automatic ], documentFontSizeAnchor[] ],
    fontSizeCells[ $mathStyleNames,
      Lookup[ settings, "MathFontSize", Automatic ], mathFontSizeAnchor[] ] ]

fontSizeCells[ _, Automatic, _ ] :=
  { }

(* Both the bare style and its "Printout" variant must be written: LaTeXBase gives every prose
   and math style an explicit printout size, and the environment-specific definition wins across
   the whole chain, so a bare override alone never reaches the PDF. *)
fontSizeCells[ styles_List, size_, anchor_ ] :=
  With[ { sizes = baseFontSizes[] },
    Join[
      KeyValueMap[ { style, base } |-> Cell[ StyleData[ style ], FontSize -> Round[ base size / anchor ] ],
        KeyTake[ sizes[ "Screen" ], styles ] ],
      KeyValueMap[ { style, base } |-> Cell[ StyleData[ style, "Printout" ], FontSize -> Round[ base size / anchor ] ],
        KeyTake[ sizes[ "Printout" ], styles ] ] ] ]

(* The size hierarchy is read out of the paclet's own base stylesheet rather than restated here,
   so regenerating the stylesheets keeps the controls in step. *)
baseFontSizes[] := baseFontSizes[] =
  With[ { cells = First @ Get @ FileNameJoin[ { PacletObject[ "WolframInstitute/MathNotebook" ][ "Location" ],
      "FrontEnd", "StyleSheets", "MathNotebook", "LaTeXBase.nb" } ] },
    <|
      "Screen" -> DeleteMissing @ Association @ Cases[ cells,
        Cell[ StyleData[ style_String ] | StyleData[ style_String, StyleDefinitions -> _ ], options___ ] :>
          ( style -> Lookup[ { options }, FontSize ] ), { 1 } ],
      "Printout" -> DeleteMissing @ Association @ Cases[ cells,
        Cell[ StyleData[ style_String, "Printout" ], options___ ] :>
          ( style -> Lookup[ { options }, FontSize ] ), { 1 } ]
    |> ]

styleFontSizeNames[] :=
  Union @@ Map[ Keys, Values @ baseFontSizes[] ]

documentFontSizeAnchor[] :=
  baseFontSizes[][ "Screen", "Text" ]

mathFontSizeAnchor[] :=
  baseFontSizes[][ "Screen", "DisplayFormula" ]

(* MaTeX cells are images rendered at a fixed size, so they cannot inherit a style change.
   The TeX survives in TaggingRules, so they are re-rendered at the scaled size instead. *)
maTeXFontSize[ notebook_NotebookObject ] :=
  Round[ $maTeXBaseFontSize Lookup[ viewSettings[ notebook ], "MathFontSize", mathFontSizeAnchor[] ] / mathFontSizeAnchor[] ]

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
