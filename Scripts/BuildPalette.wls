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

(* An ActionMenu needs its sentence as much as a button does, and Tooltip composes with the
   ActionMenuBox rewrite below because that rewrite matches at any level. *)
menuButton[ label_String, items_List, tooltip_String ] :=
  Tooltip[ ActionMenu[ label, items, Appearance -> "PopupMenu", ImageSize -> $buttonSize ], tooltip ]

sliderRow[ label_String, control_, readout_, tooltip_String ] :=
  Tooltip[
    Row[ {
      Pane[ Style[ label, 10, GrayLevel[ 0.35 ] ], ImageSize -> $sliderLabelSize, Alignment -> { Left, Center } ],
      control,
      Pane[ readout, ImageSize -> $sliderReadoutSize, Alignment -> { Right, Center } ]
    } ],
    tooltip ]

(* The slider reads and writes the focused document's own tagging rules, so it follows whichever
   paper is in front and needs no kernel to display: a three-argument CurrentValue supplies the
   unset document's size as the default, so nothing has to be evaluated to show the control. Only
   the release calls the setter. *)
viewSlider[ label_String, key_String, setter_Symbol, range_List, default_, tooltip_String ] :=
  With[ { path = { TaggingRules, "MathNotebook", key } },
    sliderRow[ label,
      Slider[
        Dynamic[ CurrentValue[ FrontEnd`InputNotebook[ ], path, default ],
          ( Needs[ "WolframInstitute`MathNotebook`" ]; setter[ # ] ) & ],
        range, ImageSize -> $sliderSize, ContinuousAction -> False ],
      Dynamic[ CurrentValue[ FrontEnd`InputNotebook[ ], path, default ] ], tooltip ] ]

staticViewSlider[ label_String, range_List, default_, tooltip_String ] :=
  sliderRow[ label, Slider[ default, range, ImageSize -> $sliderSize ], default, tooltip ]

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
  (* PaletteAndViewUX T6, Pavel's own order: what an author makes, then what points at it, then the
     two per-selection conversions, then how the document looks, then the ways out of it, then the
     things done once. Six groups where there were eight — Stylesheet folded into Document view
     because applying a sheet already clears the view tagging rules and so RESETS both sliders, and
     the two conversion groups merged, having between them lost the LaTeX pair: whole-paper export
     is the route out to LaTeX and per-cell conversion read as a competing one. TagSelectedCell,
     ConvertLaTeXCells and ConvertMathCells stay exported and documented; only their buttons are
     gone, so any of the three is one line here to restore. *)
  { "Blocks", "Blocks", {
    menuButton[ "Insert environment", Map[ environmentItem, $environments ],
      "Inserts an empty theorem-like block after the selected cell. The block numbers itself under the document's stylesheet, and a tag on it can be cited from anywhere in the paper." ],
    kernelButton[ "Proof", WolframInstitute`MathNotebook`InsertEnvironment[ "Proof" ],
      "Inserts a Proof block after the selected cell. It takes no number of its own and ends with the QED square." ],
    kernelButton[ "Equation", WolframInstitute`MathNotebook`InsertEnvironment[ "DisplayFormula" ],
      "Inserts an unnumbered display equation after the selected cell." ],
    kernelButton[ "Equation (n)", WolframInstitute`MathNotebook`InsertEnvironment[ "DisplayFormulaNumbered" ],
      "Inserts a numbered display equation after the selected cell. The number belongs to the document and follows the equation when cells move." ],
    (* T3. Not written at the selection, unlike every other button in this group: an entry belongs
       in the bibliography, so it appends there and starts one under a References heading if the
       notebook has none. *)
    kernelButton[ "Reference", WolframInstitute`MathNotebook`InsertReference[ ],
      "Adds a bibliography entry at the end of the bibliography rather than at the selection, and starts one under a References heading if this notebook has none yet. Type the citation key; Insert citation then offers it." ] } },
  { "Referencing", "Referencing", {
    kernelButton[ "Copy reference", WolframInstitute`MathNotebook`CopyCellReference[ ],
      "Copies a link to the selected cell to the clipboard. Pasted anywhere in the paper it becomes a live cross-reference reading as that cell's own number." ],
    kernelButton[ "Insert citation", WolframInstitute`MathNotebook`InsertCitation[ ],
      "Opens a list of everything this notebook has tagged, literature entries and numbered blocks alike, and inserts a citation to the one you pick. Typing a key it does not have cites that instead." ],
    kernelButton[ "\[UpArrow] Go back", WolframInstitute`MathNotebook`GoBack[ ],
      "Returns to the cell the last hyperlink was followed from." ],
    kernelButton[ "Refresh labels", WolframInstitute`MathNotebook`LabelReferences[ ],
      "Rebuilds the [key] label on every bibliography entry from that cell's tag. Use it after tagging an entry from the Cell menu, which sets the tag and not the label." ],
    menuButton[ "Sort bibliography",
      { "By first use" :> ( Needs[ "WolframInstitute`MathNotebook`" ];
          WolframInstitute`MathNotebook`SortBibliography[ "FirstUse" ] ),
        "By key" :> ( Needs[ "WolframInstitute`MathNotebook`" ];
          WolframInstitute`MathNotebook`SortBibliography[ "Key" ] ),
        "By entry" :> ( Needs[ "WolframInstitute`MathNotebook`" ];
          WolframInstitute`MathNotebook`SortBibliography[ "Entry" ] ),
        Delimiter,
        "Report uncited" :> ( Needs[ "WolframInstitute`MathNotebook`" ];
          WolframInstitute`MathNotebook`SortBibliography[ "Uncited" ] ) },
      "Reorders the bibliography by first citation, by key, or by the entry text, and reports what nothing cites. In a paper whose entries come from a .bib file the order shown here is the notebook's alone: the .bib and its style decide the compiled one." ] } },
  { "Convert", "Selection", {
    kernelButton[ "math \[Rule] MaTeX", WolframInstitute`MathNotebook`ConvertToMaTeX[ ],
      "Renders the selected display equations through real LaTeX, at the size Math size is showing. The result is an image rather than editable math, so render last. Optional: needs MaTeX, a TeX distribution and Ghostscript." ],
    kernelButton[ "MaTeX \[Rule] math", WolframInstitute`MathNotebook`ConvertFromMaTeX[ ],
      "Turns rendered MaTeX images back into editable typeset math, from the LaTeX each of those cells stores." ] } },
  { "View", "Document view", {
    menuButton[ "Apply stylesheet",
      Append[ Map[ stylesheetItem, $styleSheets ],
        "Default" :> Replace[ InputNotebook[ ], {
            notebook_NotebookObject :> SetOptions[ notebook, StyleDefinitions -> "Default.nb", LightDark -> Automatic ],
            _ :> MessageDialog[ "Open a notebook first!" ] } ] ],
      "Retypesets the whole document in a journal's style. Neither the content nor the numbering changes: those belong to the document, and the sheet owns only the typography. Applying a sheet clears the two size overrides below." ],
    dual[ viewSlider[ "Text size", "DocumentFontSize", WolframInstitute`MathNotebook`SetDocumentFontSize,
        $fontSizeRange, $defaultFontSize,
        "Scales the prose of the focused document, on screen and in print alike." ],
      staticViewSlider[ "Text size", $fontSizeRange, $defaultFontSize,
        "Scales the prose of the focused document, on screen and in print alike." ] ],
    dual[ viewSlider[ "Math size", "MathFontSize", WolframInstitute`MathNotebook`SetMathFontSize,
        $fontSizeRange, $defaultFontSize,
        "Scales the display and inline mathematics of the focused document. Inline mathematics is scaled relative to the prose it sits in, so it keeps tracking its own cell." ],
      staticViewSlider[ "Math size", $fontSizeRange, $defaultFontSize,
        "Scales the display and inline mathematics of the focused document. Inline mathematics is scaled relative to the prose it sits in, so it keeps tracking its own cell." ] ],
    kernelButton[ "Reset view", WolframInstitute`MathNotebook`ResetDocumentView[ ],
      "Clears both size overrides and returns the document to its stylesheet's own sizes." ] } },
  { "Document", "Import & Export", {
    kernelButton[ "Import .tex file\[Ellipsis]",
      With[ { directory = Replace[ Quiet @ NotebookDirectory[ InputNotebook[ ] ], Except[ _String ] -> Directory[ ] ] },
        With[ { file = SystemDialogInput[ "FileOpen", directory ] },
          If[ StringQ[ file ], NotebookPut @ WolframInstitute`MathNotebook`ImportLaTeXDocument[ file ] ] ] ],
      "Reads a LaTeX paper into a new notebook: sectioning and theorem environments become styled cells, mathematics is typeset, labels become cell tags, and cross-references and citations become live links. Anything it cannot read is carried verbatim, so exporting returns the source unchanged." ],
    (* T5: the guard has to come before the dialog, or an author with no document open is asked
       where to save and the answer is discarded — the half of the referencing defect that wasted
       the author's typing. *)
    kernelButton[ "Export to .tex\[Ellipsis]",
      Replace[ InputNotebook[ ], {
        notebook_NotebookObject :>
          With[ { default = Replace[ Quiet @ NotebookFileName[ notebook ],
                { name_String :> StringReplace[ name, ".nb" ~~ EndOfString -> ".tex" ], _ :> "paper.tex" } ] },
            With[ { file = SystemDialogInput[ "FileSave", default ] },
              If[ StringQ[ file ], WolframInstitute`MathNotebook`ExportLaTeXDocument[ notebook, file ] ] ] ],
        _ :> MessageDialog[ "Open a notebook first!" ] } ],
      "Writes the whole notebook out as a LaTeX paper. This is the route out to LaTeX; a .tex alone names figure files and a .bib that stay behind, so use Export submission to send the paper anywhere." ],
    (* SubmissionBundle T4. A .tex alone is not a submission: it names figure files and a .bib that
       stay behind in the paper's own directory, so the one-file export compiles nowhere else. This
       button is the whole tree, and it takes a directory where the other two take a file. *)
    kernelButton[ "Export submission\[Ellipsis]",
      Replace[ InputNotebook[ ], {
        notebook_NotebookObject :>
          With[ { directory = SystemDialogInput[ "Directory",
                Replace[ Quiet @ NotebookDirectory[ notebook ], Except[ _String ] -> Directory[ ] ] ] },
            If[ StringQ[ directory ],
              SystemOpen @ Lookup[
                WolframInstitute`MathNotebook`ExportLaTeXBundle[ notebook, directory ], "Directory" ] ] ],
        _ :> MessageDialog[ "Open a notebook first!" ] } ],
      "Writes the whole paper into a directory as an arXiv submission: the .tex beside every figure file and .bib it names, plus the .bbl where a local pdfLaTeX is found, since arXiv runs LaTeX but not BibTeX. No compiled PDF, which arXiv rejects in a source upload. Opens the directory when done and reports anything it could not find." ] } },
  { "Setup", "Setup", {
    kernelButton[ "Install LaTeX fonts", WolframInstitute`MathNotebook`InstallLaTeXFonts[ ],
      "Installs the Latin Modern and TeX Gyre families the stylesheets ask for. Restart the front end afterwards." ],
    kernelButton[ "Install MaTeX", WolframInstitute`MathNotebook`InstallMaTeX[ ],
      "Installs the MaTeX paclet, which renders equations through a real LaTeX. A TeX distribution and Ghostscript must already be on the machine." ],
    kernelButton[ "MaTeX preferences", WolframInstitute`MathNotebook`OpenMaTeXPreferences[ ],
      "Opens MaTeX's own configuration, where the pdfLaTeX and Ghostscript paths are set." ],
    kernelButton[ "Update from cloud", WolframInstitute`MathNotebook`UpdateMathNotebook[ ],
      "Checks the cloud for a newer MathNotebook, installs it if there is one, and reopens this palette." ],
    kernelButton[ "Tutorial", WolframInstitute`MathNotebook`OpenTutorial[ ],
      "Opens the tutorial notebook, which walks through the whole palette on a real paper." ] } }
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
