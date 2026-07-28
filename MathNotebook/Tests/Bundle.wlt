Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

(* SubmissionBundle T4. Kernel-only, as every .wlt but FrontEnd.wlt is.

   Two things are asserted separately here, because each is invisible to the other. The PLAN is a pure
   function of the source, the paper's home directory and \jobname, so what a bundle would contain can
   be measured without writing one — that is where the extension search, \jobname and the missing-file
   case live. The WRITE is then measured on a fixture built on the spot, because a plan that is right
   and a directory that is empty look identical from the plan's side.

   The .bbl is deliberately not asserted as present: it needs a local pdflatex, and this suite must
   report fewer tests on a machine without one rather than red ones. What IS asserted unconditionally
   is the by-product rule — no .aux, .log or .pdf in the bundle — since that holds whether the run
   happened or not, and it is the clause arXiv rejects a submission over. *)

$home = CreateDirectory[ ]

Export[ FileNameJoin @ { $home, "plot.pdf" }, "%PDF-1.4 not really", "Text" ]
Export[ FileNameJoin @ { $home, "photo.png" }, "not really a png", "Text" ]
CreateDirectory[ FileNameJoin @ { $home, "figures" } ]
Export[ FileNameJoin @ { $home, "figures", "nested.png" }, "nested", "Text" ]
Export[ FileNameJoin @ { $home, "refs.bib" }, "@article{a, title={T}, author={A}, year={2026}}", "Text" ]

(* Four names of four different shapes: one with an extension, one without (found by the extension
   sweep), one in a subdirectory, and one that is not there at all. *)
$source = "\\documentclass{article}
\\begin{document}
\\includegraphics[width=3cm]{photo.png}
\\includegraphics{plot}
\\includegraphics{figures/nested.png}
\\includegraphics{absent.png}
\\bibliography{refs}
\\end{document}
"

$plan = bundlePlan[ $source, $home, "paper" ]

VerificationTest[
  graphicNames[ $source ],
  { "photo.png", "plot", "figures/nested.png", "absent.png" }
]

