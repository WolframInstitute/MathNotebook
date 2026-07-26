Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

VerificationTest[
  texToBoxes[ "x^2" ],
  SuperscriptBox[ "x", "2" ]
]

VerificationTest[
  texToBoxes[ "\\frac{a}{b}" ],
  FractionBox[ "a", "b" ]
]

(* Inline Math Converter Defects T1. texToBoxes reads the TeX as a single Wolfram *expression*,
   and a comma-separated fragment never is one — "a, b" is two. Every such span answered $Failed
   and was left in the cell as literal "$...$": on the specimen paper, all 35 of its 241
   unconverted inline spans. The TeX importer's own box output is correct for exactly these, so
   presentationBoxes is consulted when the expression parse fails. *)

convertedQ[ tex_String ] :=
  FreeQ[ texToBoxes[ tex ], $Failed | "$Failed" ]

VerificationTest[ (* the sequence stays a sequence rather than collapsing to one expression *)
  MatchQ[ texToBoxes[ "a, b" ], RowBox[ { _, ",", _ } ] ],
  True
]

VerificationTest[ (* tuples, subscripted lists, a comma before a relation, a comma inside \{...\} *)
  Map[ convertedQ,
    { "(a, b)", "(V, E)", "\\mathcal{H} = (V, E)", "x_1, x_2", "p,q\\in M",
      "\\{a, b\\}", "\\{ x_1, \\ldots, x_n \\}", "e = (v_1, v_2, \\dots, v_k)" } ],
  ConstantArray[ True, 8 ]
]

VerificationTest[ (* both operands of a subscripted list survive, not just the first *)
  Count[ texToBoxes[ "x_1, x_2" ], _SubscriptBox, Infinity ],
  2
]

VerificationTest[ (* malformed TeX answers $Failed; it used to answer the *string* "$Failed",
                     which renders in the notebook as the word "$Failed" *)
  Map[ texToBoxes, { "\\frac{a", "%" } ],
  { $Failed, $Failed }
]

VerificationTest[ (* the cell keeps no "$" at all, and stores the source for the return trip *)
  splitInlineMath[ "A pair $(V, E)$ here." ],
  { "A pair ",
    Cell[ BoxData[ FormBox[ RowBox[ { "(", RowBox[ { StyleBox[ "V", "TI" ], ",", StyleBox[ "E", "TI" ] } ], ")" } ],
      TraditionalForm ] ],
      TaggingRules -> <| "MathNotebook" -> <| "SourceTeX" -> "(V, E)" |> |> ],
    " here." }
]

VerificationTest[ (* the fallback must not disturb align's "&" columns or cases' rows *)
  { Dimensions @ First @ alignBoxes[ "a&=b\\\\c&=d" ],
    Dimensions @ FirstCase[ texToBoxes[ "\\begin{cases} a & x>0 \\\\ b & x<0 \\end{cases}" ],
      GridBox[ rows_, ___ ] :> rows, { }, Infinity ] },
  { { 2, 2 }, { 2, 2 } }
]

VerificationTest[
  boxesToTeX[ SuperscriptBox[ "x", "2" ] ],
  "x^2"
]

VerificationTest[
  boxesToTeX[ TemplateBox[ <| "input" -> "\\sin x" |>, "TeXAssistantTemplate" ] ],
  "\\sin x"
]

VerificationTest[
  splitInlineMath[ "Let $x^2$ hold" ],
  { "Let ",
    Cell[ BoxData[ FormBox[ SuperscriptBox[ "x", "2" ], TraditionalForm ] ],
      TaggingRules -> <| "MathNotebook" -> <| "SourceTeX" -> "x^2" |> |> ],
    " hold" }
]

VerificationTest[
  displayParse[ "\\begin{align}a&=b\\\\c&=d\\end{align}" ],
  { "a&=b\\\\c&=d", True, "Align" }
]

VerificationTest[
  MatchQ[ alignBoxes[ "a&=b\\\\c&=d" ], GridBox[ { { _, _ }, { _, _ } }, ___ ] ],
  True
]

$testNotebook = Notebook[ {
  Cell[ "We have $E=mc^2$ inline.", "Text", CellID -> 11 ],
  Cell[ "\\begin{align}a&=b\\\\c&=d\\end{align}", "Text", CellID -> 22 ],
  Cell[ "\\[ \\int_0^1 x^2 \\, dx = \\frac{1}{3} \\]", "Text", CellID -> 33 ],
  Cell[ "\\begin{equation}x^2+y^2=z^2\\end{equation}", "Text", CellID -> 44 ],
  Cell[ "no math here", "Text" ],
  Cell[ "x = 1; $notmath", "Input" ] } ];

$converted = convertLaTeXNotebook[ $testNotebook ];

VerificationTest[
  Map[ #[[ 2 ]] &, First[ $converted ] ],
  { "Text", "DisplayFormulaNumbered", "DisplayFormula", "DisplayFormulaNumbered", "Text", "Input" }
]

VerificationTest[
  ! FreeQ[ $converted[[ 1, 2 ]], GridBox ],
  True
]

VerificationTest[
  Cases[ $converted, ( CellID -> id_ ) :> id, Infinity ],
  { 11, 22, 33, 44 }
]

VerificationTest[
  Map[ First, First @ convertMathNotebook[ $converted ] ],
  Map[ First, First @ $testNotebook ]
]

$groupedNotebook = Notebook[ {
  Cell[ CellGroupData[ {
    Cell[ "Section", "Section" ],
    Cell[ CellGroupData[ { Cell[ "inner $x^2$ math", "Text", CellID -> 55 ] }, Open ] ] }, Open ] ] } ];

VerificationTest[
  FreeQ[ convertLaTeXNotebook[ $groupedNotebook ], "inner $x^2$ math" ],
  True
]

VerificationTest[
  Cases[ convertLaTeXNotebook[ $groupedNotebook ], _CellGroupData, Infinity, Heads -> True ] // Length,
  2
]
