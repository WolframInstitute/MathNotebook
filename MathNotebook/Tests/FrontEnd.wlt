Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

(* The other test files are kernel-only and stub every chain read. This one is the opposite on
   purpose: both defects in ViewAndReferenceDefects passed their unit tests and still shipped
   broken, because "the call wrote an override cell" is not "the style changed size". Everything
   here is measured through a real front end and a real stylesheet chain, so the assertions are the
   reproductions Pavel reported rather than restatements of the code.

   The sheets are embedded with Get rather than named: a paclet stylesheet resolved by name has
   been seen to fall back to Default.nb in a headless run, so every measurement asserts the sheet
   really loaded before it is trusted. While a view override is installed, the private sheet's
   parent is an embedded notebook, and styles it does NOT override then fall through to Default.nb
   — harmless here because every style asserted is one the override writes. *)

$sheetDirectory = FileNameJoin[ { PacletObject[ "WolframInstitute/MathNotebook" ][ "Location" ],
  "FrontEnd", "StyleSheets", "MathNotebook" } ];

$templates = { "AMSArticle.nb", "ArXivArticle.nb", "RevTeXAPS.nb", "SpringerJournal.nb" };

resolvedSizes[ notebook_, styles_ ] := <|
  "Screen" -> AssociationMap[ CurrentValue[ notebook, { StyleDefinitions, #, FontSize } ] &, styles ],
  "Printout" -> AssociationMap[ CurrentValue[ notebook, { StyleDefinitions, { #, "Printout" }, FontSize } ] &, styles ]
|>

(* One front-end session measures every sheet; the tests below are pure comparisons on the result,
   so a front-end failure surfaces as a failed assertion rather than as a message storm. *)
viewMeasurements[ parent_ ] :=
  Module[ { notebook, prose, base, scaled, restored },
    notebook = CreateDocument[ { }, Visible -> False, StyleDefinitions -> parent ];
    prose = Complement[ Keys @ baseFontSizes[ parent ][ "Screen" ], $mathStyleNames ];
    base = resolvedSizes[ notebook, prose ];
    SetDocumentFontSize[ notebook, 20 ];
    scaled = resolvedSizes[ notebook, prose ];
    ResetDocumentView[ notebook ];
    restored = resolvedSizes[ notebook, prose ];
    NotebookClose[ notebook ];
    <| "Prose" -> prose, "Base" -> base, "Scaled" -> scaled, "Restored" -> restored |>
  ]

citationMeasurements[ parent_ ] :=
  Module[ { notebook, styles },
    notebook = NotebookPut @ Notebook[ {
      Cell[ "A section", "Section", CellTags -> "sec" ],
      Cell[ "A theorem", "Theorem", CellTags -> "thm" ],
      Cell[ "A definition", "Definition", CellTags -> "def" ],
      Cell[ "Ollivier, Ricci curvature", "Reference", CellTags -> "ollivier" ],
      Cell[ "Prose", "Text", CellTags -> "prose" ] },
      StyleDefinitions -> parent, Visible -> False ];
    styles = AssociationMap[
      Symbol[ "WolframInstitute`MathNotebook`Referencing`PackagePrivate`citationTargetStyle" ][ notebook, # ] &,
      { "sec", "thm", "def", "ollivier", "prose", "absent" } ];
    NotebookClose[ notebook ];
    styles
  ]

(* Inline Math Converter Defects, requirement 4: assert what a converted cell *displays*. The
   round trip reads back the stored "SourceTeX" rather than the boxes, so a cell that renders as a
   blank still exports byte-identically — display fidelity has to be measured on its own. Ink area
   is the measurement: a converted span carries less ink than the literal "$...$" it replaces (the
   two delimiters are gone) and more than an empty box. *)

inkOf[ image_ ] :=
  Total @ Flatten @ Unitize @ Subtract[ 255,
    ImageData[ ColorConvert[ image, "Grayscale" ], "Byte" ] ]

inkArea[ cell_ ] :=
  inkOf @ Rasterize[ cell, ImageResolution -> 72, LightDark -> "Light" ]

inlineInk[ text_String ] := <|
  "Converted" -> inkArea @ Cell[ TextData @ splitInlineMath[ text ], "Text" ],
  "Literal" -> inkArea @ Cell[ text, "Text" ],
  "Blank" -> inkArea @ Cell[ TextData @ { First @ StringSplit[ text, "$" ],
    Cell[ BoxData[ FormBox[ "", TraditionalForm ] ] ], Last @ StringSplit[ text, "$" ] }, "Text" ]
|>

(* T2: the same assertion one level up. A display environment glued into a paragraph is now split
   into its own cell, so what has to be shown is that the formula really renders and that the
   starred form really is unnumbered. The equation number is a CounterBox and a single rasterized
   cell has no document context to resolve one — both starred and unstarred measured 243 that way —
   so the numbering half renders the whole notebook. *)

$displayParagraph = "The cone at $p$ is:\n\\begin{equation*}\n  x^2 + y^2 = z^2\n\\end{equation*}\nand that is all.";

notebookInk[ text_String ] :=
  Module[ { notebook, file },
    notebook = NotebookPut[ convertLaTeXNotebook @ Notebook[ { Cell[ text, "Text" ] } ], Visible -> False ];
    file = Export[ FileNameJoin[ { $TemporaryDirectory, "MathNotebookDisplayInk.png" } ], notebook, ImageResolution -> 72 ];
    NotebookClose[ notebook ];
    inkOf @ Import[ file ]
  ]

displayInk[ text_String ] := <|
  "Starred" -> notebookInk[ text ],
  "Unstarred" -> notebookInk @ StringReplace[ text, "equation*" -> "equation" ],
  "Literal" -> inkArea @ Cell[ text, "Text" ],
  "Formula" -> inkArea @ FirstCase[
    First @ convertLaTeXNotebook @ Notebook[ { Cell[ text, "Text" ] } ], Cell[ _, "DisplayFormula", ___ ] ]
|>

(* T3: a letter that the kernel reads as a constant is a *display* defect and nothing else — the
   exporter reads the stored "SourceTeX", so a cell showing Euler's number still round-trips
   byte-identically. What has to be measured is the glyph. Every letter carries ink, and E and I
   carry exactly the ink of the italic letters rather than that of the two constants. *)

$letters = Join[ CharacterRange[ "a", "z" ], CharacterRange[ "A", "Z" ] ];

mathInk[ boxes_ ] :=
  inkArea @ Cell[ BoxData[ FormBox[ boxes, TraditionalForm ] ], "Text" ]

letterInk[ ] := <|
  "Minimum" -> Min @ Map[ mathInk @ texToBoxes[ # ] &, $letters ],
  "E" -> mathInk @ texToBoxes[ "E" ], "ItalicE" -> mathInk @ StyleBox[ "E", "TI" ],
  "ExponentialE" -> mathInk[ "\[ExponentialE]" ],
  "I" -> mathInk @ texToBoxes[ "I" ], "ItalicI" -> mathInk @ StyleBox[ "I", "TI" ],
  "ImaginaryI" -> mathInk[ "\[ImaginaryI]" ]
|>

(* LaTeXPaperImport T3: an imported \ref has to render as the target's number. The front end
   resolves a CounterBox against the tagged cell with no kernel — and renders XXX when the tag is
   not there, which is the failure this measures. A whole document has to be rendered: a single
   rasterized cell has no document context and every counter in it reads 0. *)

$importedSource = "\\documentclass{article}\n\\newtheorem{defn}{Definition}[section]\n\\begin{document}\n\n\\section{First} \\label{sec:one}\n\n\\section{Second} \\label{sec:two}\n\n\\begin{defn} \\label{def:one}\nA body.\n\\end{defn}\n\nSee Section~\\ref{sec:two} and Definition~\\ref{def:one}.\n\n\\end{document}\n";

importedText[ source_String ] :=
  Module[ { notebook, file },
    notebook = NotebookPut[
      Append[ latexToNotebook[ source ],
        StyleDefinitions -> Get @ FileNameJoin[ { $sheetDirectory, "AMSArticle.nb" } ] ],
      Visible -> False ];
    file = Export[ FileNameJoin[ { $TemporaryDirectory, "MathNotebookImported.pdf" } ], notebook ];
    NotebookClose[ notebook ];
    Import[ file, "Plaintext" ]
  ]

$measured = UsingFrontEnd @ <|
  "Imported" -> importedText[ $importedSource ],
  "InlineInk" -> AssociationMap[ inlineInk, { "A pair $(V, E)$ here.", "A list $x_1, x_2$ here." } ],
  "DisplayInk" -> displayInk[ $displayParagraph ],
  "LetterInk" -> letterInk[ ],
  "Sheets" -> AssociationMap[ viewMeasurements @ Get @ FileNameJoin[ { $sheetDirectory, # } ] &, $templates ],
  "Default" -> viewMeasurements[ "Default.nb" ],
  "SheetLoaded" -> AssociationMap[
    Module[ { notebook = CreateDocument[ { }, Visible -> False,
        StyleDefinitions -> Get @ FileNameJoin[ { $sheetDirectory, # } ] ], size },
      size = CurrentValue[ notebook, { StyleDefinitions, "Title", FontSize } ];
      NotebookClose[ notebook ];
      size ] &,
    $templates ],
  "Citations" -> citationMeasurements @ Get @ FileNameJoin[ { $sheetDirectory, "AMSArticle.nb" } ]
|>;

(* Nothing below is meaningful unless the template sheets actually loaded: Default.nb sizes Title
   at 45, every MathNotebook template at 26. *)
VerificationTest[
  Union @ Values @ $measured[ "SheetLoaded" ],
  { 26 }
]

(* The reported defect, literally: on every template, Theorem, Proof, Reference, Item and
   ItemNumbered stayed at their base size while Text moved. *)
VerificationTest[
  AssociationMap[
    Complement[ { "Theorem", "Proof", "Reference", "Item", "ItemNumbered" }, $measured[ "Sheets", #, "Prose" ] ] &,
    $templates ],
  AssociationMap[ { } &, $templates ]
]

VerificationTest[ (* Text lands exactly on the requested size, on screen and in print *)
  AssociationMap[ $measured[ "Sheets", #, "Scaled", "Screen", "Text" ] &, $templates ],
  AssociationMap[ 20 &, $templates ]
]

VerificationTest[ (* every prose style moved — screen AND "Printout", or the PDF is unchanged *)
  Union @ Flatten @ Table[
    With[ { m = $measured[ "Sheets", sheet ] },
      Table[ m[ "Scaled", environment, style ] > m[ "Base", environment, style ],
        { environment, { "Screen", "Printout" } }, { style, m[ "Prose" ] } ] ],
    { sheet, $templates } ],
  { True }
]

VerificationTest[ (* reset restores every base size exactly, not approximately *)
  AssociationMap[ $measured[ "Sheets", #, "Restored" ] === $measured[ "Sheets", #, "Base" ] &, $templates ],
  AssociationMap[ True &, $templates ]
]

(* A plain Default.nb document has no theorem environments; the control must still reach the prose
   it does have, and writing cells for absent styles must stay harmless. *)
VerificationTest[
  { $measured[ "Default", "Scaled", "Screen", "Text" ],
    SubsetQ[ $measured[ "Default", "Prose" ], { "Text", "Item", "ItemNumbered" } ],
    Union @ Table[ $measured[ "Default", "Scaled", "Screen", style ] > $measured[ "Default", "Base", "Screen", style ],
      { style, $measured[ "Default", "Prose" ] } ],
    $measured[ "Default", "Restored" ] === $measured[ "Default", "Base" ] },
  { 20, True, { True }, True }
]

(* T3: the style a citation renders from is resolved from the tag through the live notebook. *)
VerificationTest[
  $measured[ "Citations" ],
  <| "sec" -> "Section", "thm" -> "Theorem", "def" -> "Definition",
     "ollivier" -> "Reference", "prose" -> "Text", "absent" -> None |>
]

(* ... so a numbered environment cites by number and everything else keeps the tag. *)
VerificationTest[
  KeyValueMap[ FreeQ[ citationButton[ #1, #2 ], _CounterBox ] &, $measured[ "Citations" ] ],
  { False, False, False, True, True, True }
]

(* Inline Math Converter Defects T1: a comma-bearing span really renders as mathematics — visible
   ink, and the "$" delimiters gone. Blank < Converted < Literal on every specimen. *)
VerificationTest[
  Map[ #[ "Blank" ] < #[ "Converted" ] < #[ "Literal" ] &, $measured[ "InlineInk" ] ],
  AssociationMap[ True &, { "A pair $(V, E)$ here.", "A list $x_1, x_2$ here." } ]
]

(* T2: the split formula carries ink, and the paragraph as a whole carries less than the literal
   LaTeX it replaces — the backslashes are gone. *)
VerificationTest[
  { $measured[ "DisplayInk", "Formula" ] > 0,
    $measured[ "DisplayInk", "Starred" ] < $measured[ "DisplayInk", "Literal" ] },
  { True, True }
]

(* ... and "equation*" really is unnumbered on the page: the identical document written with
   "equation" carries strictly more ink, and the equation number is the only difference. *)
VerificationTest[
  $measured[ "DisplayInk", "Starred" ] < $measured[ "DisplayInk", "Unstarred" ],
  True
]

(* T3: no letter of the alphabet renders blank ... *)
VerificationTest[
  $measured[ "LetterInk", "Minimum" ] > 0,
  True
]

(* LaTeXPaperImport T3: the references resolve on the page. "Section~2" and "Definition~2.1" are
   the numbers of the cells the labels landed on, and no reference renders as the front end's XXX. *)
VerificationTest[
  { StringContainsQ[ $measured[ "Imported" ], "Section~2" ],
    StringContainsQ[ $measured[ "Imported" ], "Definition~2.1" ],
    StringContainsQ[ $measured[ "Imported" ], "XXX" ] },
  { True, True, False }
]

(* ... and the two the kernel has opinions about draw the italic letter, not the constant. *)
VerificationTest[
  With[ { ink = $measured[ "LetterInk" ] },
    { ink[ "E" ] === ink[ "ItalicE" ], ink[ "E" ] =!= ink[ "ExponentialE" ],
      ink[ "I" ] === ink[ "ItalicI" ], ink[ "I" ] =!= ink[ "ImaginaryI" ] } ],
  { True, True, True, True }
]
