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
   so both halves render the whole notebook.

   LaTeXPaperImport T12: a whole-notebook render and a single-cell Rasterize are not on the same
   scale and must never be compared. So every number that appears on both sides of a comparison
   below comes from notebookInk, "Literal" included; the one cell raster left, "Formula", is only
   ever asked whether it is positive. notebookInk takes the notebook rather than the source text,
   so the unconverted paragraph goes through exactly the same measurement as the converted one.
   The appearance is the second half of "the same way", and it takes BOTH options: inkOf counts every
   pixel that is not white, so on a dark appearance an unpinned background counts the whole canvas as
   ink — and Background -> White alone then leaves the prose drawn in the dark appearance's light
   foreground, on white, so a Text cell measures exactly 0 and every comparison against it inverts.
   That is what it did here, silently, until ConversionUX T2; with LightDark -> "Light" beside it the
   paragraph reads 2440 and the two formulas 1268 and 1368, which is what this file always claimed.
   (WindowSize is not pinned because it cannot be — the export
   crops to the content, so the width follows the text and the ink is unaffected by the wrap.)

   "Formula" reads 0 when no DisplayFormula cell was produced at all, rather than measuring what
   FirstCase returned: rasterizing a bare Missing["NotFound"] draws the words and carries 653 ink,
   so "Formula > 0" was passing on a paragraph the converter had left entirely alone. *)

$displayParagraph = "The cone at $p$ is:\n\\begin{equation*}\n  x^2 + y^2 = z^2\n\\end{equation*}\nand that is all.";

notebookInk[ Notebook[ cells_, options___ ] ] :=
  Module[ { notebook, file },
    notebook = NotebookPut[ Notebook[ cells, options ], Visible -> False, Background -> White,
      LightDark -> "Light" ];
    file = Export[ FileNameJoin[ { $TemporaryDirectory, "MathNotebookDisplayInk.png" } ], notebook, ImageResolution -> 72 ];
    NotebookClose[ notebook ];
    inkOf @ Import[ file ]
  ]

convertedParagraph[ text_String ] :=
  convertLaTeXNotebook @ Notebook[ { Cell[ text, "Text" ] } ]

displayInk[ text_String ] := <|
  "Starred" -> notebookInk @ convertedParagraph[ text ],
  "Unstarred" -> notebookInk @ convertedParagraph @ StringReplace[ text, "equation*" -> "equation" ],
  "Literal" -> notebookInk @ Notebook[ { Cell[ text, "Text" ] } ],
  "Formula" -> Replace[ FirstCase[ First @ convertedParagraph[ text ], Cell[ _, "DisplayFormula", ___ ] ],
    { cell_Cell :> inkArea[ cell ], _ -> 0 } ]
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

(* An imported notebook carries a StyleDefinitions of its own since T11 — chosen from the
   \documentclass — and a second one appended after it is ignored, so these tests replace it rather
   than append. Embedding the sheet is the only form that resolves reliably headless. *)
sheetDefinitions[ sheet_String ] :=
  With[ { file = FileNameJoin[ { $sheetDirectory, sheet } ] },
    If[ FileExistsQ[ file ], Get[ file ], sheet ] ]

withSheet[ Notebook[ cells_, options___ ], sheet_String ] :=
  Notebook[ cells, StyleDefinitions -> sheetDefinitions[ sheet ],
    Sequence @@ FilterRules[ { options }, Except[ StyleDefinitions ] ] ]

importedText[ imported_Notebook ] :=
  Module[ { notebook, file },
    notebook = NotebookPut[ withSheet[ imported, "AMSArticle.nb" ], Visible -> False ];
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

(* LaTeXPaperImport T10: the other bibliography, and the same reason it needs the page. Here the
   entries do reach the .tex — they are the source — so the round trip says they survived, and says
   nothing at all about whether the block renders as a bibliography or as two paragraphs of prose
   with a stray marker in front of each. Only the rendered document separates those. *)

$entrySource = "\\documentclass{article}\n\\begin{document}\n\nProse citing \\cite{smith}.\n\n\\begin{thebibliography}{9}\n\\bibitem[Sm09]{smith} A.~Smith, \\emph{A title}, 2009.\n\\bibitem{jones} B.~Jones, \\emph{Another}, 2011.\n\\end{thebibliography}\n\n\\end{document}\n";

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
    notebook = NotebookPut[ withSheet[ imported, "AMSArticle.nb" ], Visible -> False,
      Background -> White, LightDark -> "Light" ];
    file = Export[ FileNameJoin[ { $TemporaryDirectory, "MathNotebookFigureInk.png" } ], notebook,
      ImageResolution -> 72 ];
    NotebookClose[ notebook ];
    inkOf @ Import[ file ]
  ]

