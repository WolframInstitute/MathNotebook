repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];
tutorialPath = FileNameJoin[ { repoDirectory, "MathNotebook", "Assets", "MathNotebookTutorial.nb" } ];

placeholder = Cell[ "Content to be written.", "Text" ];

tutorialNotebook = Notebook[ {
  Cell[ "Writing Mathematics in Notebooks", "Title" ],
  Cell[ "MathNotebook Tutorial", "Author" ],
  Cell[ "How to write a mathematics paper in a Wolfram notebook: referencing, journal stylesheets, LaTeX conversion, and MaTeX rendering.", "Abstract" ],

  Cell[ "Getting Started", "Section" ],
  placeholder,

  Cell[ "Referencing", "Section" ],
  placeholder,

  Cell[ "Stylesheets", "Section" ],
  placeholder,

  Cell[ "Math Input Shortcuts", "Section" ],
  Cell[ "Ctrl+9 starts an inline math cell inside a text cell; Ctrl+0 exits it.", "Item" ],
  Cell[ "Ctrl+/ fraction, Ctrl+^ superscript, Ctrl+_ subscript, Ctrl+2 square root.", "Item" ],
  Cell[ "Esc-name-Esc enters symbols: esc a esc gives \[Alpha], esc el esc gives \[Element], esc -> esc gives \[Rule].", "Item" ],
  Cell[ "Cmd+Shift+E toggles the underlying cell expression (Ctrl+Shift+E on Windows and Linux).", "Item" ],
  placeholder,

  Cell[ "LaTeX Conversion", "Section" ],
  placeholder,

  Cell[ "MaTeX", "Section" ],
  placeholder,

  Cell[ "Best Practices", "Section" ],
  placeholder
  },
  StyleDefinitions -> FrontEnd`FileName[ { "MathNotebook" }, "AMSArticle.nb", CharacterEncoding -> "UTF-8" ],
  LightDark -> "Light"
];

Export[ tutorialPath, tutorialNotebook, "NB" ];
Print[ "Tutorial written to ", tutorialPath ]
