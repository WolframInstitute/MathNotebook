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
PackageScope["withInputNotebook"]

(* InputNotebook[] answers $Failed when no document is open — a palette with no paper beside it,
   which is where a new author starts. SelectedCells[$Failed] then stays unevaluated, so a guard
   written for {} matches neither branch and the Replace hands back its own argument: every entry
   point below did nothing and said nothing, and the two that prompt first discarded the tag the
   author had already typed. So each takes the notebook as an argument — the shape LabelReferences
   already had, and the repo's own "pure cores with thin wrappers" convention — and the argumentless
   form does nothing but resolve it, which is also what makes any of them testable. *)
withInputNotebook[ operation_ ] :=
  Replace[ InputNotebook[], {
    notebook_NotebookObject :> operation[ notebook ],
    _ :> MessageDialog[ "Open a notebook first!" ] } ]

CopyCellReference[] :=
  withInputNotebook[ CopyCellReference ]

CopyCellReference[ notebook_NotebookObject ] :=
  Replace[ SelectedCells[ notebook ], {
    { cell_, ___ } :>
      With[ { style = First @ Flatten @ { CurrentValue[ cell, CellStyle ] } },
        CopyToClipboard @ referenceButton[ CurrentValue[ cell, CellID ], Lookup[ $referenceLabelSpec, style, { "", { style }, "" } ] ]
      ],
    _ :> MessageDialog[ "Select a cell!" ] } ]

TagSelectedCell[] :=
  withInputNotebook[ TagSelectedCell ]

TagSelectedCell[ notebook_NotebookObject ] :=
  Replace[ SelectedCells[ notebook ], {
    { cell_, ___ } :>
      With[ { tag = InputString[ "Cell tag:" ] },
        If[ StringQ[ tag ], TagSelectedCell[ notebook, tag ] ]
      ],
    _ :> MessageDialog[ "Select a cell!" ] } ]

TagSelectedCell[ notebook_NotebookObject, tag_String ] :=
  Replace[ SelectedCells[ notebook ], {
    { cell_, ___ } :> tagCell[ cell, tag ],
    _ :> MessageDialog[ "Select a cell!" ] } ]

InsertCitation[] :=
  withInputNotebook[ InsertCitation ]

InsertCitation[ notebook_NotebookObject ] :=
  With[ { tag = InputString[ "Citation tag:" ] },
    If[ StringQ[ tag ], InsertCitation[ notebook, tag ] ] ]

InsertCitation[ notebook_NotebookObject, tag_String ] :=
  NotebookWrite[ notebook, citationButton[ tag, citationTargetStyle[ notebook, tag ] ] ]

LabelReferences[ notebook_NotebookObject ] :=
  NotebookPut[ labelReferenceCells @ NotebookGet[ notebook ], notebook ]

LabelReferences[] :=
  withInputNotebook[ LabelReferences ]

(* The label is the cell's own first tag, so a bibliography entry reads exactly as the
   citation that points at it, and nothing renumbers when cells move. *)
referenceLabel[ tag_String ] :=
  "[" <> tag <> "]"

citationButton[ tag_String ] :=
  ButtonBox[ referenceLabel[ tag ], BaseStyle -> "Citation", ButtonData -> tag ]

(* A citation to a numbered environment reads as its number. CounterBox[counter, tag] resolves
   against the tagged cell rather than the citation's own position, in the front end and with no
   kernel, so the number follows the target when cells move; an unknown tag renders as XXX.
   referenceButton cannot use it — a CellID is not a tag — hence the two renderings of one spec. *)
citationButton[ tag_String, style_ ] :=
  Replace[ Lookup[ $referenceLabelSpec, style, None ], {
    { prefix_, counters_, suffix_ } :>
      ButtonBox[
        RowBox @ DeleteCases[ Flatten @ { prefix, Riffle[ Map[ CounterBox[ #, tag ] &, counters ], "." ], suffix }, "" ],
        BaseStyle -> "Citation", ButtonData -> tag ],
    _ :> citationButton[ tag ] } ]

citationTargetStyle[ notebook_NotebookObject, tag_String ] :=
  Replace[ Cells[ notebook, CellTags -> tag ], {
    { cell_, ___ } :> First @ Flatten @ { CurrentValue[ cell, CellStyle ] },
    _ :> None } ]

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

(* The same silent no-op as the five above, one state earlier and from the other cause: nothing has
   assigned $LastHyperlinkCell, so SelectionMove[ $LastHyperlinkCell, All, Cell ] stays unevaluated
   and answers itself with no message — measured against the installed 0.1.13. A stale cell is the
   second state and needs its own word: SelectionMove on a CellObject whose cell has been deleted or
   whose notebook has been closed answers Null and does nothing, so a CellObject pattern alone is
   not enough. ParentNotebook is both the liveness test — it answers $Failed for a deleted cell — and
   what T7 needs: a link followed with "OpenInNewWindow" leaves the target in a window of its own, so
   moving the selection without raising the source notebook changes it out of the author's sight. That
   raise has NO headless measurement: SelectedNotebook[] answers $Failed whatever is selected, and so
   does AbsoluteCurrentValue[ notebook, "WindowSelected" ], both measured. So the test asserts the call
   is made and Pavel confirms the effect on a real window. *)
GoBack[] :=
  Replace[ $LastHyperlinkCell, {
    cell_CellObject :>
      Replace[ ParentNotebook[ cell ], {
        notebook_NotebookObject :> ( SetSelectedNotebook[ notebook ]; SelectionMove[ cell, All, Cell ] ),
        _ :> MessageDialog[ "The cell that link was followed from is gone!" ] } ],
    _ :> MessageDialog[ "Follow a hyperlink first!" ] } ]

InsertEnvironment[ style_String ] :=
  withInputNotebook[ InsertEnvironment[ #, style ] & ]

InsertEnvironment[ notebook_NotebookObject, style : "DisplayFormula" | "DisplayFormulaNumbered" ] :=
  writeEnvironmentCell[ notebook, Cell[ BoxData[ FormBox[ "\[Placeholder]", TraditionalForm ] ], style ] ]

InsertEnvironment[ notebook_NotebookObject, style_String ] :=
  writeEnvironmentCell[ notebook, Cell[ "", style ] ]

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
    "ItemNumbered" -> { "Item ", { "ItemNumbered" }, "" },
    "Caption" -> { "Figure ", { "Caption" }, "" }
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

writeEnvironmentCell[ notebook_NotebookObject, cell_Cell ] := (
  SelectionMove[ notebook, After, Cell ];
  NotebookWrite[ notebook, cell, All ];
  SelectionMove[ notebook, All, CellContents ]
)
