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
  importedText @ latexToNotebook[ source ]

importedText[ imported_Notebook ] :=
  Module[ { notebook, file },
    notebook = NotebookPut[
      Append[ imported,
        StyleDefinitions -> Get @ FileNameJoin[ { $sheetDirectory, "AMSArticle.nb" } ] ],
      Visible -> False ];
    file = Export[ FileNameJoin[ { $TemporaryDirectory, "MathNotebookImported.pdf" } ], notebook ];
    NotebookClose[ notebook ];
    Import[ file, "Plaintext" ]
  ]

(* LaTeXPaperImport T4: a bibliography read out of a .bib has to reach the page. Its Reference cells
   emit nothing into the .tex, so nothing in the round trip can tell whether they render at all —
   only the rendered document can. The entry's label is its own [key] dingbat, written into the cell
   because a dingbat cannot read the tags of the cell it labels. *)

$bibliographySource = "\\documentclass{article}\n\\begin{document}\n\nProse citing \\cite{ehlers} and \\cite[Theorem~1.1]{andreka}.\n\n\\bibliography{refs}\n\n\\end{document}\n";

$bibliographyBib = "@article{ehlers,\n  title={The geometry of free fall},\n  author={Ehlers, J{\\\"u}rgen},\n  year={2012}\n}\n\n@article{andreka,\n  title={A logic road},\n  author={Andr{\\'e}ka, Hajnal},\n  year={2012}\n}\n";

(* LaTeXPaperImport T5: what only the page can show is the numbering — a caption numbers itself from
   its own counter, and article counts figures straight through the document rather than per section,
   so a \ref at a figure has to read "2" and not "2.1" or the front end's XXX. The evaluated figure's
   graphic is put in kernel-side rather than by NotebookEvaluate: the front end's evaluator is the
   same kernel that is driving it, and asking for it from inside UsingFrontEnd hangs. *)

$figurePaper = "\\documentclass{article}\n\\begin{document}\n\n\\begin{figure}\n\\centering\n\\includegraphics{first.png}\n\\caption{The first picture.}\n\\label{fig:one}\n\\end{figure}\n\n\\begin{figure}\n\\centering\n\\includegraphics{second.png}\n\\caption{The second picture.}\n\\label{fig:two}\n\\end{figure}\n\nSee Figure~\\ref{fig:two}.\n\n\\end{document}\n";

(* The imported code is an Import of the file the paper shipped; a figure whose code has been
   evaluated carries its graphic in an Output cell beside it, which is what this stands in for. *)
evaluatedFigures[ source_String ] :=
  Replace[ latexToNotebook[ source ],
    Notebook[ cells_List, options___ ] :>
      Notebook[
        Flatten @ Replace[ cells,
          cell : Cell[ BoxData[ _String ], "Input", ___ ] :>
            { cell, Cell[ BoxData @ ToBoxes @ Graph[ { 1 -> 2, 2 -> 3 } ], "Output" ] }, { 1 } ],
        options ] ]

figureMeasurements[ source_String ] :=
  With[ { evaluated = evaluatedFigures[ source ] },
    <| "Graphics" -> Count[ evaluated, _GraphicsBox, Infinity ],
      "Exported" -> notebookToLaTeX[ evaluated ] === source,
      "Ink" -> notebookImageInk[ evaluated ] > notebookImageInk[ latexToNotebook[ source ] ],
      "Text" -> importedText[ latexToNotebook[ source ] ] |> ]

(* Only a real save can show this: the front end splits a ButtonBox[RowBox[...]] in a TextData into
   one button per run, so before the runs were merged back an imported paper round-tripped only as
   long as nobody wrote it to disk — the specimen's citations came back multiplied five and fifteen
   fold and its \eqref came back as \cite\ref\cite. *)
savedRoundTrip[ source_String ] :=
  Module[ { file, notebook, back },
    file = FileNameJoin[ { $TemporaryDirectory, "MathNotebookSaved.nb" } ];
    Export[ file, latexToNotebook[ source ], "NB" ];
    notebook = NotebookOpen[ file, Visible -> False ];
    back = NotebookGet[ notebook ];
    NotebookClose[ notebook ];
    <| "Buttons" -> Count[ back, _ButtonBox, Infinity ], "Exported" -> notebookToLaTeX[ back ] === source |>
  ]

$savedSource = "\\documentclass{article}\n\\begin{document}\n\n\\section{S} \\label{sec:a}\n\nSee \\cite{first, second} and Section~\\ref{sec:a} and~\\eqref{eq:a}.\n\n\\begin{equation}\\label{eq:a}\nx^2\n\\end{equation}\n\n\\end{document}\n";

(* LaTeXPaperImport T7: an environment body that spans cells has to number itself once. The name,
   the number and the QED square come from the style, so every cell of a three-cell theorem would
   carry all three and the next theorem would be 1.4 — and none of that is visible in the kernel or
   in a round trip, because both read the stored source. Only the rendered page shows it. *)

