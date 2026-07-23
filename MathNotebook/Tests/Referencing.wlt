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
