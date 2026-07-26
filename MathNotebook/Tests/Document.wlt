Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

(* LaTeXPaperImport T2. The document layer above the math converter: \section/\subsection/
   \subsubsection and theorem-like environments become cells of the corresponding style, and come
   back out as the environment names the source used. Everything it does not convert — lists,
   figures, front matter — is carried verbatim, and every cell records the whitespace that followed
   it in the source, so the export of an imported document is the source byte for byte. *)

$preamble = "\\documentclass{article}\n\\usepackage{amsthm}\n\\newtheorem{defn}{Definition}[section]\n\\newtheorem{axiom}{Axiom}[section]\n\\newtheorem{cor}[thm]{Corollary}\n\\newtheorem*{conv}{Convention}\n"

$source = $preamble <> "\\begin{document}\n\n\\section{First} \\label{sec:one}\n\nProse with $x^2$ in it.\n\n\\subsection{Inner}\n\n\\begin{defn}[Named] \\label{def:one}\n    A definition body with $y$.\n\\end{defn}\n\n\\begin{axiom}[Proximity]\nAn axiom body.\n\\end{axiom}\n\n\\begin{proof}\nA proof body.\n\\end{proof}\n\n\\begin{itemize}\n    \\item untouched\n\\end{itemize}\n\n\\end{document}\n"

$notebook = latexToNotebook[ $source ]

$cells = First[ $notebook ]

