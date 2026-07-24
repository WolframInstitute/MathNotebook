Package["WolframInstitute`MathNotebook`"]

PackageExport[CopyCellReference]
PackageExport[TagSelectedCell]
PackageExport[GoBack]
PackageExport[InsertEnvironment]
PackageExport[InsertCitation]
PackageExport[$LastHyperlinkCell]

PackageScope["$theoremEnvironments"]
PackageScope["$referenceLabelSpec"]
PackageScope["referenceButton"]

CopyCellReference[] :=
  Replace[ SelectedCells[ InputNotebook[] ], {
    { cell_, ___ } :>
      With[ { style = First @ Flatten @ { CurrentValue[ cell, CellStyle ] } },
        CopyToClipboard @ referenceButton[ CurrentValue[ cell, CellID ], Lookup[ $referenceLabelSpec, style, { "", { style }, "" } ] ]
      ],
    {} :> MessageDialog[ "Select a cell!" ] } ]

TagSelectedCell[] :=
  Replace[ SelectedCells[ InputNotebook[] ], {
    { cell_, ___ } :>
      With[ { tag = InputString[ "Cell tag:" ] },
        If[ StringQ[ tag ], SetOptions[ cell, CellTags -> tag ] ]
      ],
    {} :> MessageDialog[ "Select a cell!" ] } ]

InsertCitation[] :=
  With[ { tag = InputString[ "Citation tag:" ] },
    If[ StringQ[ tag ],
      NotebookWrite[ InputNotebook[], ButtonBox[ "[" <> tag <> "]", BaseStyle -> "Citation", ButtonData -> tag ] ] ]
  ]

GoBack[] :=
  SelectionMove[ $LastHyperlinkCell, All, Cell ]

InsertEnvironment[ style : "DisplayFormula" | "DisplayFormulaNumbered" ] :=
  writeEnvironmentCell[ Cell[ BoxData[ FormBox[ "\[Placeholder]", TraditionalForm ] ], style ] ]

InsertEnvironment[ style_String ] :=
  writeEnvironmentCell[ Cell[ "", style ] ]

$theoremEnvironments = <|
  "Theorem" -> "Plain", "Lemma" -> "Plain", "Proposition" -> "Plain",
  "Corollary" -> "Plain", "Conjecture" -> "Plain", "Claim" -> "Plain",
  "Definition" -> "Definition", "Example" -> "Definition", "Construction" -> "Definition",
  "Remark" -> "Remark", "Question" -> "Remark", "Observation" -> "Remark"
|>

$referenceLabelSpec = Join[
  <|
    "DisplayFormulaNumbered" -> { "(", { "DisplayFormulaNumbered" }, ")" },
    "Section" -> { "Section ", { "Section" }, "" },
    "Subsection" -> { "Section ", { "Section", "Subsection" }, "" },
    "Subsubsection" -> { "Section ", { "Section", "Subsection", "Subsubsection" }, "" },
    "ItemNumbered" -> { "Item ", { "ItemNumbered" }, "" }
  |>,
  AssociationMap[ { # <> " ", { "Section", "Theorem" }, "" } &, Keys[ $theoremEnvironments ] ]
]

referenceButton[ id_Integer, { prefix_, counters_, suffix_ } ] :=
  Button[
    Row @ { prefix,
      Dynamic[ Row[ Riffle[ Map[ CurrentValue[ First[ Cells[ CellID -> id ], $Failed ], { "CounterValue", # } ] &, counters ], "." ] ] ],
      suffix },
    NotebookFind[ InputNotebook[], id, All, CellID ],
    BaseStyle -> "Link", Appearance -> None
  ]

writeEnvironmentCell[ cell_Cell ] :=
  With[ { notebook = InputNotebook[] },
    SelectionMove[ notebook, After, Cell ];
    NotebookWrite[ notebook, cell, All ];
    SelectionMove[ notebook, All, CellContents ]
  ]
