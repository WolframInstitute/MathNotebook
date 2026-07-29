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
PackageScope["citationSpecButton"]
PackageScope["freshReferenceTag"]
PackageScope["referenceLabel"]
PackageScope["referenceDingbat"]
PackageScope["citationButton"]
PackageScope["cellReferenceSpec"]
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

(* Two defects met here, and the second is why this button changed key. Reported: a copied reference
   to Axiom 3.1.3 pasted as "Theorem 0.0". The word and the chain were looked up from the STYLE — an
   imported axiom is style Theorem carrying a per-cell dingbat of "Axiom S.SS.TheoremAxiom." — which
   is the \ref rule ("read the chain off the target cell, not the target's style", labelCounters in
   Document.wl) that this path never got. But the two zeros are a defect of their own: an imported
   cell has NO CellID, CurrentValue[cell, CellID] reads 0, and Cells[CellID -> 0] matches EVERY cell,
   so the old Dynamic resolved its counters at the document's first cell — where a paper's Section
   counter is 0 — and NotebookFind[nb, 0, All, CellID] navigates nowhere. Measured: a CellID cannot be
   written onto an existing cell either; SetOptions and CurrentValue[...] = are both silent no-ops.

   So the copy keys on the cell's TAG, which is what CounterBox's second argument wants, and this
   button becomes the same front-end cross-reference \ref and InsertCitation already build: no kernel
   to resolve, right in the printed PDF, and it follows the target when cells move. Pavel's call
   (2026-07-29) for a cell with no tag: tag it automatically rather than prompting or refusing, so
   the control never interrupts — the generated tag exports as the \label such a reference needs. *)
CopyCellReference[ notebook_NotebookObject ] :=
  Replace[ SelectedCells[ notebook ], {
    { cell_, ___ } :> copyCellReference[ notebook, cell ],
    _ :> MessageDialog[ "Select a cell!" ] } ]

(* The clipboard payload is a Text cell holding the button, and the shape was measured rather than
   chosen: pasted into prose, a Cell[BoxData[...]] island renders in the BOX face — 29 px tall against
   the prose's 19 — which is ImportDisplayDefects T5's wrong-font defect again, and a bare ButtonBox
   pastes as its own boxes spelled out as text. The TextData form is the prose face. The paste splits
   it into one button per run, the reopen-split shape mergedButtons already rejoins: every fragment
   carries the same ButtonData, so each navigates, and the export still emits the one \ref. *)
copyCellReference[ notebook_NotebookObject, cell_CellObject ] :=
  CopyToClipboard @ Cell[
    TextData @ { citationSpecButton[ referenceAnchorTag[ notebook, cell ],
      cellReferenceSpec[ NotebookRead[ cell ], First @ Flatten @ { CurrentValue[ cell, CellStyle ] } ] ] },
    "Text" ]

(* An untagged cell is tagged here, which is also what makes it referenceable in the exported .tex.
   The name is the first unused ref:n, so a second copy of the same cell reuses the tag it already
   gave it rather than accumulating one per click. *)
referenceAnchorTag[ notebook_NotebookObject, cell_CellObject ] :=
  Replace[ FirstCase[ Flatten @ { CurrentValue[ cell, CellTags ] }, tag_String /; tag =!= "" ], {
    tag_String :> tag,
    _ :> With[ { tag = freshReferenceTag @ NotebookGet[ notebook ] }, tagCell[ cell, tag ]; tag ] } ]

$referenceTagPrefix = "ref:"

freshReferenceTag[ notebook_ ] :=
  With[ { taken = Cases[ Flatten @ Cases[ notebook, ( CellTags -> tags_ ) :> tags, Infinity ], _String ] },
    $referenceTagPrefix <> ToString @ FirstCase[ Range[ Length[ taken ] + 1 ],
      n_ /; ! MemberQ[ taken, $referenceTagPrefix <> ToString[ n ] ] ] ]

