Package["WolframInstitute`MathNotebook`"]

PackageExport[ConvertToMaTeX]
PackageExport[ConvertFromMaTeX]
PackageExport[InstallMaTeX]
PackageExport[OpenMaTeXPreferences]

PackageScope["findExecutable"]
PackageScope["executableDirectories"]
PackageScope["mathTeX"]
PackageScope["maTeXCellQ"]
PackageScope["maTeXCell"]
PackageScope["toMaTeXNotebook"]
PackageScope["fromMaTeXNotebook"]
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

toMaTeXCell[ size_ ][ cell : Cell[ _, style : "DisplayFormula" | "DisplayFormulaNumbered", options___ ] ] :=
  With[ { tex = mathTeX[ cell ] },
    If[ tex === $Failed, cell, maTeXCell[ tex, style, { options }, size ] ]
  ]

toMaTeXCell[ size_ ][ cell_ ] :=
  cell

(* The one place a MaTeX cell is built. Converting and re-rendering at a new size differ only in
   where the TeX comes from, and building both here is what keeps them from drifting apart on the
   size — which is exactly how a converted cell came to ignore the document's math size. *)
maTeXCell[ tex_String, style_String, options_List, size_ ] :=
  Cell[ BoxData[ ToBoxes @ MaTeX`MaTeX[ tex, "DisplayStyle" -> True, FontSize -> size ] ], style,
    Sequence @@ retainedCellOptions[ options ],
    TaggingRules -> <| "MathNotebook" -> <| "SourceTeX" -> tex, "MaTeX" -> True |> |> ]

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
    If[ StringQ[ stored ],
      Replace[ displayParse[ StringTrim[ stored ] ],
        { { body_, _, "Align" } :> "\\begin{aligned}\n" <> StringTrim[ body ] <> "\n\\end{aligned}",
          { body_, _, _ } :> StringTrim[ body ],
          $Failed -> stored } ],
      boxesToTeX @ cellBoxes[ cell ] ]
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