$bodyPaper = "\\documentclass{article}\n\\newtheorem{thm}{Theorem}[section]\n\\begin{document}\n\n\\section{First}\n\n\\begin{thm}\\label{Thm:a}\nA first claim, before the equation:\n\\begin{equation}\\label{Eq:a}\nx^2 + y^2 = z^2\n\\end{equation}\nand a second claim after it.\n\\end{thm}\n\n\\begin{proof}\nFirst step.\n\\begin{equation*}\na + b\n\\end{equation*}\nSecond step.\n\\end{proof}\n\n\\begin{thm}\\label{Thm:b}\nA later claim.\n\\end{thm}\n\nSee Theorem~\\ref{Thm:a}, Theorem~\\ref{Thm:b} and~\\eqref{Eq:a}.\n\n\\end{document}\n";

notebookImageInk[ imported_Notebook ] :=
  Module[ { notebook, file },
    notebook = NotebookPut[
      Append[ imported, StyleDefinitions -> Get @ FileNameJoin[ { $sheetDirectory, "AMSArticle.nb" } ] ],
      Visible -> False ];
    file = Export[ FileNameJoin[ { $TemporaryDirectory, "MathNotebookFigureInk.png" } ], notebook,
      ImageResolution -> 72 ];
    NotebookClose[ notebook ];
    inkOf @ Import[ file ]
  ]

$measured = UsingFrontEnd @ <|
  "Imported" -> importedText[ $importedSource ],
  "Figures" -> figureMeasurements[ $figurePaper ],
  "Saved" -> savedRoundTrip[ $savedSource ],
  "Body" -> importedText @ latexToNotebook[ $bodyPaper ],
  "Bibliography" -> importedText @ latexToNotebook[ $bibliographySource, bibliographyDatabase[ $bibliographyBib ] ],
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

(* LaTeXPaperImport T4: the bibliography is on the page, each entry under its own [key] dingbat and
   its TeX accent drawn as the character it prints; the citation in the prose reads as the same
   label, and the \bibliography command itself is nowhere to be seen. *)
VerificationTest[
  { StringContainsQ[ $measured[ "Bibliography" ], "[ehlers] J" ],
    StringContainsQ[ $measured[ "Bibliography" ], "rgen Ehlers, The geometry of free fall, 2012." ],
    StringContainsQ[ $measured[ "Bibliography" ], "[andreka, Theorem~1.1]" ],
    StringContainsQ[ $measured[ "Bibliography" ], "\\bibliography" ],
    StringContainsQ[ $measured[ "Bibliography" ], "XXX" ] },
  { True, True, True, False, False }
]

(* ... and the two the kernel has opinions about draw the italic letter, not the constant. *)
VerificationTest[
  With[ { ink = $measured[ "LetterInk" ] },
    { ink[ "E" ] === ink[ "ItalicE" ], ink[ "E" ] =!= ink[ "ExponentialE" ],
      ink[ "I" ] === ink[ "ItalicI" ], ink[ "I" ] =!= ink[ "ImaginaryI" ] } ],
  { True, True, True, True }
]

(* LaTeXPaperImport T5: the captions number themselves on the page, straight through the document as
   article does, and "Figure~2" is the number of the cell the label landed on rather than the front
   end's XXX. An evaluated figure's graphic really lands in the rendered document — strictly more ink
   than the same paper unevaluated — and still exports the source byte for byte, so a live picture
   cannot leak into the .tex. *)
VerificationTest[
  { StringContainsQ[ $measured[ "Figures", "Text" ], "Figure 1. The first picture." ],
    StringContainsQ[ $measured[ "Figures", "Text" ], "Figure 2. The second picture." ],
    StringContainsQ[ $measured[ "Figures", "Text" ], "See Figure~2." ],
    StringContainsQ[ $measured[ "Figures", "Text" ], "XXX" ],
    $measured[ "Figures", "Graphics" ] > 0,
    $measured[ "Figures", "Ink" ],
    $measured[ "Figures", "Exported" ] },
  { True, True, True, False, True, True, True }
]

(* A paper written to disk and opened again still exports its source byte for byte. The front end
   handed back nine buttons where the import made three — one per bracket, comma and key — and every
   one of them would have exported a command of its own. *)
VerificationTest[
  { $measured[ "Saved", "Buttons" ] > 3, $measured[ "Saved", "Exported" ] },
  { True, True }
]

(* LaTeXPaperImport T7: a theorem whose body wraps around a display equation is three cells, and the
   page has to show one heading, one number and one equation number for it — and the theorem after
   it has to read 1.2 and not 1.4. The proof beside it is the same claim for the QED square, which
   comes from CellFrameLabels rather than from the dingbat and so needs suppressing separately. *)
VerificationTest[
  { StringCount[ $measured[ "Body" ], "Theorem 1.1." ],
    StringCount[ $measured[ "Body" ], "Theorem 1.2." ],
    StringCount[ $measured[ "Body" ], "Proof." ],
    StringCount[ $measured[ "Body" ], "\[EmptySquare]" ],
    StringContainsQ[ $measured[ "Body" ], "See Theorem~1.1, Theorem~1.2 and~(1)." ],
    StringContainsQ[ $measured[ "Body" ], "XXX" | "\\begin{equation" ] },
  { 1, 1, 1, 1, True, False }
]
