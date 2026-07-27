Package["WolframInstitute`MathNotebook`"]

PackageExport[SetDocumentFontSize]
PackageExport[SetMathFontSize]
PackageExport[ResetDocumentView]

PackageScope["$mathStyleNames"]
PackageScope["$viewSettingKeys"]
PackageScope["baseStyleCells"]
PackageScope["baseFontSizes"]
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

ResetDocumentView[] :=
  ResetDocumentView[ InputNotebook[] ]

ResetDocumentView[ notebook_NotebookObject ] :=
  ( applyViewSettings[ notebook, AssociationMap[ Automatic &, Join[ $viewSettingKeys, $obsoleteViewSettingKeys ] ] ];
    rescaleMaTeXCells[ notebook ] )

$viewSettingKeys = { "DocumentFontSize", "MathFontSize" }

(* A content-width control shipped in 0.1.5 through 0.1.7 and was then withdrawn. Its key is still
   cleared on reset so that a document written with one of those versions is left with no trace of
   it; nothing else reads the key, and the private sheet is rebuilt whole on every call, so a
   leftover value cannot affect a document's layout. *)
$obsoleteViewSettingKeys = { "ContentWidth" }

$mathStyleNames = { "DisplayFormula", "DisplayFormulaNumbered", "DisplayFormulaEquationNumber" }

applyViewSettings[ notebook_NotebookObject, changes_Association ] :=
  With[ { parent = parentStyleSheet[ notebook ] },
    KeyValueMap[
      { key, value } |-> ( CurrentValue[ notebook, { TaggingRules, "MathNotebook", key } ] = Replace[ value, Automatic -> Inherited ] ),
      changes ];
    (* The bare parent goes back on first, unconditionally: a second call has to override the
       document's real stylesheet rather than nest inside the private sheet the first one left. *)
    SetOptions[ notebook, StyleDefinitions -> parent ];
    With[ { settings = viewSettings[ notebook ] },
      If[ documentTaggingRules[ notebook ] === <||>,
        CurrentValue[ notebook, { TaggingRules, "MathNotebook" } ] = Inherited ];
      If[ settings =!= <||>,
        SetOptions[ notebook, StyleDefinitions -> viewStyleSheet[ parent, settings ] ] ] ] ]

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
        Lookup[ settings, "MathFontSize", Automatic ], mathFontSizeAnchor[ parent ] ] ] ]

(* Of two cells carrying the same StyleData head the front end keeps the first and discards the
   second outright — it does not merge their options. The prose and mathematics controls overlap on
   no style today, but they are generated independently and merging is what makes that safe. *)
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
   The TeX survives in TaggingRules, so they are re-rendered at the scaled size instead. The size
   is scaled from the base one by the ratio the math control is holding, so an untouched document
   gives back $maTeXBaseFontSize exactly. ConvertToMaTeX reads it too, which is what makes a newly
   converted cell the same size as one the slider has already been over; the pure two-argument form
   is what lets that be asserted without a front end. *)
maTeXFontSize[ notebook_NotebookObject ] :=
  maTeXFontSize[ parentStyleSheet[ notebook ], viewSettings[ notebook ] ]

maTeXFontSize[ parent_, settings_Association ] :=
  With[ { anchor = mathFontSizeAnchor[ parent ] },
    Round[ $maTeXBaseFontSize Lookup[ settings, "MathFontSize", anchor ] / anchor ] ]

rescaleMaTeXCells[ notebook_NotebookObject ] :=
  With[ { cells = Select[ Cells[ notebook ], maTeXCellQ @ NotebookRead[ # ] & ] },
    If[ cells =!= { },
      Needs[ "MaTeX`" ];
      writeCells[ resizedMaTeXCell[ maTeXFontSize[ notebook ] ], cells ] ] ]

resizedMaTeXCell[ size_ ][ cell : Cell[ _, style_String, options___ ] ] :=
  maTeXCell[ storedSourceTeX[ cell ], style, { options }, size ]
