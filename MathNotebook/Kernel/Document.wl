Package["WolframInstitute`MathNotebook`"]

PackageExport[ImportLaTeXDocument]
PackageExport[ExportLaTeXDocument]

PackageScope["latexToNotebook"]
PackageScope["notebookToLaTeX"]
PackageScope["theoremEnvironments"]
PackageScope["environmentCell"]
PackageScope["documentTagging"]

ImportLaTeXDocument[ file_String ] :=
  latexToNotebook @ Import[ file, "Text" ]

ExportLaTeXDocument[ notebook_Notebook ] :=
  notebookToLaTeX[ notebook ]

ExportLaTeXDocument[ notebook_Notebook, file_String ] :=
  Export[ file, notebookToLaTeX[ notebook ], "Text" ]

ExportLaTeXDocument[ notebook_NotebookObject, rest___ ] :=
  ExportLaTeXDocument[ NotebookGet[ notebook ], rest ]

latexToNotebook[ source_String ] :=
  Module[ { preamble, body, postamble, pieces },
    { preamble, body, postamble } = documentParts[ source ];
    pieces = documentPieces[ body, theoremEnvironments[ preamble ] ];
    Notebook[ withSeparators[ pieces ],
      TaggingRules -> <| "MathNotebook" -> <|
        "Preamble" -> preamble,
        "Postamble" -> postamble,
        "BodyPrefix" -> joinMarks @ TakeWhile[ pieces, MatchQ[ _separatorMark ] ] |> |> ]
  ]

notebookToLaTeX[ notebook : Notebook[ cells_List, ___ ] ] :=
  With[ { tagging = documentTagging[ notebook ] },
    tagging[ "Preamble" ] <> tagging[ "BodyPrefix" ] <>
      StringJoin @ Map[ cell |-> cellToLaTeX[ cell ] <> cellSeparator[ cell ], notebookCellList[ cells ] ] <>
      tagging[ "Postamble" ] ]

(* Which source environment names this document uses, and what each is printed as. The amsthm
   defaults are the twelve style names lowercased; a \newtheorem declaration overrides or adds to
   them, in either of its two forms — \newtheorem{name}{Printed}[counter] and, when the environment
   shares another's counter, \newtheorem{name}[shared]{Printed}. The specimen paper declares four
   of its own, so a fixed table of English names would have matched none of them. *)
theoremEnvironments[ preamble_String ] :=
  Join[
    AssociationMap[ Capitalize, Map[ ToLowerCase, Keys @ $theoremEnvironments ] ],
    <| "proof" -> "Proof" |>,
    Association @ StringCases[ preamble,
      { "\\newtheorem" ~~ "*" | "" ~~ "{" ~~ name : Except[ "}" ] .. ~~ "}{" ~~ printed : Except[ "}" ] .. ~~ "}" :>
          name -> printed,
        "\\newtheorem" ~~ "*" | "" ~~ "{" ~~ name : Except[ "}" ] .. ~~ "}[" ~~ Except[ "]" ] .. ~~ "]{" ~~
            printed : Except[ "}" ] .. ~~ "}" :> name -> printed } ] ]

documentParts[ source_String ] :=
  First[ StringCases[ source,
      Shortest[ preamble___ ] ~~ "\\begin{document}" ~~ body__ ~~ "\\end{document}" ~~ postamble___ :>
        { preamble <> "\\begin{document}", body, "\\end{document}" <> postamble } ],
    { "", source, "" } ]

(* Every cell carries the whitespace that followed it in the source, so the export is a plain
   StringJoin and the blocking survives exactly: the paper separates blocks with two newlines in
   most places and three in two of them, and a display equation lifted out of a paragraph rejoins
   with one. Riffling everything with "\n\n" was seven diff lines on the specimen. *)
documentPieces[ body_String, environments_Association ] :=
  Flatten @ Map[ Replace[ text_String :> paragraphPieces[ text ] ],
    StringSplit[ body, structureRules[ environments ] ] ]

withSeparators[ pieces_List ] :=
  Cases[
    SequenceReplace[ pieces,
      { { cell_Cell, marks : Longest[ _separatorMark .. ] } :> taggedCell[ cell, joinMarks @ { marks } ],
        { cell_Cell } :> taggedCell[ cell, "" ] } ],
    _Cell ]

