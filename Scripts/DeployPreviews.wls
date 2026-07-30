repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];
styleSheetDirectory = Replace[ Environment[ "MATHNOTEBOOK_STYLESHEETS" ],
  Except[ _String ] :> FileNameJoin[ { repoDirectory, "MathNotebook", "FrontEnd", "StyleSheets", "MathNotebook" } ] ];
tutorialPath = Replace[ Environment[ "MATHNOTEBOOK_TUTORIAL" ],
  Except[ _String ] :> FileNameJoin[ { repoDirectory, "MathNotebook", "Assets", "MathNotebookTutorial.nb" } ] ];

(* PlainArticle is deployed like the four journal templates although it imitates no journal: the
   README's stylesheet table lists it as the default an imported paper lands on, so the row needs a
   sample to point at. ComplexSystems has no .tex sample because there is no redistributable class to
   compile against; this one has none because there is nothing for it to imitate. *)
$styleSheets = { "PlainArticle", "AMSArticle", "ArXivArticle", "SpringerJournal", "RevTeXAPS", "ComplexSystems" };

(* The samples' bibliography entries used to carry neither a CellTags nor a dingbat, so every sample
   this script deploys showed unlabelled entries indented into the 185 pt gutter the sheets reserve for
   exactly that label (Pavel's reading, 2026-07-30 — and nothing in the suite reads this script, which
   is why it went unnoticed). The labels are now produced by the paclet's own Refresh labels rather
   than written by hand here, so a sample cannot drift from what the palette does. *)
PacletDirectoryLoad[ FileNameJoin[ { repoDirectory, "MathNotebook" } ] ];
Needs[ "WolframInstitute`MathNotebook`" ];
labelReferences = WolframInstitute`MathNotebook`PackageScope`labelReferenceCells;
citation = WolframInstitute`MathNotebook`PackageScope`citationButton;

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
  Cell[ If[ name === "ComplexSystems", "This template gives every environment its own counter, running straight through the document with no section prefix, which is what the journal prints.", "The theorem environments share one counter, so this theorem follows the definition above and both reset at the next section." ], "Theorem" ],
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

  Cell[ TextData @ { "A citation is the entry's own tag, so it reads exactly as the entry it points at \[LongDash] ",
    citation[ "matex" ], " and ", citation[ "ollivier" ], " below \[LongDash] and clicking it moves there." }, "Text" ],

  Cell[ "References", "Section" ],
  Cell[ "Horvat, MaTeX: LaTeX labels in Mathematica, https://github.com/szhorvat/MaTeX",
    "Reference", CellTags -> "matex" ],
  Cell[ "Ollivier, Ricci curvature of Markov chains on metric spaces, https://arxiv.org/abs/0810.5625",
    "Reference", CellTags -> "ollivier" ]
};

urls = Association @ Map[
  { name } |-> name -> deploy[ selfContained[ labelReferences @ Notebook @ sampleCells[ name ], name ],
    "MathNotebook/Sample-" <> name <> ".nb" ],
  $styleSheets ];

urls[ "Tutorial" ] = deploy[ selfContained[ Get[ tutorialPath ], "AMSArticle" ], "MathNotebook/Tutorial.nb" ];

Scan[ { file } |-> ( urls[ FileNameTake[ file ] ] = deployFile[ file ] ),
  FileNames[ { "*.tex", "*.pdf" }, latexDirectory ] ];

Scan[ Print[ First[ # ], ": ", Last[ # ] ] &, Normal[ urls ] ]
