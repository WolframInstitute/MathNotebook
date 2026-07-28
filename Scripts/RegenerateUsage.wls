(* Rebuilds the Usage cell of a reference page from the symbol's own usage string, so Kernel/Usage.wl
   is the single source of truth for what the Documentation Center shows. The pages are the paclet's
   only documentation channel — the browser mirror that used to be deployed beside the paclet was
   deleted in 0.1.14 — and they had fallen one release behind the API: four symbols gained a
   notebook-argument form in BasicFunctionality T2 and no page mentioned it.

   With no arguments this reports which pages disagree with Usage.wl and writes nothing; named
   symbols are rewritten. Every ExpressionUUID it emits is derived from a hash of its own content, so
   running it twice is a no-op — the alternative is the churn CLAUDE.md records for a stylesheet
   rebuild, where fresh UUIDs make a 599-line diff of nothing. *)

repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];
symbols = Rest @ Replace[ $ScriptCommandLine, Except[ _List ] :> { } ];

pageDirectory = FileNameJoin[ { repoDirectory, "MathNotebook",
  "Documentation", "English", "ReferencePages", "Symbols" } ];

PacletDirectoryLoad[ repoDirectory ];
Needs[ "WolframInstitute`MathNotebook`" ];

(* MessageName is HoldFirst, so Symbol[name]::usage cannot be read that way — CLAUDE.md's probe fault. *)
usageString[ symbol_String ] :=
  ToExpression[ "WolframInstitute`MathNotebook`" <> symbol <> "::usage" ];

(* One usage line is "Sym[args] prose". A brace-aware split is needed for the {cell, ...} argument,
   whose comma is not a separator. *)
argumentPieces[ "" ] := { };
argumentPieces[ arguments_String ] :=
  Module[ { characters = Characters[ arguments ], depths },
    depths = Accumulate @ Map[ Switch[ #, "{", 1, "}", -1, _, 0 ] &, characters ];
    Map[ StringTrim, StringSplit[
      StringJoin @ MapThread[ If[ #1 === "," && #2 === 0, "\[FormalCapitalA]", #1 ] &, { characters, depths } ],
      "\[FormalCapitalA]" ] ]
  ];

usageForms[ symbol_String ] :=
  Map[
    { line } |-> First[
      StringCases[ line, symbol ~~ "[" ~~ arguments___ ~~ "] " ~~ prose___ :>
        { argumentPieces[ arguments ], prose } ],
      { $Failed, line } ],
    StringSplit[ usageString[ symbol ], "\n" ] ];

(* Deterministic, so a second run rewrites the same bytes. *)
uuidFor[ key_String ] :=
  With[ { hex = IntegerString[ Hash[ key, "MD5" ], 16, 32 ] },
    StringRiffle[ StringTake[ hex, { { 1, 8 }, { 9, 12 }, { 13, 16 }, { 17, 20 }, { 21, 32 } } ], "-" ] ];

(* The three argument shapes the pages use, in the house box form. *)
argumentBox[ argument_String ] :=
  Which[
    StringStartsQ[ argument, "{" ],
      "RowBox[{\"{\", \n     RowBox[{" <> StringRiffle[
        Map[ "\"" <> # <> "\"" &, StringSplit[ StringTake[ argument, { 2, -2 } ], ", " ] ], ", \", \", \" \", " ] <> "}], \"}\"}]",
    StringStartsQ[ argument, "\"" ],
      "\"\\\"\\<" <> StringTake[ argument, { 2, -2 } ] <> "\\>\\\"\"",
    True,
      "\"" <> argument <> "\"" ];

argumentsBox[ { } ] := "RowBox[{\"[\", \"]\"}]";
argumentsBox[ { argument_ } ] := "RowBox[{\"[\", " <> argumentBox[ argument ] <> ", \"]\"}]";
argumentsBox[ arguments_List ] :=
  "RowBox[{\"[\", \n    RowBox[{" <>
    StringRiffle[ Map[ argumentBox, arguments ], ", \", \", \" \", " ] <> "}], \"]\"}]";

(* A mention of an argument in the prose is set in italics, as the sibling pages do; the words are
   the symbol's own argument names, so nothing else is touched. A dotted name (file.tex) is a RowBox
   of its pieces rather than one string, which is the pages' own convention. *)
italicBox[ word_String ] :=
  If[ StringContainsQ[ word, "." ],
    "StyleBox[\n   RowBox[{" <> StringRiffle[ Map[ "\"" <> # <> "\"" &,
      StringSplit[ word, "." ~~ x_ :> { ".", x } ] // Flatten ], ", " ] <> "}], \"TI\"]",
    "StyleBox[\"" <> word <> "\", \"TI\"]" ];

(* StringSplit with an empty list of delimiters answers the string rather than a list of one, so an
   argumentless form has to skip the split — otherwise the Join downstream stays unevaluated and the
   whole build silently stops being a string. *)
proseItems[ prose_String, { }, key_String ] :=
  { " " <> ToString[ prose, InputForm ] <> "," };

proseItems[ prose_String, names_List, key_String ] :=
  Module[ { pieces },
    pieces = StringSplit[ prose,
      Map[ { name } |-> ( WordBoundary ~~ name ~~ WordBoundary ) :> name, names ] ];
    MapIndexed[
      { piece, position } |-> If[ MemberQ[ names, piece ],
        " Cell[BoxData[\n  " <> italicBox[ piece ] <> "], \"InlineFormula\",ExpressionUUID->\n  \"" <>
          uuidFor[ key <> "-italic-" <> ToString @ First[ position ] ] <> "\"],",
        " " <> ToString[ piece, InputForm ] <> "," ],
      DeleteCases[ pieces, "" ] ]
  ];

formItems[ symbol_String, { arguments_List, prose_String }, index_Integer ] :=
  Module[ { key = symbol <> "-" <> ToString[ index ], names, items },
    names = DeleteCases[ Flatten @ Map[
      StringCases[ #, ( "{" | "\"" ) ... ~~ name : ( WordCharacter | "." ) .. ~~ ( "}" | "\"" | ", ..." ) ... :> name ] &,
      arguments ], "..." ];
    items = Join[
      { If[ index === 1,
          " Cell[\"   \", \"ModInfo\",ExpressionUUID->\"" <> uuidFor[ key <> "-modinfo" ] <> "\"],",
          " \"\\n\"," ],
        " Cell[BoxData[\n  RowBox[{\n   ButtonBox[\"" <> symbol <> "\",\n    BaseStyle->\"Link\",\n    ButtonData->\"paclet:WolframInstitute/MathNotebook/ref/" <>
          symbol <> "\"], \n   " <> argumentsBox[ arguments ] <> "}]], \"InlineFormula\",ExpressionUUID->\n  \"" <>
          uuidFor[ key <> "-form" ] <> "\"],",
        " \" \\[LineSeparator]\"," },
      proseItems[ prose, names, key ] ];
    items
  ];

(* Every item carries its own trailing comma, so the last one loses it rather than the join adding it. *)
usageItems[ symbol_String ] :=
  StringDrop[
    StringRiffle[ Flatten @ MapIndexed[ formItems[ symbol, #1, First[ #2 ] ] &, usageForms[ symbol ] ], "\n" ],
    -1 ];

(* The span replaced is the item list of the Usage cell and nothing else, so the cell keeps its own
   CellID and ExpressionUUID — a page whose cell identity changes is one the Documentation Center can
   resolve to the wrong place. The page is read and written as "String" rather than "Text": "Text"
   strips the trailing newline, so a file written from it lost the one every sibling has, and the
   unchanged-comparison — being made on the stripped text — then reported the file as already correct. *)
rewritePage[ symbol_String ] :=
  Module[ { file, text, closing, start, finish, items, replacement },
    file = FileNameJoin[ { pageDirectory, symbol <> ".nb" } ];
    If[ ! FileExistsQ[ file ], Print[ symbol, ": no page" ]; Return[ False ] ];
    text = Import[ file, "String" ];
    closing = First[ StringPosition[ text, "\n}], \"Usage\",\n CellID->" ], $Failed ];
    If[ closing === $Failed, Print[ symbol, ": no Usage cell" ]; Return[ False ] ];
    start = Last @ Last @ StringPosition[ StringTake[ text, First[ closing ] ], "Cell[TextData[{\n" ];
    finish = First[ closing ];
    items = usageItems[ symbol ];
    (* A join that stays unevaluated is still an argument Export will happily write, as ToString of
       the whole expression on one line — that is how this script destroyed four pages on its first
       run, silently, and reported "rewrote 3 forms" while doing it. So nothing is written until the
       replacement is a string, parses as a Notebook, and carries one separator per declared form. *)
    If[ ! StringQ[ items ], Print[ symbol, ": items did not build as a string" ]; Return[ False ] ];
    replacement = StringTake[ text, { 1, start } ] <> items <> StringDrop[ text, finish - 1 ];
    If[ ! StringQ[ replacement ], Print[ symbol, ": replacement did not build as a string" ]; Return[ False ] ];
    If[ Length @ StringCases[ items, " \\[LineSeparator]" ] =!= Length @ usageForms[ symbol ],
      Print[ symbol, ": built ", Length @ StringCases[ items, " \\[LineSeparator]" ], " forms of ",
        Length @ usageForms[ symbol ] ]; Return[ False ] ];
    If[ FreeQ[ Quiet @ ToExpression[ replacement, InputForm, Hold ], _Notebook ],
      Print[ symbol, ": result does not parse as a notebook" ]; Return[ False ] ];
    If[ replacement === text,
      Print[ symbol, ": unchanged" ]; False,
      Export[ file, replacement, "String" ];
      Print[ symbol, ": rewrote ", Length @ usageForms[ symbol ], " forms" ]; True ]
  ];

(* Each form contributes exactly one "\[LineSeparator]" to the cell, and that count is independent of
   how the exporter happened to wrap the ButtonData line — which a pattern over the boxes is not. The
   separator must be counted wherever it stands and not as a whole item: ExportLaTeXBundle.nb glues it
   to the front of its prose string, and requiring the closing quote reported that page as documenting
   no forms at all, which read exactly like a page with no Usage cell. *)
documentedForms[ symbol_String ] :=
  With[ { file = FileNameJoin[ { pageDirectory, symbol <> ".nb" } ] },
    If[ ! FileExistsQ[ file ], Missing[ "NoPage" ],
      With[ { text = Import[ file, "Text" ] },
        Length @ StringCases[
          StringTake[ text, { 1, First @ First @ StringPosition[ text, "\n}], \"Usage\"," ] } ],
          " \\[LineSeparator]" ] ] ] ];

If[ symbols === { },
  Print[ "check mode: forms declared in Usage.wl against forms shown on the page\n" ];
  Scan[
    { symbol } |-> With[ { declared = Length @ usageForms[ symbol ], shown = documentedForms[ symbol ] },
      Print[ StringPadRight[ symbol, 26 ], " usage: ", declared, "   page: ", shown,
        If[ declared === shown, "", "   <- out of date" ] ] ],
    Map[ FileBaseName, FileNames[ "*.nb", pageDirectory ] ] ],
  Scan[ rewritePage, symbols ] ]