(* The four declared environments are read out of the preamble, in all three \newtheorem forms.
   A fixed table of English names would have matched none of the specimen paper's four. *)
VerificationTest[
  KeyTake[ theoremEnvironments[ $preamble ], { "defn", "axiom", "cor", "conv", "theorem", "proof" } ],
  <| "defn" -> "Definition", "axiom" -> "Axiom", "cor" -> "Corollary", "conv" -> "Convention",
     "theorem" -> "Theorem", "proof" -> "Proof" |>
]

VerificationTest[
  Map[ #[[ 2 ]] &, $cells ],
  { "Section", "Text", "Subsection", "Definition", "Theorem", "Proof", "Item" }
]

VerificationTest[ (* the title is the cell content, the whitespace around the command is kept, and
                     T3's \label has become the cell's tag *)
  First @ $cells,
  Cell[ "First", "Section",
    TaggingRules -> <| "MathNotebook" -> <| "Indent" -> "", "Trailing" -> " ", "Separator" -> "\n\n",
      "TrailingAfter" -> "" |> |>,
    CellTags -> "sec:one" ]
]

VerificationTest[ (* the source environment name is kept, not the style it was mapped to *)
  Map[ Lookup[ #, "Environment", None ] &,
    Cases[ $cells, Cell[ ___, TaggingRules -> <| "MathNotebook" -> tagging_ |>, ___ ] :> tagging ] ],
  { None, None, None, "defn", "axiom", "proof", None }
]

(* An environment whose printed name is none of the twelve the stylesheets define — the specimen
   paper's ten Axioms — is written as a Theorem so that it numbers with them, and carries a dingbat
   saying what it really is. Leaving it as literal text would have dropped a third of that paper's
   environments. *)
VerificationTest[
  FirstCase[ $cells, Cell[ _, "Theorem", options___ ] :> FirstCase[ { options }, ( CellDingbat -> dingbat_ ) :> dingbat ] ],
  Cell[ TextData[ { "Axiom ", CounterBox[ "Section" ], ".", CounterBox[ "Theorem" ], "." } ], FontWeight -> "Bold" ]
]

VerificationTest[ (* a declared environment matching one of the twelve gets no dingbat override *)
  FreeQ[ FirstCase[ $cells, Cell[ _, "Definition", ___ ] ], CellDingbat ],
  True
]

VerificationTest[ (* mathematics inside a section title and an environment body is converted *)
  FreeQ[ $cells, "Prose with $x^2$ in it." ] && ! FreeQ[ $cells, SuperscriptBox[ "x", "2" ] ],
  True
]

VerificationTest[ (* T8: the itemize is an Item cell whose content is the item's own text, with the
                     \begin, the \item and the \end all carried as source around it *)
  { Last[ $cells ][[ 1 ]], Last[ $cells ][[ 2 ]],
    Cases[ Last @ $cells, ( TaggingRules -> <| "MathNotebook" -> tagging_ |> ) :>
      Lookup[ tagging, { "EnvironmentOpen", "EnvironmentClose" } ] ] },
  { "untouched", "Item",
    { { "\\begin{itemize}\n    \\item ", "\n\\end{itemize}" } } }
]

VerificationTest[ (* the whole document, out and back, byte for byte *)
  notebookToLaTeX[ $notebook ],
  $source
]

(* A commented-out environment must not become a live cell. Both delimiters are anchored to the
   start of a line, so "%\begin{defn}" is prose. *)
VerificationTest[
  Map[ #[[ 2 ]] &, First @ latexToNotebook[
    $preamble <> "\\begin{document}\n\n%\\begin{defn}\ncommented out\n%\\end{defn}\n\n\\end{document}\n" ] ],
  { "Text" }
]

(* Blocking is preserved exactly, not normalised: three newlines between two blocks stay three, and
   a display equation lifted out of a paragraph rejoins with the single newline it had. *)
$blockingSource = $preamble <> "\\begin{document}\n\nOne.\n\n\nTwo, then:\n\\begin{equation*}\nx^2\n\\end{equation*}\nand on.\n\n\\end{document}\n"

VerificationTest[
  { Map[ #[[ 2 ]] &, First @ latexToNotebook[ $blockingSource ] ],
    notebookToLaTeX @ latexToNotebook[ $blockingSource ] === $blockingSource },
  { { "Text", "Text", "DisplayFormula", "Text" }, True }
]

(* An indented \begin/\end pair, and a trailing space at the end of a body line, both survive —
   between them they were the last diff lines on the second specimen. *)
$indentedSource = $preamble <> "\\begin{document}\n\n\t\\begin{defn}\n\t\tBody with a trailing space. \n\t\\end{defn}\t\n\n\\end{document}\n"

VerificationTest[
  { Map[ #[[ 2 ]] &, First @ latexToNotebook[ $indentedSource ] ],
    notebookToLaTeX @ latexToNotebook[ $indentedSource ] === $indentedSource },
  { { "Definition" }, True }
]

(* A document with no \begin{document} at all is all body, so the layer is usable on a fragment. *)
VerificationTest[
  notebookToLaTeX @ latexToNotebook[ "\\section{Only}\n\nSome prose.\n" ],
  "\\section{Only}\n\nSome prose.\n"
]

(* LaTeXPaperImport T3. \label becomes the CellTags the referencing palette and CounterBox both key
   on, and \ref/\eqref become the front end's own cross-reference — a CounterBox chain resolved at
   the labelled cell, so the number is right in the PDF with no kernel and follows the target when
   cells move. \ref is the bare number and \eqref parenthesises it, as LaTeX prints them: authors
   write "Theorem~\ref{...}", so a "Theorem " prefix would say the word twice. *)

$referenceSource = $preamble <> "\\begin{document}\n\n\\section{First} \\label{sec:one}\n\n\\begin{defn}[Named] \\label{def:one}\nA body.\n\\end{defn}\n\n\\begin{equation}\\label{eq:one}\nx^2\n\\end{equation}\n\nSee Section~\\ref{sec:one}, Definition~\\ref{def:one} and~\\eqref{eq:one}, but not \\ref{fig:absent}.\n\n\\end{document}\n"

$referenceNotebook = latexToNotebook[ $referenceSource ]

VerificationTest[ (* the label lands on the cell it labels, whatever carried it in the source *)
  Cases[ First @ $referenceNotebook, Cell[ _, style_String, ___, CellTags -> key_String, ___ ] :> style -> key ],
  { "Section" -> "sec:one", "Definition" -> "def:one", "DisplayFormulaNumbered" -> "eq:one" }
]

VerificationTest[ (* \ref is the bare counter chain of the target's style, \eqref the same in parens *)
  Cases[ First @ $referenceNotebook, _ButtonBox, Infinity ],
  { ButtonBox[ RowBox @ { CounterBox[ "Section", "sec:one" ] }, BaseStyle -> "Citation", ButtonData -> "sec:one" ],
    ButtonBox[ RowBox @ { CounterBox[ "Section", "def:one" ], ".", CounterBox[ "Theorem", "def:one" ] },
      BaseStyle -> "Citation", ButtonData -> "def:one" ],
    ButtonBox[ RowBox @ { "(", CounterBox[ "DisplayFormulaNumbered", "eq:one" ], ")" },
      BaseStyle -> "Citation", ButtonData -> "eq:one" ] }
]

VerificationTest[ (* a key no converted cell carries at all is left as source rather than rendered as
                     the front end's XXX *)
  ! FreeQ[ First @ $referenceNotebook, "\\ref{fig:absent}" ],
  True
]

VerificationTest[ (* out and back, with both commands distinguished *)
  notebookToLaTeX[ $referenceNotebook ],
  $referenceSource
]

VerificationTest[ (* the tag is the origin of the exported \label, not a mirror of it: retagging a
                     structural cell changes the source that comes back *)
  StringContainsQ[
    notebookToLaTeX @ Notebook[ Replace[ First @ $referenceNotebook,
      Cell[ content_, "Section", options___, CellTags -> _, rest___ ] :> Cell[ content, "Section", options, CellTags -> "sec:renamed", rest ], { 1 } ] ],
    "\\section{First} \\label{sec:renamed}" ],
  True
]

(* LaTeXPaperImport T4. \cite becomes a Citation button labelled with the key in brackets — the same
   rendering referenceLabel gives a Reference cell's dingbat, so a citation reads as the entry it
   points at — and the \bibliography commands become the Reference cells of the entries the paper
   cites. Those entries are in the .bib and not in the .tex, so the last cell of the block carries
   the commands verbatim and the rest emit nothing at all. *)

$bib = "@article{first,\n  title={A first paper, with a comma},\n  author={Ehlers, J{\\\"u}rgen and Pirani, Felix},\n  journal={A Journal},\n  volume={44},\n  number={6},\n  pages={1587--1609},\n  year={2012},\n  publisher={Springer}\n}\n\n@book{second,\n  title={A second},\n  author={Andr{\\'e}ka, Hajnal},\n  year=2019\n}\n\n@misc{uncited,\n  title={Never cited},\n  year={1999}\n}\n"

$entries = bibliographyDatabase[ $bib ]

(* A value holds both the comma the fields are separated by and the braces the entry ends with, so
   the split is at the commas standing at brace depth zero. A TeX accent becomes the character it
   prints and -- becomes the dash, neither of which the return trip can notice: the .tex gets its
   \bibliography command back, not the entry. *)
VerificationTest[
  { Keys @ $entries,
    $entries[ "first" ][ "title" ], $entries[ "first" ][ "pages" ], $entries[ "first" ][ "author" ],
    $entries[ "second" ][ "author" ], $entries[ "second" ][ "year" ], $entries[ "second" ][ "Type" ] },
  { { "first", "second", "uncited" },
    "A first paper, with a comma", "1587\[Dash]1609", "Ehlers, J\[UDoubleDot]rgen and Pirani, Felix",
    "Andr\[EAcute]ka, Hajnal", "2019", "book" }
]

$citeSource = "\\documentclass{article}\n\\begin{document}\n\nProse citing \\cite{first}, then \\cite{first, second} and \\cite{first,second}, then \\cite[Theorem~1.1]{second}.\n\n\\bibliographystyle{alphaurl}\n\\bibliography{refs}\n\n\\end{document}\n"

$citeNotebook = latexToNotebook[ $citeSource, $entries ]

(* Only the cited keys become cells, as LaTeX prints only those, and they come in the order of the
   .bib. Each is tagged with its key and dingbatted with it, which is what a citation navigates to. *)
VerificationTest[
  Cases[ First @ $citeNotebook, Cell[ _, style_String, options___ ] :>
    { style, Lookup[ { options }, CellTags, None ] } ],
  { { "Text", None }, { "Reference", "first" }, { "Reference", "second" } }
]

(* Every entry but the last emits nothing, and the last carries the commands the .tex actually has —
   which is why the fields are formatted for reading and not to be parsed back. *)
VerificationTest[
  Cases[ First @ $citeNotebook, Cell[ _, "Reference", ___ ] ],
  { Cell[ "J\[UDoubleDot]rgen Ehlers, Felix Pirani, A first paper, with a comma, A Journal, 44(6), 1587\[Dash]1609, Springer, 2012.",
      "Reference", TaggingRules -> <| "MathNotebook" -> <| "Suppressed" -> "True", "Separator" -> "" |> |>,
      CellTags -> "first", CellDingbat -> Cell[ TextData[ "[first]" ] ] ],
    Cell[ "Hajnal Andr\[EAcute]ka, A second, 2019.", "Reference",
      TaggingRules -> <| "MathNotebook" -> <| "Suppressed" -> "",
        "BibliographyTeX" -> "\\bibliographystyle{alphaurl}\n\\bibliography{refs}", "Separator" -> "\n\n" |> |>,
      CellTags -> "second", CellDingbat -> Cell[ TextData[ "[second]" ] ] ] }
]

(* The label is the key in brackets, the verbatim brace content rides along as the ButtonData — both
   the navigation target and what the exporter writes back — and an optional argument follows the
   keys, which is why the exporter counts them to tell \cite{a, b} from \cite[note]{a}. *)
VerificationTest[
  Cases[ First @ $citeNotebook, _ButtonBox, Infinity ],
  { ButtonBox[ RowBox @ { "[", "first", "]" }, BaseStyle -> "Citation", ButtonData -> "first" ],
    ButtonBox[ RowBox @ { "[", "first", ", ", "second", "]" }, BaseStyle -> "Citation",
      ButtonData -> "first, second" ],
    ButtonBox[ RowBox @ { "[", "first", ", ", "second", "]" }, BaseStyle -> "Citation",
      ButtonData -> "first,second" ],
    ButtonBox[ RowBox @ { "[", "second", ", ", "Theorem~1.1" , "]" }, BaseStyle -> "Citation",
      ButtonData -> "second" ] }
]

(* Out and back, with the two spellings of a two-key citation kept apart, and the bibliography
   commands emitted once by the last Reference cell while the entries themselves emit nothing. *)
VerificationTest[
  { notebookToLaTeX[ $citeNotebook ] === $citeSource,
    Length @ StringCases[ notebookToLaTeX[ $citeNotebook ], "\\bibliography" ],
    StringContainsQ[ notebookToLaTeX[ $citeNotebook ], "Andr" ] },
  { True, 2, False }
]

(* A paper whose .bib is not there is left exactly as it was before T4: the commands stay one Text
   cell, and the citations still convert, because a citation label is literal text and is right with
   no bibliography to point at — where a \ref would have rendered the front end's XXX. *)
VerificationTest[
  { Map[ #[[ 2 ]] &, First @ latexToNotebook[ $citeSource ] ],
    Length @ Cases[ First @ latexToNotebook[ $citeSource ], _ButtonBox, Infinity ],
    notebookToLaTeX @ latexToNotebook[ $citeSource ] === $citeSource },
  { { "Text", "Text" }, 4, True }
]

(* LaTeXPaperImport T5. A figure becomes the code that draws it plus a Caption cell: one Input cell
   per \includegraphics, holding an Import of the shipped file for the author to replace with the
   code that generates the picture, and a Caption cell tagged with the figure's \label so
   "Figure \ref{fig:x}" resolves to the front end's own counter. The markup that drew the picture —
   \centering, the includegraphics options, a whole tikzpicture — rides verbatim on the caption cell,
   which is what lets a TikZ figure round-trip a picture the notebook cannot render. *)

$figureSource = "\\documentclass{article}\n\\begin{document}\n\nProse before, see Figure \\ref{fig:one} and Figure \\ref{fig:none}.\n\n\\begin{figure}[htpb]\n\t\\centering\n\t\\begin{tikzpicture}\n\t\t\\draw (0,0) -- (1,1);\n\t\\end{tikzpicture}\n\t\\caption{A \\textbf{drawn} picture, $x^2$.}\n\t\\label{fig:one}\n\\end{figure}\n\n\\begin{figure*}\n\\includegraphics[width=0.7\\textwidth]{a.png}\n\\includegraphics{b.png}\n\\end{figure*}\n\nProse after.\n\n\\end{document}\n"

$figureNotebook = latexToNotebook[ $figureSource ]

(* The kernel's own reader of these is file-private to Document.wl, so a test that called it would
   silently get an inert symbol back — the PackageScope trap. *)
storedRule[ cell_Cell, key_String ] :=
  Lookup[ Cases[ cell, ( TaggingRules -> tagging_ ) :> tagging[ "MathNotebook" ] ][[ 1 ]], key, "" ]

(* The captioned figure gives one Caption cell carrying the label as its tag; the captionless one
   gives an Input cell per graphic and no caption at all. *)
VerificationTest[
  Cases[ First @ $figureNotebook, Cell[ _, style_String, options___ ] :>
    { style, Lookup[ { options }, CellTags, None ] } ],
  { { "Text", None }, { "Caption", "fig:one" }, { "Input", None }, { "Input", None }, { "Text", None } }
]

(* The graphic cells hold code that produces the picture, and emit nothing into the .tex — the
   markup that drew it is on the caption cell instead. The last cell of a captionless figure carries
   the whole environment verbatim, since there is no cell content to write back. *)
VerificationTest[
  { Cases[ First @ $figureNotebook, Cell[ BoxData[ code_String ], "Input", ___ ] :> code ],
    Map[ storedRule[ #, "Suppressed" ] &, Cases[ First @ $figureNotebook, Cell[ _, "Input", ___ ] ] ],
    Map[ storedRule[ #, "FigureTeX" ] &, Cases[ First @ $figureNotebook, Cell[ _, "Input", ___ ] ] ] },
  { { "Import[ FileNameJoin @ { NotebookDirectory[], \"a.png\" } ]",
      "Import[ FileNameJoin @ { NotebookDirectory[], \"b.png\" } ]" },
    { "True", "" },
    { "", "\\begin{figure*}\n\\includegraphics[width=0.7\\textwidth]{a.png}\n\\includegraphics{b.png}\n\\end{figure*}" } }
]

(* A caption holds braces of its own, so it ends at the brace that closes it and not at the first
   "}" — \textbf{drawn} is inside this one, and the source on either side of the caption is what the
   exporter puts back. The label is taken out of the trailing source and becomes the cell's tag. *)
VerificationTest[
  Cases[ First @ $figureNotebook, cell : Cell[ _, "Caption", ___ ] :>
    { storedRule[ cell, "FigurePrefix" ], storedRule[ cell, "Trailing" ], storedRule[ cell, "TrailingAfter" ],
      Cases[ cell, TextData[ { text_String, ___ } ] :> text, Infinity ] } ],
  { { "\\begin{figure}[htpb]\n\t\\centering\n\t\\begin{tikzpicture}\n\t\t\\draw (0,0) -- (1,1);\n\t\\end{tikzpicture}\n\t\\caption{",
      "}\n\t", "\n\\end{figure}", { "A \\textbf{drawn} picture, " } } }
]

(* A \ref at a figure resolves through the Caption counter, which article numbers straight through
   the document; a key no cell carries is still left as source. *)
VerificationTest[
  { Cases[ First @ $figureNotebook, CounterBox[ counter_, key_ ] :> { counter, key }, Infinity ],
    StringContainsQ[ ToString[ First @ $figureNotebook, InputForm ], "\\\\ref{fig:none}" ] },
  { { { "Caption", "fig:one" } }, True }
]

(* Out and back, with the tikzpicture the notebook never rendered returned verbatim. *)
VerificationTest[
  notebookToLaTeX[ $figureNotebook ] === $figureSource,
  True
]

(* Unlike a bibliography entry, a caption is the notebook's to own: it is written back out of the
   cell, so editing it in the notebook reaches the .tex. *)
VerificationTest[
  StringContainsQ[
    notebookToLaTeX @ Replace[ $figureNotebook,
      Cell[ _, "Caption", options___ ] :> Cell[ "Retitled.", "Caption", options ], { 2 } ],
    "\\caption{Retitled.}\n\t\\label{fig:one}" ],
  True
]

(* Evaluating a figure's code leaves an Output cell beside it, and neither the code nor a rasterized
   graphic has a LaTeX form — the figure's own markup is what goes back into the .tex. So the whole
   evaluation family emits nothing, and a live picture in the notebook cannot leak into the source. *)
VerificationTest[
  notebookToLaTeX @ Replace[ $figureNotebook,
    Notebook[ cells_List, options___ ] :>
      Notebook[
        Flatten @ Replace[ cells,
          cell : Cell[ _, "Input", ___ ] :>
            { cell, Cell[ BoxData @ ToBoxes @ Graphics @ Disk[ ], "Output" ],
              Cell[ BoxData[ "1 + 1" ], "Code" ] }, { 1 } ],
        options ] ],
  $figureSource
]

(* Writing a notebook to disk and opening it again splits a ButtonBox[RowBox[...]] in a TextData into
   one button per run, so the round trip held only for a notebook that had never been saved. This is
   the shape the front end really hands back, measured: a two-key citation as five buttons and an
   \eqref as three, the parentheses carried off into buttons of their own so the counter no longer
   looked parenthesised and the brackets no longer looked like references at all. The runs are put
   back together before anything reads them. Tests/FrontEnd.wlt asserts the same through a real save. *)
$splitCell = Cell[ TextData[ {
  "See ",
  ButtonBox[ "[", BaseStyle -> "Citation", ButtonData -> "first, second" ],
  ButtonBox[ "first", BaseStyle -> "Citation", ButtonData -> "first, second" ],
  ButtonBox[ ", ", BaseStyle -> "Citation", ButtonData -> "first, second" ],
  ButtonBox[ "second", BaseStyle -> "Citation", ButtonData -> "first, second" ],
  ButtonBox[ "]", BaseStyle -> "Citation", ButtonData -> "first, second" ],
  " and ",
  ButtonBox[ "(", BaseStyle -> "Citation", ButtonData -> "eq:a" ],
  ButtonBox[ CounterBox[ "DisplayFormulaNumbered", "eq:a" ], BaseStyle -> "Citation", ButtonData -> "eq:a" ],
  ButtonBox[ ")", BaseStyle -> "Citation", ButtonData -> "eq:a" ],
  "." } ], "Text" ]

VerificationTest[
  notebookToLaTeX @ Notebook[ { $splitCell } ],
  "See \\cite{first, second} and \\eqref{eq:a}.\n\n"
]

(* LaTeXPaperImport T7. An environment body is split exactly as the document body is: its display
   math is lifted into cells of its own, and a nested environment becomes its own cells. What kept
   a body to one cell before was that the \end{...} had nowhere else to go; it rides on the LAST
   cell of the group now and the \begin{...} on the first, both as plain strings, so the export is
   still a StringJoin and the delimiters still land where the source had them. *)

$bodySource = $preamble <> "\\begin{document}\n\n\\begin{defn}[Named] \\label{def:one}\nBefore the equation:\n\\begin{equation}\\label{eq:inner}\nx^2\n\\end{equation}\nand after it.\n\n\\begin{axiom}\nA nested body.\n\\end{axiom}\n\nA last word.\n\\end{defn}\n\nSee Definition~\\ref{def:one} and~\\eqref{eq:inner}.\n\n\\end{document}\n"

$bodyNotebook = latexToNotebook[ $bodySource ]

$bodyCells = First[ $bodyNotebook ]

(* Six cells where T2 made one: the definition's prose in three pieces, the equation it wrapped
   around, and the nested axiom, which carries its own \begin/\end inside the definition's. *)
VerificationTest[
  Map[ #[[ 2 ]] &, $bodyCells ],
  { "Definition", "DisplayFormulaNumbered", "Definition", "Theorem", "Definition", "Text" }
]

(* The equation inside the body is a real numbered cell now, so its \label is a tag and the \eqref
   at it resolves to a counter instead of being left as literal source — 43 of hodgepaper's 72
   unconverted references are of exactly this kind. *)
VerificationTest[
  Cases[ $bodyCells, Cell[ _, style_String, ___, CellTags -> key_String, ___ ] :> style -> key ],
  { "Definition" -> "def:one", "DisplayFormulaNumbered" -> "eq:inner" }
]

VerificationTest[
  Cases[ $bodyCells, _ButtonBox, Infinity ],
  { ButtonBox[ RowBox @ { CounterBox[ "Section", "def:one" ], ".", CounterBox[ "Theorem", "def:one" ] },
      BaseStyle -> "Citation", ButtonData -> "def:one" ],
    ButtonBox[ RowBox @ { "(", CounterBox[ "DisplayFormulaNumbered", "eq:inner" ], ")" },
      BaseStyle -> "Citation", ButtonData -> "eq:inner" ] }
]

(* The name, the number and the QED square belong to the block and not to each of its cells: the
   first prose cell of a body opens it and the last closes it, and every cell between suppresses
   both. Without this a definition whose body ran to three cells would be numbered three times and
   would say "Definition" three times. Suppressing on the cell rather than declaring a continuation
   style keeps a sheet swap working: "this cell continues the one above" is true under every
   stylesheet, where writing the positive counter onto each cell would pin the numbering. *)
VerificationTest[
  Map[ { FreeQ[ #, CounterIncrements ], FreeQ[ #, CellFrameLabels ] } &,
    Cases[ $bodyCells, Cell[ _, "Definition", ___ ] ] ],
  { { True, False }, { False, False }, { False, True } }
]

(* Out and back, byte for byte, with the nested \begin{axiom} inside the definition's own. *)
VerificationTest[
  notebookToLaTeX[ $bodyNotebook ],
  $bodySource
]

(* A nested environment opening a body is the case where the two wrappers meet on one cell: the
   outer \begin is prepended to the inner one, and the outer \end appended to the inner's. *)
$nestedSource = $preamble <> "\\begin{document}\n\n\\begin{proof}\n\\begin{axiom}\nThe only body.\n\\end{axiom}\n\\end{proof}\n\n\\end{document}\n"

VerificationTest[
  { Map[ #[[ 2 ]] &, First @ latexToNotebook[ $nestedSource ] ],
    notebookToLaTeX @ latexToNotebook[ $nestedSource ] === $nestedSource },
  { { "Theorem" }, True }
]

(* An empty body has no cell to hang the wrapper on, so one is made for it. *)
VerificationTest[
  notebookToLaTeX @ latexToNotebook[ $preamble <> "\\begin{document}\n\n\\begin{conv}\n\\end{conv}\n\n\\end{document}\n" ],
  $preamble <> "\\begin{document}\n\n\\begin{conv}\n\\end{conv}\n\n\\end{document}\n"
]

(* A body that opens with a display equation is where the two ways a cell can carry a \label meet.
   The equation's tag is a mirror of the \label already inside its stored source, where a section's
   or an environment's tag is the origin of one — so writing the tag back out on the cell that also
   carries the \begin emitted the label twice. What this cannot fix is the ordering: the name and
   the number go on the body's first *prose* cell, so here they follow the equation rather than
   precede it. Neither specimen paper has such a body — all 102 of their environments open with
   prose — so it is left as a known limit rather than guessed at. *)
$displayFirstSource = $preamble <> "\\begin{document}\n\n\\begin{defn}\n\\begin{equation}\\label{eq:x}\nx^2\n\\end{equation}\nAnd prose.\n\\end{defn}\n\n\\end{document}\n"

VerificationTest[
  { Map[ #[[ 2 ]] &, First @ latexToNotebook[ $displayFirstSource ] ],
    StringCount[ notebookToLaTeX @ latexToNotebook[ $displayFirstSource ], "\\label{eq:x}" ],
    notebookToLaTeX @ latexToNotebook[ $displayFirstSource ] === $displayFirstSource },
  { { "DisplayFormulaNumbered", "Definition" }, 1, True }
]

(* LaTeXPaperImport T8. Front matter and lists. \title, \author and \date join the three sectioning
   commands as commands whose braced argument is the cell's content — the style name lowercased is the
   command, so one clause writes all six back — and abstract joins proof as an environment outside the
   twelve that has a style of its own. A list is recorded exactly as T7 records a theorem: the \begin
   on the first cell of the group, the \end on the last, and each \item on the cell it opens. *)

$frontSource = $preamble <> "\\begin{document}\n\n\\title{\\vspace{-1cm}A Paper}\n\\author{\n% a comment\n{First Author}\n}\n\\date{}\n\n\\maketitle\n\n\\begin{abstract}\nAn abstract with $x^2$.\n\nA second paragraph of it.\n\\end{abstract}\n\n\\section{Body}\n\n\\end{document}\n"

$frontNotebook = latexToNotebook[ $frontSource ]

(* \maketitle is the one front-matter command left as prose: it has no content, so it has no notebook
   counterpart, and hiding it while \sloppy and \tableofcontents stay visible would be arbitrary. *)
VerificationTest[
  Map[ #[[ 2 ]] &, First @ $frontNotebook ],
  { "Title", "Author", "Date", "Text", "Abstract", "Abstract", "Section" }
]

(* A braced argument is matched brace-balanced, not up to the first "}", or the specimen's
   \title{\vspace{-1.5cm}...} would have been cut in half; \date{} is the empty case. *)
VerificationTest[
  Cases[ First @ $frontNotebook, Cell[ content_, "Title" | "Author" | "Date", ___ ] :> content ],
  { "\\vspace{-1cm}A Paper", "\n% a comment\n{First Author}\n", "" }
]

(* The abstract is a block like a theorem: only its first cell is headed, so the style's "Abstract. "
   dingbat is printed once however many paragraphs it runs to. *)
VerificationTest[
  Map[ FreeQ[ #, CounterIncrements ] &, Cases[ First @ $frontNotebook, Cell[ _, "Abstract", ___ ] ] ],
  { True, False }
]

VerificationTest[ (* out and back, byte for byte *)
  notebookToLaTeX[ $frontNotebook ],
  $frontSource
]

VerificationTest[ (* the cell owns its content, so retitling the notebook reaches the .tex *)
  StringContainsQ[
    notebookToLaTeX @ Notebook[ Replace[ First @ $frontNotebook,
      Cell[ _, "Title", options___ ] :> Cell[ "Renamed", "Title", options ], { 1 } ] ],
    "\\title{Renamed}" ],
  True
]

$listSource = $preamble <> "\\begin{document}\n\n\\begin{itemize}\n    \\item First with $x^2$.\n    \\item Second.\n\n      A second paragraph.\n\\end{itemize}\n\n\\begin{enumerate}\n\\item[(E)] Labelled.\n\\item Plain.\n\\end{enumerate}\n\n\\end{document}\n"

$listNotebook = latexToNotebook[ $listSource ]

(* An item is a cell; a second paragraph of the same item is an ItemParagraph, which is what carries
   no bullet of its own. *)
VerificationTest[
  Map[ #[[ 2 ]] &, First @ $listNotebook ],
  { "Item", "Item", "ItemParagraph", "ItemNumbered", "ItemNumbered" }
]

(* LaTeX restarts every list where the front end's counters run on until a section resets them, so the
   first item of a list carries the reset — and \item[label] prints its label instead of the number
   and consumes no counter, so the label becomes the cell's dingbat. *)
VerificationTest[
  Map[
    { FirstCase[ #, ( CounterAssignments -> value_ ) :> value, None ],
      FirstCase[ #, ( CounterIncrements -> value_ ) :> value, None ],
      FirstCase[ #, ( CellDingbat -> Cell[ TextData[ label_ ], ___ ] ) :> label, None ] } &,
    Cases[ First @ $listNotebook, Cell[ _, "Item" | "ItemNumbered", ___ ] ] ],
  { { { { "Item", 0 } }, None, None },
    { None, None, None },
    { { { "ItemNumbered", 0 } }, { }, { "(E)" } },
    { None, None, None } }
]

VerificationTest[ (* out and back, byte for byte, with every \item where the source had it *)
  notebookToLaTeX[ $listNotebook ],
  $listSource
]

(* A list inside a theorem body: the body's prose cells take the environment style and the item cells
   are left alone, because environmentStyled restyles only what is still "Text" at its level. *)
$listInBodySource = $preamble <> "\\begin{document}\n\n\\begin{defn}\nA definition:\n\\begin{itemize}\n\\item One.\n\\end{itemize}\nand after.\n\\end{defn}\n\n\\end{document}\n"

VerificationTest[
  { Map[ #[[ 2 ]] &, First @ latexToNotebook[ $listInBodySource ] ],
    notebookToLaTeX @ latexToNotebook[ $listInBodySource ] === $listInBodySource },
  { { "Definition", "Item", "Definition" }, True }
]

(* Nesting: the depth chooses Subitem over Item, and the two wrappers meet on the inner list's last
   cell, where the outer \end is appended to the inner's. *)
$nestedListSource = $preamble <> "\\begin{document}\n\n\\begin{itemize}\n\\item Outer.\n  \\begin{enumerate}\n  \\item Inner.\n  \\end{enumerate}\n\\end{itemize}\n\n\\end{document}\n"

VerificationTest[
  { Map[ #[[ 2 ]] &, First @ latexToNotebook[ $nestedListSource ] ],
    notebookToLaTeX @ latexToNotebook[ $nestedListSource ] === $nestedListSource },
  { { "Item", "SubitemNumbered" }, True }
]

(* An item whose whole content is display math has no cell that could take the item style — three of
   hodgepaper's description items are an align and nothing else — so the head goes onto the cell that
   opens it. Without this the item's [label], which is the whole of its content, is not shown at all. *)
$displayItemSource = $preamble <> "\\begin{document}\n\n\\begin{description}\n\\item[(a)]\n\\begin{equation*}\nx^2\n\\end{equation*}\n\\end{description}\n\n\\end{document}\n"

VerificationTest[
  { Map[ #[[ 2 ]] &, First @ latexToNotebook[ $displayItemSource ] ],
    Cases[ First @ latexToNotebook[ $displayItemSource ],
      Cell[ ___, CellDingbat -> Cell[ TextData[ label_ ], ___ ], ___ ] :> label, Infinity ],
    notebookToLaTeX @ latexToNotebook[ $displayItemSource ] === $displayItemSource },
  { { "DisplayFormula" }, { { "(a)" } }, True }
]

(* Which \item belongs to this list is a depth walk, and both halves of it bite on the specimen. A
   \begin written inline whose \end starts a line — $\begin{cases} ... \n\end{cases}$ — drove the depth
   negative when only line-initial delimiters were counted, and items (b) and after became
   continuation paragraphs of (a). A commented-out %\item must not count at all, which is what the
   comment mask does now that the StartOfLine anchor cannot do it alone. *)
$maskSource = $preamble <> "\\begin{document}\n\n\\begin{enumerate}\n\\item[(a)] A case: $x = \\begin{cases}\n\t1\n\t\\end{cases}$\n%\\item[(skipped)] commented out\n\\item[(b)] Second.\n\\end{enumerate}\n\n\\end{document}\n"

VerificationTest[
  { Map[ #[[ 2 ]] &, First @ latexToNotebook[ $maskSource ] ],
    Cases[ First @ latexToNotebook[ $maskSource ],
      Cell[ ___, CellDingbat -> Cell[ TextData[ label_ ], ___ ], ___ ] :> label, Infinity ],
    notebookToLaTeX @ latexToNotebook[ $maskSource ] === $maskSource },
  { { "ItemNumbered", "ItemNumbered" }, { { "(a)" }, { "(b)" } }, True }
]

(* A list with no items at all still has to come back out. *)
VerificationTest[
  notebookToLaTeX @ latexToNotebook[
    $preamble <> "\\begin{document}\n\n\\begin{itemize}\n\\end{itemize}\n\n\\end{document}\n" ],
  $preamble <> "\\begin{document}\n\n\\begin{itemize}\n\\end{itemize}\n\n\\end{document}\n"
]
