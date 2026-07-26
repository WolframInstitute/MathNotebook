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
  { "Section", "Text", "Subsection", "Definition", "Theorem", "Proof", "Text" }
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

VerificationTest[ (* itemize is not a theorem environment: it stays as text, so the export can put
                     it back untouched *)
  ! FreeQ[ Last @ $cells, "\\begin{itemize}\n    \\item untouched\n\\end{itemize}" ],
  True
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

VerificationTest[ (* a key no converted cell carries — the specimen paper's figure labels — is left
                     as source rather than rendered as the front end's XXX *)
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