joinMarks[ pieces_List ] :=
  StringJoin @@ Cases[ pieces, separatorMark[ separator_ ] :> separator ]

taggedCell[ cell : Cell[ content_, style_, options___ ], separator_String ] :=
  Cell[ content, style,
    TaggingRules -> <| "MathNotebook" -> Append[ storedTagging[ cell ], "Separator" -> separator ] |>,
    Sequence @@ DeleteCases[ { options }, TaggingRules -> _ ] ]

cellSeparator[ cell_Cell ] :=
  Replace[ cellTagging[ cell, "Separator" ], "" -> "\n\n" ]

(* Sections and theorem-like environments are both just delimiters in the body, so one StringSplit
   finds them; what falls between is prose, and goes to the math converter unchanged. One rule per
   declared environment name, with the name written literally into both delimiters — a string
   pattern will not take a back-reference to a named Alternatives, and answers
   StringExpression::invld rather than failing to match. Only declared names are matched, so
   \begin{figure} and \begin{itemize} pass through as text. *)
structureRules[ environments_Association ] :=
  Join[
    Map[ Apply[ { command, style } |->
        ( StartOfLine ~~ indent : ( " " | "\t" ) ... ~~ command ~~ "{" ~~ Shortest[ title___ ] ~~ "}" ~~
            trailing : Except[ "\n" ] ... :> sectionCell[ style, indent, title, trailing ] ) ],
      { { "\\subsubsection", "Subsubsection" }, { "\\subsection", "Subsection" }, { "\\section", "Section" } } ],
    Map[ name |->
        ( StartOfLine ~~ indent : ( " " | "\t" ) ... ~~ ( "\\begin{" <> name <> "}" ) ~~
            title : ( "[" ~~ Except[ "]" ] ... ~~ "]" ) | "" ~~ trailing : Except[ "\n" ] ... ~~
            Shortest[ inner___ ] ~~ StartOfLine ~~ closingIndent : ( " " | "\t" ) ... ~~ ( "\\end{" <> name <> "}" ) :>
          environmentCell[ environments, name, indent, title, trailing, inner, closingIndent ] ),
      Keys[ environments ] ] ]

sectionCell[ style_String, indent_String, title_String, trailing_String ] :=
  Cell[ inlineContent[ title ], style,
    TaggingRules -> <| "MathNotebook" -> <| "Indent" -> indent, "Trailing" -> trailing |> |> ]

(* The body is deliberately NOT run through convertLaTeXCell: that would split a display equation
   into its own cell, and an environment has to stay one cell or the \end{...} lands in the wrong
   place on the way out. Only inline math is converted; a display environment inside a theorem
   stays literal, which the round trip preserves. *)
environmentCell[ environments_Association, name_String, indent_String, title_String, trailing_String,
    inner_String, closingIndent_String ] :=
  Cell[ inlineContent @ StringDelete[ inner,
      { StartOfString ~~ "\n" ~~ ( " " | "\t" ) ..., "\n" ~~ EndOfString } ],
    environmentStyle @ environments[ name ],
    Sequence @@ environmentDingbat[ environments[ name ] ],
    TaggingRules -> <| "MathNotebook" -> <|
      "Environment" -> name, "EnvironmentTitle" -> title, "Trailing" -> trailing, "Indent" -> indent,
      "ClosingIndent" -> closingIndent,
      "BodyIndent" -> First[ StringCases[ inner, StartOfString ~~ "\n" ~~ bodyIndent : ( " " | "\t" ) ... :> bodyIndent, 1 ], "" ] |> |> ]

