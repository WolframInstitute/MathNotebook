repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];
styleSheetDirectory = Replace[ Environment[ "MATHNOTEBOOK_STYLESHEETS" ],
  Except[ _String ] :> FileNameJoin[ { repoDirectory, "MathNotebook", "FrontEnd", "StyleSheets", "MathNotebook" } ] ];
tutorialPath = Replace[ Environment[ "MATHNOTEBOOK_TUTORIAL" ],
  Except[ _String ] :> FileNameJoin[ { repoDirectory, "MathNotebook", "Assets", "MathNotebookTutorial.nb" } ] ];

$styleSheets = { "AMSArticle", "ArXivArticle", "SpringerJournal", "RevTeXAPS" };

If[ $CloudBase === None, $CloudBase = "https://www.wolframcloud.com" ];
If[ ! $CloudConnected, CloudConnect[] ];

styleSheet[ name_String ] :=
  Get @ FileNameJoin[ { styleSheetDirectory, name <> ".nb" } ];

selfContained[ Notebook[ cells_List, options___ ], name_String ] :=
  Notebook[ cells, StyleDefinitions -> styleSheet[ name ], LightDark -> "Light",
    Sequence @@ FilterRules[ { options }, Except[ StyleDefinitions | LightDark ] ] ];

latexDirectory = FileNameJoin[ { repoDirectory, "LaTeX" } ];

deploy[ notebook_Notebook, path_String ] :=
  First @ CloudDeploy[ notebook, CloudObject[ path ], Permissions -> "Public" ];

deployFile[ path_String ] :=
  With[ { object = CopyFile[ path, CloudObject[ "MathNotebook/" <> FileNameTake[ path ] ], OverwriteTarget -> True ] },
    SetPermissions[ object, "Public" ];
    First[ object ]
  ];

math[ boxes_ ] := BoxData[ FormBox[ boxes, TraditionalForm ] ];

sampleCells[ name_String ] := {
  Cell[ "A Sample Article", "Title" ],
  Cell[ "MathNotebook", "Author" ],
  Cell[ "Set in the " <> name <> " stylesheet.", "Date" ],
  Cell[ "Every style of the MathNotebook stylesheets appears below, so this page shows what a paper looks like in this template: title block, sectioning, theorem environments numbered per section, displayed equations, and a bibliography.", "Abstract" ],

  Cell[ "Statement", "Section" ],
  Cell[ "A graph is a pair (V, E) with E a set of unordered pairs of distinct elements of V.", "Definition" ],
  Cell[ "The theorem environments share one counter, so this theorem follows the definition above and both reset at the next section.", "Theorem" ],
  Cell[ math @ RowBox[ { SubscriptBox[ "\[Sum]", RowBox[ { "v", "\[Element]", "V" } ] ],
    RowBox[ { "deg", "(", "v", ")" } ], "=", RowBox[ { "2", RowBox[ { "|", "E", "|" } ] } ] } ], "DisplayFormulaNumbered" ],
  Cell[ "Summing degrees counts every edge twice.", "Proof" ],

  Cell[ "Displayed mathematics", "Section" ],
  Cell[ "An unnumbered display, for an aside:", "Text" ],
  Cell[ math @ RowBox[ { "\[Chi]", "(", "G", ")", "\[LessEqual]", RowBox[ { "\[CapitalDelta]", "(", "G", ")" } ], "+", "1" } ], "DisplayFormula" ],
  Cell[ TextData[ { "Inline mathematics sits in text at the surrounding size, as in ", Cell[ math @ SuperscriptBox[ "e", RowBox[ { "\[ImaginaryI]", "\[Pi]" } ] ] ], " = ", Cell[ math @ RowBox[ { "-", "1" } ] ], ", and a numbered display is referenced by the live number the palette copies." } ], "Text" ],
  Cell[ "A numbered display, aligned as an align environment converts:", "Text" ],
  Cell[ math @ GridBox[ { { RowBox[ { "\[PartialD]", "\[Omega]" } ], RowBox[ { "=", "0" } ] }, { RowBox[ { "\[Omega]", "\[Wedge]", "\[Omega]" } ], RowBox[ { "=", RowBox[ { "-", RowBox[ { "\[Omega]", "\[Wedge]", "\[Omega]" } ] } ] } ] } },
    GridBoxAlignment -> { "Columns" -> { { Right, Left } } } ], "DisplayFormulaNumbered" ],

  Cell[ "Subsections", "Section" ],
  Cell[ "A subsection", "Subsection" ],
  Cell[ "Subsection and subsubsection headings are numbered within their parent and reset with it.", "Text" ],
  Cell[ "A subsubsection", "Subsubsection" ],
  Cell[ "Remark, Question, and Observation are set like this one \[LongDash] italic label, upright body.", "Remark" ],

  Cell[ "References", "Section" ],
  Cell[ "Horvat, MaTeX: LaTeX labels in Mathematica, https://github.com/szhorvat/MaTeX", "Reference" ],
  Cell[ "Ollivier, Ricci curvature of Markov chains on metric spaces, https://arxiv.org/abs/0810.5625", "Reference" ]
};

urls = Association @ Map[
  { name } |-> name -> deploy[ selfContained[ Notebook @ sampleCells[ name ], name ], "MathNotebook/Sample-" <> name <> ".nb" ],
  $styleSheets ];

urls[ "Tutorial" ] = deploy[ selfContained[ Get[ tutorialPath ], "AMSArticle" ], "MathNotebook/Tutorial.nb" ];

Scan[ { file } |-> ( urls[ FileNameTake[ file ] ] = deployFile[ file ] ),
  FileNames[ { "*.tex", "*.pdf" }, latexDirectory ] ];

Scan[ Print[ First[ # ], ": ", Last[ # ] ] &, Normal[ urls ] ]
