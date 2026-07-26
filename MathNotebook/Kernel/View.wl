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
PackageScope["printMagnification"]
PackageScope["printableWidth"]
PackageScope["$fullContentWidth"]
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

SetContentWidth[ width : _?NumericQ | Automatic | Full ] :=
  SetContentWidth[ InputNotebook[], width ]

(* The width is an absolute measure in printer's points, the same number on paper as on screen, and
   the column is centered in the page. Full \[LongDash] which is where the palette's slider tops out, and any
   width at or beyond it \[LongDash] means the unconstrained page, which is what leaving the setting out
   already does, so it is stored as no setting at all rather than as a value of its own. *)
SetContentWidth[ notebook_NotebookObject, width : _?NumericQ | Automatic | Full ] :=
  applyViewSettings[ notebook,
    <| "ContentWidth" -> Replace[ width,
      { Full -> Automatic, size_?NumericQ :> If[ size >= $fullContentWidth, Automatic, Round[ size ] ] } ] |> ]

ResetDocumentView[] :=
  ResetDocumentView[ InputNotebook[] ]

ResetDocumentView[ notebook_NotebookObject ] :=
  ( applyViewSettings[ notebook, AssociationMap[ Automatic &, $viewSettingKeys ] ];
    rescaleMaTeXCells[ notebook ] )

$viewSettingKeys = { "DocumentFontSize", "MathFontSize", "ContentWidth" }

(* The top step of the palette's column-width slider, in points. Kept here rather than in
   Scripts/BuildPalette.wls because the setter is what has to recognise the top of the range as
   Full; the build script names this number too and the two must agree. *)
$fullContentWidth = 500

$mathStyleNames = { "DisplayFormula", "DisplayFormulaNumbered", "DisplayFormulaEquationNumber" }

applyViewSettings[ notebook_NotebookObject, changes_Association ] :=
  With[ { parent = parentStyleSheet[ notebook ] },
    KeyValueMap[
      { key, value } |-> ( CurrentValue[ notebook, { TaggingRules, "MathNotebook", key } ] = Replace[ value, Automatic -> Inherited ] ),
      changes ];
    (* The bare parent goes back on first, unconditionally. The paper geometry the printed column is
       computed from has to be read off the document's real chain: read through a private sheet this
       function installed on an earlier call, PaperSize answers Automatic and every printed margin
       silently comes out of a symbolic width. *)
    SetOptions[ notebook, StyleDefinitions -> parent ];
    With[ { settings = viewSettings[ notebook ], printable = printableWidth[ notebook ] },
      If[ documentTaggingRules[ notebook ] === <||>,
        CurrentValue[ notebook, { TaggingRules, "MathNotebook" } ] = Inherited ];
      If[ settings =!= <||>,
        SetOptions[ notebook, StyleDefinitions -> viewStyleSheet[ parent, printable, settings ] ] ] ] ]

(* The printed column is absolute, so its margins depend on the paper the document is actually set
   to print on \[LongDash] which the stylesheet declares and the user can change \[LongDash] not on the stylesheet alone. *)
printableWidth[ notebook_NotebookObject ] :=
  First @ CurrentValue[ notebook, { PrintingOptions, "PaperSize" } ] -
    Total @ First @ CurrentValue[ notebook, { PrintingOptions, "PrintingMargins" } ]

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

viewStyleSheet[ parent_, printable_, settings_Association ] :=
  Notebook[
    Join[
      { Cell[ StyleData[ StyleDefinitions -> parent ] ],
        Cell[ StyleData[ $viewStyleSheetMarker ], StyleMenuListing -> None, MenuSortingValue -> None ] },
      viewStyleCells[ parent, printable, settings ] ],
    StyleDefinitions -> "PrivateStylesheetFormatting.nb" ]

viewStyleCells[ parent_, printable_, settings_Association ] :=
  With[ { sizes = baseFontSizes[ parent ] },
    mergedStyleCells @ Join[
      fontSizeCells[ sizes, Complement[ styleFontSizeNames[], $mathStyleNames ],
        Lookup[ settings, "DocumentFontSize", Automatic ], documentFontSizeAnchor[ parent ] ],
      fontSizeCells[ sizes, $mathStyleNames,
        Lookup[ settings, "MathFontSize", Automatic ], mathFontSizeAnchor[ parent ] ],
      contentWidthCells[ parent, printable, Lookup[ settings, "ContentWidth", Automatic ] ] ] ]

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

