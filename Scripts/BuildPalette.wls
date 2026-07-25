repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];
palettePath = FileNameJoin[ { repoDirectory, "MathNotebook", "FrontEnd", "Palettes", "MathNotebook.nb" } ];

$environments = { "Theorem", "Lemma", "Proposition", "Corollary", "Conjecture", "Claim",
  "Definition", "Example", "Construction", "Remark", "Question", "Observation" };
$styleSheets = { "AMSArticle", "ArXivArticle", "SpringerJournal", "RevTeXAPS" };
$buttonSize = { 200, 27 };
$labelSize = { 182, 20 };

SetAttributes[ kernelButton, HoldRest ]
kernelButton[ label_, code_ ] :=
  Button[ label, Needs[ "WolframInstitute`MathNotebook`" ]; code,
    Method -> "Queued", Appearance -> "Palette", ImageSize -> $buttonSize ]

stylesheetItem[ name_String ] :=
  With[ { file = name <> ".nb" },
    name :> SetOptions[ InputNotebook[],
      StyleDefinitions -> FrontEnd`FileName[ { "MathNotebook" }, file, CharacterEncoding -> "UTF-8" ],
      LightDark -> "Light" ] ]

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
      PaneSelector[ { True -> Column[ buttons, Spacings -> 0 ], False -> Spacer[ 0 ] },
        Dynamic[ CurrentValue[ EvaluationNotebook[ ], path, True ] ], ImageSize -> Automatic ]
    }, Spacings -> 0 ] ]

staticGroup[ { key_String, label_String, buttons_List } ] :=
  Column[ {
    Row[ { Opener[ True ], groupLabel[ label ] } ],
    Column[ buttons, Spacings -> 0 ]
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
