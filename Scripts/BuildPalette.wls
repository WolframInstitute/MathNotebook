repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];
palettePath = FileNameJoin[ { repoDirectory, "MathNotebook", "FrontEnd", "Palettes", "MathNotebook.nb" } ];

$environments = { "Theorem", "Lemma", "Proposition", "Corollary", "Conjecture", "Claim",
  "Definition", "Example", "Construction", "Remark", "Question", "Observation" };
(* PlainArticle is not a template — it is Default.nb with the environments added, and it is what an
   imported paper lands on when its \documentclass names no journal. It belongs in the menu so a
   document can be switched back to it after a template has been tried. *)
$styleSheets = { "AMSArticle", "ArXivArticle", "SpringerJournal", "RevTeXAPS", "ComplexSystems", "PlainArticle" };
$buttonSize = { 200, 27 };
$labelSize = { 182, 20 };
$fontSizeRange = { 8, 28, 1 };
$sliderLabelSize = { 72, 20 };
$sliderSize = { 92, 18 };
$sliderReadoutSize = { 34, 20 };

(* The neutral slider position is the base sheet's own Text size, so the sliders and
   SetDocumentFontSize agree on what "unchanged" means. *)
$defaultFontSize = FirstCase[
  Get @ FileNameJoin[ { repoDirectory, "MathNotebook", "FrontEnd", "StyleSheets", "MathNotebook", "LaTeXBase.nb" } ],
  Cell[ StyleData[ "Text" ], ___, FontSize -> size_, ___ ] :> size, 13, Infinity ];

SetAttributes[ kernelButton, HoldRest ]
kernelButton[ label_, code_ ] :=
  Button[ label, Needs[ "WolframInstitute`MathNotebook`" ]; code,
    Method -> "Queued", Appearance -> "Palette", ImageSize -> $buttonSize ]

(* The conversion buttons are named by their verb alone and take their direction from the group
   heading, so each one carries the sentence that says what it does to the selection. *)
kernelButton[ label_, code_, tooltip_String ] :=
  Tooltip[ kernelButton[ label, code ], tooltip ]

(* Applying a stylesheet replaces the private sheet the view controls install, so the stored
   sizes have to go with it or the sliders would report a size the document no longer has.

   BasicFunctionality T5: with no document open SetOptions[ $Failed, ... ] does nothing and says
   nothing, the palette's own half of the hole the seven kernel entry points had. The guard cannot
   call the paclet's withInputNotebook — that is a PackageScope symbol, and a button's code is stored
   verbatim, so it may hold nothing but System` symbols and fully qualified public ones — so the
   Replace is written out here and lands in the .nb literally. *)
stylesheetItem[ name_String ] :=
  With[ { file = name <> ".nb" },
    name :> Replace[ InputNotebook[], {
      notebook_NotebookObject :> ( SetOptions[ notebook,
          StyleDefinitions -> FrontEnd`FileName[ { "MathNotebook" }, file, CharacterEncoding -> "UTF-8" ],
          LightDark -> "Light" ];
        CurrentValue[ notebook, { TaggingRules, "MathNotebook" } ] = Inherited ),
      _ :> MessageDialog[ "Open a notebook first!" ] } ] ]

environmentItem[ environment_String ] :=
  environment :> ( Needs[ "WolframInstitute`MathNotebook`" ];
    WolframInstitute`MathNotebook`InsertEnvironment[ environment ] )

sectionLabel[ text_String, level_ : GrayLevel[ 0.4 ] ] :=
  Style[ text, 11, Bold, level ]

(* The front end persists a palette's own TaggingRules under
   CurrentValue[ $FrontEnd, PalettesMenuSettings ] keyed by palette file name, so state
   written on EvaluationNotebook[] survives a front end restart despite Saveable -> False. *)
groupStatePath[ key_String ] :=
  { TaggingRules, key <> "Open" }

groupLabel[ text_String ] :=
  Pane[ Mouseover[ sectionLabel[ text ], sectionLabel[ text, GrayLevel[ 0.15 ] ] ],
    ImageSize -> $labelSize, Alignment -> { Left, Center } ]