contentWidthCells[ _, _, Automatic | Full ] :=
  { }

contentWidthCells[ _, _, width_?NumericQ ] /; width >= $fullContentWidth :=
  { }

(* The two environments need different arithmetic for the same column, and this is the one place in
   the file where screen and print genuinely diverge.

   On screen the inset is Scaled[ 0.5 ] - width/2: the front end resolves Scaled in CellMargins
   against PageWidth, which on screen is the window, so the two symmetric insets cancel the window
   out and leave a column of exactly width points that stays centered as the window is resized.

   In print that same sum silently resolves the Scaled part against the window rather than the
   paper — a bare Scaled[ f ] does track the paper, but a sum does not — so the printed inset is
   computed as points instead, from the paper the document is set to print on. Cell margins are
   laid out at the "Printout" environment's own magnification and only then put on paper, so the
   point value is divided by it; without that the column comes out at 0.72 of the width asked for.

   It is Text that is centered, and every other style keeps its own indent relative to it: a
   section number and a theorem or abstract dingbat is drawn to the left of its own cell margin, so
   it hangs outside the column exactly as it does in LaTeX. Those offsets are negative, so the
   printed inset is not allowed below the widest of them or a dingbat would fall off the paper. *)
contentWidthCells[ parent_, printable_, width_ ] :=
  With[ { margins = baseCellMargins[ parent ] },
    Join[
      marginCells[ margins[ "Screen" ], Scaled[ 0.5 ] - width / 2, StyleData ],
      marginCells[ margins[ "Printout" ],
        Max[ 0, - Min @ styleOffsets @ margins[ "Printout" ],
          ( printable - width ) / ( 2 printMagnification[ parent ] ) ],
        StyleData[ #, "Printout" ] & ] ] ]

marginCells[ <| |>, _, _ ] :=
  { }

marginCells[ margins_Association, inset_, style_ ] :=
  With[ { offsets = styleOffsets[ margins ] },
    KeyValueMap[
      { name, base } |-> Cell[ style[ name ], CellMargins -> { inset + offsets[ name ], Last @ base } ],
      margins ] ]

styleOffsets[ margins_Association ] :=
  Map[ First[ # ] - First @ margins[ "Text" ] &, margins ]

(* The base geometry is read out of the document's own stylesheet chain rather than out of
   LaTeXBase.nb: it is the one channel that resolves the list styles, which no MathNotebook sheet
   declares, and that also fits a document still on Default.nb. Reading from the parent rather than
   from the document keeps a second call from compounding its own override. Both environments are
   read, as the sizes are: LaTeXBase indents a style differently in print than on screen, and the
   printed inset is added to the printed indent. *)
baseCellMargins[ parent_ ] := baseCellMargins[ parent ] =
  With[ { document = CreateDocument[ { }, Visible -> False, StyleDefinitions -> parent ] },
    With[ { read = environment |-> Select[
          AssociationMap[
            CurrentValue[ document, { StyleDefinitions, environment[ # ], CellMargins } ] &,
            columnStyleNames[] ],
          MatchQ[ { { _?NumericQ, _?NumericQ }, { _?NumericQ, _?NumericQ } } ] ] },
      With[ { margins = <| "Screen" -> read[ # & ], "Printout" -> read[ { #, "Printout" } & ] |> },
        NotebookClose[ document ];
        margins ] ] ]

(* Default.nb gives StyleData[ All, "Printout" ] a Magnification of 0.72, so every length in a
   printout style is laid out at that scale before it reaches the paper. It is not readable as a
   style option — CurrentValue[ nb, { StyleDefinitions, { style, "Printout" }, Magnification } ]
   answers 1 — but a document whose SCREEN environment is "Printout" resolves it on the notebook. *)
printMagnification[ parent_ ] := printMagnification[ parent ] =
  With[ { document = CreateDocument[ { }, Visible -> False, StyleDefinitions -> parent,
      ScreenStyleEnvironment -> "Printout" ] },
    With[ { magnification = AbsoluteCurrentValue[ document, Magnification ] },
      NotebookClose[ document ];
      magnification ] ]

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
