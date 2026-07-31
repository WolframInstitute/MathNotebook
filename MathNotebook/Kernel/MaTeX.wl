Package["WolframInstitute`MathNotebook`"]

PackageExport[ConvertToMaTeX]
PackageExport[ConvertFromMaTeX]
PackageExport[ConvertLaTeXToMaTeX]
PackageExport[ConvertMaTeXToLaTeX]
PackageExport[InstallMaTeX]
PackageExport[OpenMaTeXPreferences]

PackageScope["findExecutable"]
PackageScope["executableDirectories"]
PackageScope["mathTeX"]
PackageScope["maTeXCellQ"]
PackageScope["maTeXCell"]
PackageScope["toMaTeXNotebook"]
PackageScope["fromMaTeXNotebook"]
PackageScope["laTeXToMaTeXCell"]
PackageScope["maTeXToLaTeXCell"]
PackageScope["maTeXToLaTeXNotebook"]
PackageScope["laTeXSourceText"]
PackageScope["userInitFile"]
PackageScope["$maTeXPreferences"]
PackageScope["$maTeXBaseFontSize"]

$maTeXBaseFontSize = 14

(* A MaTeX cell is an image, so it cannot inherit a style change and has to be rendered at the size
   the document is showing mathematics at right now. That size is maTeXFontSize, the same function
   SetMathFontSize re-renders through — a conversion and a later slider touch therefore agree, where
   converting at the fixed $maTeXBaseFontSize left every new cell at 14 until the slider was moved. *)
ConvertToMaTeX[] :=
  withInputNotebook[ { notebook } |->
    ( Needs[ "MaTeX`" ]; convertCells[ toMaTeXCell @ maTeXFontSize[ notebook ], notebook ] ) ]

ConvertToMaTeX[ notebook_NotebookObject ] :=
  ( Needs[ "MaTeX`" ];
    NotebookPut[ toMaTeXNotebook[ NotebookGet[ notebook ], maTeXFontSize[ notebook ] ], notebook ] )

ConvertToMaTeX[ cells : { __CellObject } ] :=
  ( Needs[ "MaTeX`" ];
    writeCells[ toMaTeXCell @ maTeXFontSize @ ParentNotebook @ First[ cells ], cells ] )

ConvertFromMaTeX[] :=
  withInputNotebook[ { notebook } |-> convertCells[ fromMaTeXCell, notebook ] ]

ConvertFromMaTeX[ notebook_NotebookObject ] :=
  NotebookPut[ fromMaTeXNotebook[ NotebookGet[ notebook ] ], notebook ]

ConvertFromMaTeX[ cells : { __CellObject } ] :=
  writeCells[ fromMaTeXCell, cells ]

(* The other pair's diagonal: the LaTeX an author typed as text, rendered in one step. Where
   ConvertToMaTeX reads a typeset cell, this reads the cell's own string — its display delimiters if
   it carries any, all of it if it carries none — so a cell holding a bare \frac{a}{b} renders as
   readily as one holding $$ ... $$. The source is stored verbatim beside the body MaTeX is given,
   which is what lets the trip back give what was typed rather than a re-delimited paraphrase.

   An empty selection converts nothing here, alone among the conversions in this file: every other
   one touches only cells of a math style, where this one would render every prose cell in the paper. *)
ConvertLaTeXToMaTeX[] :=
  withInputNotebook[ { notebook } |->
    ( Needs[ "MaTeX`" ]; convertSelectedCells[ laTeXToMaTeXCell @ maTeXFontSize[ notebook ], notebook ] ) ]

ConvertLaTeXToMaTeX[ cells : { __CellObject } ] :=
  ( Needs[ "MaTeX`" ];
    writeCells[ laTeXToMaTeXCell @ maTeXFontSize @ ParentNotebook @ First[ cells ], cells ] )

ConvertMaTeXToLaTeX[] :=
  withInputNotebook[ { notebook } |-> convertCells[ maTeXToLaTeXCell, notebook ] ]

ConvertMaTeXToLaTeX[ notebook_NotebookObject ] :=
  NotebookPut[ maTeXToLaTeXNotebook[ NotebookGet[ notebook ] ], notebook ]

