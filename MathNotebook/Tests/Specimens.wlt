Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

(* LaTeXPaperImport T6. The two real papers this item was measured against, pinned as fixtures: each
   one is imported, exported, and compared with its own source, and its structure is counted, so a
   break reports which converter regressed rather than only that the bytes moved.

   Neither paper is in the repo -- one is an unpublished draft with two co-authors and the other a
   published paper of Pavel's, and neither is the paclet's to redistribute -- so this file looks for
   them in the repo's gitignored Resources/, or in the directory named by MATHNOTEBOOK_SPECIMENS, and emits no
   tests for a paper it cannot find. A run without them reports fewer tests rather than green ones,
   and the notice below names what was missing. When the paclet is installed from an archive rather
   than loaded from the working tree, nothing is found and nothing is asserted.

   T10 adds a third group at the end of the file, and it is not one of those two papers: the paclet's
   own four LaTeX samples, which the repo does contain. They are the only documents here with a
   thebibliography written into the .tex, so without them a task could drop that whole converter and
   leave every test green.

   Kernel-only, as every .wlt but FrontEnd.wlt is. The save-and-reopen half of the round trip -- the
   button splitting T5 found, which no in-kernel comparison can see -- needs a front end and is
   asserted there, on a synthetic source.

   A census that moves is this fixture working, not a bug in it. T7 lifted the display math out of
   theorem bodies, T8 converted the front matter and the lists, and T9 made the numbering the
   document's rather than the sheets', so all three changed these numbers, and the diff is the record
   of what each task did. "Bytes" is the guard on that reading: if it moves, the paper changed and not
   the converter. *)

(* RepoOrganization T2. Two directories, and they are not the same one: the repo root, where the
   LaTeX samples at the end of this file live, and the specimen home Resources/, which
   MATHNOTEBOOK_SPECIMENS overrides. One symbol served as both until the papers moved into
   Resources/, at which point pointing it there silently took the samples group with it. *)
$repoDirectory =
  Replace[ PacletObject[ "WolframInstitute/MathNotebook" ][ "Location" ],
    { location_String :> ParentDirectory[ location ], _ :> None } ]

