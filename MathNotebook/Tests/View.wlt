Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

(* The base geometry a real parent sheet would supply, stubbed so the arithmetic is testable
   without a front end: Section hangs 26 pt left of Text, which is what forces the offsets to be
   anchored on the smallest margin rather than on Text. *)
baseCellMargins[ "StubSheet.nb" ] = <|
  "Text" -> { { 66, 10 }, { 4, 4 } },
  "Section" -> { { 40, 25 }, { 10, 28 } },
  "Theorem" -> { { 130, 10 }, { 8, 8 } } |>;

(* The sizes a real parent sheet resolves through its chain, stubbed for the same reason. The
   point of the stub is the styles LaTeXBase under-declares: Theorem, Proof and Reference carry a
   printout size but no screen size in the file, and the list styles are not in it at all. *)
baseFontSizes[ "StubSheet.nb" ] = <|
  "Screen" -> <| "Text" -> 13, "Title" -> 26, "Theorem" -> 13, "Proof" -> 13, "Reference" -> 13,
    "Item" -> 15, "ItemNumbered" -> 15, "DisplayFormula" -> 13, "DisplayFormulaNumbered" -> 13,
    "DisplayFormulaEquationNumber" -> 12 |>,
  "Printout" -> <| "Text" -> 10, "Title" -> 17, "Theorem" -> 10, "Proof" -> 10, "Reference" -> 10,
    "Item" -> 15, "ItemNumbered" -> 15, "DisplayFormula" -> 10, "DisplayFormulaNumbered" -> 10,
    "DisplayFormulaEquationNumber" -> 10 |> |>;

(* The wrapper test passes a real sheet name, and reading the sizes through the chain needs a front
   end, so that name is stubbed too — otherwise the suite stops being kernel-only. *)
baseFontSizes[ "AMSArticle.nb" ] = baseFontSizes[ "StubSheet.nb" ];

styleNames[ cells_List ] := Cases[ cells, Cell[ StyleData[ style_String, ___ ], ___ ] :> style ];

(* These go through viewStyleCells rather than calling styleFontSizeNames directly: an undeclared
   symbol is private to its own file, so a direct call from the test would stay unevaluated and the
   test would pass or fail for a reason unrelated to what it checks. *)
VerificationTest[ (* the anchors resolve *)
  { NumericQ @ documentFontSizeAnchor[ "StubSheet.nb" ], NumericQ @ mathFontSizeAnchor[ "StubSheet.nb" ] },
  { True, True }
]

VerificationTest[ (* the character styles stay out, so an inline citation keeps inheriting its cell *)
  Intersection[ styleNames @ viewStyleCells[ "StubSheet.nb", <| "DocumentFontSize" -> 20 |> ],
    { "Hyperlink", "Citation", "URL" } ],
  { }
]

VerificationTest[ (* the text control reaches the theorem, proof, reference and list styles on SCREEN,
                     which is the defect Pavel reported: they carry no bare FontSize in LaTeXBase *)
  Complement[ { "Theorem", "Proof", "Reference", "Item", "ItemNumbered" },
    Cases[ viewStyleCells[ "StubSheet.nb", <| "DocumentFontSize" -> 20 |> ],
      Cell[ StyleData[ style_String ], ___, FontSize -> _, ___ ] :> style ] ],
  { }
]

VerificationTest[ (* an untouched document gets no override cells at all *)
  viewStyleCells[ "StubSheet.nb", <| |> ],
  { }
]

VerificationTest[ (* at the anchor size every style is written back at exactly its base size *)
  Union @ Cases[
    viewStyleCells[ "StubSheet.nb", <| "DocumentFontSize" -> documentFontSizeAnchor[ "StubSheet.nb" ] |> ],
    Cell[ StyleData[ style_String ], FontSize -> size_ ] :> size === baseFontSizes[ "StubSheet.nb" ][ "Screen", style ] ],
  { True }
]

