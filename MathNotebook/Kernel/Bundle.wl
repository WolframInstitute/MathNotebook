Package["WolframInstitute`MathNotebook`"]

PackageExport[ExportLaTeXBundle]

PackageScope["bundlePlan"]
PackageScope["graphicNames"]
PackageScope["graphicCandidates"]
PackageScope["bibliographyCandidates"]
PackageScope["bibliographyProgram"]
PackageScope["bundleTarget"]
PackageScope["bundleBibliography"]
PackageScope["bundleClass"]

(* ExportLaTeXDocument writes one file, and a .tex alone is not a submission: measured on the second
   specimen — main.tex, seven PNGs and references.bib — an export into an empty directory leaves
   main.tex alone in it while that same .tex names all seven \includegraphics files and
   \bibliography{references}. The round trip is byte-exact and the result compiles nowhere but the
   paper's original directory. This is the whole gap, and closing it is copying the files the source
   names beside the .tex and compiling the .bbl arXiv will not compile itself.

   Two decisions taken in T1 and visible in the code below.

   A named figure with no file is REPORTED, never evaluated. The only way an \includegraphics reaches
   the exported source at all is from an imported paper's stored markup — the whole evaluation family
   emits nothing, so a picture a notebook generates has no \includegraphics to satisfy — which means
   the case is an imported paper whose author replaced Import[...] with the code that draws the
   picture and whose shipped file has since gone. Evaluating that code would have to guess the format
   (arXiv accepts PDF/PNG/JPG for PDFLaTeX and EPS/PS for LaTeX and converts neither) and the size the
   source's own \includegraphics options assume, which is guessing at the author's compile route.

   No PDF goes in the bundle, ever. arXiv excludes .pdf and .ps from a source upload, so a compiled
   paper beside its source is a rejected submission and not a convenience. The LaTeX run therefore
   happens in a scratch copy and only the .bbl comes back — which is also what keeps the .aux and .log
   out without a cleanup pass. *)

Options[ ExportLaTeXBundle ] = {
  "SourceDirectory" -> Automatic,
  "Name" -> Automatic,
  "Bibliography" -> Automatic
}

(* A NotebookObject knows both things a Notebook expression cannot: where its paper's files are, and
   what \jobname is. Options given by the caller come first, so an explicit one still wins. *)
ExportLaTeXBundle[ notebook_NotebookObject, directory_String, opts : OptionsPattern[ ] ] :=
  ExportLaTeXBundle[ NotebookGet[ notebook ], directory, opts,
    "SourceDirectory" -> Replace[ Quiet @ NotebookDirectory[ notebook ], Except[ _String ] -> Automatic ],
    "Name" -> Replace[ Quiet @ NotebookFileName[ notebook ],
      { file_String :> FileBaseName[ file ], _ -> Automatic } ] ]

