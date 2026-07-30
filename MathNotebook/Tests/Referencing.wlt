Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

VerificationTest[
  Sort @ Keys @ $theoremEnvironments,
  Sort @ { "Theorem", "Lemma", "Proposition", "Corollary", "Conjecture", "Claim",
    "Definition", "Example", "Construction", "Remark", "Question", "Observation" }
]

VerificationTest[
  SubsetQ[ Keys @ $referenceLabelSpec,
    Join[ Keys @ $theoremEnvironments, { "DisplayFormulaNumbered", "Section", "Subsection", "Subsubsection", "ItemNumbered" } ] ],
  True
]

VerificationTest[
  $referenceLabelSpec[ "Lemma" ],
  { "Lemma ", { "Section", "Theorem" }, "" }
]

VerificationTest[
  $referenceLabelSpec[ "DisplayFormulaNumbered" ],
  { "(", { "DisplayFormulaNumbered" }, ")" }
]

(* ---------------------------------------------------------------------------------------------
   FirstReadingDefects T4. What a copied reference prints comes off the TARGET CELL, not off its
   style: an imported axiom is style Theorem carrying its own dingbat, and the style lookup gave the
   word Theorem over two counters the cell never increments. The three cases are told apart by what
   the cell's own label carries, and the third is not the second.
   --------------------------------------------------------------------------------------------- *)

$axiomDingbat = Cell[ TextData[ { "Axiom ", CounterBox[ "Section" ], ".", CounterBox[ "Subsection" ], ".",
  CounterBox[ "TheoremAxiom" ], "." } ], FontWeight -> "Bold", FontSlant -> "Plain" ]

$axiomCell = Cell[ "First axiom.", "Theorem", CellDingbat -> $axiomDingbat,
  CounterIncrements -> "TheoremAxiom", CellTags -> "ax:1" ]

(* The word and all three counters come out of the dingbat, and the label's terminating period is
   not part of the number. Under the old style lookup this was { "Theorem ", { "Section", "Theorem" } }. *)
VerificationTest[
  cellReferenceSpec[ $axiomCell, "Theorem" ],
  { "Axiom ", { "Section", "Subsection", "TheoremAxiom" }, "" }
]

