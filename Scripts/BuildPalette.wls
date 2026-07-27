repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];
palettePath = FileNameJoin[ { repoDirectory, "MathNotebook", "FrontEnd", "Palettes", "MathNotebook.nb" } ];

$environments = { "Theorem", "Lemma", "Proposition", "Corollary", "Conjecture", "Claim",
  "Definition", "Example", "Construction", "Remark", "Question", "Observation" };
(* PlainArticle is not a template — it is Default.nb with the environments added, and it is what an
   imported paper lands on when its \documentclass names no journal. It belongs in the menu so a
   document can be switched back to it after a template has been tried. *)
$styleSheets = { "AMSArticle", "ArXivArticle", "SpringerJournal", "RevTeXAPS", "PlainArticle" };
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

(* Applying a stylesheet replaces the private sheet the view controls install, so the stored
   sizes have to go with it or the sliders would report a size the document no longer has. *)
stylesheetItem[ name_String ] :=
  With[ { file = name <> ".nb" },
    name :> ( SetOptions[ InputNotebook[],
        StyleDefinitions -> FrontEnd`FileName[ { "MathNotebook" }, file, CharacterEncoding -> "UTF-8" ],
        LightDark -> "Light" ];
      CurrentValue[ InputNotebook[], { TaggingRules, "MathNotebook" } ] = Inherited ) ]

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
          ( Needs[ "WolframInstitute`MathNotebook`" ]; setter[ InputNotebook[ ], # ] ) & ],
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
  { "Environments", "Environments", {
    ActionMenu[ "Insert environment", Map[ environmentItem, $environments ],
      Appearance -> "PopupMenu", ImageSize -> $buttonSize ],
    kernelButton[ "Proof", WolframInstitute`MathNotebook`InsertEnvironment[ "Proof" ] ],
    kernelButton[ "Equation", WolframInstitute`MathNotebook`InsertEnvironment[ "DisplayFormula" ] ],
    kernelButton[ "Equation (n)", WolframInstitute`MathNotebook`InsertEnvironment[ "DisplayFormulaNumbered" ] ] } },
  { "Stylesheet", "Stylesheet", {
    ActionMenu[ "Apply stylesheet",
      Append[ Map[ stylesheetItem, $styleSheets ],
        "Default" :> SetOptions[ InputNotebook[], StyleDefinitions -> "Default.nb", LightDark -> Automatic ] ],
      Appearance -> "PopupMenu", ImageSize -> $buttonSize ] } },
  { "View", "Document view", {
    dual[ viewSlider[ "Text size", "DocumentFontSize", WolframInstitute`MathNotebook`SetDocumentFontSize,
        $fontSizeRange, $defaultFontSize ],
      staticViewSlider[ "Text size", $fontSizeRange, $defaultFontSize ] ],
    dual[ viewSlider[ "Math size", "MathFontSize", WolframInstitute`MathNotebook`SetMathFontSize,
        $fontSizeRange, $defaultFontSize ],
      staticViewSlider[ "Math size", $fontSizeRange, $defaultFontSize ] ],
    kernelButton[ "Reset view", WolframInstitute`MathNotebook`ResetDocumentView[] ] } },
  { "Convert", "LaTeX \[LeftRightArrow] math (selection)", {
    kernelButton[ "TeX \[Rule] math", WolframInstitute`MathNotebook`ConvertLaTeXCells[] ],
    kernelButton[ "Math \[Rule] TeX", WolframInstitute`MathNotebook`ConvertMathCells[] ] } },
  { "MaTeX", "MaTeX (optional)", {
    kernelButton[ "Math \[Rule] MaTeX", WolframInstitute`MathNotebook`ConvertToMaTeX[] ],
    kernelButton[ "MaTeX \[Rule] math", WolframInstitute`MathNotebook`ConvertFromMaTeX[] ],
    kernelButton[ "MaTeX preferences", WolframInstitute`MathNotebook`OpenMaTeXPreferences[] ],
    kernelButton[ "Install MaTeX", WolframInstitute`MathNotebook`InstallMaTeX[] ] } },
  { "Setup", "Setup", {
    kernelButton[ "Install LaTeX fonts", WolframInstitute`MathNotebook`InstallLaTeXFonts[] ],
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