clickableLabel[ text_String, path_List, target : True | False ] :=
  EventHandler[ groupLabel[ text ],
    { "MouseClicked" :> ( CurrentValue[ EvaluationNotebook[ ], path, True ] = target ) },
    Method -> "Preemptive" ]

paletteGroup[ { key_String, label_String, buttons_List } ] :=
  With[ { path = groupStatePath[ key ] },
    Column[ {
      Row[ { Opener[ Dynamic[ CurrentValue[ EvaluationNotebook[ ], path, True ] ] ],
        PaneSelector[
          { True -> clickableLabel[ label, path, False ],
            False -> clickableLabel[ label, path, True ] },
          Dynamic[ CurrentValue[ EvaluationNotebook[ ], path, True ] ], ImageSize -> Automatic ] } ],
      PaneSelector[ { True -> Column[ Map[ liveItem, buttons ], Spacings -> 0 ], False -> Spacer[ 0 ] },
        Dynamic[ CurrentValue[ EvaluationNotebook[ ], path, True ] ], ImageSize -> Automatic ]
    }, Spacings -> 0 ] ]

sliderRow[ label_String, control_, readout_ ] :=
  Row[ {
    Pane[ Style[ label, 10, GrayLevel[ 0.35 ] ], ImageSize -> $sliderLabelSize, Alignment -> { Left, Center } ],
    control,
    Pane[ readout, ImageSize -> $sliderReadoutSize, Alignment -> { Right, Center } ]
  } ]

(* The slider reads and writes the focused document's own tagging rules, so it follows whichever
   paper is in front and needs no kernel to display: a three-argument CurrentValue supplies the
   unset document's size as the default, so nothing has to be evaluated to show the control. Only
   the release calls the setter. *)