ExportLaTeXBundle[ notebook_Notebook, directory_String, opts : OptionsPattern[ ] ] :=
  Module[ { source, name, home, plan, found, missing, extra },
    source = notebookToLaTeX[ notebook ];
    name = Replace[ OptionValue[ "Name" ], Automatic -> "paper" ];
    home = Replace[ OptionValue[ "SourceDirectory" ], Automatic -> None ];
    plan = bundlePlan[ source, home, name ];
    found = Select[ plan, StringQ @ #[ "Source" ] & ];
    missing = Select[ plan, MissingQ @ #[ "Source" ] & ];
    If[ ! DirectoryQ[ directory ], CreateDirectory[ directory, CreateIntermediateDirectories -> True ] ];
    Export[ FileNameJoin @ { directory, name <> ".tex" }, source, "Text" ];
    Scan[ bundleCopy[ directory, # ] &, found ];
    (* One message for a notebook with no directory, not one per file it could not look for. *)
    If[ home === None,
      If[ missing =!= { }, Message[ ExportLaTeXBundle::nohome ] ],
      Scan[ Message[ ExportLaTeXBundle::nofile, #[ "Name" ], #[ "Looked" ] ] &, missing ] ];
    bundleClass[ source ];
    extra = If[ OptionValue[ "Bibliography" ] === False || bibliographyNames[ source ] === { },
      { },
      bundleBibliography[ directory, name, source ] ];
    (* Map, not Lookup: an empty list reads as an empty rule list, so Lookup[{}, "Target"] answers
       Missing["KeyAbsent", ...] and the whole Join then stays unevaluated inside the result. *)
    <| "Directory" -> directory,
       "Files" -> Join[ { name <> ".tex" }, Map[ #[ "Target" ] &, found ], extra ],
       "Missing" -> Map[ #[ "Name" ] &, missing ] |>
  ]

ExportLaTeXBundle::nofile =
  "The file `1`, which the paper names, was not found at `2`: the bundle does not contain it and \
LaTeX will not compile without it.";

ExportLaTeXBundle::nohome =
  "The notebook has no directory on disk, so the figures and bibliography files the paper names \
cannot be located and the bundle holds the .tex alone. Save the notebook beside its paper, or pass \
\"SourceDirectory\".";

ExportLaTeXBundle::nolatex =
  "No local pdflatex and `1` were found, so the bundle carries no .bbl. arXiv does not run BibTeX: \
install a TeX distribution and export again, or add the .bbl by hand.";

ExportLaTeXBundle::nobbl =
  "The local LaTeX run produced no `1`.bbl, so the bundle carries none. arXiv does not run BibTeX.";

ExportLaTeXBundle::noclass =
  "The document class `1` is not in the local TeX distribution. arXiv compiles against its own TeX \
Live, so this is a warning about the class and not about the bundle.";

(* Every file the source names, paired with where it is on disk — a pure function of the source, the
   paper's home directory and \jobname, so a bundle can be asserted without writing one. Each entry
   carries the name as the source spells it, the path it must have in the bundle, and the file it is
   copied from; an unresolved name keeps its "Name" and reports Missing for the other two. *)
bundlePlan[ source_String, home_, name_String ] :=
  Join[
    Map[ plannedFile[ #, graphicCandidates[ #, home ] ] &, graphicNames[ source ] ],
    Map[ plannedFile[ #, bibliographyCandidates[ #, home, name ] ] &, bibliographyNames[ source ] ] ]

plannedFile[ name_String, candidates_List ] :=
  Replace[ SelectFirst[ candidates, FileExistsQ ],
    { path_String :> <| "Name" -> name, "Target" -> bundleTarget[ name, path ], "Source" -> path,
                        "Looked" -> path |>,
      (* "Looked" is where the search went, which is what the author has to go and find. It differs
         from "Name" for exactly the cases that are hard to read off the source: \jobname.bib, and an
         extensionless \includegraphics that was tried against six extensions. *)
      _ :> <| "Name" -> name, "Target" -> Missing[ "NotFound", name ],
              "Source" -> Missing[ "NotFound", name ],
              "Looked" -> First[ candidates, name ] |> } ]

(* \includegraphics{plot} is legal and finds plot.pdf, so the copy has to keep the extension that was
   resolved rather than the name that was written. *)
bundleTarget[ name_String, path_String ] :=
  If[ FileExtension[ name ] === "", name <> "." <> FileExtension[ path ], name ]

graphicNames[ source_String ] :=
  DeleteDuplicates @ Flatten @ StringCases[ source,
    "\\includegraphics" ~~ ( "[" ~~ Except[ "]" ] ... ~~ "]" ) | "" ~~ "{" ~~
      file : Except[ "}" ] .. ~~ "}" :> file ]

$graphicExtensions = { "pdf", "png", "jpg", "jpeg", "eps", "ps" }

graphicCandidates[ name_String, home_ ] :=
  If[ StringQ[ home ],
    With[ { base = FileNameJoin @ { home, name } },
      If[ FileExtension[ name ] === "", Map[ base <> "." <> # &, $graphicExtensions ], { base } ] ],
    { } ]

bibliographyCandidates[ name_String, home_, jobName_String ] :=
  If[ StringQ[ home ], { bibliographyFile[ name, home, jobName ] }, { } ]

(* The bundle directory may be the paper's own — the palette's dialog lets an author pick it, and
   nothing about that is unreasonable — in which case every copy is a file onto itself, which CopyFile
   refuses with a message rather than treating as a no-op. Compare the resolved paths and skip. *)
bundleCopy[ directory_String, entry_Association ] :=
  With[ { target = FileNameJoin @ { directory, entry[ "Target" ] } },
    If[ ! DirectoryQ @ DirectoryName[ target ],
      CreateDirectory[ DirectoryName[ target ], CreateIntermediateDirectories -> True ] ];
    If[ AbsoluteFileName[ entry[ "Source" ] ] =!= Quiet @ AbsoluteFileName[ target ],
      CopyFile[ entry[ "Source" ], target, OverwriteTarget -> True ] ] ]

(* The .bbl is the one piece copying cannot produce: arXiv runs LaTeX but not BibTeX, so a paper with
   a .bib compiles there only if the .bbl travels with it. Compiled in a scratch copy of the bundle,
   with only the .bbl brought back, which is how the .aux, .log and .pdf a run leaves behind stay out
   of the upload without a cleanup pass. \addbibresource is biblatex and is biber's, not BibTeX's. *)
bundleBibliography[ directory_String, name_String, source_String ] :=
  Module[ { program = bibliographyProgram[ source ], latex, scratch, bbl },
    latex = findExecutable[ "pdflatex" ];
    If[ ! StringQ[ latex ] || ! StringQ @ findExecutable[ program ],
      Message[ ExportLaTeXBundle::nolatex, program ];
      Return[ { } ] ];
    scratch = FileNameJoin @ { $TemporaryDirectory, "MathNotebookBundle-" <> CreateUUID[ ] };
    CopyDirectory[ directory, scratch ];
    RunProcess[ { latex, "-interaction=nonstopmode", name <> ".tex" }, ProcessDirectory -> scratch ];
    RunProcess[ { findExecutable[ program ], name }, ProcessDirectory -> scratch ];
    bbl = FileNameJoin @ { scratch, name <> ".bbl" };
    If[ FileExistsQ[ bbl ],
      CopyFile[ bbl, FileNameJoin @ { directory, name <> ".bbl" }, OverwriteTarget -> True ],
      Message[ ExportLaTeXBundle::nobbl, name ] ];
    DeleteDirectory[ scratch, DeleteContents -> True ];
    If[ FileExistsQ @ FileNameJoin @ { directory, name <> ".bbl" }, { name <> ".bbl" }, { } ]
  ]

bibliographyProgram[ source_String ] :=
  If[ StringContainsQ[ source, "\\addbibresource" ], "biber", "bibtex" ]

(* A class the local TeX distribution does not have is the one missing piece no directory listing
   shows. kpsewhich answers it in one call; with no TeX distribution there is nothing to ask and the
   check is skipped rather than guessed. *)
bundleClass[ source_String ] :=
  With[ { class = documentClass[ source ], kpsewhich = findExecutable[ "kpsewhich" ] },
    If[ class =!= "" && StringQ[ kpsewhich ] &&
        RunProcess[ { kpsewhich, class <> ".cls" }, "ExitCode" ] =!= 0,
      Message[ ExportLaTeXBundle::noclass, class ] ] ]
