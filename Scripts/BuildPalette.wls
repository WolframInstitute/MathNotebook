repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];
palettePath = FileNameJoin[ { repoDirectory, "MathNotebook", "FrontEnd", "Palettes", "MathNotebook.nb" } ];

$environments = { "Theorem", "Lemma", "Proposition", "Corollary", "Conjecture", "Claim",
  "Definition", "Example", "Construction", "Remark", "Question", "Observation" };
$styleSheets = { "AMSArticle", "ArXivArticle", "SpringerJournal", "RevTeXAPS" };
$buttonSize = { 200, 27 };

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

sectionLabel[ text_String ] :=
  Style[ text, 11, Bold, GrayLevel[ 0.4 ] ]

paletteColumn = Column[ {
    sectionLabel[ "Referencing" ],
    kernelButton[ "Copy reference", WolframInstitute`MathNotebook`CopyCellReference[] ],
    kernelButton[ "Tag cell", WolframInstitute`MathNotebook`TagSelectedCell[] ],
    kernelButton[ "Insert citation", WolframInstitute`MathNotebook`InsertCitation[] ],
    kernelButton[ "\[UpArrow] Go back", WolframInstitute`MathNotebook`GoBack[] ],
    sectionLabel[ "Environments" ],
    ActionMenu[ "Insert environment", Map[ environmentItem, $environments ],
      Appearance -> "PopupMenu", ImageSize -> $buttonSize ],
    kernelButton[ "Proof", WolframInstitute`MathNotebook`InsertEnvironment[ "Proof" ] ],
    kernelButton[ "Equation", WolframInstitute`MathNotebook`InsertEnvironment[ "DisplayFormula" ] ],
    kernelButton[ "Equation (n)", WolframInstitute`MathNotebook`InsertEnvironment[ "DisplayFormulaNumbered" ] ],
    sectionLabel[ "Stylesheet" ],
    ActionMenu[ "Apply stylesheet",
      Append[ Map[ stylesheetItem, $styleSheets ],
        "Default" :> SetOptions[ InputNotebook[], StyleDefinitions -> "Default.nb", LightDark -> Automatic ] ],
      Appearance -> "PopupMenu", ImageSize -> $buttonSize ],
    sectionLabel[ "LaTeX" ],
    kernelButton[ "TeX \[Rule] notebook", WolframInstitute`MathNotebook`ConvertLaTeXCells[] ],
    kernelButton[ "Notebook \[Rule] TeX", WolframInstitute`MathNotebook`ConvertMathCells[] ],
    kernelButton[ "\[Rule] MaTeX", WolframInstitute`MathNotebook`ConvertToMaTeX[] ],
    kernelButton[ "\[LeftArrow] MaTeX", WolframInstitute`MathNotebook`ConvertFromMaTeX[] ],
    sectionLabel[ "Setup" ],
    kernelButton[ "Install MaTeX", WolframInstitute`MathNotebook`InstallMaTeX[] ],
    kernelButton[ "Install LaTeX fonts", WolframInstitute`MathNotebook`InstallLaTeXFonts[] ],
    kernelButton[ "Tutorial", WolframInstitute`MathNotebook`OpenTutorial[] ]
  }, Spacings -> { 0, { 0, { 0.35 }, 0 } } ];

paletteBoxes = ReplaceAll[ ToBoxes @ paletteColumn,
  ActionMenuBox[ label_, items_, options___ ] :>
    ActionMenuBox[ label, items, Evaluator -> Automatic, Method -> "Queued", options ] ];

paletteNotebook = Notebook[
  { Cell[ BoxData[ paletteBoxes ] ] },
  WindowTitle -> "MathNotebook",
  WindowSize -> All,
  WindowFrame -> "Palette",
  WindowElements -> {},
  WindowFrameElements -> { "CloseBox" },
  WindowFloating -> True,
  Saveable -> False,
  Editable -> False,
  ShowCellBracket -> False,
  StyleDefinitions -> "Palette.nb"
];

Export[ palettePath, paletteNotebook, "NB" ];
Print[ "Palette written to ", palettePath ]
