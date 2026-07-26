Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

(* The base geometry a real parent sheet would supply, stubbed so the arithmetic is testable
   without a front end: Section hangs 26 pt left of Text, which is what forces the offsets to be
   anchored on the smallest margin rather than on Text. *)
baseCellMargins[ "StubSheet.nb" ] = <|
  "Screen" -> <|
    "Text" -> { { 66, 10 }, { 4, 4 } },
    "Section" -> { { 40, 25 }, { 10, 28 } },
    "Theorem" -> { { 130, 10 }, { 8, 8 } } |>,
  "Printout" -> <|
    "Text" -> { { 49, 3 }, { 4, 4 } },
    "Section" -> { { 30, 18 }, { 10, 28 } },
    "Theorem" -> { { 97, 3 }, { 8, 8 } } |> |>;

(* Default.nb lays every printout style out at 0.72 before it reaches the paper. *)
printMagnification[ "StubSheet.nb" ] = 0.72;

(* The printable width of the A4 with 72 pt margins the template sheets declare — a property of the
   document rather than of its stylesheet, which is why it is an argument and not a chain read. *)
$printable = 451.28;

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
  Intersection[ styleNames @ viewStyleCells[ "StubSheet.nb", $printable, <| "DocumentFontSize" -> 20 |> ],
    { "Hyperlink", "Citation", "URL" } ],
  { }
]

VerificationTest[ (* the text control reaches the theorem, proof, reference and list styles on SCREEN,
                     which is the defect Pavel reported: they carry no bare FontSize in LaTeXBase *)
  Complement[ { "Theorem", "Proof", "Reference", "Item", "ItemNumbered" },
    Cases[ viewStyleCells[ "StubSheet.nb", $printable, <| "DocumentFontSize" -> 20 |> ],
      Cell[ StyleData[ style_String ], ___, FontSize -> _, ___ ] :> style ] ],
  { }
]

VerificationTest[ (* an untouched document gets no override cells at all *)
  viewStyleCells[ "StubSheet.nb", $printable, <| |> ],
  { }
]

VerificationTest[ (* at the anchor size every style is written back at exactly its base size *)
  Union @ Cases[
    viewStyleCells[ "StubSheet.nb", $printable, <| "DocumentFontSize" -> documentFontSizeAnchor[ "StubSheet.nb" ] |> ],
    Cell[ StyleData[ style_String ], FontSize -> size_ ] :> size === baseFontSizes[ "StubSheet.nb" ][ "Screen", style ] ],
  { True }
]

VerificationTest[ (* the whole hierarchy scales proportionally, not just Text *)
  Cases[ viewStyleCells[ "StubSheet.nb", $printable, <| "DocumentFontSize" -> 2 documentFontSizeAnchor[ "StubSheet.nb" ] |> ],
    Cell[ StyleData[ "Title" ], ___, FontSize -> size_, ___ ] :> size ],
  { Round[ 2 baseFontSizes[ "StubSheet.nb" ][ "Screen", "Title" ] ] }
]

VerificationTest[ (* prose and mathematics are independent *)
  Intersection[ styleNames @ viewStyleCells[ "StubSheet.nb", $printable, <| "DocumentFontSize" -> 20 |> ], $mathStyleNames ],
  { }
]

VerificationTest[ (* the math control reaches the equation number, which would otherwise drift *)
  Union @ styleNames @ viewStyleCells[ "StubSheet.nb", $printable, <| "MathFontSize" -> 20 |> ],
  Union @ $mathStyleNames
]

VerificationTest[ (* every size override is written in the "Printout" variant too, or it never prints *)
  Cases[ viewStyleCells[ "StubSheet.nb", $printable, <| "MathFontSize" -> 20 |> ],
    Cell[ StyleData[ "DisplayFormula", "Printout" ], ___, FontSize -> size_, ___ ] :> size ],
  { Round[ 20 baseFontSizes[ "StubSheet.nb" ][ "Printout", "DisplayFormula" ] / mathFontSizeAnchor[ "StubSheet.nb" ] ] }
]

VerificationTest[ (* on screen the two symmetric Scaled halves cancel the window out, leaving Text
                     in an absolute column of `width` points that stays centered as it is resized *)
  Cases[ contentWidthCells[ "StubSheet.nb", $printable, 300 ],
    Cell[ StyleData[ "Text" ], CellMargins -> value_ ] :> value ],
  { { { Scaled[ 0.5 ] - 150, Scaled[ 0.5 ] - 150 }, { 4, 4 } } }
]

VerificationTest[ (* Section hangs 26 pt to the left of that column, as it does in the base sheet *)
  Cases[ contentWidthCells[ "StubSheet.nb", $printable, 300 ],
    Cell[ StyleData[ "Section" ], CellMargins -> { { left_, _ }, _ } ] :> left ],
  { Scaled[ 0.5 ] - 176 }
]

VerificationTest[ (* in print the inset is points, not Scaled, and it is divided by the printout
                     magnification: Text has to measure 300 pt on the paper itself *)
  With[ { inset = Cases[ contentWidthCells[ "StubSheet.nb", $printable, 300 ],
      Cell[ StyleData[ "Text", "Printout" ], CellMargins -> { pair : { _, _ }, _ } ] :> pair ] },
    $printable - printMagnification[ "StubSheet.nb" ] Total @ First @ inset ],
  300.,
  SameTest -> Equal
]

VerificationTest[ (* the width prints as well as it displays *)
  Length @ Cases[ contentWidthCells[ "StubSheet.nb", $printable, 300 ],
    Cell[ StyleData[ "Section", "Printout" ], CellMargins -> _ ] ],
  1
]

VerificationTest[ (* Full, and the top of the palette's slider, leave the page unconstrained *)
  { contentWidthCells[ "StubSheet.nb", $printable, Full ],
    contentWidthCells[ "StubSheet.nb", $printable, $fullContentWidth ] },
  { { }, { } }
]

VerificationTest[ (* a column wider than the paper clamps at the widest hang rather than printing a
                     section number off the edge of the page *)
  Union @ Cases[ contentWidthCells[ "StubSheet.nb", 300, 480 ],
    Cell[ StyleData[ "Section", "Printout" ], CellMargins -> { { left_, _ }, _ } ] :> left ],
  { 0 }
]

VerificationTest[ (* two cells for one style cancel in the front end, so the three controls must merge *)
  With[ { cells = viewStyleCells[ "StubSheet.nb", $printable,
      <| "DocumentFontSize" -> 20, "MathFontSize" -> 16, "ContentWidth" -> 300 |> ] },
    DuplicateFreeQ @ Cases[ cells, Cell[ style_StyleData, ___ ] :> style ] ],
  True
]

VerificationTest[ (* and a merged cell really carries both settings *)
  Sort @ Cases[ viewStyleCells[ "StubSheet.nb", $printable, <| "DocumentFontSize" -> 20, "ContentWidth" -> 300 |> ],
    Cell[ StyleData[ "Text" ], options___ ] :> Sort @ Keys @ { options } ],
  { { CellMargins, FontSize } }
]

VerificationTest[ (* the sheet keeps the parent recoverable and marks itself as ours *)
  With[ { sheet = viewStyleSheet[ "AMSArticle.nb", $printable, <| "DocumentFontSize" -> 20 |> ] },
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
