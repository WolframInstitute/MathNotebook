Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

(* LaTeXPaperImport T6. The two real papers this item was measured against, pinned as fixtures: each
   one is imported, exported, and compared with its own source, and its structure is counted, so a
   break reports which converter regressed rather than only that the bytes moved.

   Neither paper is in the repo -- one is an unpublished draft with two co-authors and the other a
   published paper of Pavel's, and neither is the paclet's to redistribute -- so this file looks for
   them beside the loaded paclet, or in the directory named by MATHNOTEBOOK_SPECIMENS, and emits no
   tests for a paper it cannot find. A run without them reports fewer tests rather than green ones,
   and the notice below names what was missing. When the paclet is installed from an archive rather
   than loaded from the working tree, nothing is found and nothing is asserted.

   Kernel-only, as every .wlt but FrontEnd.wlt is. The save-and-reopen half of the round trip -- the
   button splitting T5 found, which no in-kernel comparison can see -- needs a front end and is
   asserted there, on a synthetic source.

   A census that moves is this fixture working, not a bug in it. T7 lifts the display math out of
   theorem bodies and T8 converts front matter and lists, so both will change these numbers, and the
   diff is then the record of what the task did. "Bytes" is the guard on that reading: if it moves,
   the paper changed and not the converter. *)

$specimenDirectory =
  SelectFirst[
    { Environment[ "MATHNOTEBOOK_SPECIMENS" ],
      Replace[ PacletObject[ "WolframInstitute/MathNotebook" ][ "Location" ],
        { location_String :> ParentDirectory[ location ], _ :> None } ] },
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
    " -- put the paper beside the paclet directory, or point MATHNOTEBOOK_SPECIMENS at it." ] ]

(* $evaluationStyles is file-private in Document.wl, and an undeclared symbol read from here would be
   a distinct symbol with no value, so the two styles the importer actually emits are written out.
   Only the cell content is read, never the options, so the source a figure carries verbatim in its
   tagging rules does not count as literal LaTeX left in the prose. *)
specimenProse[ cells_List ] :=
  StringJoin @ Cases[ cells,
    Cell[ content_, Except[ "Input" | "Output" ], ___ ] :>
      StringJoin @ Cases[ content, _String, Infinity ] ]

specimenCensus[ file_String ] :=
  Module[ { source, notebook, cells, prose, written },
    source = Import[ file, "Text" ];
    notebook = ImportLaTeXDocument[ file ];
    cells = First[ notebook ];
    prose = specimenProse[ cells ];
    written = FileNameJoin @ { $TemporaryDirectory, "MathNotebookSpecimen.tex" };
    ExportLaTeXDocument[ notebook, written ];
    <| "Bytes" -> StringLength[ source ],
       "Cells" -> Length[ cells ],
       "Styles" -> KeySort @ Counts @ Cases[ cells, Cell[ _, style_String, ___ ] :> style ],
       "Tagged" -> Count[ cells, Cell[ __, CellTags -> _, ___ ] ],
       "Buttons" -> Count[ cells, _ButtonBox, Infinity ],
       "Counters" -> Count[ cells, _CounterBox, Infinity ],
       "Literal" -> <|
         "Reference" -> StringCount[ prose, "\\ref{" | "\\eqref{" ],
         "Citation" -> StringCount[ prose, "\\cite{" ],
         "Graphics" -> StringCount[ prose, "\\includegraphics" ],
         "Display" -> StringCount[ prose, "\\begin{equation" | "\\begin{align" ] |>,
       "Identical" -> notebookToLaTeX[ notebook ] === source,
       "Written" -> Import[ written, "Text" ] === source |>
  ]

$measured = Map[ specimenCensus, $specimens ]

(* The causal paper converts completely: no \ref, \cite, \includegraphics or display environment is
   left as literal text anywhere in its prose, and its 7 figures are 7 Input cells beside 7 captions.
   Hodge's remainders are the two gaps the item still has open -- 72 references whose target is not a
   converted cell, which is T3's rule and not a defect, and 55 equation/align blocks inside theorem
   bodies, which is T7. *)
$expected = <|
  "Causal graphs" -> <|
    "Bytes" -> 36656,
    "Cells" -> 130,
    "Styles" -> <| "Caption" -> 7, "Construction" -> 2, "Definition" -> 20, "DisplayFormula" -> 2,
      "Input" -> 7, "Reference" -> 14, "Section" -> 8, "Subsection" -> 11, "Text" -> 49,
      "Theorem" -> 10 |>,
    "Tagged" -> 39,
    "Buttons" -> 14,
    "Counters" -> 25,
    "Literal" -> <| "Reference" -> 0, "Citation" -> 0, "Graphics" -> 0, "Display" -> 0 |> |>,
  "Hodge" -> <|
    "Bytes" -> 142877,
    "Cells" -> 172,
    "Styles" -> <| "Definition" -> 15, "DisplayFormula" -> 4, "DisplayFormulaNumbered" -> 9,
      "Example" -> 8, "Lemma" -> 10, "Proof" -> 12, "Proposition" -> 5, "Remark" -> 11,
      "Section" -> 6, "Text" -> 85, "Theorem" -> 7 |>,
    "Tagged" -> 60,
    "Buttons" -> 197,
    "Counters" -> 222,
    "Literal" -> <| "Reference" -> 72, "Citation" -> 0, "Graphics" -> 0, "Display" -> 55 |> |> |>

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
      references = KeyTake[ $measured[ name ], { "Tagged", "Buttons", "Counters" } ],
      literal = $measured[ name, "Literal" ],
      expected = $expected[ name ] },
    VerificationTest[ identical, True,
      TestID -> id <> ": the exported source is the imported source" ];
    VerificationTest[ written, True,
      TestID -> id <> ": the written file is the imported source" ];
    VerificationTest[ structure, KeyTake[ expected, { "Bytes", "Cells", "Styles" } ],
      TestID -> id <> ": cells and styles" ];
    VerificationTest[ references, KeyTake[ expected, { "Tagged", "Buttons", "Counters" } ],
      TestID -> id <> ": tags, citations and counters" ];
    VerificationTest[ literal, expected[ "Literal" ],
      TestID -> id <> ": what is still literal LaTeX" ] ],
  { name, Keys @ $measured } ]
