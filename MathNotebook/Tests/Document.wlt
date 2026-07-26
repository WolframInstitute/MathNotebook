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

VerificationTest[ (* the title is the cell content; the \label stays verbatim for T3 to claim *)
  First @ $cells,
  Cell[ "First", "Section",
    TaggingRules -> <| "MathNotebook" -> <| "Indent" -> "", "Trailing" -> " \\label{sec:one}", "Separator" -> "\n\n" |> |> ]
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
