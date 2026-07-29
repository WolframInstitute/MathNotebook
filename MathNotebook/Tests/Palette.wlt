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
  Select[ { "Import .tex file\\[Ellipsis]", "Export to .tex\\[Ellipsis]", "Export submission\\[Ellipsis]",
      "Typeset", "Show source", "Render", "Restore" },
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

(* PaletteAndViewUX T1: the other four group headings, which nothing asserted — renaming "Environments"
   to "Blocks" at Pavel's request (2026-07-29) left the whole suite green, so the rename was invisible to
   every test in the repo. The old name is asserted ABSENT rather than only the new one present: a
   heading left behind in a second place would otherwise pass. *)
VerificationTest[
  { Select[ { "Referencing", "Blocks", "Stylesheet", "Setup" },
      ! StringContainsQ[ $paletteSource, # ] & ],
    StringContainsQ[ $paletteSource, "Environments" ] },
  { { }, False }
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
  7
]

(* Seven routes out to LaTeX, seven tooltips, each the sentence for its own button. *)
VerificationTest[
  Select[ { "Reads a LaTeX paper into a new notebook",
      "Writes the whole notebook out as a LaTeX paper",
      "Writes the whole paper into a directory as an arXiv submission",
      "Reads the selected cells as LaTeX",
      "Turns the typeset mathematics of the selected cells back into LaTeX source",
      "Renders the selected display equations through real LaTeX",
      "Turns rendered MaTeX images back into editable typeset math" },
    ! StringContainsQ[ $paletteSource, # ] & ],
  { }
]

(* JournalSubmission T3. A template the palette does not list is a template no author can apply
   from the paclet's own UI: ComplexSystems was generated, tested and shipped in the working tree
   while $styleSheets in BuildPalette.wls still named five sheets, and nothing detected it — the
   stylesheet tests measure the .nb files and never look at the menu. Derive the expected list from
   the shipped sheets rather than writing it out, so a seventh template is caught the same way.
   LaTeXBase is the shared base the five chain from, not a template, and is not offered. *)
VerificationTest[
  Select[
    DeleteCases[
      Map[ FileBaseName,
        FileNames[ "*.nb", FileNameJoin @ {
          DirectoryName @ palettePath @ PacletObject[ "WolframInstitute/MathNotebook" ],
          "..", "StyleSheets", "MathNotebook" } ] ],
      "LaTeXBase" ],
    ! StringContainsQ[ $paletteSource, "\"" <> # <> ".nb\"" ] & ],
  { }
]

(* ImportLaTeXDocument and ExportLaTeXDocument had no palette presence at all, which is what made
   the two per-selection buttons look like the only route out to LaTeX. Each takes a path, so each
   button gets one from a dialog of its own and neither needs a new exported symbol.

   SubmissionBundle T4 adds the third: ExportLaTeXBundle takes a DIRECTORY where the other two take a
   file, so its dialog is a "Directory" one and the count of dialogs is what says all three are wired.
   The bundle button existing is not the same as it being reachable — a generated palette can carry a
   label whose code was never regenerated. *)
VerificationTest[
  { StringContainsQ[ $paletteSource, "MathNotebook`ImportLaTeXDocument" ],
    StringContainsQ[ $paletteSource, "MathNotebook`ExportLaTeXDocument" ],
    StringContainsQ[ $paletteSource, "MathNotebook`ExportLaTeXBundle" ],
    StringCount[ $paletteSource, "SystemDialogInput" ],
    StringCount[ $paletteSource, "SystemDialogInput[\"Directory\"" ] },
  { True, True, True, 3, 1 }
]


(* BasicFunctionality T5: the palette's own half of the $Failed hole. Its stored code cannot call the
   paclet's withInputNotebook — a PackageScope symbol, where a button may hold only System` symbols and
   fully qualified public ones — so the guard is written out by BuildPalette.wls and has to land in the
   artifact nine times: once per stylesheet menu item including Default, and once in each of the two
   export buttons, where it must come BEFORE the dialog or an author with no document is asked where to
   save and the answer is discarded. The two view sliders are guarded the other way, by calling the
   argumentless form the kernel now guards, so no bare two-argument setter may remain. *)
VerificationTest[
  { StringCount[ $paletteSource, "Open a notebook first!" ],
    StringCount[ $paletteSource, "SetDocumentFontSize[#]" ],
    StringCount[ $paletteSource, "SetMathFontSize[#]" ],
    StringContainsQ[ $paletteSource, "SetOptions[InputNotebook[]" ] },
  { 9, 1, 1, False }
]
