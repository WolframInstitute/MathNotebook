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

VerificationTest[
  labelReferenceCells @ Notebook[ { Cell[ "Ollivier, Ricci curvature", "Reference", CellTags -> "ollivier" ] } ],
  Notebook[ { Cell[ "Ollivier, Ricci curvature", "Reference", CellTags -> "ollivier",
    CellDingbat -> Cell[ TextData[ "[ollivier]" ] ] ] } ]
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
    CellDingbat -> Cell[ TextData[ "[new]" ] ] ] } ]
]

(* A cell may carry several tags; the first is the label. *)
VerificationTest[
  labelReferenceCells @ Notebook[ { Cell[ "Two tags", "Reference", CellTags -> { "first", "second" } ] } ],
  Notebook[ { Cell[ "Two tags", "Reference", CellTags -> { "first", "second" },
    CellDingbat -> Cell[ TextData[ "[first]" ] ] ] } ]
]

VerificationTest[
  labelReferenceCells @ Notebook[ { Cell[ "Prose, tagged but not a reference", "Text", CellTags -> "prose" ] } ],
  Notebook[ { Cell[ "Prose, tagged but not a reference", "Text", CellTags -> "prose" ] } ]
]
