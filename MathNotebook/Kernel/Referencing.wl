Package["WolframInstitute`MathNotebook`"]

PackageExport[CopyCellReference]
PackageExport[TagSelectedCell]
PackageExport[GoBack]
PackageExport[InsertEnvironment]
PackageExport[InsertCitation]
PackageExport[LabelReferences]
PackageExport[$LastHyperlinkCell]

PackageScope["$theoremEnvironments"]
PackageScope["$referenceLabelSpec"]
PackageScope["referenceButton"]
PackageScope["referenceLabel"]
PackageScope["referenceDingbat"]
PackageScope["citationButton"]
PackageScope["labelReferenceCells"]

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
        If[ StringQ[ tag ], tagCell[ cell, tag ] ]
      ],
    {} :> MessageDialog[ "Select a cell!" ] } ]

InsertCitation[] :=
  With[ { tag = InputString[ "Citation tag:" ] },
    If[ StringQ[ tag ], NotebookWrite[ InputNotebook[], citationButton[ tag ] ] ]
  ]

LabelReferences[ notebook_NotebookObject ] :=
  NotebookPut[ labelReferenceCells @ NotebookGet[ notebook ], notebook ]

LabelReferences[] :=
  LabelReferences[ InputNotebook[] ]

(* The label is the cell's own first tag, so a bibliography entry reads exactly as the
   citation that points at it, and nothing renumbers when cells move. *)
referenceLabel[ tag_String ] :=
  "[" <> tag <> "]"

citationButton[ tag_String ] :=
  ButtonBox[ referenceLabel[ tag ], BaseStyle -> "Citation", ButtonData -> tag ]

referenceDingbat[ tags_ ] :=
  Replace[ First[ Flatten @ { tags }, None ],
    { tag_String :> { CellDingbat -> Cell[ TextData[ referenceLabel[ tag ] ] ] }, _ :> { } } ]

tagCell[ cell_CellObject, tag_String ] := (
  SetOptions[ cell, CellTags -> tag ];
  If[ MemberQ[ Flatten @ { CurrentValue[ cell, CellStyle ] }, "Reference" ],
    SetOptions[ cell, referenceDingbat[ tag ] ] ]
)

labelReferenceCells[ notebook_Notebook ] :=
  ReplaceAll[ notebook,
    Cell[ contents_, "Reference", options___ ] :>
      Cell[ contents, "Reference",
        Sequence @@ FilterRules[ { options }, Except[ CellDingbat ] ],
        Sequence @@ referenceDingbat @ Lookup[ { options }, CellTags, { } ] ] ]

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
