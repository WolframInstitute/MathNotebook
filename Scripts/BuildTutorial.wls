repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];
tutorialPath = FileNameJoin[ { repoDirectory, "MathNotebook", "Assets", "MathNotebookTutorial.nb" } ];

placeholder = Cell[ "Content to be written.", "Text" ];
key[ text_String ] := StyleBox[ text, FontWeight -> "Bold" ];
name[ text_String ] := StyleBox[ text, FontSlant -> "Italic" ];

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
  Cell[ TextData[ { key[ "Ctrl+9" ], " inline math in text, ", key[ "Ctrl+0" ], " exits." } ], "Item" ],
  Cell[ TextData[ { key[ "Ctrl+/" ], " fraction, ", key[ "Ctrl+2" ], " square root." } ], "Item" ],
  Cell[ TextData[ { key[ "Ctrl+^" ], " superscript, ", key[ "Ctrl+_" ], " subscript, ", key[ "Ctrl+%" ], " switches between them." } ], "Item" ],
  Cell[ TextData[ { key[ "esc" ], " ", name[ "name" ], " ", key[ "esc" ], " enters symbols: ", name[ "a" ], " \[RightArrow] \[Alpha], ", name[ "el" ], " \[RightArrow] \[Element], ", name[ "->" ], " \[RightArrow] \[Rule]." } ], "Item" ],
  Cell[ TextData[ { key[ "Cmd+Shift+E" ], " shows the cell expression (", key[ "Ctrl+Shift+E" ], " on Windows)." } ], "Item" ],

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
