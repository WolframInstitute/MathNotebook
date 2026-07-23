Package["WolframInstitute`MathNotebook`"]

PackageExport[ConvertToMaTeX]
PackageExport[ConvertFromMaTeX]
PackageExport[InstallMaTeX]

PackageScope["findExecutable"]
PackageScope["mathTeX"]
PackageScope["maTeXCellQ"]
PackageScope["toMaTeXNotebook"]
PackageScope["fromMaTeXNotebook"]

ConvertToMaTeX[] :=
  ConvertToMaTeX[ InputNotebook[] ]

ConvertToMaTeX[ notebook_NotebookObject ] :=
  ( Needs[ "MaTeX`" ]; NotebookPut[ toMaTeXNotebook[ NotebookGet[ notebook ] ], notebook ] )

ConvertFromMaTeX[] :=
  ConvertFromMaTeX[ InputNotebook[] ]

ConvertFromMaTeX[ notebook_NotebookObject ] :=
  NotebookPut[ fromMaTeXNotebook[ NotebookGet[ notebook ] ], notebook ]

InstallMaTeX[] :=
  (
    If[ ! PacletObjectQ @ Quiet @ PacletObject[ "MaTeX" ],
      Replace[ Quiet @ PacletInstall[ "MaTeX" ], _?FailureQ :> PacletInstall[ latestMaTeXReleaseURL[] ] ] ];
    Needs[ "MaTeX`" ];
    MaTeX`ConfigureMaTeX[
      "pdfLaTeX" -> findExecutable[ "pdflatex" ],
      "Ghostscript" -> findExecutable[ "gs" ] ]
  )

toMaTeXNotebook[ Notebook[ cells_List, options___ ] ] :=
  Notebook[ Map[ toMaTeXCell, cells ], options ]

fromMaTeXNotebook[ Notebook[ cells_List, options___ ] ] :=
  Notebook[ Map[ fromMaTeXCell, cells ], options ]

toMaTeXCell[ cell : Cell[ _, style : "DisplayFormula" | "DisplayFormulaNumbered", options___ ] ] :=
  With[ { tex = mathTeX[ cell ] },
    If[ tex === $Failed,
      cell,
      Cell[ BoxData[ ToBoxes @ MaTeX`MaTeX[ tex, "DisplayStyle" -> True, FontSize -> 14 ] ], style,
        Sequence @@ retainedCellOptions[ { options } ],
        TaggingRules -> <| "MathNotebook" -> <| "SourceTeX" -> tex, "MaTeX" -> True |> |> ] ]
  ]

toMaTeXCell[ cell_ ] :=
  cell

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

latestMaTeXReleaseURL[] :=
  First @ Query[ "assets", All, "browser_download_url" ] @
    Import[ "https://api.github.com/repos/szhorvat/MaTeX/releases/latest", "RawJSON" ]

findExecutable[ name_String ] :=
  SelectFirst[
    Append[
      FileNameJoin[ { #, name } ] & /@ { "/usr/local/bin", "/opt/homebrew/bin", "/Library/TeX/texbin", "/usr/bin" },
      StringTrim @ RunProcess[ { "/bin/zsh", "-lc", "which " <> name }, "StandardOutput" ] ],
    FileExistsQ ]
