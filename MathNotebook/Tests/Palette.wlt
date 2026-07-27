Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

(* ConversionUX T1. The palette is generated, so what an author reads on it is only as good as the
   last run of Scripts/BuildPalette.wls, and a dropped tooltip or a reverted label is invisible
   until someone hovers. Read it as TEXT: a palette .nb must never be read back with Get or Import
   as an expression, since its literal EvaluationNotebook[] calls are then re-evaluated and every
   CurrentValue collapses to its default. The exporter wraps long lines with a trailing backslash
   and escapes the boxes' own strings, so both are undone before anything is matched. *)

$paletteSource = StringDelete[
  Import[ palettePath @ PacletObject[ "WolframInstitute/MathNotebook" ], "Text" ],
  { "\\\n", "\\<", "\\>", "\\\"" } ];

buttonQ[ label_String ] :=
  StringContainsQ[ $paletteSource, "ButtonBox[\"" <> label <> "\"" ];

(* Every conversion is named by its verb alone and takes its direction from the group heading. *)
VerificationTest[
  Select[ { "Import .tex file\\[Ellipsis]", "Export to .tex\\[Ellipsis]", "Typeset", "Show source",
      "Render", "Restore" },
    ! buttonQ[ # ] & ],
  { }
]

(* The defect these replaced: four labels built from three interchangeable words, two of which
   differ by one letter. *)
VerificationTest[
  Select[ { "TeX \\[Rule] math", "Math \\[Rule] TeX", "Math \\[Rule] MaTeX", "MaTeX \\[Rule] math" },
    buttonQ ],
  { }
]

(* A verb alone only reads if the heading says which direction it goes. *)
VerificationTest[
  Select[ { "Whole paper (LaTeX)", "Selection: LaTeX \\[LeftRightArrow] math",
      "Selection: math \\[LeftRightArrow] MaTeX" },
    ! StringContainsQ[ $paletteSource, # ] & ],
  { }
]

VerificationTest[
  StringCount[ $paletteSource, "TooltipBox[" ],
  6
]

(* Six conversions, six tooltips, each the sentence for its own button. *)
VerificationTest[
  Select[ { "Reads a LaTeX paper into a new notebook",
      "Writes the whole notebook out as a LaTeX paper",
      "Reads the selected cells as LaTeX",
      "Turns the typeset mathematics of the selected cells back into LaTeX source",
      "Renders the selected display equations through real LaTeX",
      "Turns rendered MaTeX images back into editable typeset math" },
    ! StringContainsQ[ $paletteSource, # ] & ],
  { }
]

(* ImportLaTeXDocument and ExportLaTeXDocument had no palette presence at all, which is what made
   the two per-selection buttons look like the only route out to LaTeX. Each takes a path, so each
   button gets one from a dialog of its own and neither needs a new exported symbol. *)
VerificationTest[
  { StringContainsQ[ $paletteSource, "MathNotebook`ImportLaTeXDocument" ],
    StringContainsQ[ $paletteSource, "MathNotebook`ExportLaTeXDocument" ],
    StringCount[ $paletteSource, "SystemDialogInput" ] },
  { True, True, 2 }
]