(* A declared environment whose printed name is none of the twelve — the specimen paper's ten
   Axioms — is written as a Theorem, which numbers it correctly, with a dingbat that says what it
   really is. The alternative was to leave a third of the paper's environments as literal text. *)
environmentStyle[ printed_String ] :=
  If[ KeyExistsQ[ $theoremEnvironments, printed ] || printed === "Proof", printed, "Theorem" ]

environmentDingbat[ printed_String ] :=
  If[ environmentStyle[ printed ] === printed,
    { },
    { CellDingbat -> Cell[ TextData[ { printed <> " ", CounterBox[ "Section" ], ".", CounterBox[ "Theorem" ], "." } ],
        FontWeight -> "Bold" ] } ]

(* Only the leading whitespace goes: a trailing space at the end of a source line is invisible in a
   cell but is a diff line on the way out, and several of the paper's paragraphs carry one. A
   paragraph break is a blank line, so the delimiter needs two newlines — splitting on one would
   break a wrapped paragraph in half. *)
paragraphPieces[ text_String ] :=
  Map[ Replace[ paragraph_String :> Sequence @@ blockPieces[ paragraph ] ],
    StringSplit[ text,
      { StartOfString ~~ separator : WhitespaceCharacter .. :> separatorMark[ separator ],
        separator : WhitespaceCharacter .. ~~ EndOfString :> separatorMark[ separator ],
        separator : ( "\n" ~~ WhitespaceCharacter ... ~~ "\n" ) :> separatorMark[ separator ] } ] ]

(* This is convertLaTeXCell's job, done here instead: that function trims the whitespace around a
   display equation it lifts out of a paragraph, and here the whitespace is the thing that has to
   survive. So the two split primitives underneath it are composed directly, and every piece is
   followed by the whitespace that followed it in the source. *)
blockPieces[ paragraph_String ] :=
  Flatten @ Map[ Replace[ { chunk_String :> textPieces[ chunk ], cell_Cell :> { cell, separatorMark[ "" ] } } ],
    mergeStrings @ splitDisplayMath[ paragraph ] ]

textPieces[ chunk_String ] :=
  With[ { core = StringTrim[ chunk ] },
    If[ core === "",
      { separatorMark[ chunk ] },
      { separatorMark @ First[ StringCases[ chunk, StartOfString ~~ space : WhitespaceCharacter .. :> space, 1 ], "" ],
        Cell[ inlineContent[ core ], "Text" ],
        separatorMark @ First[ StringCases[ chunk, space : WhitespaceCharacter .. ~~ EndOfString :> space, 1 ], "" ] } ] ]

inlineContent[ text_String ] :=
  Replace[ splitInlineMath[ text ], { { unchanged_String } :> unchanged, parts_List :> TextData[ parts ] } ]

notebookCellList[ cells_List ] :=
  Flatten @ Replace[ cells, Cell[ CellGroupData[ inner_List, ___ ], ___ ] :> notebookCellList[ inner ], { 1 } ]

cellToLaTeX[ cell : Cell[ _, "Section" | "Subsection" | "Subsubsection", ___ ] ] :=
  cellTagging[ cell, "Indent" ] <> "\\" <> ToLowerCase[ cell[[ 2 ]] ] <> "{" <> cellTeXText[ cell ] <> "}" <>
    cellTagging[ cell, "Trailing" ]

cellToLaTeX[ cell_Cell ] /; cellTagging[ cell, "Environment" ] =!= "" :=
  With[ { name = cellTagging[ cell, "Environment" ] },
    cellTagging[ cell, "Indent" ] <> "\\begin{" <> name <> "}" <> cellTagging[ cell, "EnvironmentTitle" ] <>
      cellTagging[ cell, "Trailing" ] <> "\n" <> cellTagging[ cell, "BodyIndent" ] <> cellTeXText[ cell ] <>
      "\n" <> cellTagging[ cell, "ClosingIndent" ] <> "\\end{" <> name <> "}" ]

cellToLaTeX[ cell_Cell ] :=
  Replace[ convertMathCell[ cell ], { Cell[ text_String, ___ ] :> text, other_ :> ToString[ other, InputForm ] } ]

cellTeXText[ Cell[ content_, ___ ] ] :=
  Replace[ convertMathCell @ Cell[ content, "Text" ], { Cell[ text_String, ___ ] :> text, _ :> "" } ]

cellTagging[ cell_Cell, key_String ] :=
  Lookup[ Replace[ storedTagging[ cell ], Except[ _Association ] -> <| |> ], key, "" ]

storedTagging[ Cell[ ___, TaggingRules -> tagging_, ___ ] ] :=
  Lookup[ Association @ tagging, "MathNotebook", <| |> ]

storedTagging[ _ ] :=
  <| |>

documentTagging[ Notebook[ _, options___ ] ] :=
  Join[ <| "Preamble" -> "", "Postamble" -> "", "BodyPrefix" -> "" |>,
    Replace[ Lookup[ Association @ Cases[ { options }, _Rule ], TaggingRules, <| |> ],
      { tagging_ :> Replace[ Lookup[ Association @ tagging, "MathNotebook", <| |> ], Except[ _Association ] -> <| |> ] } ] ]