(* A cell carrying no dingbat of its own is the common case and keeps the style's spec. *)
VerificationTest[
  cellReferenceSpec[ Cell[ "A theorem", "Theorem" ], "Theorem" ],
  $referenceLabelSpec[ "Theorem" ]
]

(* An equation's number lives in its CellFrameLabels, so that is where its chain is read — and the
   closing parenthesis stays where the dingbat's period goes. *)
VerificationTest[
  cellReferenceSpec[
    Cell[ "x = y", "DisplayFormulaNumbered",
      CellFrameLabels -> { { None, Cell[ TextData[ { "(", CounterBox[ "Section" ], ".",
        CounterBox[ "DisplayFormulaNumbered" ], ")" } ], "DisplayFormulaEquationNumber" ] }, { None, None } } ],
    "DisplayFormulaNumbered" ],
  { "(", { "Section", "DisplayFormulaNumbered" }, ")" }
]

(* A label carrying NO counter is an unnumbered environment — hodgepaper's starred ones, a
   bibliography entry — and there is no number to print, so the reference reads [tag] rather than
   falling back to a style spec whose counters that cell deliberately does not increment. *)
VerificationTest[
  { cellReferenceSpec[ Cell[ "A convention.", "Theorem", CellDingbat -> Cell[ TextData[ "Convention." ] ],
      CounterIncrements -> { } ], "Theorem" ],
    cellReferenceSpec[ Cell[ "Ollivier.", "Reference",
      CellDingbat -> Cell[ TextData[ "[ollivier]" ] ] ], "Reference" ] },
  { None, None }
]

(* A suppressed continuation cell of an environment body carries CellDingbat -> None: the number
   belongs to the cell that heads the group, and the style's spec resolves to the same value there. *)
VerificationTest[
  cellReferenceSpec[ Cell[ "... continued.", "Theorem", CellDingbat -> None, CounterIncrements -> { } ], "Theorem" ],
  $referenceLabelSpec[ "Theorem" ]
]

(* NotebookRead can answer $Failed for a selection state nobody anticipated; an unmatched argument
   would leave CopyCellReference unevaluated and silent, which is this repo's oldest trap. *)
VerificationTest[
  { cellReferenceSpec[ $Failed, "Lemma" ], cellReferenceSpec[ { }, "Text" ] },
  { $referenceLabelSpec[ "Lemma" ], None }
]

(* And the button the copy path builds from that spec is the front end's own cross-reference, keyed
   on the tag: three CounterBoxes where the style says two, and the word the cell prints. *)
VerificationTest[
  citationSpecButton[ "ax:1", cellReferenceSpec[ $axiomCell, "Theorem" ] ],
  ButtonBox[
    RowBox[ { "Axiom ", CounterBox[ "Section", "ax:1" ], ".", CounterBox[ "Subsection", "ax:1" ], ".",
      CounterBox[ "TheoremAxiom", "ax:1" ] } ],
    BaseStyle -> "Citation", ButtonData -> "ax:1" ]
]

(* An unnumbered target's spec is None, and that reads as the bare tag rather than as a CounterBox
   the front end would render XXX. *)
VerificationTest[
  citationSpecButton[ "ollivier", None ],
  citationButton[ "ollivier" ]
]

(* The generated tag is the first unused ref:n, so a second copy of an untagged cell reuses the name
   its first copy gave rather than accumulating one per click. *)
VerificationTest[
  { freshReferenceTag @ Notebook[ { Cell[ "Prose", "Text" ] } ],
    freshReferenceTag @ Notebook[ { Cell[ "One", "Theorem", CellTags -> "ref:1" ],
      Cell[ "Two", "Lemma", CellTags -> { "ref:2", "other" } ] } ] },
  { "ref:1", "ref:3" }
]

VerificationTest[
  referenceLabel[ "ollivier" ],
  "[ollivier]"
]

(* The bibliography entry and the citation pointing at it must read the same. *)
VerificationTest[
  Cases[ referenceDingbat[ "ollivier" ], Cell[ TextData[ text_String ] ] :> text, Infinity ],
  { First @ citationButton[ "ollivier" ] }
]

(* A citation to a numbered environment reads as its number, resolved at the target by the
   front end, not as the raw tag. *)
VerificationTest[
  citationButton[ "myThm", "Theorem" ],
  ButtonBox[
    RowBox[ { "Theorem ", CounterBox[ "Section", "myThm" ], ".", CounterBox[ "Theorem", "myThm" ] } ],
    BaseStyle -> "Citation", ButtonData -> "myThm" ]
]

VerificationTest[
  citationButton[ "euler", "DisplayFormulaNumbered" ],
  ButtonBox[ RowBox[ { "(", CounterBox[ "DisplayFormulaNumbered", "euler" ], ")" } ],
    BaseStyle -> "Citation", ButtonData -> "euler" ]
]

VerificationTest[
  citationButton[ "prelims", "Subsection" ],
  ButtonBox[
    RowBox[ { "Section ", CounterBox[ "Section", "prelims" ], ".", CounterBox[ "Subsection", "prelims" ] } ],
    BaseStyle -> "Citation", ButtonData -> "prelims" ]
]

(* Every numbered environment cites by number ... *)
VerificationTest[
  Union @ Map[ MatchQ[ citationButton[ "t", # ], ButtonBox[ _RowBox, __ ] ] &, Keys @ $referenceLabelSpec ],
  { True }
]

(* ... and every other target, a bibliography entry or a tag with no cell, keeps the tag. *)
VerificationTest[
  { citationButton[ "ollivier", "Reference" ], citationButton[ "ollivier", "Text" ], citationButton[ "ollivier", None ] },
  ConstantArray[ citationButton[ "ollivier" ], 3 ]
]

(* The label rides with ParagraphIndent -> 0: the style's -24 hanging indent is for an entry with no
   dingbat, and on a labelled cell it outdents the dingbat into the margin reserved for it. *)
VerificationTest[
  labelReferenceCells @ Notebook[ { Cell[ "Ollivier, Ricci curvature", "Reference", CellTags -> "ollivier" ] } ],
  Notebook[ { Cell[ "Ollivier, Ricci curvature", "Reference", CellTags -> "ollivier",
    CellDingbat -> Cell[ TextData[ "[ollivier]" ] ], ParagraphIndent -> 0 ] } ]
]

(* Relabelling does not accumulate a second indent beside the first. *)
VerificationTest[
  labelReferenceCells @ labelReferenceCells @
    Notebook[ { Cell[ "Twice", "Reference", CellTags -> "twice" ] } ],
  Notebook[ { Cell[ "Twice", "Reference", CellTags -> "twice",
    CellDingbat -> Cell[ TextData[ "[twice]" ] ], ParagraphIndent -> 0 ] } ]
]

VerificationTest[
  labelReferenceCells @ Notebook[ { Cell[ "An untagged entry", "Reference",
    CellDingbat -> Cell[ TextData[ "[stale]" ] ] ] } ],
  Notebook[ { Cell[ "An untagged entry", "Reference" ] } ]
]

VerificationTest[
  labelReferenceCells @ Notebook[ { Cell[ "Retagged", "Reference", CellTags -> "new",
    CellDingbat -> Cell[ TextData[ "[old]" ] ] ] } ],
  Notebook[ { Cell[ "Retagged", "Reference", CellTags -> "new",
    CellDingbat -> Cell[ TextData[ "[new]" ] ], ParagraphIndent -> 0 ] } ]
]

(* A cell may carry several tags; the first is the label. *)
VerificationTest[
  labelReferenceCells @ Notebook[ { Cell[ "Two tags", "Reference", CellTags -> { "first", "second" } ] } ],
  Notebook[ { Cell[ "Two tags", "Reference", CellTags -> { "first", "second" },
    CellDingbat -> Cell[ TextData[ "[first]" ] ], ParagraphIndent -> 0 ] } ]
]

VerificationTest[
  labelReferenceCells @ Notebook[ { Cell[ "Prose, tagged but not a reference", "Text", CellTags -> "prose" ] } ],
  Notebook[ { Cell[ "Prose, tagged but not a reference", "Text", CellTags -> "prose" ] } ]
]

(* T6. The live route writes options onto the cells themselves, so it needs the clearing stated where
   the expression route simply deleted the option: referenceDingbat's {} means "no option" to a cell
   being built and "this label has to go" to one already carrying it. Both take the label from
   referenceDingbat, so the two routes cannot disagree about what an entry reads. *)
VerificationTest[
  Map[ referenceLabelOptions, { "ollivier", { "first", "second" } } ],
  { { CellDingbat -> Cell[ TextData[ "[ollivier]" ] ], ParagraphIndent -> 0 },
    { CellDingbat -> Cell[ TextData[ "[first]" ] ], ParagraphIndent -> 0 } }
]

VerificationTest[
  Map[ referenceLabelOptions, { { }, None } ],
  ConstantArray[ { CellDingbat -> Inherited, ParagraphIndent -> Inherited }, 2 ]
]

(* ---------------------------------------------------------------------------------------------
   InsertReference: the pure core. Three cases, told apart by what the block's last cell carries.
   --------------------------------------------------------------------------------------------- *)

$paper = Notebook[ { Cell[ "A Paper", "Title" ], Cell[ "Prose.", "Text" ] } ]

$firstEntry = insertReferenceCells[ $paper, "ollivier" ]

(* A notebook with no bibliography gains two cells: the anchor heading and the entry. *)
VerificationTest[
  Cases[ $firstEntry, Cell[ _, style_String, ___ ] :> style, Infinity ],
  { "Title", "Text", "Section", "Reference" }
]

(* The anchor is unnumbered, suppressed, and tagged — all three, since each is load-bearing. *)
VerificationTest[
  FirstCase[ $firstEntry, Cell[ "References", "Section", options___ ] :>
    { Lookup[ { options }, CounterIncrements ], Lookup[ { options }, CellTags ],
      cellTagging[ Cell[ "References", "Section", options ], "Suppressed" ] }, None, Infinity ],
  { { }, $bibliographyAnchorTag, "True" }
]

(* The entry reads as the citation pointing at it. *)
VerificationTest[
  FirstCase[ $firstEntry, Cell[ _, "Reference", options___ ] :>
    { Lookup[ { options }, CellTags ], Lookup[ { options }, CellDingbat ] }, None, Infinity ],
  { "ollivier", Cell[ TextData[ "[ollivier]" ] ] }
]

(* The first entry carries BOTH delimiters, so a hand-written bibliography exports as a real
   thebibliography rather than as loose prose. *)
VerificationTest[
  StringCases[ notebookToLaTeX[ $firstEntry ],
    "\\begin{thebibliography}" | "\\bibitem{ollivier}" | "\\end{thebibliography}" ],
  { "\\begin{thebibliography}", "\\bibitem{ollivier}", "\\end{thebibliography}" }
]

(* The anchor prints nothing: thebibliography heads itself, and a cell emitting "References" too
   would put the heading in the compiled paper twice. This is the whole reason it is suppressed. *)
VerificationTest[
  StringContainsQ[ notebookToLaTeX[ $firstEntry ], "References" ],
  False
]

$secondEntry = insertReferenceCells[ $firstEntry, "lott" ]

(* A second insert makes no second anchor, and no second thebibliography. *)
VerificationTest[
  { Count[ $secondEntry, Cell[ "References", "Section", ___ ], Infinity ],
    StringCount[ notebookToLaTeX[ $secondEntry ], "\\begin{thebibliography}" ],
    StringCount[ notebookToLaTeX[ $secondEntry ], "\\end{thebibliography}" ] },
  { 1, 1, 1 }
]

(* The entries come out in insertion order, each under its own \bibitem. *)
VerificationTest[
  StringCases[ notebookToLaTeX[ $secondEntry ], "\\bibitem{" ~~ key : Except[ "}" ] .. ~~ "}" :> key ],
  { "ollivier", "lott" }
]

(* The closing delimiter MOVED. It rides on whichever cell is last, so appending without moving it
   would emit the new entry after the \end — which round-trips fine and compiles to nothing. *)
VerificationTest[
  Map[ cell |-> { Lookup[ Cases[ cell, _Rule, { 1 } ], CellTags ],
      cellTagging[ cell, "EnvironmentClose" ] =!= "" },
    Cases[ $secondEntry, Cell[ _, "Reference", ___ ], Infinity ] ],
  { { "ollivier", False }, { "lott", True } }
]

(* --- The .bib case: the entries are not the notebook's, so the new one is suppressed and the cell
   carrying the \bibliography commands stays last. --- *)

$database = Notebook[ {
  Cell[ "Prose.", "Text" ],
  Cell[ "Ollivier, Ricci curvature.", "Reference", CellTags -> "ollivier",
    TaggingRules -> <| "MathNotebook" -> <| "Suppressed" -> "True" |> |> ],
  Cell[ "Lott and Villani.", "Reference", CellTags -> "lott",
    TaggingRules -> <| "MathNotebook" -> <| "Suppressed" -> "",
      "BibliographyTeX" -> "\\bibliography{refs}" |> |> ] } ]

VerificationTest[
  bibliographyDatabaseQ[ $database ],
  True
]

VerificationTest[
  bibliographyDatabaseQ[ $secondEntry ],
  False
]

$databaseInserted = insertReferenceCells[ $database, "sturm" ]

(* The new entry goes BEFORE the carrier, and is suppressed like every other .bib entry. *)
VerificationTest[
  Map[ cell |-> { Lookup[ Cases[ cell, _Rule, { 1 } ], CellTags ], cellTagging[ cell, "Suppressed" ] },
    Cases[ $databaseInserted, Cell[ _, "Reference", ___ ], Infinity ] ],
  { { "ollivier", "True" }, { "sturm", "True" }, { "lott", "" } }
]

(* So the exported source is unchanged — which is what InsertReference::bibfile says out loud. *)
VerificationTest[
  notebookToLaTeX[ $databaseInserted ],
  notebookToLaTeX[ $database ]
]

(* An imported thebibliography paper gets no anchor: its existing block is the anchor. *)
VerificationTest[
  Count[ insertReferenceCells[ $database, "sturm" ], Cell[ "References", "Section", ___ ], Infinity ],
  0
]

(* ---------------------------------------------------------------------------------------------
   T4. The citation chooser's list is a pure function of the notebook, which is the whole reason
   it is assertable — the dialog around it is not drivable headless.
   --------------------------------------------------------------------------------------------- *)

$tagged = Notebook[ {
  Cell[ "A section", "Section", CellTags -> "sec:intro" ],
  Cell[ "A theorem", "Theorem", CellTags -> { "Thm:main", "Thm:alias" } ],
  Cell[ "An equation", "DisplayFormulaNumbered", CellTags -> "eq:one" ],
  Cell[ "Untagged prose", "Text" ],
  Cell[ "Ollivier.", "Reference", CellTags -> "ollivier" ],
  Cell[ "Lott and Villani.", "Reference", CellTags -> "lott" ] } ]

(* Literature is what a Reference cell carries; everything else is a block. Literature comes first
   and alphabetical, blocks in document order. *)
VerificationTest[
  Map[ { #[ "Tag" ], #[ "Style" ], #[ "Group" ] } &, citationChoices[ $tagged ] ],
  { { "lott", "Reference", "Literature" },
    { "ollivier", "Reference", "Literature" },
    { "sec:intro", "Section", "Blocks" },
    { "Thm:main", "Theorem", "Blocks" },
    { "Thm:alias", "Theorem", "Blocks" },
    { "eq:one", "DisplayFormulaNumbered", "Blocks" } }
]

(* An untagged cell contributes nothing, and a repeated tag is offered once. *)
VerificationTest[
  Map[ #[ "Tag" ] &,
    citationChoices @ Notebook[ {
      Cell[ "One", "Text" ],
      Cell[ "Two", "Theorem", CellTags -> "dup" ],
      Cell[ "Three", "Lemma", CellTags -> "dup" ] } ] ],
  { "dup" }
]

VerificationTest[
  citationChoices @ Notebook[ { Cell[ "Nothing tagged", "Text" ] } ],
  { }
]

(* Every offered choice is a button returning its own tag. The HoldPattern is not decoration: a bare
   DialogReturn[tag_] is EVALUATED as Cases' pattern argument before any matching happens, and the
   call then answers {} — the same silent-empty failure as Cases[opts, FontSize -> _]. *)
VerificationTest[
  Cases[ citationChooserRows[ citationChoices[ $tagged ], "" ], HoldPattern[ DialogReturn[ tag_ ] ] :> tag, Infinity ],
  { "lott", "ollivier", "sec:intro", "Thm:main", "Thm:alias", "eq:one" }
]

(* The filter narrows on the tag and on the style alike. *)
VerificationTest[
  { Cases[ citationChooserRows[ citationChoices[ $tagged ], "thm" ], HoldPattern[ DialogReturn[ t_ ] ] :> t, Infinity ],
    Cases[ citationChooserRows[ citationChoices[ $tagged ], "Reference" ], HoldPattern[ DialogReturn[ t_ ] ] :> t, Infinity ] },
  { { "Thm:main", "Thm:alias" }, { "lott", "ollivier" } }
]

(* Text no tag matches is offered as a new key — this is the free-text half of the one field. *)
VerificationTest[
  Cases[ citationChooserRows[ citationChoices[ $tagged ], "sturm" ], HoldPattern[ DialogReturn[ t_ ] ] :> t, Infinity ],
  { "sturm" }
]

(* A filter that is narrowing a real list does NOT also offer to invent a key from it: "ollivier"
   matches an entry, so the only row is that entry. *)
VerificationTest[
  Cases[ citationChooserRows[ citationChoices[ $tagged ], "ollivier" ], HoldPattern[ DialogReturn[ t_ ] ] :> t, Infinity ],
  { "ollivier" }
]

(* Both group headings are shown when both groups have matches, and only the one that does when not. *)
VerificationTest[
  { Cases[ citationChooserRows[ citationChoices[ $tagged ], "" ],
      Style[ text_String, 10, Bold, _ ] :> text, Infinity ],
    Cases[ citationChooserRows[ citationChoices[ $tagged ], "eq:" ],
      Style[ text_String, 10, Bold, _ ] :> text, Infinity ] },
  { { "Literature", "Blocks" }, { "Blocks" } }
]

(* ---------------------------------------------------------------------------------------------
   T5. Sorting the block. Three parts move and only one of them travels with a cell — a wrong split
   still round-trips, so these read the delimiters off the reordered cells and off the source.
   --------------------------------------------------------------------------------------------- *)

$bibliography = Notebook[ {
  Cell[ TextData[ { "As shown in ",
    ButtonBox[ "[lott]", BaseStyle -> "Citation", ButtonData -> "lott" ], " and ",
    ButtonBox[ "[sturm]", BaseStyle -> "Citation", ButtonData -> "sturm" ], "." } ], "Text" ],
  Cell[ "Bourbaki.", "Reference", CellTags -> "bourbaki",
    TaggingRules -> <| "MathNotebook" -> <|
      "EnvironmentOpen" -> "\\begin{thebibliography}{99}\n\n\\bibitem{bourbaki}\n",
      "Separator" -> "\n\n" |> |> ],
  Cell[ "Sturm.", "Reference", CellTags -> "sturm",
    TaggingRules -> <| "MathNotebook" -> <|
      "EnvironmentOpen" -> "\\bibitem{sturm}\n", "Separator" -> "\n\n" |> |> ],
  Cell[ "Lott and Villani.", "Reference", CellTags -> "lott",
    TaggingRules -> <| "MathNotebook" -> <|
      "EnvironmentOpen" -> "\\bibitem{lott}\n",
      "EnvironmentClose" -> "\n\n\\end{thebibliography}", "Separator" -> "\n" |> |> ] } ]

$order = notebook |-> Map[ referenceKey, Cases[ notebook, Cell[ _, "Reference", ___ ], Infinity ] ]

(* Order of first citation, which is BibTeX's unsrt: lott is cited before sturm, and bourbaki is
   cited nowhere and so goes last. *)
VerificationTest[
  { citedTags[ $bibliography ], $order @ sortBibliographyCells[ $bibliography, "FirstUse" ] },
  { { "lott", "sturm" }, { "lott", "sturm", "bourbaki" } }
]

VerificationTest[
  { $order @ sortBibliographyCells[ $bibliography, "Key" ],
    $order @ sortBibliographyCells[ $bibliography, "Entry" ] },
  { { "bourbaki", "lott", "sturm" }, { "bourbaki", "lott", "sturm" } }
]

(* The \begin follows whichever entry is first and the \end whichever is last. Reordering without
   moving them emits a \begin in the middle of the list and still round-trips. *)
VerificationTest[
  Map[ cell |-> { referenceKey[ cell ],
      StringContainsQ[ cellTagging[ cell, "EnvironmentOpen" ], "\\begin{thebibliography}" ],
      cellTagging[ cell, "EnvironmentClose" ] =!= "" },
    Cases[ sortBibliographyCells[ $bibliography, "FirstUse" ], Cell[ _, "Reference", ___ ], Infinity ] ],
  { { "lott", True, False }, { "sturm", False, False }, { "bourbaki", False, True } }
]

(* Each entry keeps its own \bibitem, and the source carries exactly one environment. *)
VerificationTest[
  With[ { source = notebookToLaTeX @ sortBibliographyCells[ $bibliography, "FirstUse" ] },
    { StringCases[ source, "\\bibitem{" ~~ key : Except[ "}" ] .. ~~ "}" :> key ],
      StringCount[ source, "\\begin{thebibliography}" ],
      StringCount[ source, "\\end{thebibliography}" ] } ],
  { { "lott", "sturm", "bourbaki" }, 1, 1 }
]

(* And the \begin really does stand before every entry. Counting the delimiters cannot see this:
   with the opening left to travel on its original cell there is still exactly ONE \begin and ONE
   \end in the source, both simply at the end of the list — measured, that bite fails the per-cell
   reading above and this file's every source-level count. *)
VerificationTest[
  With[ { source = notebookToLaTeX @ sortBibliographyCells[ $bibliography, "FirstUse" ] },
    { Order[ First @ First @ StringPosition[ source, "\\begin{thebibliography}" ],
        First @ First @ StringPosition[ source, "\\bibitem" ] ],
      Order[ First @ Last @ StringPosition[ source, "\\bibitem" ],
        First @ First @ StringPosition[ source, "\\end{thebibliography}" ] ] } ],
  { 1, 1 }
]

(* A separator describes the gap at a place in the source, not the entry that happens to precede
   it, so it stays where it was: the block still ends with the single newline it ended with. *)
VerificationTest[
  Map[ cellTagging[ #, "Separator" ] &,
    Cases[ sortBibliographyCells[ $bibliography, "Key" ], Cell[ _, "Reference", ___ ], Infinity ] ],
  { "\n\n", "\n\n", "\n" }
]

(* The .bib carrier is pinned last however the rest are ordered. *)
$databaseBibliography = Notebook[ {
  Cell[ TextData[ { ButtonBox[ "[sturm]", BaseStyle -> "Citation", ButtonData -> "sturm" ] } ], "Text" ],
  Cell[ "Lott.", "Reference", CellTags -> "lott",
    TaggingRules -> <| "MathNotebook" -> <| "Suppressed" -> "True" |> |> ],
  Cell[ "Sturm.", "Reference", CellTags -> "sturm",
    TaggingRules -> <| "MathNotebook" -> <| "Suppressed" -> "True" |> |> ],
  Cell[ "Bourbaki.", "Reference", CellTags -> "bourbaki",
    TaggingRules -> <| "MathNotebook" -> <| "Suppressed" -> "",
      "BibliographyTeX" -> "\\bibliography{refs}" |> |> ] } ]

VerificationTest[
  $order @ sortBibliographyCells[ $databaseBibliography, "FirstUse" ],
  { "sturm", "lott", "bourbaki" }
]

(* And the source is untouched, since the .bib owns the order there. *)
VerificationTest[
  notebookToLaTeX @ sortBibliographyCells[ $databaseBibliography, "FirstUse" ],
  notebookToLaTeX[ $databaseBibliography ]
]

(* Fewer than two entries is a no-op rather than an error. *)
VerificationTest[
  sortBibliographyCells[ Notebook[ { Cell[ "Only one.", "Reference", CellTags -> "one" ] } ], "Key" ],
  Notebook[ { Cell[ "Only one.", "Reference", CellTags -> "one" ] } ]
]

(* The audit answers the question a sort cannot: bourbaki is an entry nothing cites, and a \ref to a
   theorem is NOT a dangling citation, which is why "Dangling" is measured against every tag. *)
VerificationTest[
  bibliographyAudit[ $bibliography ],
  <| "Uncited" -> { "bourbaki" }, "Dangling" -> { } |>
]

VerificationTest[
  bibliographyAudit @ Notebook[ {
    Cell[ TextData[ {
      ButtonBox[ "Theorem 1", BaseStyle -> "Citation", ButtonData -> "Thm:main" ],
      ButtonBox[ "[ghost]", BaseStyle -> "Citation", ButtonData -> "ghost" ] } ], "Text" ],
    Cell[ "A theorem", "Theorem", CellTags -> "Thm:main" ],
    Cell[ "Lott.", "Reference", CellTags -> "lott" ] } ],
  <| "Uncited" -> { "lott" }, "Dangling" -> { "ghost" } |>
]

(* The bibliography anchor's tag is a marker, not a citation target. Found by driving the installed
   0.1.18: two inserts into a fresh notebook and the chooser offered "MathNotebookBibliography"
   beside the two keys. No kernel test had covered a notebook that InsertReference had built. *)
VerificationTest[
  Map[ #[ "Tag" ] &,
    citationChoices @ insertReferenceCells[ insertReferenceCells[ $paper, "a" ], "b" ] ],
  { "a", "b" }
]