$specimenDirectory =
  SelectFirst[
    { Environment[ "MATHNOTEBOOK_SPECIMENS" ],
      Replace[ $repoDirectory, { root_String :> FileNameJoin @ { root, "Resources" }, _ :> None } ] },
    StringQ[ # ] && DirectoryQ[ # ] &, None ]

specimenFile[ file_String ] :=
  If[ FileExistsQ[ file ], file, Missing[ "NotFound", FileNameTake[ file ] ] ]

(* The causal-graphs paper ships as a zip, and its main.tex needs references.bib beside it or the
   bibliography converts to nothing at all, so the archive is extracted whole into a fresh directory. *)
specimenArchive[ archive_String, member_String ] :=
  If[ FileExistsQ[ archive ],
    SelectFirst[ ExtractArchive[ archive, CreateDirectory[] ], FileNameTake[ # ] === member &,
      Missing[ "NotFound", FileNameTake[ archive ] ] ],
    Missing[ "NotFound", FileNameTake[ archive ] ] ]

$candidates =
  If[ $specimenDirectory === None,
    <| "Causal graphs" -> Missing[ "NotFound", "Axiomatic_Relativity_from_Causal_Graphs.zip" ],
       "Hodge" -> Missing[ "NotFound", "hodgepaper.tex" ] |>,
    <| "Causal graphs" -> specimenArchive[
         FileNameJoin @ { $specimenDirectory, "Axiomatic_Relativity_from_Causal_Graphs.zip" }, "main.tex" ],
       "Hodge" -> specimenFile @ FileNameJoin @ { $specimenDirectory, "hodgepaper.tex" } |> ]

$specimens = DeleteMissing[ $candidates ]

If[ Length[ $specimens ] < Length[ $candidates ],
  Print[ "Specimens.wlt: no tests emitted for ",
    StringRiffle[ Last /@ Values @ Select[ $candidates, MissingQ ], ", " ],
    " -- put the paper in the repo's Resources/, or point MATHNOTEBOOK_SPECIMENS at it." ] ]

(* $evaluationStyles is file-private in Document.wl, and an undeclared symbol read from here would be
   a distinct symbol with no value, so the two styles the importer actually emits are written out.
   Only the cell content is read, never the options, so the source a figure carries verbatim in its
   tagging rules does not count as literal LaTeX left in the prose. *)
specimenProse[ cells_List ] :=
  StringJoin @ Cases[ cells,
    Cell[ content_, Except[ "Input" | "Output" ], ___ ] :>
      StringJoin @ Cases[ content, _String, Infinity ] ]

(* cellTagging is file-private for the same reason, so the rules are read out here. T7 replaced
   "one environment is one cell" with "one cell of the group carries the \begin", and the invariant
   that goes with it is that exactly one cell of each group is headed -- keeps its style's dingbat
   and its counter increment. Numbering a body twice, or not at all, is invisible to both the round
   trip and the style census: both read the stored source, and the continuation cells carry the
   right style either way. *)
specimenTagging[ cell_Cell, key_String ] :=
  Replace[
    Cases[ cell, ( TaggingRules -> tagging_ ) :>
      Lookup[ Lookup[ Association @ tagging, "MathNotebook", <| |> ], key, "" ] ],
    { { value_String, ___ } :> value, _ :> "" } ]

$environmentStyles = Join[ Keys @ $theoremEnvironments, { "Proof", "Abstract" } ]

$itemStyles = { "Item", "ItemNumbered", "Subitem", "SubitemNumbered", "Subsubitem", "SubsubitemNumbered" }

$listNames = "itemize" | "enumerate" | "description"

(* T8's invariant is the same shape as T7's, one level down: every \item the source writes lands on a
   cell (Items), and every one of those cells shows a marker (ItemsHeaded) -- either from an Item-family
   style or, for an item whose whole content is display math, from the dingbat itemHead writes on it.
   An item that lost its number or its [label] is invisible to the round trip, which reads the stored
   source, and to the style counts, which see the cell either way.

   T9 counts numbering separately, because it is the one thing here that neither the round trip nor any
   of the counts above can see: all five keys read options that no exporter reads back. Numbered is an
   environment counted by a counter of its own; Unnumbered one the source declares starred, which must
   therefore stop incrementing the counter its style claims; EquationNumbers a display formula numbered
   within its section rather than straight through the document; ItemFormats an item of an enumerate whose
   label= prints something other than the style's arabic number; Resets a counter restarted at a
   sectioning level the sheets do not restart it at, the item resets T8 owns being left out so that what
   is counted is T9's own. The two papers cover the five between them and neither covers all five.
   Resets earns its place: dropping the whole reset pass leaves both papers exporting byte for byte AND
   every other number here intact, because a reset is a CounterAssignments that no exporter reads and no
   other count looks at. It is the fifth time in this item that fidelity and correctness came apart. *)
specimenCensus[ file_String ] :=
  Module[ { source, notebook, cells, prose, opens, written },
    source = Import[ file, "Text" ];
    (* hodgepaper declares a .bib it does not ship, which T10 reports; the report is asserted below
       rather than here, so that the census run stays a measurement and not a message storm. *)
    notebook = Quiet[ ImportLaTeXDocument[ file ], ImportLaTeXDocument::nobib ];
    cells = First[ notebook ];
    prose = specimenProse[ cells ];
    opens = Map[ specimenTagging[ #, "EnvironmentOpen" ] &, cells ];
    written = FileNameJoin @ { $TemporaryDirectory, "MathNotebookSpecimen.tex" };
    ExportLaTeXDocument[ notebook, written ];
    <| "Bytes" -> StringLength[ source ],
       "Cells" -> Length[ cells ],
       "Styles" -> KeySort @ Counts @ Cases[ cells, Cell[ _, style_String, ___ ] :> style ],
       "Tagged" -> Count[ cells, Cell[ __, CellTags -> _, ___ ] ],
       "Buttons" -> Count[ cells, _ButtonBox, Infinity ],
       "Counters" -> Count[ cells, _CounterBox, Infinity ],
       "Environments" -> Count[ opens,
         opening_ /; StringContainsQ[ opening, "\\begin{" ] &&
           ! StringContainsQ[ opening, "\\begin{" ~~ $listNames ~~ "}" ] ],
       "Lists" -> Count[ opens, opening_ /; StringContainsQ[ opening, "\\begin{" ~~ $listNames ~~ "}" ] ],
       "Headed" -> Count[ cells,
         cell : Cell[ _, style_String, ___ ] /; MemberQ[ $environmentStyles, style ] && FreeQ[ cell, CellDingbat -> None ] ],
       "Items" -> Total @ Map[ StringCount[ #, "\\item" ] &, opens ],
       "ItemsHeaded" -> Count[ cells,
         cell : Cell[ _, style_String, ___ ] /;
           StringContainsQ[ specimenTagging[ cell, "EnvironmentOpen" ], "\\item" ] &&
           ( MemberQ[ $itemStyles, style ] || ! FreeQ[ cell, CellDingbat -> _ ] ) ],
       "Numbering" -> <|
         "Numbered" -> Count[ cells,
           Cell[ _, style_String, ___, CounterIncrements -> Except[ { } ], ___ ] /;
             MemberQ[ $environmentStyles, style ] ],
         "Unnumbered" -> Count[ cells,
           cell : Cell[ _, style_String, ___, CounterIncrements -> { }, ___ ] /;
             MemberQ[ $environmentStyles, style ] && FreeQ[ cell, CellDingbat -> None ] ],
         "EquationNumbers" -> Count[ cells, Cell[ _, "DisplayFormulaNumbered", ___, CellFrameLabels -> _, ___ ] ],
         "ItemFormats" -> Count[ cells, cell_Cell /; ! FreeQ[ cell, CounterFunction ] ],
         "Resets" -> Length @ Select[
           Flatten[ Cases[ cells, ( CounterAssignments -> value_ ) :> value, Infinity ], 1 ],
           ! MemberQ[ $itemStyles, First[ # ] ] & ] |>,
       "Literal" -> <|
         "Reference" -> StringCount[ prose, "\\ref{" | "\\eqref{" ],
         "Citation" -> StringCount[ prose, "\\cite{" ],
         "Graphics" -> StringCount[ prose, "\\includegraphics" ],
         "Display" -> StringCount[ prose, "\\begin{equation" | "\\begin{align" ],
         "Item" -> StringCount[ prose, "\\item" ],
         "FrontMatter" -> StringCount[ prose, "\\title{" | "\\author{" | "\\date{" | "\\begin{abstract}" ] |>,
       "Identical" -> notebookToLaTeX[ notebook ] === source,
       "Written" -> Import[ written, "Text" ] === source |>
  ]

$measured = Map[ specimenCensus, $specimens ]

(* The causal paper converts completely: no \ref, \cite, \includegraphics, display environment, \item
   or front-matter command is left as literal text anywhere in its prose, and its 7 figures are 7 Input
   cells beside 7 captions. T7 left it untouched -- none of its 32 environments holds display math --
   and T8 is where it moves again: 130 cells became 169 as its title, author, date and abstract became
   cells of their own and its 12 lists became 41 items. \maketitle is the one command left as prose, by
   the decision that a command with no content has no notebook counterpart; it joins \sloppy and
   \tableofcontents rather than being singled out.

   Hodge is where T7 showed: 172 cells became 349 as 53 of its 55 display blocks were lifted out of
   theorem bodies, and 43 of its 72 unconvertible references found the cell they point at. T8 takes it
   to 378 -- 11 lists, 31 items, a title, an author and an abstract. What is left is named rather than
   rounded off. The 2 display blocks are the ones texToBoxes cannot read -- an equation* wrapping a
   tikzcd and an equation wrapping a gathered -- which are left as source deliberately. Of the 29
   references, 6 are at tables and the rest are at labels no cell carries: an align with two \labels
   keeps only the first, and a \label on its own line inside a body is not on the \begin line where
   labelledCell reads it. The 6 literal \items are the three commented-out enumerate blocks, which must
   stay literal: the comment mask in itemChunks is what keeps them out of the live lists.

   T9 moves only the numbering keys and the counter count, not one cell or style: the causal paper
   declares four independent per-subsection counters, so all 32 of its environments carry one, while
   hodgepaper shares one per-section counter across six environment names -- which is exactly what the
   sheets do -- so none of its 71 carry anything and what moves there is its four starred environments,
   its 33 equations numbered within the section as amsart numbers them, and the five items of its two
   enumerates opened with a label= format. *)
$expected = <|
  "Causal graphs" -> <|
    "Bytes" -> 36656,
    "Cells" -> 169,
    "Styles" -> <| "Abstract" -> 1, "Author" -> 1, "Caption" -> 7, "Construction" -> 2, "Date" -> 1,
      "Definition" -> 20, "DisplayFormula" -> 2, "Input" -> 7, "Item" -> 38, "ItemNumbered" -> 3,
      "Reference" -> 14, "Section" -> 8, "Subsection" -> 11, "Text" -> 43, "Theorem" -> 10,
      "Title" -> 1 |>,
    "Tagged" -> 39,
    "Buttons" -> 14,
    "Counters" -> 101,
    "Environments" -> 33,
    "Lists" -> 12,
    "Headed" -> 33,
    "Items" -> 41,
    "ItemsHeaded" -> 41,
    "Numbering" -> <| "Numbered" -> 32, "Unnumbered" -> 0, "EquationNumbers" -> 0, "ItemFormats" -> 0,
      "Resets" -> 16 |>,
    "Literal" -> <| "Reference" -> 0, "Citation" -> 0, "Graphics" -> 0, "Display" -> 0, "Item" -> 0,
      "FrontMatter" -> 0 |> |>,
  "Hodge" -> <|
    "Bytes" -> 142877,
    "Cells" -> 378,
    "Styles" -> <| "Abstract" -> 1, "Author" -> 1, "Definition" -> 28, "DisplayFormula" -> 50,
      "DisplayFormulaNumbered" -> 33, "Example" -> 21, "ItemNumbered" -> 28, "Lemma" -> 14,
      "Proof" -> 77, "Proposition" -> 7, "Remark" -> 13, "Section" -> 6, "Text" -> 87,
      "Theorem" -> 11, "Title" -> 1 |>,
    "Tagged" -> 84,
    "Buttons" -> 240,
    "Counters" -> 394,
    "Environments" -> 71,
    "Lists" -> 11,
    "Headed" -> 71,
    "Items" -> 31,
    "ItemsHeaded" -> 31,
    "Numbering" -> <| "Numbered" -> 0, "Unnumbered" -> 4, "EquationNumbers" -> 33, "ItemFormats" -> 5,
      "Resets" -> 4 |>,
    "Literal" -> <| "Reference" -> 29, "Citation" -> 0, "Graphics" -> 0, "Display" -> 2, "Item" -> 6,
      "FrontMatter" -> 0 |> |> |>

(* Both halves of the round trip: the pure core, and the same thing through the public wrapper and a
   file. They are not the same claim -- Export could add or drop a byte the core never sees. Both are
   against the imported text and not the bytes on disk: hodgepaper.tex has CRLF line endings, which
   Import normalizes away, so re-exporting it is faithful to the document and rewrites 1746 of its
   line endings. That is why "Bytes" reads 142877 for a file of 144624. *)
Do[
  With[ {
      id = name,
      identical = $measured[ name, "Identical" ],
      written = $measured[ name, "Written" ],
      structure = KeyTake[ $measured[ name ], { "Bytes", "Cells", "Styles" } ],
      references = KeyTake[ $measured[ name ],
        { "Tagged", "Buttons", "Counters", "Environments", "Lists", "Headed", "Items", "ItemsHeaded" } ],
      literal = $measured[ name, "Literal" ],
      numbering = $measured[ name, "Numbering" ],
      expected = $expected[ name ] },
    VerificationTest[ identical, True,
      TestID -> id <> ": the exported source is the imported source" ];
    VerificationTest[ written, True,
      TestID -> id <> ": the written file is the imported source" ];
    VerificationTest[ structure, KeyTake[ expected, { "Bytes", "Cells", "Styles" } ],
      TestID -> id <> ": cells and styles" ];
    VerificationTest[ references,
      KeyTake[ expected,
        { "Tagged", "Buttons", "Counters", "Environments", "Lists", "Headed", "Items", "ItemsHeaded" } ],
      TestID -> id <> ": tags, citations and counters" ];
    VerificationTest[ numbering, expected[ "Numbering" ],
      TestID -> id <> ": how it is numbered" ];
    VerificationTest[ literal, expected[ "Literal" ],
      TestID -> id <> ": what is still literal LaTeX" ] ],
  { name, Keys @ $measured } ]

(* LaTeXPaperImport T10. A declared .bib that is not on disk is the one gap in this converter that
   neither detector above can see: the paper comes back with no Reference cells and its citations
   still reading as their keys, the round trip is exact either way, and no census key counts a
   bibliography that is not there. hodgepaper is the real case -- it declares its .bib as
   \jobname.bib and ships without the file -- so the report is asserted on the papers themselves,
   and the causal paper, which ships references.bib, must stay silent.

   The expected message has to be written literally into each VerificationTest: the test holds its
   arguments, but a With that binds ImportLaTeXDocument::nobib to a variable evaluates the MessageName
   to its own text first and then matches nothing. *)
Do[
  With[ { id = name, file = $specimens[ name ] },
    If[ name === "Hodge",
      VerificationTest[ Head @ ImportLaTeXDocument[ file ], Notebook, { ImportLaTeXDocument::nobib },
        TestID -> id <> ": a declared .bib that is not there is reported" ],
      VerificationTest[ Head @ ImportLaTeXDocument[ file ], Notebook,
        TestID -> id <> ": a .bib that is there is converted in silence" ] ] ],
  { name, Keys @ $specimens } ]

(* SubmissionBundle T4. The gap measured on these same two papers: an ExportLaTeXDocument into an
   empty directory leaves the .tex alone in it while that .tex names seven \includegraphics files and
   \bibliography{references}, so the round trip is byte-exact and the result compiles nowhere but the
   paper's original directory. The bundle is the claim the census cannot make -- every number above is
   about one file -- so it is asserted here as a directory listing checked against arXiv's own rules.

   The causal paper is the case that works: seven PNGs beside a .bib. hodgepaper is the case that is
   reported: it declares \jobname.bib and ships without it, so its bundle is short by exactly that
   file and says so. The .bbl is not asserted -- it needs a local pdflatex, and this suite reports
   fewer tests on a machine without one rather than red ones -- but the BY-PRODUCTS are, since the run
   either happened in a scratch copy or did not happen at all, and either way nothing arXiv excludes
   may be in the directory. *)
$bundled =
  Association @ Map[
    Function[ name,
      Module[ { file = $specimens[ name ], directory = CreateDirectory[ ], notebook, result },
        notebook = Quiet @ ImportLaTeXDocument[ file ];
        result = Quiet @ ExportLaTeXBundle[ notebook, directory,
          "SourceDirectory" -> DirectoryName @ AbsoluteFileName @ file,
          "Name" -> FileBaseName[ file ] ];
        name -> <|
          "Missing" -> result[ "Missing" ],
          "Written" -> Sort @ Map[ FileNameTake, FileNames[ "*", directory ] ],
          "Promised" -> Complement[ Sort @ result[ "Files" ],
            Sort @ Map[ FileNameTake, FileNames[ "*", directory ] ] ],
          "Excluded" -> Select[ FileNames[ "*", directory ],
            StringMatchQ[ FileNameTake[ # ],
              FileBaseName[ file ] ~~ "." ~~ ( "aux" | "log" | "pdf" | "ps" | "blg" | "out" ) ] & ],
          "TeX" -> ( Import[ FileNameJoin @ { directory, FileBaseName[ file ] <> ".tex" }, "Text" ] ===
            Import[ file, "Text" ] ) |> ] ],
    Keys @ $specimens ]

$expectedBundle = <|
  "Causal graphs" -> <| "Missing" -> { },
    "Written" -> { "bisect.png", "branchial_graph.png", "causal_graph.png", "hg_rule.png", "main.tex",
      "message.png", "multiway_graph.png", "references.bib", "spatial_hg.png" } |>,
  (* Short by exactly the file it declares and does not ship, and it names it. *)
  "Hodge" -> <| "Missing" -> { "\\jobname.bib" },
    "Written" -> { "hodgepaper.tex" } |> |>

Do[
  With[ { id = name, measured = $bundled[ name ], expected = $expectedBundle[ name ] },
    VerificationTest[ measured[ "Missing" ], expected[ "Missing" ],
      TestID -> id <> ": what the bundle could not find" ];
    VerificationTest[ DeleteCases[ measured[ "Written" ], _?( StringEndsQ[ #, ".bbl" ] & ) ],
      expected[ "Written" ],
      TestID -> id <> ": the bundle is the .tex plus every file it names" ];
    VerificationTest[ measured[ "Promised" ], { },
      TestID -> id <> ": every file the result reports is on disk" ];
    VerificationTest[ measured[ "Excluded" ], { },
      TestID -> id <> ": no LaTeX by-product arXiv excludes" ];
    VerificationTest[ measured[ "TeX" ], True,
      TestID -> id <> ": the bundled .tex is the imported source" ] ],
  { name, Keys @ $bundled } ]

(* The paclet's own four LaTeX samples are the only documents this repo actually contains, and the
   only ones anywhere here with a thebibliography written into the .tex -- both specimen papers use a
   .bib. They are small, they are committed, and between them they carry a title block, an abstract,
   three sectioning levels, four theorem environments, numbered and unnumbered display math, a
   cross-reference and a bibliography, so a fresh clone with no specimens still pins something. They
   sit beside the paclet directory rather than inside it, so an installed paclet finds nothing and
   asserts nothing, exactly as the two papers above. *)
$samples =
  If[ ! StringQ[ $repoDirectory ], { },
    FileNames[ "Sample-*.tex", FileNameJoin @ { $repoDirectory, "LaTeX" } ] ]

If[ $samples === { },
  Print[ "Specimens.wlt: no tests emitted for the LaTeX samples -- LaTeX/Sample-*.tex was not found ",
    "beside the paclet directory." ] ]

Do[
  Module[ { id = FileBaseName[ file ], source = Import[ file, "Text" ], notebook },
    notebook = ImportLaTeXDocument[ file ];
    VerificationTest[ notebookToLaTeX[ notebook ], source,
      TestID -> id <> ": the exported source is the imported source" ];
    VerificationTest[
      Cases[ First @ notebook,
        cell : Cell[ _, "Reference", ___, CellTags -> key_String, ___ ] :>
          key -> FirstCase[ cell, ( CellDingbat -> Cell[ TextData[ label_ ], ___ ] ) :> label,
            None, Infinity ] ],
      { "matex" -> "[matex]", "ollivier" -> "[ollivier]" },
      TestID -> id <> ": the thebibliography entries" ] ],
  { file, $samples } ]
