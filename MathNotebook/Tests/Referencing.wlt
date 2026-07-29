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

VerificationTest[
  MatchQ[ referenceButton[ 42, $referenceLabelSpec[ "Theorem" ] ],
    Button[ _Row, _, BaseStyle -> "Link", Appearance -> None ] ],
  True
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
