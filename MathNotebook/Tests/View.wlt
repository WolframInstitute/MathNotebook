Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

(* The base geometry a real parent sheet would supply, stubbed so the arithmetic is testable
   without a front end: Section hangs 26 pt left of Text, which is what forces the offsets to be
   anchored on the smallest margin rather than on Text. *)
baseCellMargins[ "StubSheet.nb" ] = <|
  "Text" -> { { 66, 10 }, { 4, 4 } },
  "Section" -> { { 40, 25 }, { 10, 28 } },
  "Theorem" -> { { 130, 10 }, { 8, 8 } } |>;

styleNames[ cells_List ] := Cases[ cells, Cell[ StyleData[ style_String, ___ ], ___ ] :> style ];

VerificationTest[ (* the size hierarchy is readable out of the base sheet, in both environments *)
  { NumericQ @ documentFontSizeAnchor[], NumericQ @ mathFontSizeAnchor[],
    SubsetQ[ Keys @ baseFontSizes[][ "Screen" ], { "Text", "Title", "DisplayFormula" } ],
    SubsetQ[ Keys @ baseFontSizes[][ "Printout" ], { "Text", "Title", "DisplayFormula" } ] },
  { True, True, True, True }
]

VerificationTest[ (* an untouched document gets no override cells at all *)
  viewStyleCells[ "StubSheet.nb", <| |> ],
  { }
]

VerificationTest[ (* at the anchor size every style is written back at exactly its base size *)
  Union @ Cases[
    viewStyleCells[ "StubSheet.nb", <| "DocumentFontSize" -> documentFontSizeAnchor[] |> ],
    Cell[ StyleData[ style_String ], FontSize -> size_ ] :> size === baseFontSizes[][ "Screen", style ] ],
  { True }
]

VerificationTest[ (* the whole hierarchy scales proportionally, not just Text *)
  Cases[ viewStyleCells[ "StubSheet.nb", <| "DocumentFontSize" -> 2 documentFontSizeAnchor[] |> ],
    Cell[ StyleData[ "Title" ], ___, FontSize -> size_, ___ ] :> size ],
  { Round[ 2 baseFontSizes[][ "Screen", "Title" ] ] }
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
  { Round[ 20 baseFontSizes[][ "Printout", "DisplayFormula" ] / mathFontSizeAnchor[] ] }
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