viewSlider[ label_String, key_String, setter_Symbol, range_List, default_ ] :=
  With[ { path = { TaggingRules, "MathNotebook", key } },
    sliderRow[ label,
      Slider[
        Dynamic[ CurrentValue[ FrontEnd`InputNotebook[ ], path, default ],
          ( Needs[ "WolframInstitute`MathNotebook`" ]; setter[ # ] ) & ],
        range, ImageSize -> $sliderSize, ContinuousAction -> False ],
      Dynamic[ CurrentValue[ FrontEnd`InputNotebook[ ], path, default ] ] ] ]

staticViewSlider[ label_String, range_List, default_ ] :=
  sliderRow[ label, Slider[ default, range, ImageSize -> $sliderSize ], default ]

(* Rasterize leaves a Dynamic unevaluated, so the screenshot needs a static stand-in for every
   dynamic item; dual pairs the live rendition with it. *)
SetAttributes[ dual, HoldAll ]

liveItem[ dual[ live_, _ ] ] := live
liveItem[ item_ ] := item

staticItem[ dual[ _, static_ ] ] := static
staticItem[ item_ ] := item

staticGroup[ { key_String, label_String, buttons_List } ] :=
  Column[ {
    Row[ { Opener[ True ], groupLabel[ label ] } ],
    Column[ Map[ staticItem, buttons ], Spacings -> 0 ]
  }, Spacings -> 0 ]

$groups = {
  { "Referencing", "Referencing", {
    kernelButton[ "Copy reference", WolframInstitute`MathNotebook`CopyCellReference[] ],
    kernelButton[ "Tag cell", WolframInstitute`MathNotebook`TagSelectedCell[] ],
    kernelButton[ "Insert citation", WolframInstitute`MathNotebook`InsertCitation[] ],
    kernelButton[ "\[UpArrow] Go back", WolframInstitute`MathNotebook`GoBack[] ] } },
  (* Pavel rejected "Environments" as the heading (2026-07-29) and asked for something like "Blocks".
     The first element is the fold-state key, renamed with it: the state lives in the front end's
     init.m under a flat key, so the group opens in its default state once for anyone who had folded
     it, which is cosmetic. The "Insert environment" button below keeps its own label — he named the
     group, not the button, and the LaTeX word is the right one for what that menu inserts. *)
  { "Blocks", "Blocks", {
    ActionMenu[ "Insert environment", Map[ environmentItem, $environments ],
      Appearance -> "PopupMenu", ImageSize -> $buttonSize ],
    kernelButton[ "Proof", WolframInstitute`MathNotebook`InsertEnvironment[ "Proof" ] ],
    kernelButton[ "Equation", WolframInstitute`MathNotebook`InsertEnvironment[ "DisplayFormula" ] ],
    kernelButton[ "Equation (n)", WolframInstitute`MathNotebook`InsertEnvironment[ "DisplayFormulaNumbered" ] ] } },
  { "Stylesheet", "Stylesheet", {
    ActionMenu[ "Apply stylesheet",
      Append[ Map[ stylesheetItem, $styleSheets ],
        "Default" :> Replace[ InputNotebook[], {
            notebook_NotebookObject :> SetOptions[ notebook, StyleDefinitions -> "Default.nb", LightDark -> Automatic ],
            _ :> MessageDialog[ "Open a notebook first!" ] } ] ],
      Appearance -> "PopupMenu", ImageSize -> $buttonSize ] } },
  { "View", "Document view", {
    dual[ viewSlider[ "Text size", "DocumentFontSize", WolframInstitute`MathNotebook`SetDocumentFontSize,
        $fontSizeRange, $defaultFontSize ],
      staticViewSlider[ "Text size", $fontSizeRange, $defaultFontSize ] ],
    dual[ viewSlider[ "Math size", "MathFontSize", WolframInstitute`MathNotebook`SetMathFontSize,
        $fontSizeRange, $defaultFontSize ],
      staticViewSlider[ "Math size", $fontSizeRange, $defaultFontSize ] ],
    kernelButton[ "Reset view", WolframInstitute`MathNotebook`ResetDocumentView[] ] } },
  (* Three conversion groups where there were two. The whole-paper route is the one an author
     wants and it had no palette presence at all, which is what made the two per-selection buttons
     look like the only way out to LaTeX; the heading now says which is which, and each button is
     named by its verb alone so no two labels differ by one letter. *)
  { "Document", "Whole paper (LaTeX)", {
    kernelButton[ "Import .tex file\[Ellipsis]",
      With[ { directory = Replace[ Quiet @ NotebookDirectory[ InputNotebook[] ], Except[ _String ] -> Directory[] ] },
        With[ { file = SystemDialogInput[ "FileOpen", directory ] },
          If[ StringQ[ file ], NotebookPut @ WolframInstitute`MathNotebook`ImportLaTeXDocument[ file ] ] ] ],
      "Reads a LaTeX paper into a new notebook: sectioning and theorem environments become styled cells, mathematics is typeset, labels become cell tags, and cross-references and citations become live links. Anything it cannot read is carried verbatim, so exporting returns the source unchanged." ],
    (* T5: the guard has to come before the dialog, or an author with no document open is asked
       where to save and the answer is discarded — the half of the referencing defect that wasted
       the author's typing. *)
    kernelButton[ "Export to .tex\[Ellipsis]",
      Replace[ InputNotebook[], {
        notebook_NotebookObject :>
          With[ { default = Replace[ Quiet @ NotebookFileName[ notebook ],
                { name_String :> StringReplace[ name, ".nb" ~~ EndOfString -> ".tex" ], _ :> "paper.tex" } ] },
            With[ { file = SystemDialogInput[ "FileSave", default ] },
              If[ StringQ[ file ], WolframInstitute`MathNotebook`ExportLaTeXDocument[ notebook, file ] ] ] ],
        _ :> MessageDialog[ "Open a notebook first!" ] } ],
      "Writes the whole notebook out as a LaTeX paper. This is the export route; the selection buttons below only change how a few cells are written and are a convenience beside it." ],
    (* SubmissionBundle T4. A .tex alone is not a submission: it names figure files and a .bib that
       stay behind in the paper's own directory, so the one-file export compiles nowhere else. This
       button is the whole tree, and it takes a directory where the other two take a file. *)
    kernelButton[ "Export submission\[Ellipsis]",
      Replace[ InputNotebook[], {
        notebook_NotebookObject :>
          With[ { directory = SystemDialogInput[ "Directory",
                Replace[ Quiet @ NotebookDirectory[ notebook ], Except[ _String ] -> Directory[] ] ] },
            If[ StringQ[ directory ],
              SystemOpen @ Lookup[
                WolframInstitute`MathNotebook`ExportLaTeXBundle[ notebook, directory ], "Directory" ] ] ],
        _ :> MessageDialog[ "Open a notebook first!" ] } ],
      "Writes the whole paper into a directory as an arXiv submission: the .tex beside every figure file and .bib it names, plus the .bbl where a local pdfLaTeX is found, since arXiv runs LaTeX but not BibTeX. No compiled PDF, which arXiv rejects in a source upload. Opens the directory when done and reports anything it could not find." ] } },
  { "Convert", "Selection: LaTeX \[LeftRightArrow] math", {
    kernelButton[ "Typeset", WolframInstitute`MathNotebook`ConvertLaTeXCells[],
      "Reads the selected cells as LaTeX and replaces the mathematics in them with editable typeset math. With nothing selected, the whole notebook. Input, Code and Output cells are skipped, so a $ in code is safe." ],
    kernelButton[ "Show source", WolframInstitute`MathNotebook`ConvertMathCells[],
      "Turns the typeset mathematics of the selected cells back into LaTeX source, to read or paste elsewhere. With nothing selected, the whole notebook. To write out a paper, use Export to .tex above." ] } },
  { "MaTeX", "Selection: math \[LeftRightArrow] MaTeX", {
    kernelButton[ "Render", WolframInstitute`MathNotebook`ConvertToMaTeX[],
      "Renders the selected display equations through real LaTeX, at the size Math size is showing. The result is an image rather than editable math, so render last. Optional: needs MaTeX, a TeX distribution and Ghostscript." ],
    kernelButton[ "Restore", WolframInstitute`MathNotebook`ConvertFromMaTeX[],
      "Turns rendered MaTeX images back into editable typeset math, from the LaTeX each of those cells stores." ] } },
  { "Setup", "Setup", {
    kernelButton[ "Install LaTeX fonts", WolframInstitute`MathNotebook`InstallLaTeXFonts[] ],
    kernelButton[ "Install MaTeX", WolframInstitute`MathNotebook`InstallMaTeX[] ],
    kernelButton[ "MaTeX preferences", WolframInstitute`MathNotebook`OpenMaTeXPreferences[] ],
    kernelButton[ "Update from cloud", WolframInstitute`MathNotebook`UpdateMathNotebook[] ],
    kernelButton[ "Tutorial", WolframInstitute`MathNotebook`OpenTutorial[] ] } }
};

paletteColumn[ renderer_ ] :=
  Column[ Map[ renderer, $groups ], Spacings -> 0.4 ];

toPaletteBoxes[ expression_ ] :=
  ReplaceAll[ ToBoxes @ expression,
    ActionMenuBox[ label_, items_, options___ ] :>
      ActionMenuBox[ label, items, Evaluator -> Automatic, Method -> "Queued", options ] ]

paletteBoxes = toPaletteBoxes @ paletteColumn[ paletteGroup ];
staticBoxes = toPaletteBoxes @ paletteColumn[ staticGroup ];

paletteNotebook = Notebook[
  { Cell[ BoxData[ paletteBoxes ] ] },
  WindowTitle -> "MathNotebook",
  WindowSize -> { All, All },
  WindowFrame -> "Palette",
  WindowElements -> {},
  WindowFrameElements -> { "CloseBox" },
  WindowFloating -> True,
  Saveable -> False,
  Editable -> False,
  ShowCellBracket -> False,
  StyleDefinitions -> "Palette.nb"
];

imagePath = FileNameJoin[ { repoDirectory, "Images", "Palette.png" } ];

Export[ palettePath, paletteNotebook, "NB" ];
Print[ "Palette written to ", palettePath ];

If[ ! DirectoryQ[ DirectoryName[ imagePath ] ], CreateDirectory[ DirectoryName[ imagePath ] ] ];
Export[ imagePath,
  UsingFrontEnd @ Rasterize[ RawBoxes[ staticBoxes ], "Image", ImageResolution -> 144, LightDark -> "Light" ] ];
Print[ "Palette image written to ", imagePath ]
