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