(* One name, one entry, in source order, with the .bib last. *)
VerificationTest[
  Map[ #[ "Name" ] &, $plan ],
  { "photo.png", "plot", "figures/nested.png", "absent.png", "refs" }
]

(* \includegraphics{plot} is legal and resolves to plot.pdf, so the copy has to carry the extension
   that was found and not the name that was written; \bibliography{refs} gains the .bib the same way. *)
VerificationTest[
  Map[ #[ "Target" ] &, $plan ],
  { "photo.png", "plot.pdf", "figures/nested.png", Missing[ "NotFound", "absent.png" ], "refs.bib" }
]

(* A file the paper names and disk does not have is reported, never omitted silently and never
   evaluated — the T1 decision. *)
VerificationTest[
  Map[ #[ "Name" ] &, Select[ $plan, MissingQ @ #[ "Source" ] & ] ],
  { "absent.png" }
]

(* With no home directory nothing can be looked for, so every named file is missing and the message is
   one about the notebook rather than four about the files. *)
VerificationTest[
  Map[ #[ "Source" ] &, bundlePlan[ $source, None, "paper" ] ],
  Map[ Missing[ "NotFound", # ] &, { "photo.png", "plot", "figures/nested.png", "absent.png", "refs" } ]
]

(* \jobname is the .tex's base name, which is the one thing a Notebook expression cannot know and the
   caller therefore passes in. hodgepaper is the live case. *)
VerificationTest[
  Map[ #[ "Looked" ] &, bundlePlan[ "\\bibliography{\\jobname}", $home, "hodgepaper" ] ],
  { FileNameJoin @ { $home, "hodgepaper.bib" } }
]

(* \addbibresource is biblatex, whose .bbl is biber's and not BibTeX's. *)
VerificationTest[
  { bibliographyProgram[ "\\bibliography{refs}" ], bibliographyProgram[ "\\addbibresource{refs.bib}" ] },
  { "bibtex", "biber" }
]

(* A thebibliography paper declares no .bib, so no LaTeX run is attempted for it and no .bbl is
   wanted: the entries are already in the .tex. All four of the paclet's samples are that shape. *)
VerificationTest[
  bibliographyNames[ "\\begin{thebibliography}{9}\n\\bibitem{a} A\n\\end{thebibliography}" ],
  { }
]

(* --- The write. A notebook that names the fixture's files, bundled into an empty directory. --- *)

$notebook = Notebook[ { Cell[ "Body.", "Text" ] },
  TaggingRules -> <| "MathNotebook" -> <| "Preamble" -> $source, "Postamble" -> "", "BodyPrefix" -> "" |> |> ]

$bundle = CreateDirectory[ ]

$result = Quiet @ ExportLaTeXBundle[ $notebook, $bundle, "SourceDirectory" -> $home, "Name" -> "paper" ]

$written = Sort @ Map[ FileNameDrop[ #, FileNameDepth[ $bundle ] ] &, FileNames[ "*", $bundle, Infinity ] ]

(* The gap this item closed: the one-file export left the .tex alone in the directory while that .tex
   named four figures and a .bib. The nested subdirectory is created, not flattened. *)
VerificationTest[
  DeleteCases[ $written, "figures" | "paper.bbl" ],
  { FileNameJoin @ { "figures", "nested.png" }, "paper.tex", "photo.png", "plot.pdf", "refs.bib" }
]

VerificationTest[
  $result[ "Missing" ],
  { "absent.png" }
]

(* arXiv excludes .aux, .log, .pdf and .ps from a source upload, so the optional LaTeX run happens in
   a scratch copy and only the .bbl comes back. This holds whether pdflatex was found or not, which is
   why it is asserted without a guard. Keyed on the job name and not on the extension: plot.pdf is a
   FIGURE, and arXiv accepts PDF figures for a PDFLaTeX route — what it rejects is the compiled paper
   and the run's own by-products. *)
VerificationTest[
  Select[ $written, StringMatchQ[ #, "paper." ~~ ( "aux" | "log" | "pdf" | "ps" | "blg" | "out" ) ] & ],
  { }
]

(* Reported files and written files are the same list — a result that promises a file the directory
   does not have is the failure this item exists to remove. *)
VerificationTest[
  Complement[ Sort @ $result[ "Files" ], $written ],
  { }
]

(* The bundle's .tex is the file the one-file export writes, byte for byte: the bundle adds files
   beside it and changes nothing in it. Compared as files, since Export["Text"] adds a trailing
   newline that Import then takes off again and neither side of that is this item's business. *)
VerificationTest[
  Import[ FileNameJoin @ { $bundle, "paper.tex" }, "Text" ],
  Import[ ExportLaTeXDocument[ $notebook, FileNameJoin @ { CreateDirectory[ ], "paper.tex" } ], "Text" ]
]

(* A missing figure is a message and not a silent omission. *)
VerificationTest[
  ExportLaTeXBundle[ $notebook, CreateDirectory[ ], "SourceDirectory" -> $home, "Name" -> "paper" ],
  _Association,
  { ExportLaTeXBundle::nofile },
  SameTest -> MatchQ
]

(* A notebook with no directory on disk gets one message about itself, not one per file. *)
VerificationTest[
  ExportLaTeXBundle[ $notebook, CreateDirectory[ ], "Name" -> "paper", "Bibliography" -> False ],
  _Association,
  { ExportLaTeXBundle::nohome },
  SameTest -> MatchQ
]

(* The bundle directory may be the paper's own, and then every copy is a file onto itself — which
   CopyFile refuses with a message rather than treating as a no-op. *)
VerificationTest[
  Quiet[ ExportLaTeXBundle[ $notebook, $home,
      "SourceDirectory" -> $home, "Name" -> "paper", "Bibliography" -> False ][ "Files" ] ],
  { "paper.tex", "photo.png", "plot.pdf", FileNameJoin @ { "figures", "nested.png" }, "refs.bib" }
]

VerificationTest[
  Import[ FileNameJoin @ { $home, "plot.pdf" }, "Text" ],
  "%PDF-1.4 not really"
]