VerificationTest[ (* the whole hierarchy scales proportionally, not just Text *)
  Cases[ viewStyleCells[ "StubSheet.nb", <| "DocumentFontSize" -> 2 documentFontSizeAnchor[ "StubSheet.nb" ] |> ],
    Cell[ StyleData[ "Title" ], ___, FontSize -> size_, ___ ] :> size ],
  { Round[ 2 baseFontSizes[ "StubSheet.nb" ][ "Screen", "Title" ] ] }
]

VerificationTest[ (* prose and mathematics are independent *)
  Intersection[ styleNames @ viewStyleCells[ "StubSheet.nb", <| "DocumentFontSize" -> 20 |> ], $mathStyleNames ],
  { }
]

VerificationTest[ (* the math control reaches the equation number, which would otherwise drift *)
  Union @ styleNames @ viewStyleCells[ "StubSheet.nb", <| "MathFontSize" -> 20 |> ],
  Union @ $mathStyleNames
]

VerificationTest[ (* every size override is written in the "Printout" variant too, or it never prints *)
  Cases[ viewStyleCells[ "StubSheet.nb", <| "MathFontSize" -> 20 |> ],
    Cell[ StyleData[ "DisplayFormula", "Printout" ], ___, FontSize -> size_, ___ ] :> size ],
  { Round[ 20 baseFontSizes[ "StubSheet.nb" ][ "Printout", "DisplayFormula" ] / mathFontSizeAnchor[ "StubSheet.nb" ] ] }
]

VerificationTest[ (* the width is a symmetric Scaled inset plus each style's own indent *)
  Cases[ contentWidthCells[ "StubSheet.nb", 0.6 ],
    Cell[ StyleData[ "Text" ], CellMargins -> value_ ] :> value ],
  { { { Scaled[ 0.2 ] + 26, Scaled[ 0.2 ] }, { 4, 4 } } }
]

VerificationTest[ (* no offset is negative, so no hanging dingbat is pushed off the page *)
  Cases[ contentWidthCells[ "StubSheet.nb", 0.6 ], Scaled[ _ ] + _?Negative, Infinity ],
  { }
]

VerificationTest[ (* the width prints as well as it displays *)
  Length @ Cases[ contentWidthCells[ "StubSheet.nb", 0.6 ], Cell[ StyleData[ "Section", "Printout" ], CellMargins -> _ ] ],
  1
]

VerificationTest[ (* two cells for one style cancel in the front end, so the three controls must merge *)
  With[ { cells = viewStyleCells[ "StubSheet.nb",
      <| "DocumentFontSize" -> 20, "MathFontSize" -> 16, "ContentWidth" -> 0.6 |> ] },
    DuplicateFreeQ @ Cases[ cells, Cell[ style_StyleData, ___ ] :> style ] ],
  True
]

VerificationTest[ (* and a merged cell really carries both settings *)
  Sort @ Cases[ viewStyleCells[ "StubSheet.nb", <| "DocumentFontSize" -> 20, "ContentWidth" -> 0.6 |> ],
    Cell[ StyleData[ "Text" ], options___ ] :> Sort @ Keys @ { options } ],
  { { CellMargins, FontSize } }
]

VerificationTest[ (* the sheet keeps the parent recoverable and marks itself as ours *)
  With[ { sheet = viewStyleSheet[ "AMSArticle.nb", <| "DocumentFontSize" -> 20 |> ] },
    { First @ First @ sheet,
      Count[ First @ sheet, Cell[ StyleData[ "MathNotebookView" ], ___ ] ],
      Last @ sheet } ],
  { Cell[ StyleData[ StyleDefinitions -> "AMSArticle.nb" ] ], 1,
    StyleDefinitions -> "PrivateStylesheetFormatting.nb" }
]

VerificationTest[ (* the list styles are covered even though no MathNotebook sheet declares them *)
  Complement[ { "Item", "ItemNumbered", "Text", "Section" }, columnStyleNames[] ],
  { }
]
