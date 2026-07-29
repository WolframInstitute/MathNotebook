Package["WolframInstitute`MathNotebook`"]

PackageExport[CopyCellReference]
PackageExport[TagSelectedCell]
PackageExport[GoBack]
PackageExport[InsertEnvironment]
PackageExport[InsertCitation]
PackageExport[InsertReference]
PackageExport[SortBibliography]
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
PackageScope["citationChoices"]
PackageScope["citationChooserRows"]

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

(* Choosing the tag instead of typing it, which is T4 and Pavel's "combobox with tags of the
   literature cells". It is a DIALOG and not a control on the palette, deliberately: the palette
   needs no kernel to display — the property the two view sliders were built around — while a live
   tag list can only come from a kernel query on whichever notebook is in front, so a palette-level
   combobox would launch a kernel on every repaint and be stale between them.

   The list is a pure function of the Notebook expression, which is what makes any of this testable
   with no front end; only the panel around it needs a dialog. The filter field doubles as the free
   text entry — a key the document does not carry yet is offered as its own row rather than needing
   a second field, and that row is the reason a citation to a tag with no target cell must keep
   working: citationTargetStyle answers None and the button falls back to referenceLabel's [key]. *)
InsertCitation[ notebook_NotebookObject ] :=
  With[ { tag = chooseCitationTag @ citationChoices @ NotebookGet[ notebook ] },
    If[ StringQ[ tag ] && tag =!= "", InsertCitation[ notebook, tag ] ] ]

(* Literature is what a Reference cell carries and everything else is a block — the split Pavel
   asked for. A cell may carry several tags and each is citable, so all of them are offered; the
   first is only privileged as the entry's printed label. Blocks stay in document order, so
   equations and theorems appear where they occur, and literature is alphabetical. *)
citationChoices[ notebook_ ] :=
  With[ { choices = DeleteDuplicatesBy[
      Flatten @ Map[ citationChoice, Cases[ notebook, Cell[ _, _String, ___ ], Infinity ] ],
      Lookup[ "Tag" ] ] },
    Join[
      SortBy[ Select[ choices, #[ "Group" ] === $literatureGroup & ], Lookup[ "Tag" ] ],
      Select[ choices, #[ "Group" ] =!= $literatureGroup & ] ] ]

$literatureGroup = "Literature"
$blockGroup = "Blocks"

citationChoice[ cell : Cell[ _, style_String, ___ ] ] :=
  Map[ tag |-> <| "Tag" -> tag, "Style" -> style,
      "Group" -> If[ style === "Reference", $literatureGroup, $blockGroup ] |>,
    Cases[ Flatten @ { Cases[ cell, ( CellTags -> tags_ ) :> tags, { 1 } ] }, _String ] ]

citationChoice[ _ ] :=
  { }

chooseCitationTag[ choices_List ] :=
  DialogInput[ citationChooserPanel[ choices ], WindowTitle -> "Insert citation" ]

citationChooserPanel[ choices_List ] :=
  With[ { entries = choices },
    DynamicModule[ { filter = "" },
      Column[ {
        InputField[ Dynamic[ filter ], String, ContinuousAction -> True,
          FieldHint -> "filter, or a new key", ImageSize -> { 300, Automatic } ],
        Pane[ Dynamic @ citationChooserRows[ entries, filter ],
          ImageSize -> { 300, 260 }, Scrollbars -> { False, Automatic } ],
        Item[ CancelButton[ ], Alignment -> Right ]
      }, Spacings -> 0.6 ] ] ]

citationChooserRows[ entries_List, filter_String ] :=
  With[ { matching = Select[ entries, citationChoiceMatchQ[ #, filter ] & ] },
    Column[
      Flatten @ Join[
        Map[ group |-> Prepend[
            Map[ citationChooserRow, Select[ matching, #[ "Group" ] === group & ] ],
            citationChooserHeading[ group ] ],
          Select[ { $literatureGroup, $blockGroup },
            group |-> AnyTrue[ matching, #[ "Group" ] === group & ] ] ],
        citationChooserNewRows[ matching, filter ] ],
      Spacings -> 0.2 ] ]

(* The one row the document cannot supply. It appears only while nothing matches, so a filter that
   is narrowing a real list does not also offer to invent a key from it — and the test for that is
   the MATCHES and not an exact tag comparison, since "eq:" is nobody's tag and everybody's prefix. *)
citationChooserNewRows[ matching_List, filter_String ] :=
  If[ filter === "" || matching =!= { },
    { },
    { citationChooserHeading[ "New key" ],
      citationChooserButton[ referenceLabel[ filter ], "not in this notebook", filter ] } ]

citationChooserHeading[ text_String ] :=
  Style[ text, 10, Bold, GrayLevel[ 0.45 ] ]

citationChooserRow[ choice_Association ] :=
  citationChooserButton[
    If[ choice[ "Group" ] === $literatureGroup, referenceLabel[ choice[ "Tag" ] ], choice[ "Tag" ] ],
    choice[ "Style" ], choice[ "Tag" ] ]

citationChooserButton[ label_String, note_String, tag_String ] :=
  Button[
    Row[ { Pane[ Style[ label, 11 ], ImageSize -> { 190, Automatic }, Alignment -> Left ],
      Style[ note, 9, GrayLevel[ 0.5 ] ] } ],
    DialogReturn[ tag ], Appearance -> "Frameless", Alignment -> Left,
    ImageSize -> { 282, Automatic } ]

citationChoiceMatchQ[ choice_Association, filter_String ] :=
  filter === "" ||
    StringContainsQ[ choice[ "Tag" ], filter, IgnoreCase -> True ] ||
    StringContainsQ[ choice[ "Style" ], filter, IgnoreCase -> True ]

(* Where the reference goes, which turns out to be the whole of ImportDisplayDefects T5. Writing at a
   cell-bracket selection REPLACES the cell: measured, "Prose here." was overwritten by the button and
   the cell became a BoxData one. That second half is also the wrong-font defect Pavel reported, and it
   is not the stylesheets — the same reference in the same Text cell under the same sheet measures 406
   ink at height 15 as inline TextData, which is the prose face exactly (409/15), and 482 at height 17
   as BoxData, because BoxData renders in the box face. So the data loss and the face are one bug.

   A whole-cell selection is recognised by NotebookRead answering a Cell, and the insertion point then
   moves inside that cell's contents; a cursor already inside contents reads as "" with the cell still
   in SelectedCells, so it is left alone. No selected cell at all means there is no cell to insert
   into, and an empty Text cell is made to hold the reference rather than letting the front end invent
   a BoxData one. *)
citationInsertionPoint[ notebook_NotebookObject ] :=
  Which[
    MatchQ[ NotebookRead[ notebook ], _Cell | { __Cell } ],
      SelectionMove[ notebook, After, CellContents ],
    SelectedCells[ notebook ] === { },
      ( NotebookWrite[ notebook, Cell[ "", "Text" ] ];
        SelectionMove[ notebook, All, CellContents ] ) ]

InsertCitation[ notebook_NotebookObject, tag_String ] :=
  ( citationInsertionPoint[ notebook ];
    NotebookWrite[ notebook, citationButton[ tag, citationTargetStyle[ notebook, tag ] ] ] )

(* A bibliography entry the notebook owns. It is deliberately NOT written at the selection, the way
   every other Blocks button writes: an entry belongs in the bibliography, so it appends after the
   last one there is and, in a notebook with none, at the end of the document under an anchor
   heading created for it. The surgery is a pure core over the Notebook expression rather than
   SelectionMove and NotebookWrite, both because moving a \end{thebibliography} between cells is not
   a thing a selection can express and because that is what makes it testable with no front end.
   Pavel's call: no re-sort on insert — reordering the block as a side effect of adding one entry is
   right once and alarming every other time, so SortBibliography is a separate action. *)
InsertReference[ ] :=
  withInputNotebook[ InsertReference ]

InsertReference[ notebook_NotebookObject ] :=
  With[ { tag = InputString[ "Citation key:" ] },
    If[ StringQ[ tag ] && tag =!= "", InsertReference[ notebook, tag ] ] ]

InsertReference[ notebook_NotebookObject, tag_String ] :=
  With[ { document = NotebookGet[ notebook ] },
    If[ bibliographyDatabaseQ[ document ], Message[ InsertReference::bibfile ] ];
    NotebookPut[ insertReferenceCells[ document, tag ], notebook ] ]

(* Reported rather than refused. The .bib is the source of truth for such a paper — every entry cell
   is suppressed and the block's last cell carries the \bibliography commands verbatim — so an entry
   added here shows in the notebook and cannot reach the .tex. Silence would make it look exported. *)
InsertReference::bibfile =
  "The bibliography of this notebook comes from a .bib file, which stays the source of truth. The \
new entry will be shown in the notebook but will not be written into the exported .tex; add it to \
the .bib as well."

(* Ordering the bibliography, which the notebook can do and the compiled paper cannot always: a
   thebibliography prints its entries in the order they stand, so this IS the printed order, while
   a .bib paper's order belongs to its bibliography style and this only changes what the notebook
   shows. "FirstUse" is BibTeX's unsrt and the default because it is what a reader of the numbered
   list expects. "Uncited" sorts nothing — it is the question a sort cannot answer. *)
SortBibliography[ ] :=
  withInputNotebook[ SortBibliography ]

SortBibliography[ notebook_NotebookObject ] :=
  SortBibliography[ notebook, "FirstUse" ]

SortBibliography[ notebook_NotebookObject, "Uncited" ] :=
  With[ { audit = bibliographyAudit @ NotebookGet[ notebook ] },
    MessageDialog @ bibliographyAuditText[ audit ];
    audit ]

SortBibliography[ notebook_NotebookObject, method_String ] :=
  If[ MemberQ[ $bibliographySortMethods, method ],
    NotebookPut[ sortBibliographyCells[ NotebookGet[ notebook ], method ], notebook ],
    Message[ SortBibliography::method, method, $bibliographySortMethods ]; $Failed ]

SortBibliography::method =
  "`1` is not a bibliography order. Use one of `2`."

bibliographyAuditText[ audit_Association ] :=
  Replace[
    StringRiffle[ DeleteCases[ {
      bibliographyAuditLine[ "Never cited: ", audit[ "Uncited" ] ],
      bibliographyAuditLine[ "Citing nothing in this notebook: ", audit[ "Dangling" ] ] }, "" ], "\n" ],
    "" -> "Every entry is cited, and every citation has a target." ]

bibliographyAuditLine[ prefix_String, keys_List ] :=
  If[ keys === { }, "", prefix <> StringRiffle[ keys, ", " ] ]

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

(* The Reference style's ParagraphIndent -24 is a hanging indent for a hand-written entry; on a cell
   carrying a dingbat it outdents the dingbat with the first line, eating 24 pt of the margin the
   sheets reserve for exactly that label — so the label travels with ParagraphIndent -> 0
   (ImportDisplayDefects T1). Per-cell is right for the same reason it is for an environment body:
   "this cell hangs its own label" is true under every stylesheet. *)
referenceDingbat[ tags_ ] :=
  Replace[ First[ Flatten @ { tags }, None ],
    { tag_String :> { CellDingbat -> Cell[ TextData[ referenceLabel[ tag ] ] ], ParagraphIndent -> 0 },
      _ :> { } } ]

tagCell[ cell_CellObject, tag_String ] := (
  SetOptions[ cell, CellTags -> tag ];
  If[ MemberQ[ Flatten @ { CurrentValue[ cell, CellStyle ] }, "Reference" ],
    SetOptions[ cell, referenceDingbat[ tag ] ] ]
)

labelReferenceCells[ notebook_Notebook ] :=
  ReplaceAll[ notebook,
    Cell[ contents_, "Reference", options___ ] :>
      Cell[ contents, "Reference",
        Sequence @@ FilterRules[ { options }, Except[ { CellDingbat, ParagraphIndent } ] ],
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