ConvertMaTeXToLaTeX[ cells : { __CellObject } ] :=
  writeCells[ maTeXToLaTeXCell, cells ]

OpenMaTeXPreferences[] :=
  With[ { file = userInitFile[] },
    If[ ! FileExistsQ[ file ],
      CreateDirectory[ DirectoryName[ file ], CreateIntermediateDirectories -> True ];
      Export[ file, $maTeXPreferences, "Text" ] ];
    NotebookOpen[ file ]
  ]

userInitFile[] :=
  FileNameJoin[ { $UserBaseDirectory, "Kernel", "init.m" } ]

InstallMaTeX[] :=
  (
    If[ ! PacletObjectQ @ Quiet @ PacletObject[ "MaTeX" ],
      Replace[ Quiet @ PacletInstall[ "MaTeX" ], _?FailureQ :> PacletInstall[ latestMaTeXReleaseURL[] ] ] ];
    Needs[ "MaTeX`" ];
    MaTeX`ConfigureMaTeX[
      "pdfLaTeX" -> findExecutable[ "pdflatex" ],
      "Ghostscript" -> findExecutable[ "gs" ] ]
  )

toMaTeXNotebook[ notebook_Notebook, size_ ] :=
  mapCells[ toMaTeXCell[ size ], notebook ]

fromMaTeXNotebook[ notebook_Notebook ] :=
  mapCells[ fromMaTeXCell, notebook ]

maTeXToLaTeXNotebook[ notebook_Notebook ] :=
  mapCells[ maTeXToLaTeXCell, notebook ]

toMaTeXCell[ size_ ][ cell : Cell[ _, style : "DisplayFormula" | "DisplayFormulaNumbered", options___ ] ] :=
  With[ { tex = mathTeX[ cell ] },
    If[ tex === $Failed, cell, maTeXCell[ tex, style, { options }, size ] ]
  ]

toMaTeXCell[ size_ ][ cell_ ] :=
  cell

(* The one place a MaTeX cell is built. Converting and re-rendering at a new size differ only in
   where the TeX comes from, and building both here is what keeps them from drifting apart on the
   size — which is exactly how a converted cell came to ignore the document's math size. The fifth
   argument is the author's own source where a cell has one, carried separately from the body MaTeX
   renders because that body is what every later re-render is given. *)
maTeXCell[ tex_String, style_String, options_List, size_ ] :=
  maTeXCell[ tex, style, options, size, None ]

maTeXCell[ tex_String, style_String, options_List, size_, source_ ] :=
  Cell[ BoxData[ ToBoxes @ MaTeX`MaTeX[ tex, "DisplayStyle" -> True, FontSize -> size ] ], style,
    Sequence @@ retainedCellOptions[ options ],
    TaggingRules -> <| "MathNotebook" -> <| "SourceTeX" -> tex, "MaTeX" -> True,
      If[ StringQ[ source ], "LaTeXSource" -> source, Nothing ] |> |> ]

laTeXToMaTeXCell[ size_ ][ Cell[ TextData[ parts : _String | { __String } ], style_String, options___ ] ] :=
  laTeXToMaTeXCell[ size ][ Cell[ StringJoin @ Flatten @ { parts }, style, options ] ]

laTeXToMaTeXCell[ size_ ][ Cell[ text_String, style_String /; StringFreeQ[ style, "Input" | "Code" | "Output" | "Program" | "Message" | "Print" ], options___ ] ] /; StringTrim[ text ] =!= "" :=
  Apply[
    { tex, numbered } |-> maTeXCell[ tex, If[ TrueQ[ numbered ], "DisplayFormulaNumbered", "DisplayFormula" ],
      { options }, size, text ],
    displaySource[ text ] ]

laTeXToMaTeXCell[ _ ][ cell_ ] :=
  cell

maTeXToLaTeXCell[ cell : Cell[ _, style_String, options___ ] ] /; maTeXCellQ[ cell ] :=
  With[ { text = laTeXSourceText[ cell, style ] },
    If[ StringQ[ text ], Cell[ text, "Text", Sequence @@ retainedCellOptions[ { options } ] ], cell ] ]

