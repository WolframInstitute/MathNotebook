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

(* ---------------------------------------------------------------------------------------------
   PaletteAndViewUX T6. Six groups, Pavel's order, reviewed group by group on 2026-07-29.
   --------------------------------------------------------------------------------------------- *)

VerificationTest[
  Select[ { "Insert environment", "Proof", "Equation", "Equation (n)", "Continue block", "Reference",
      "Copy reference", "Insert citation", "\\[UpArrow] Go back", "Refresh labels", "Sort bibliography",
      "math \\[Rule] MaTeX", "MaTeX \\[Rule] math",
      "Apply stylesheet", "Reset view",
      "Import .tex file\\[Ellipsis]", "Export to .tex\\[Ellipsis]", "Export submission\\[Ellipsis]",
      "Install LaTeX fonts", "Install MaTeX", "MaTeX preferences", "Update from cloud", "Tutorial" },
    ! StringContainsQ[ $paletteSource, # ] & ],
  { }
]

(* The three buttons taken off on 2026-07-29. Tag cell because the front end's own Cell Tags menu
   does it; the two per-selection LaTeX conversions because the whole-paper export is the route out
   to LaTeX and these read as a competing one. All three functions remain public — asserted below,
   since "gone from the palette" must not become "gone from the paclet". *)
VerificationTest[
  Select[ { "Tag cell", "Typeset", "Show source" }, buttonQ ],
  { }
]

VerificationTest[
  Map[ Head @ ToExpression[ "WolframInstitute`MathNotebook`" <> # <> "::usage" ] &,
    { "TagSelectedCell", "ConvertLaTeXCells", "ConvertMathCells" } ],
  { String, String, String }
]

(* The headings, and the ORDER of them, which is what he actually asked for: what an author makes,
   then what points at it, then the two per-selection conversions, then how the document looks,
   then the ways out, then the things done once. Order is asserted because a group moved is exactly
   as invisible to a presence test as a group renamed was to the whole suite before T1. *)
VerificationTest[
  Ordering @ Map[ First @ First @ StringPosition[ $paletteSource, "\"" <> # <> "\"" ] &,
    { "Blocks", "Referencing", "Selection", "Document view", "Import & Export", "Setup" } ],
  Range[ 6 ]
]

(* Every heading these replaced, asserted ABSENT — a name left behind in a second place would
   otherwise pass. "Stylesheet" is among them because that group no longer exists: applying a sheet
   already clears the view tagging rules and so resets both sliders, so the menu lives in Document
   view beside the controls it resets. Its own label is "Apply stylesheet", lower case. *)
VerificationTest[
  Select[ { "Environments", "Stylesheet", "Whole paper (LaTeX)",
      "Selection: LaTeX \\[LeftRightArrow] math", "Selection: math \\[LeftRightArrow] MaTeX" },
    StringContainsQ[ $paletteSource, # ] & ],
  { }
]

(* T6 gave a sentence to every button, menu and slider, where before only the seven conversion
   routes had one. The count is the assertion that none was dropped; the sample below is the
   assertion that they say what they should. *)
VerificationTest[
  StringCount[ $paletteSource, "TooltipBox[" ],
  25
]

VerificationTest[
  Select[ { "Reads a LaTeX paper into a new notebook",
      "Writes the whole notebook out as a LaTeX paper",
      "Writes the whole paper into a directory as an arXiv submission",
      "Renders the selected display equations through real LaTeX",
      "Turns rendered MaTeX images back into editable typeset math",
      "Adds a bibliography entry at the end of the bibliography rather than at the selection",
      "Rebuilds the [key] label on every bibliography entry",
      "Reorders the bibliography by first citation",
      "Opens a list of everything this notebook has tagged" },
    ! StringContainsQ[ $paletteSource, # ] & ],
  { }
]

(* The .bib asymmetry is on the palette and not only in CLAUDE.md: an author sorting the
   bibliography of such a paper is told the order shown is the notebook's alone. *)
VerificationTest[
  StringContainsQ[ $paletteSource,
    "the order shown here is the notebook's alone" ],
  True
]

(* T5's four orders are all reachable. *)
VerificationTest[
  Select[ { "By first use", "By key", "By entry", "Report uncited" },
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
   label whose code was never regenerated. T6 adds the same check for the two new symbols. *)
VerificationTest[
  { Select[ { "ImportLaTeXDocument", "ExportLaTeXDocument", "ExportLaTeXBundle",
        "InsertReference", "SortBibliography", "LabelReferences" },
      ! StringContainsQ[ $paletteSource, "MathNotebook`" <> # ] & ],
    StringCount[ $paletteSource, "SystemDialogInput" ],
    StringCount[ $paletteSource, "SystemDialogInput[\"Directory\"" ] },
  { { }, 3, 1 }
]

(* BasicFunctionality T5: the palette's own half of the $Failed hole. Its stored code cannot call the
   paclet's withInputNotebook — a PackageScope symbol, where a button may hold only System` symbols and
   fully qualified public ones — so the guard is written out by BuildPalette.wls and has to land in the
   artifact nine times: once per stylesheet menu item including Default, and once in each of the two
   export buttons, where it must come BEFORE the dialog or an author with no document is asked where to
   save and the answer is discarded. Every other new entry point is guarded the other way, by calling an
   argumentless or one-string form the kernel guards — which is why T5's four sort orders add none. *)
VerificationTest[
  { StringCount[ $paletteSource, "Open a notebook first!" ],
    StringCount[ $paletteSource, "SetDocumentFontSize[#]" ],
    StringCount[ $paletteSource, "SetMathFontSize[#]" ],
    StringContainsQ[ $paletteSource, "SetOptions[InputNotebook[]" ] },
  { 9, 1, 1, False }
]