(* LaTeXPaperImport T8: LaTeX restarts every list, where the front end's ItemNumbered counter runs on
   until a Section resets it — so two lists in one section would read 1, 2, 3, 4 and the second one
   would be wrong. The reset is a CounterAssignments on the first item of each list, and nothing in
   the kernel or in the round trip can see whether it worked: both read the stored source. Reading the
   resolved counter off the live cells is exact where the rendered page is not — an item's dingbat is
   just "1.", which collides with everything in a PDF's plaintext. An \item[label] prints its label
   instead of the number and consumes no counter, which is why the third value is 0 and not 1. *)

$listPaper = "\\documentclass{article}\n\\begin{document}\n\n\\title{A Title}\n\\author{An Author}\n\\maketitle\n\n\\begin{abstract}\nAn abstract.\n\nA second paragraph of it.\n\\end{abstract}\n\n\\section{First}\n\n\\begin{enumerate}\n\\item First.\n\\item Second.\n\\end{enumerate}\n\nBetween the lists.\n\n\\begin{enumerate}\n\\item[(E)] Labelled.\n\\item Restarted.\n\\end{enumerate}\n\n\\end{document}\n";

listMeasurements[ source_String ] :=
  Module[ { notebook, counters },
    notebook = NotebookPut[ withSheet[ latexToNotebook[ source ], "AMSArticle.nb" ], Visible -> False ];
    counters = Map[ CurrentValue[ #, { "CounterValue", "ItemNumbered" } ] &,
      Cells[ notebook, CellStyle -> "ItemNumbered" ] ];
    NotebookClose[ notebook ];
    <| "Counters" -> counters, "Text" -> importedText @ latexToNotebook[ source ] |>
  ]

(* LaTeXPaperImport T9: the numbering. Every part of this is invisible to the kernel and to the round
   trip — both read the stored source, and the numbering is declared in the preamble, which is carried
   verbatim — so the only place it can be asserted is a live document. The counters are read off the
   cells rather than out of the page for the same reason T8 reads them: "1.1.1" collides with too much
   of a PDF's plaintext to count reliably, and a resolved counter is exact. The page is then read too,
   because the counter says nothing about which counters the dingbat actually prints.
   Four claims at once. A per-subsection definition restarts in the second subsection (1, 2, then 1).
   A lemma sharing the theorem counter numbers with the theorems and not with the definitions. A starred
   environment consumes nothing, so the lemma after the convention is 1.2 and not 1.3 — this is the one
   that was wrong on hodgepaper. And amsart numbers equations within the section, so the equation in the
   second section is (2.1) and not (2). *)

$numberingPaper = "\\documentclass{amsart}\n\\newtheorem{thm}{Theorem}[section]\n\\newtheorem{lem}[thm]{Lemma}\n\\newtheorem{defn}{Definition}[subsection]\n\\newtheorem*{conv}{Convention}\n\\begin{document}\n\n\\section{First}\n\n\\subsection{One}\n\n\\begin{defn}\\label{Def:a}\nA first definition.\n\\end{defn}\n\n\\begin{defn}\nA second definition.\n\\end{defn}\n\n\\begin{thm}\nA theorem.\n\\end{thm}\n\n\\begin{conv}\nA convention.\n\\end{conv}\n\n\\begin{lem}\\label{Lem:a}\nA lemma.\n\\end{lem}\n\n\\begin{equation}\\label{Eq:a}\nx^2\n\\end{equation}\n\n\\subsection{Two}\n\n\\begin{defn}\nA third definition.\n\\end{defn}\n\n\\section{Second}\n\n\\begin{equation}\\label{Eq:b}\ny^2\n\\end{equation}\n\n\\begin{enumerate}[label=(\\alph*)]\n\\item Lettered.\n\\item Also lettered.\n\\end{enumerate}\n\nSee Definition~\\ref{Def:a}, Lemma~\\ref{Lem:a}, \\eqref{Eq:a} and \\eqref{Eq:b}.\n\n\\end{document}\n";

numberingMeasurements[ source_String ] :=
  Module[ { notebook, counters },
    notebook = NotebookPut[ withSheet[ latexToNotebook[ source ], "AMSArticle.nb" ], Visible -> False ];
    counters = <|
      "Definition" -> Map[ CurrentValue[ #, { "CounterValue", "TheoremDefn" } ] &,
        Cells[ notebook, CellStyle -> "Definition" ] ],
      "Theorem" -> Map[ CurrentValue[ #, { "CounterValue", "Theorem" } ] &,
        Join[ Cells[ notebook, CellStyle -> "Theorem" ], Cells[ notebook, CellStyle -> "Lemma" ] ] ],
      "Equation" -> Map[ CurrentValue[ #, { "CounterValue", "DisplayFormulaNumbered" } ] &,
        Cells[ notebook, CellStyle -> "DisplayFormulaNumbered" ] ] |>;
    NotebookClose[ notebook ];
    <| "Counters" -> counters, "Text" -> importedText @ latexToNotebook[ source ] |>
  ]

(* LaTeXPaperImport T11: an imported paper has to open with its environments live, and the sheet is
   the only thing that decides whether it does. On Default.nb the twelve environment styles do not
   exist, so the definition prints no name and no number, the proof prints no name and no QED square,
   the headings print no number — and the reference to the definition reads "2.0", because its
   section counter increments and its theorem counter never does. That is a broken reference on the
   page and it is invisible everywhere else: the kernel, the round trip and the counter values are
   all identical under both sheets. The pair is measured, not just the good half, because the whole
   claim is that the sheet is what fixed it. *)

$plainPaper = "\\documentclass{article}\n\\newtheorem{defn}{Definition}[section]\n\\begin{document}\n\n\\section{First} \\label{sec:one}\n\n\\section{Second} \\label{sec:two}\n\n\\begin{defn} \\label{def:one}\nA body.\n\\end{defn}\n\n\\begin{proof}\nA proof.\n\\end{proof}\n\nSee Section~\\ref{sec:two} and Definition~\\ref{def:one}.\n\n\\end{document}\n";

(* A PDF's plaintext breaks a line wherever the layout does, so every comparison here is against the
   text with its whitespace taken out. *)
sheetText[ source_String, sheet_String ] :=
  Module[ { notebook, file },
    notebook = NotebookPut[ withSheet[ latexToNotebook[ source ], sheet ], Visible -> False ];
    file = Export[ FileNameJoin[ { $TemporaryDirectory, "MathNotebookSheet.pdf" } ], notebook ];
    NotebookClose[ notebook ];
    StringDelete[ Import[ file, "Plaintext" ], WhitespaceCharacter ]
  ]

(* ConversionUX T2: a newly converted MaTeX cell has to come out at the size the document is showing
   mathematics at. Nothing kernel-side can see this — the cell round-trips through its stored
   "SourceTeX" whatever size the image was rendered at, and the size arithmetic on its own passes
   while ConvertToMaTeX goes on ignoring it, which is exactly how the bug shipped. What is measured
   is the image: the width of the rendered GraphicsBox, converted under an untouched document and
   under one whose math control is at twice the anchor. The third document converts first and moves
   the slider afterwards, so the two orders can be compared — they now build the cell through the
   same constructor and must land on the same image, where before the conversion always drew at 14.

   Guarded rather than assumed: MaTeX is optional and shells out to pdflatex and Ghostscript, so a
   machine without them gets no tests here rather than failing ones. The configuration written is
   the one InstallMaTeX writes, so a MaTeX that has never been configured still renders. *)

$maTeXAvailable = PacletObjectQ @ Quiet @ PacletObject[ "MaTeX" ] &&
  StringQ @ findExecutable[ "pdflatex" ] && StringQ @ findExecutable[ "gs" ];

If[ ! $maTeXAvailable,
  Print[ "MaTeX, pdflatex or Ghostscript is absent: the MaTeX conversion size tests are not run." ] ];

maTeXDocument[ parent_ ] :=
  NotebookPut[ Notebook[
    { Cell[ BoxData[ FormBox[ SuperscriptBox[ "x", "2" ], TraditionalForm ] ], "DisplayFormula" ] },
    StyleDefinitions -> parent, Visible -> False ] ]

maTeXWidth[ notebook_NotebookObject ] :=
  FirstCase[ NotebookGet[ notebook ], GraphicsBox[ ___, ImageSize -> { width_, _ }, ___ ] :> width, 0, Infinity ]

maTeXMeasurements[ parent_ ] :=
  Module[ { size = 2 mathFontSizeAnchor[ parent ], base, scaled, rescaled, measurements },
    Needs[ "MaTeX`" ];
    MaTeX`ConfigureMaTeX[ "pdfLaTeX" -> findExecutable[ "pdflatex" ], "Ghostscript" -> findExecutable[ "gs" ] ];
    base = maTeXDocument[ parent ];
    ConvertToMaTeX[ base ];
    scaled = maTeXDocument[ parent ];
    SetMathFontSize[ scaled, size ];
    ConvertToMaTeX[ scaled ];
    rescaled = maTeXDocument[ parent ];
    ConvertToMaTeX[ rescaled ];
    SetMathFontSize[ rescaled, size ];
    measurements = <| "Size" -> maTeXFontSize[ scaled ], "Base" -> maTeXWidth[ base ],
      "Scaled" -> maTeXWidth[ scaled ], "Rescaled" -> maTeXWidth[ rescaled ] |>;
    NotebookClose /@ { base, scaled, rescaled };
    measurements
  ]

(* BasicFunctionality T2: with no document open, every selection-driven entry point did nothing and
   said nothing. InputNotebook[] answers $Failed there — a palette with no paper beside it, which is
   where a new author starts — and SelectedCells[$Failed] then stays unevaluated, so the guard
   written for an empty selection matched neither branch and the Replace handed back its own
   argument. No test in the repo had ever called one of these: they are front-end operations end to
   end, so the kernel-only files cannot reach them, and the failure raises no message, which leaves
   the dialog the author is supposed to see as the only detector.

   A headless UsingFrontEnd has no input notebook, so it reproduces the reported state exactly and
   for free — that is also why these were untestable before the notebook arguments existed, and why
   they now need nothing but a front end. TimeConstrained is not decoration: without the guard,
   TagSelectedCell and InsertCitation reach InputString first, and the run would block rather than
   fail. *)

dialogText[ result_ ] :=
  Replace[ result,
    dialog_NotebookObject :>
      With[ { text = FirstCase[ NotebookGet[ dialog ], s_String /; StringEndsQ[ s, "!" ], None, Infinity ] },
        NotebookClose[ dialog ]; text ] ]

$noDocumentCalls = <|
  "CopyCellReference" -> Hold @ CopyCellReference[],
  "TagSelectedCell" -> Hold @ TagSelectedCell[],
  "InsertCitation" -> Hold @ InsertCitation[],
  "InsertEnvironment" -> Hold @ InsertEnvironment[ "Theorem" ],
  "LabelReferences" -> Hold @ LabelReferences[],
  (* T5: the same hole in the seven entry points T2 did not touch, each of which handed $Failed to a
     notebook_NotebookObject overload — or to convertCells — and returned unevaluated with no
     message. Driven and measured that way before the guard went in. ConvertToMaTeX is safe to call
     here without MaTeX installed precisely because the guard now answers before the Needs. *)
  "SetDocumentFontSize" -> Hold @ SetDocumentFontSize[ 20 ],
  "SetMathFontSize" -> Hold @ SetMathFontSize[ 20 ],
  "ResetDocumentView" -> Hold @ ResetDocumentView[],
  "ConvertLaTeXCells" -> Hold @ ConvertLaTeXCells[],
  "ConvertMathCells" -> Hold @ ConvertMathCells[],
  "ConvertToMaTeX" -> Hold @ ConvertToMaTeX[],
  "ConvertFromMaTeX" -> Hold @ ConvertFromMaTeX[]
|>;

noDocumentDialogs[ ] :=
  Map[ dialogText @ TimeConstrained[ ReleaseHold[ # ], 30, "TIMEOUT" ] &, $noDocumentCalls ]

(* The other half of the same task: the notebook-argument overloads that make the above possible,
   driven against a live document. The counters are read off the cells for the reason T8 and T9 read
   them there — a dingbat of "1." collides with too much of a page's plaintext — and Proof and
   DisplayFormulaNumbered are in the list because they must NOT consume the theorem counter. *)
referencingDrive[ parent_ ] :=
  Module[ { notebook, cells, inserted, measurements },
    notebook = NotebookPut @ Notebook[ {
      Cell[ "A section", "Section" ],
      Cell[ "A theorem", "Theorem" ],
      Cell[ "Smith, A title", "Reference", CellTags -> "Sm09" ] },
      StyleDefinitions -> parent, Visible -> False ];
    cells = Cells[ notebook ];
    measurements = <| "Unselected" -> dialogText @ CopyCellReference[ notebook ] |>;
    SelectionMove[ cells[[ 2 ]], All, Cell ];
    measurements[ "Copied" ] = dialogText @ CopyCellReference[ notebook ];
    measurements[ "Clipboard" ] = Count[ NotebookGet @ ClipboardNotebook[], _Button | _ButtonBox, Infinity ];
    TagSelectedCell[ notebook, "Thm:key" ];
    measurements[ "Tagged" ] = CurrentValue[ cells[[ 2 ]], CellTags ];
    LabelReferences[ notebook ];
    measurements[ "Dingbat" ] = FirstCase[ NotebookGet[ notebook ],
      Cell[ _, "Reference", ___, CellDingbat -> Cell[ TextData[ label_String ] ], ___ ] :> label, None, Infinity ];
    SelectionMove[ Last @ Cells[ notebook ], After, Cell ];
    Scan[ InsertEnvironment[ notebook, # ] &, { "Theorem", "Lemma", "Proof", "DisplayFormulaNumbered" } ];
    inserted = Cells[ notebook ];
    measurements[ "Styles" ] = Map[ First @ Flatten @ { CurrentValue[ #, CellStyle ] } &, inserted ];
    measurements[ "Counters" ] = Map[ CurrentValue[ #, { "CounterValue", "Theorem" } ] &,
      Select[ inserted,
        MemberQ[ { "Theorem", "Lemma", "Proof" }, First @ Flatten @ { CurrentValue[ #, CellStyle ] } ] & ] ];
    SelectionMove[ Last @ Cells[ notebook ], After, Cell ];
    InsertCitation[ notebook, "Thm:key" ];
    measurements[ "Citation" ] = FirstCase[ NotebookGet[ notebook ],
      ButtonBox[ boxes_, ___, ButtonData -> "Thm:key", ___ ] :> boxes, None, Infinity ];
    NotebookClose[ notebook ];
    measurements
  ]

(* BasicFunctionality T3: GoBack[] is the same silent no-op one state earlier and from the other
   cause — the unset $LastHyperlinkCell rather than a $Failed notebook — so it is reachable with a
   document open and needs a measurement of its own. Three states, and only the middle one may move a
   selection: nothing followed yet, a live cell, and a cell that has since been deleted. That last
   one is why a CellObject pattern alone is not enough — SelectionMove on a deleted cell answers Null
   and does nothing at all. "Value" is measured before the symbol is assigned here, so a kernel that
   arrives with it already set fails a test rather than passing the "Unset" one for the wrong reason. *)
goBackDrive[ ] :=
  Module[ { notebook, cells, measurements },
    measurements = <| "Value" -> ValueQ[ $LastHyperlinkCell ], "Unset" -> dialogText @ GoBack[] |>;
    notebook = NotebookPut @ Notebook[ { Cell[ "One", "Text" ], Cell[ "Two", "Text" ] }, Visible -> False ];
    cells = Cells[ notebook ];
    SelectionMove[ Last[ cells ], All, Cell ];
    $LastHyperlinkCell = First[ cells ];
    measurements[ "Returned" ] = dialogText @ GoBack[];
    measurements[ "Selected" ] = SelectedCells[ notebook ] === { First[ cells ] };
    NotebookDelete[ First[ cells ] ];
    measurements[ "Stale" ] = dialogText @ GoBack[];
    NotebookClose[ notebook ];
    $LastHyperlinkCell = "First[{}] is what the stylesheet assigns with nothing selected";
    measurements[ "NonCell" ] = dialogText @ GoBack[];
    Clear[ $LastHyperlinkCell ];
    measurements
  ]

(* "NoDocument" is first in this association on purpose: a notebook left open by any measurement
   above it would become the input notebook, and the state under test would be gone. *)
$measured = UsingFrontEnd @ <|
  "NoDocument" -> noDocumentDialogs[ ],
  "GoBack" -> goBackDrive[ ],
  "Referencing" -> referencingDrive @ Get @ FileNameJoin[ { $sheetDirectory, "AMSArticle.nb" } ],
  "Imported" -> importedText[ $importedSource ],
  "PlainSheet" -> AssociationMap[ sheetText[ $plainPaper, # ] &, { "PlainArticle.nb", "Default.nb" } ],
  "Lists" -> listMeasurements[ $listPaper ],
  "Numbering" -> numberingMeasurements[ $numberingPaper ],
  "Figures" -> figureMeasurements[ $figurePaper ],
  "Saved" -> savedRoundTrip[ $savedSource ],
  "Body" -> importedText @ latexToNotebook[ $bodyPaper ],
  "Bibliography" -> importedText @ latexToNotebook[ $bibliographySource, bibliographyDatabase[ $bibliographyBib ] ],
  "Entries" -> importedText[ $entrySource ],
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
  "Citations" -> citationMeasurements @ Get @ FileNameJoin[ { $sheetDirectory, "AMSArticle.nb" } ],
  "MaTeX" -> If[ $maTeXAvailable, maTeXMeasurements @ Get @ FileNameJoin[ { $sheetDirectory, "AMSArticle.nb" } ] ]
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

(* BasicFunctionality T2 and T5: the reported defect, literally. With no document open every one of
   the twelve tells the author, where each formerly returned an unevaluated expression and no message.
   Asserted as the whole association so an entry point that stops answering cannot hide behind the
   eleven that still do. *)
VerificationTest[
  $measured[ "NoDocument" ],
  AssociationMap[ "Open a notebook first!" &,
    { "CopyCellReference", "TagSelectedCell", "InsertCitation", "InsertEnvironment", "LabelReferences",
      "SetDocumentFontSize", "SetMathFontSize", "ResetDocumentView",
      "ConvertLaTeXCells", "ConvertMathCells", "ConvertToMaTeX", "ConvertFromMaTeX" } ]
]

(* BasicFunctionality T3: the palette's "Go back" before any hyperlink has been followed, which is
   the state the button is in the moment a paper is opened. It answered SelectionMove[
   $LastHyperlinkCell, All, Cell ] with no message; it now says so, and says something different for
   a cell that has since been deleted. The non-cell state is the shape the stylesheet's own
   ButtonFunction writes when it clicks with nothing selected. *)
VerificationTest[
  KeyTake[ $measured[ "GoBack" ], { "Value", "Unset", "Stale", "NonCell" } ],
  <| "Value" -> False, "Unset" -> "Follow a hyperlink first!",
    "Stale" -> "The cell that link was followed from is gone!",
    "NonCell" -> "Follow a hyperlink first!" |>
]

(* And a live cell is still gone back to, so the guard is a guard and not a refusal: the selection
   leaves the last cell and lands on the recorded one. *)
VerificationTest[
  KeyTake[ $measured[ "GoBack" ], { "Returned", "Selected" } ],
  <| "Returned" -> Null, "Selected" -> True |>
]

(* BasicFunctionality T7, and the weakest test in this file on purpose. A link followed with
   "OpenInNewWindow" leaves its target in a window of its own, so GoBack has to raise the source
   notebook or the selection moves out of the author's sight. The raise itself cannot be measured
   here — SelectedNotebook[] answers $Failed whatever is selected, and AbsoluteCurrentValue[ notebook,
   "WindowSelected" ] answers $Failed too, both measured on two visible notebooks — so what is
   asserted is that the call is in the definition, and the effect is Pavel's to confirm on a real
   window. It bites on the call being dropped, which is what it is for; it would not bite on the call
   being wrong. The test above is what keeps it honest: raising must not cost the selection move. *)
VerificationTest[
  FreeQ[ DownValues[ GoBack ], SetSelectedNotebook ],
  False
]

(* With a document, the guard that was always in the source and never reachable now fires — and a
   real selection still succeeds, so the guard is a guard and not a refusal. *)
VerificationTest[
  { $measured[ "Referencing", "Unselected" ], $measured[ "Referencing", "Copied" ],
    $measured[ "Referencing", "Clipboard" ] },
  { "Select a cell!", Null, 1 }
]

(* The notebook-argument overloads, driven for the first time: the tag reaches the cell and the
   bibliography entry gets the label its citations read. *)
VerificationTest[
  { $measured[ "Referencing", "Tagged" ], $measured[ "Referencing", "Dingbat" ] },
  { "Thm:key", "[Sm09]" }
]

(* Four environments land in order, and the theorem counter runs 1, 2, 3 across the two theorems and
   the lemma while Proof consumes none of it — it reads the lemma's 3 rather than a 4 of its own. *)
VerificationTest[
  { $measured[ "Referencing", "Styles" ], $measured[ "Referencing", "Counters" ] },
  { { "Section", "Theorem", "Reference", "Theorem", "Lemma", "Proof", "DisplayFormulaNumbered" },
    { 1, 2, 3, 3 } }
]

(* The citation written by the two-argument form resolves against the tag it was given. The boxes
   are read back off a live notebook, which splits the prefix string into runs of its own, so what is
   asserted is the counter chain rather than the whole RowBox. *)
VerificationTest[
  Cases[ $measured[ "Referencing", "Citation" ], _CounterBox, Infinity ],
  { CounterBox[ "Section", "Thm:key" ], CounterBox[ "Theorem", "Thm:key" ] }
]

(* Inline Math Converter Defects T1: a comma-bearing span really renders as mathematics — visible
   ink, and the "$" delimiters gone. Blank < Converted < Literal on every specimen. *)
VerificationTest[
  Map[ #[ "Blank" ] < #[ "Converted" ] < #[ "Literal" ] &, $measured[ "InlineInk" ] ],
  AssociationMap[ True &, { "A pair $(V, E)$ here.", "A list $x_1, x_2$ here." } ]
]

(* T2: the split formula carries ink, and the converted paper carries less than the literal LaTeX
   it replaces — the backslashes, the braces and the two "equation*" are gone. Both papers are
   rendered as notebooks (LaTeXPaperImport T12), so the comparison is between like and like; the
   converted one is three cells against the literal one's single cell and still measures less. *)
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

(* LaTeXPaperImport T10: a thebibliography written into the .tex is on the page as a bibliography —
   each entry under its own [key] dingbat, the citation reading as the same label, and none of the
   markup that produced it left as text. The [Sm09] the source prints instead of a number is
   deliberately not shown: it would make the entry and the citation to it disagree. An entry is prose,
   so what prose carries verbatim it carries verbatim too — the ~ and the \emph are on the page as
   they are everywhere else in an imported paper. *)
VerificationTest[
  { StringContainsQ[ $measured[ "Entries" ], "[smith] A.~Smith" ],
    StringContainsQ[ $measured[ "Entries" ], "[jones] B.~Jones" ],
    StringContainsQ[ $measured[ "Entries" ], "citing [smith]" ],
    StringContainsQ[ $measured[ "Entries" ], "bibitem" | "thebibliography" | "Sm09" ],
    StringContainsQ[ $measured[ "Entries" ], "XXX" ] },
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

(* LaTeXPaperImport T8: the second list restarts. Without the per-list reset these read 1, 2, 2, 3. *)
VerificationTest[
  $measured[ "Lists", "Counters" ],
  { 1, 2, 0, 1 }
]

(* ... and the front matter is on the page: the title and author as their own styles, the abstract
   headed once however many paragraphs it runs to, the [label] of an item drawn instead of a number,
   and no list or front-matter command left as prose. The author is read case-insensitively because
   the Author style is small caps, so the PDF's plaintext of "An Author" is "AN AUTHOR". \maketitle is
   the one command still there, by the decision that a command with no content has no notebook
   counterpart — it is asserted rather than overlooked. *)
VerificationTest[
  { StringContainsQ[ $measured[ "Lists", "Text" ], "A Title" ],
    StringContainsQ[ $measured[ "Lists", "Text" ], "An Author", IgnoreCase -> True ],
    StringCount[ $measured[ "Lists", "Text" ], "Abstract." ],
    StringContainsQ[ $measured[ "Lists", "Text" ], "(E)" ],
    StringContainsQ[ $measured[ "Lists", "Text" ],
      "\\item" | "\\title" | "\\author" | "\\begin{abstract}" | "\\begin{enumerate}" ],
    StringCount[ $measured[ "Lists", "Text" ], "\\maketitle" ],
    StringContainsQ[ $measured[ "Lists", "Text" ], "XXX" ] },
  { True, True, 1, True, False, 1, False }
]

(* LaTeXPaperImport T9: the resolved counters. The definitions restart in the second subsection, the
   lemma numbers with the theorems rather than with the definitions, the starred convention consumes
   nothing so the lemma after it is 2 and not 3, and the equation restarts in the second section. *)
VerificationTest[
  $measured[ "Numbering", "Counters" ],
  <| "Definition" -> { 1, 2, 1 }, "Theorem" -> { 1, 1, 2 }, "Equation" -> { 1, 1 } |>
]

(* ... and what the dingbats print, which no counter value can say. Three counters for a definition
   where the sheets print two, an unnumbered Convention, an equation number carrying its section, an
   enumerate lettered by its label= rather than numbered by the style, and every reference reading its
   target's own number. *)
VerificationTest[
  With[ { text = $measured[ "Numbering", "Text" ] },
    { StringCount[ text, "Definition 1.1.1." ], StringCount[ text, "Definition 1.1.2." ],
      StringCount[ text, "Definition 1.2.1." ],
      StringCount[ text, "Theorem 1.1." ], StringCount[ text, "Lemma 1.2." ],
      StringCount[ text, "Convention." ], StringContainsQ[ text, "Convention 1" ],
      StringCount[ text, "(1.1)" ], StringCount[ text, "(2.1)" ],
      StringContainsQ[ text, "(a) Lettered." ], StringContainsQ[ text, "(b) Also lettered." ],
      StringContainsQ[ text, "See Definition~1.1.1, Lemma~1.2, (1.1) and (2.1)." ],
      StringContainsQ[ text, "XXX" ] } ],
  { 1, 1, 1, 1, 1, 1, False, 2, 2, True, True, True, False }
]

(* LaTeXPaperImport T11: the environments are live on the fifth sheet — the name, the number, the
   QED square and the numbered headings — and the cross-reference reads the definition's own number. *)
VerificationTest[
  Map[ StringContainsQ[ $measured[ "PlainSheet", "PlainArticle.nb" ], # ] &,
    { "Definition2.1.", "Proof.", "\[EmptySquare]", "1.First", "2.Second", "Definition~2.1", "Section~2" } ],
  ConstantArray[ True, 7 ]
]

(* And the same paper on Default.nb, which is what an import landed on before this task: no name, no
   number, no square, no heading number, and a reference that reads 2.0. *)
VerificationTest[
  Map[ StringContainsQ[ $measured[ "PlainSheet", "Default.nb" ], # ] &,
    { "Definition2.1.", "Proof.", "\[EmptySquare]", "1.First", "Definition~2.0" } ],
  { False, False, False, False, True }
]

(* ConversionUX T2: the converted image is wider under a document whose math control is at twice the
   anchor, and it is the same image whether the slider was moved before the conversion or after it.
   Converting at the fixed base size gives 14 for the size and one width for all three. *)
If[ $maTeXAvailable,
VerificationTest[
  With[ { m = $measured[ "MaTeX" ] },
    { m[ "Size" ], m[ "Base" ] > 0, m[ "Scaled" ] > m[ "Base" ], m[ "Scaled" ] === m[ "Rescaled" ] } ],
  { 2 $maTeXBaseFontSize, True, True, True }
]
]