maTeXToLaTeXCell[ cell_ ] :=
  cell

(* What was typed, where the cell was made from typed LaTeX; the stored body wearing the delimiters
   its style implies, where it was made from typeset mathematics instead and has no source of its own. *)
laTeXSourceText[ cell_Cell, style_String ] :=
  Replace[ storedLaTeXSource[ cell ],
    Except[ _String ] :> Replace[ storedSourceTeX[ cell ], tex_String :> delimitedTeX[ tex, style ] ] ]

delimitedTeX[ tex_String, "DisplayFormulaNumbered" ] :=
  "\\begin{equation}\n" <> tex <> "\n\\end{equation}"

delimitedTeX[ tex_String, _String ] :=
  "\\[ " <> tex <> " \\]"

fromMaTeXCell[ cell : Cell[ _, style_String, options___ ] ] /; maTeXCellQ[ cell ] :=
  With[ { tex = storedSourceTeX[ cell ] },
    Cell[ BoxData[ FormBox[ displayBodyBoxes[ tex ], TraditionalForm ] ], style,
      Sequence @@ retainedCellOptions[ { options } ],
      TaggingRules -> <| "MathNotebook" -> <| "SourceTeX" -> tex |> |> ]
  ]

fromMaTeXCell[ cell_ ] :=
  cell

maTeXCellQ[ Cell[ ___, TaggingRules -> tagging_, ___ ] ] :=
  TrueQ @ Lookup[ Association @ Lookup[ Association @ tagging, "MathNotebook", <||> ], "MaTeX", False ]

maTeXCellQ[ _ ] :=
  False

mathTeX[ cell_Cell ] :=
  With[ { stored = storedSourceTeX[ cell ] },
    If[ StringQ[ stored ], First @ displaySource[ stored ], boxesToTeX @ cellBoxes[ cell ] ]
  ]

$maTeXPreferences = "\
(* ::Package:: *)

(** User initialization file **)

(* MaTeX preferences: preamble, magnification, and the inline-TeX hook.
   The hook is due to Nik Murzin, https://github.com/sw1sh; set $useMaTeXQ = True to enable it,
   so that TeX typed into a notebook renders through LaTeX instead of the built-in parser. *)

Needs[ \"MaTeX`\" ];

$MaTeXPreamble = {
  \"\\\\usepackage{amsfonts}\",
  \"\\\\usepackage{amssymb}\",
  \"\\\\usepackage{mathtools}\",
  \"\\\\usepackage{tikz}\",
  \"\\\\usepackage{tikz-cd}\",
  \"\\\\usetikzlibrary{cd}\"
};

$useMaTeXMag = 2;
$useMaTeXBaselineShift = 0;

InputAssistant`TeXStringToBoxes // Unprotect;
InputAssistant`TeXStringToBoxes[ s_String ] /; TrueQ[ $useMaTeXQ ] :=
  AdjustmentBox[
    ToBoxes @ MaTeX[ s, Magnification -> $useMaTeXMag, \"Preamble\" -> $MaTeXPreamble ],
    BoxBaselineShift -> $useMaTeXBaselineShift
  ];
InputAssistant`TeXStringToBoxes // Protect;

$useMaTeXQ = False;
"

latestMaTeXReleaseURL[] :=
  First @ Query[ "assets", All, "browser_download_url" ] @
    Import[ "https://api.github.com/repos/szhorvat/MaTeX/releases/latest", "RawJSON" ]

findExecutable[ name_String ] :=
  SelectFirst[
    FileNameJoin /@ Tuples[ { executableDirectories[],
      If[ $OperatingSystem === "Windows", { name <> ".exe", name }, { name } ] } ],
    FileExistsQ ]

executableDirectories[] :=
  Join[
    StringSplit[ Environment[ "PATH" ], If[ $OperatingSystem === "Windows", ";", ":" ] ],
    { "/usr/local/bin", "/opt/homebrew/bin", "/Library/TeX/texbin", "/usr/bin" },
    FileNames[ "*", FileNames[ "/usr/local/texlive/*/bin" ] ] ]
