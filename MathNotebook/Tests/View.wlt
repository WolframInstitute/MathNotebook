Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

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
  Union @ Append[ $mathStyleNames, $inlineMathStyleName ]
]

(* PaletteAndViewUX T2: inline mathematics is the fourth math style and the only one whose override is
   RELATIVE. An inline island is styled "InlineFormula", which resolves through the chain as
   1.05*Inherited and so renders at 1.05 x the size of the cell it sits in; the control scales that
   ratio rather than writing a size, because an absolute size reaches the island but stops the tracking
   (measured: a Title's inline mathematics shrinks from 1649 ink to 1577). So this is the one override
   asserted as an expression and not a number, and it is Inherited-bearing on purpose. *)
VerificationTest[
  Cases[ viewStyleCells[ "StubSheet.nb", <| "MathFontSize" -> 2 mathFontSizeAnchor[ "StubSheet.nb" ] |> ],
    Cell[ StyleData[ $inlineMathStyleName, ___ ], ___, FontSize -> size_, ___ ] :> size ],
  { 2.1 Inherited, 2.1 Inherited }
]

VerificationTest[ (* untouched, the control writes nothing at all and the sheet's own 1.05 stands *)
  Cases[ viewStyleCells[ "StubSheet.nb", <| "DocumentFontSize" -> 20 |> ],
    Cell[ StyleData[ $inlineMathStyleName, ___ ], ___ ] ],
  { }
]

VerificationTest[ (* every size override is written in the "Printout" variant too, or it never prints *)
  Cases[ viewStyleCells[ "StubSheet.nb", <| "MathFontSize" -> 20 |> ],
    Cell[ StyleData[ "DisplayFormula", "Printout" ], ___, FontSize -> size_, ___ ] :> size ],
  { Round[ 20 baseFontSizes[ "StubSheet.nb" ][ "Printout", "DisplayFormula" ] / mathFontSizeAnchor[ "StubSheet.nb" ] ] }
]

VerificationTest[ (* two cells for one style would cancel in the front end, so the controls merge *)
  With[ { cells = viewStyleCells[ "StubSheet.nb", <| "DocumentFontSize" -> 20, "MathFontSize" -> 16 |> ] },
    DuplicateFreeQ @ Cases[ cells, Cell[ style_StyleData, ___ ] :> style ] ],
  True
]

VerificationTest[ (* the withdrawn column-width setting is inert: it writes no cells and no margins *)
  viewStyleCells[ "StubSheet.nb", <| "ContentWidth" -> 300 |> ],
  { }
]

(* ConversionUX T2. A MaTeX cell is an image, so the size it is rendered at has to be computed
   rather than inherited, and both the re-render and ConvertToMaTeX now read it here. The two-
   argument form is the pure core of the NotebookObject one, which is what lets the arithmetic be
   asserted without a front end; the wiring itself is measured in Tests/FrontEnd.wlt. *)
VerificationTest[ (* an untouched document renders MaTeX at the base size and nothing else *)
  maTeXFontSize[ "StubSheet.nb", <| |> ],
  $maTeXBaseFontSize
]

VerificationTest[ (* ... and a scaled one at the ratio the math styles themselves moved by *)
  maTeXFontSize[ "StubSheet.nb", <| "MathFontSize" -> 2 mathFontSizeAnchor[ "StubSheet.nb" ] |> ],
  2 $maTeXBaseFontSize
]

VerificationTest[ (* the prose control must not reach it: MaTeX renders mathematics *)
  maTeXFontSize[ "StubSheet.nb", <| "DocumentFontSize" -> 26 |> ],
  $maTeXBaseFontSize
]

VerificationTest[ (* the sheet keeps the parent recoverable and marks itself as ours *)
  With[ { sheet = viewStyleSheet[ "AMSArticle.nb", <| "DocumentFontSize" -> 20 |> ] },
    { First @ First @ sheet,
      Count[ First @ sheet, Cell[ StyleData[ "MathNotebookView" ], ___ ] ],
      Last @ sheet } ],
  { Cell[ StyleData[ StyleDefinitions -> "AMSArticle.nb" ] ], 1,
    StyleDefinitions -> "PrivateStylesheetFormatting.nb" }
]
