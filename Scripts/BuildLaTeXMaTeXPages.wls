(* One-off: the two reference pages for the LaTeX <-> MaTeX pair, each a TEXT transform of its
   nearest sibling. Expression surgery is not available here — a page's PrimaryExamplesSection is a
   HoldAllComplete InterpretationBox, so a blanket string rule lands as a literal call inside it —
   so every identifier, sentence and CellID is rewritten as text. Each replacement asserts its own
   occurrence count: a rule that silently matches nothing leaves a page that still parses and still
   opens, wearing its template's identity.

   Run once, at 0.1.23, and kept as the record of how a new page is made rather than as a build step:
   it always starts from the TEMPLATE, so running it again discards whatever the two pages have since
   become — including the Usage cells Scripts/RegenerateUsage.wls writes, which must be run after it. *)

repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];

pageDirectory = FileNameJoin[ { repoDirectory, "MathNotebook", "Documentation", "English",
  "ReferencePages", "Symbols" } ];

pagePath[ symbol_String ] := FileNameJoin[ { pageDirectory, symbol <> ".nb" } ];

replace[ text_String, rules_List ] :=
  Fold[
    { current, rule } |->
      With[ { count = StringCount[ current, First[ rule ] ] },
        If[ count =!= 1,
          Print[ "ABORT: ", count, " occurrences of ", InputForm @ StringTake[ First[ rule ], UpTo[ 70 ] ] ];
          Abort[ ] ];
        StringReplace[ current, rule ] ],
    text, rules ];

(* Deleting a clause of a Notes cell by line, so that no long literal has to survive the exporter's
   own wrapping: from the line reading `from` up to and including the next one reading `to`. *)
dropRange[ text_String, from_String, to_String ] :=
  With[ { lines = StringSplit[ text, "\n", All ] },
    With[ { start = First @ Flatten @ Position[ lines, from ] },
      With[ { stop = start + First @ Flatten @ Position[ Drop[ lines, start ], to ] },
        StringRiffle[ Join[ Take[ lines, start - 1 ], Drop[ lines, stop ] ], "\n" ] ] ] ];

(* A page sharing a CellID or an ExpressionUUID with its template is one the Documentation Center can
   resolve to the wrong place, and the identifier is line-wrapped in most of these pages — hence the
   \s*, without which only a minority is rewritten and the rest is inherited from the template. *)
freshIdentifiers[ text_String ] :=
  StringReplace[ text, {
    RegularExpression[ "CellID->[0-9]+" ] :>
      "CellID->" <> ToString @ RandomInteger[ { 100000000, 999999999 } ],
    RegularExpression[ "ExpressionUUID->\\s*\"[0-9a-fA-F-]+\"" ] :>
      "ExpressionUUID->\"" <> ToString @ CreateUUID[ ] <> "\"" } ];

(* An inserted cell wears these until freshIdentifiers gives every cell on the page its own. *)
$placeholder = " CellID->0,ExpressionUUID->\"00000000-0000-0000-0000-000000000000\"],";

notesCell[ text_String ] :=
  "Cell[\"\\<\\\n" <> text <> "\\\n\\>\", \"Notes\",\n";

$laTeXToMaTeX = replace[ Import[ pagePath[ "ConvertToMaTeX" ], "String" ], {
  "so every form acts on the front end" -> "so both forms act on the front end",
  "kernel with no front end.\"" ->
    "kernel with no front end. Nothing is converted when nothing is selected, where the other conversions would take the whole notebook.\"",
  " \" to set one up.\"\n}], \"Notes\",\n" ->
    " \" to set one up.\"\n}], \"Notes\",\n" <> $placeholder <> "\n\n" <>
      notesCell[
        "Each selected cell is taken whole: the body inside its display \\\n\
delimiters where it carries them, and all of its text where it carries none. \\\n\
The source is recorded on the rendered cell, so the trip back gives exactly \\\n\
what was typed." ],
  " \" to get back to native math.\"" -> " \" to get back the LaTeX source.\"",
  "\"0.1.11\"" -> "\"0.1.23\"" } ];

(* The NotebookObject clause of the first note goes with the notebook form this pair does not have. *)
$laTeXToMaTeX = dropRange[ $laTeXToMaTeX, " StyleBox[\"notebook\",", " \" and \"," ];

$maTeXToLaTeX = replace[ Import[ pagePath[ "ConvertFromMaTeX" ], "String" ], {
  ". The native math is recovered from the source recorded on the cell, not " ->
    ". The LaTeX is the source recorded on the cell, not ",
  "Cell[\"Cells that were never rendered with MaTeX are left alone.\", \"Notes\",\n" ->
    notesCell[
      "A cell rendered from typed LaTeX gives that source back verbatim, \\\n\
delimiters and all. One rendered from typeset mathematics has no source of \\\n\
its own, and gives its stored TeX wearing the delimiters its style implies." ] <>
      $placeholder <> "\n\nCell[\"Cells that were never rendered with MaTeX are left alone.\", \"Notes\",\n",
  "\"0.1.11\"" -> "\"0.1.23\"" } ];

(* The rename is last, so that every rule above matches the template's own wording. Both symbols go
   in one pass: neither replacement contains the other's pattern, where a second pass over the
   result would rewrite what the first pass had just written. *)
write[ symbol_String, text_String, rules_List ] :=
  Export[ pagePath[ symbol ], StringReplace[ freshIdentifiers[ text ], rules ], "String" ];

write[ "ConvertLaTeXToMaTeX", $laTeXToMaTeX,
  { "ConvertToMaTeX" -> "ConvertLaTeXToMaTeX", "ConvertFromMaTeX" -> "ConvertMaTeXToLaTeX" } ];

write[ "ConvertMaTeXToLaTeX", $maTeXToLaTeX,
  { "ConvertFromMaTeX" -> "ConvertMaTeXToLaTeX", "ConvertToMaTeX" -> "ConvertLaTeXToMaTeX" } ];

(* A written page is not a good page: it has to parse as one Notebook, carry no trace of the
   template's name, share no identifier with it, and say its own name where the template said its. *)
identifiers[ text_String ] :=
  StringCases[ text,
    { RegularExpression[ "CellID->[0-9]+" ], RegularExpression[ "ExpressionUUID->\\s*\"[0-9a-fA-F-]+\"" ] } ];

report[ symbol_String, template_String ] :=
  With[ { text = Import[ pagePath[ symbol ], "String" ] },
    Print[ symbol,
      (* a page is a sequence of comments AND a Notebook, so Hold[ _Notebook ] is a probe fault:
         it reads False on a pristine page too *)
      ": parses ", ! FreeQ[ Quiet @ ToExpression[ text, InputForm, Hold ], _Notebook ],
      " | template name left ", StringCount[ text, template ],
      " | shared identifiers ",
      Length @ Intersection[ identifiers @ text, identifiers @ Import[ pagePath[ template ], "String" ] ],
      " | own name ", StringCount[ text, symbol ],
      " | notes ", StringCount[ text, "\"Notes\"," ] ] ];

report[ "ConvertLaTeXToMaTeX", "ConvertToMaTeX" ];
report[ "ConvertMaTeXToLaTeX", "ConvertFromMaTeX" ];