(* What the reference prints is what the target's own label prints. Three cases, and the third is not
   the second: a cell carrying NO dingbat of its own takes its style's spec (the common case — the
   sheets number the twelve environments), a cell whose dingbat carries CounterBoxes takes the word
   and the chain out of it, and a cell whose dingbat carries NONE is unnumbered — a starred
   environment, a bibliography entry — so there is no number to print and the reference reads [tag].
   The label's trailing period is its terminator rather than part of the number, so the suffix drops
   it; an equation's closing parenthesis stays. *)
cellReferenceSpec[ cell_Cell, style_String ] :=
  Replace[ cellNumberLabel[ cell, style ], {
    None :> Lookup[ $referenceLabelSpec, style, None ],
    label_ :> labelReferenceSpec[ label ] } ]

(* NotebookRead can answer $Failed or {} for a selection state nobody anticipated; an unmatched
   argument here would leave CopyCellReference unevaluated and silent, the repo's own trap. *)
cellReferenceSpec[ _, style_String ] :=
  Lookup[ $referenceLabelSpec, style, None ]

cellNumberLabel[ cell_, "DisplayFormula" | "DisplayFormulaNumbered" ] :=
  FirstCase[ cell, ( CellFrameLabels -> value_ ) :> value, None ]

cellNumberLabel[ cell_, _ ] :=
  FirstCase[ cell, ( CellDingbat -> value_ ) :> value, None ]

labelReferenceSpec[ label_ ] :=
  Replace[ FirstCase[ label, TextData[ parts_ ] :> Flatten @ { parts }, None, { 0, Infinity } ],
    { parts_List /; ! FreeQ[ parts, _CounterBox ] :> partsReferenceSpec[ parts ],
      _ :> None } ]

partsReferenceSpec[ parts_List ] :=
  With[ { positions = Flatten @ Position[ parts, _CounterBox, { 1 }, Heads -> False ] },
    { StringJoin @ Cases[ Take[ parts, First[ positions ] - 1 ], _String ],
      Cases[ parts, box_CounterBox :> First[ box ] ],
      StringDelete[ StringJoin @ Cases[ Drop[ parts, Last[ positions ] ], _String ],
        "." ~~ EndOfString ] } ]

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

(* The bibliography anchor's tag is a marker for SortBibliography and not a citation target, so it
   is dropped here — found by driving the installed 0.1.18, where "MathNotebookBibliography" was
   offered as a citable block. Nothing else in the notebook carries a tag it did not ask for. *)
citationChoice[ cell : Cell[ _, style_String, ___ ] ] :=
  Map[ tag |-> <| "Tag" -> tag, "Style" -> style,
      "Group" -> If[ style === "Reference", $literatureGroup, $blockGroup ] |>,
    DeleteCases[
      Cases[ Flatten @ { Cases[ cell, ( CellTags -> tags_ ) :> tags, { 1 } ] }, _String ],
      $bibliographyAnchorTag ] ]

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

(* The form the palette's menu items call, so each item is one guarded call and the "Open a notebook
   first!" dialog stays in the kernel rather than being written out four more times into the .nb. *)
SortBibliography[ method_String ] :=
  withInputNotebook[ SortBibliography[ #, method ] & ]

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
   The copy path shares this now: it passes the spec it read off the target cell rather than a style
   name, which is what retired the CellID-keyed rendering that could not resolve a tag. *)
citationButton[ tag_String, style_ ] :=
  citationSpecButton[ tag, Lookup[ $referenceLabelSpec, style, None ] ]

citationSpecButton[ tag_String, { prefix_, counters_, suffix_ } ] :=
  ButtonBox[
    RowBox @ DeleteCases[ Flatten @ { prefix, Riffle[ Map[ CounterBox[ #, tag ] &, counters ], "." ], suffix }, "" ],
    BaseStyle -> "Citation", ButtonData -> tag ]

citationSpecButton[ tag_String, _ ] :=
  citationButton[ tag ]

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

writeEnvironmentCell[ notebook_NotebookObject, cell_Cell ] := (
  SelectionMove[ notebook, After, Cell ];
  NotebookWrite[ notebook, cell, All ];
  SelectionMove[ notebook, All, CellContents ]
)
