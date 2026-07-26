Package["WolframInstitute`MathNotebook`"]

PackageExport[ImportLaTeXDocument]
PackageExport[ExportLaTeXDocument]

PackageScope["latexToNotebook"]
PackageScope["notebookToLaTeX"]
PackageScope["theoremEnvironments"]
PackageScope["environmentCell"]
PackageScope["documentTagging"]
PackageScope["bibliographyDatabase"]
PackageScope["citationBox"]

ImportLaTeXDocument[ file_String ] :=
  With[ { source = Import[ file, "Text" ] },
    latexToNotebook[ source, bibliographyEntries[ source, file ] ] ]

ExportLaTeXDocument[ notebook_Notebook ] :=
  notebookToLaTeX[ notebook ]

ExportLaTeXDocument[ notebook_Notebook, file_String ] :=
  Export[ file, notebookToLaTeX[ notebook ], "Text" ]

ExportLaTeXDocument[ notebook_NotebookObject, rest___ ] :=
  ExportLaTeXDocument[ NotebookGet[ notebook ], rest ]

latexToNotebook[ source_String ] :=
  latexToNotebook[ source, <| |> ]

latexToNotebook[ source_String, entries_Association ] :=
  Module[ { preamble, body, postamble, pieces, cells },
    { preamble, body, postamble } = documentParts[ source ];
    pieces = documentPieces[ body, theoremEnvironments[ preamble ], citedEntries[ body, entries ] ];
    cells = Map[ labelledCell, withSeparators[ pieces ] ];
    Notebook[ Map[ referenceCell[ #, labelStyles[ cells ] ] &, cells ],
      TaggingRules -> <| "MathNotebook" -> <|
        "Preamble" -> preamble,
        "Postamble" -> postamble,
        "BodyPrefix" -> joinMarks @ TakeWhile[ pieces, MatchQ[ _separatorMark ] ] |> |> ]
  ]

notebookToLaTeX[ notebook : Notebook[ cells_List, ___ ] ] :=
  With[ { tagging = documentTagging[ notebook ] },
    tagging[ "Preamble" ] <> tagging[ "BodyPrefix" ] <>
      StringJoin @ Map[ cell |-> cellToLaTeX[ cell ] <> cellSeparator[ cell ],
        Select[ notebookCellList[ cells ], exportedCellQ ] ] <>
      tagging[ "Postamble" ] ]

(* Evaluating a figure's code leaves an Output cell beside it, and neither the code nor the graphic
   has a LaTeX form — the figure's own markup is what goes back into the .tex. So the whole
   evaluation family emits nothing, and a live picture in the notebook cannot leak into the source.
   The exception is the cell carrying a captionless figure, which is an Input cell itself. *)
$evaluationStyles = { "Input", "Output", "Code", "Print", "Message", "Echo" }

exportedCellQ[ cell_Cell ] :=
  cellTagging[ cell, "Suppressed" ] === "" &&
    ( cellTagging[ cell, "FigureTeX" ] =!= "" ||
      ! MemberQ[ $evaluationStyles, Replace[ cell, { Cell[ _, style_String, ___ ] :> style, _ :> None } ] ] )

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
documentPieces[ body_String, environments_Association, entries_Association ] :=
  Flatten @ Map[ Replace[ text_String :> paragraphPieces[ text ] ],
    StringSplit[ body, structureRules[ environments, entries ] ] ]

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
structureRules[ environments_Association, entries_Association ] :=
  Join[
    bibliographyRules[ entries ],
    figureRules[ ],
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

(* A figure is the one block a notebook can do better than the source: LaTeX ships a rendered
   picture, and the notebook wants the code that draws it. So each \includegraphics becomes an Input
   cell holding code that produces that picture — Import of the shipped file, which the author
   replaces with the code that generates it — and the caption becomes a Caption cell tagged with the
   figure's \label, which is what makes "Figure \ref{fig:x}" resolve to the front end's own counter.
   Only declared theorem names are matched by the environment rules, so figure needs its own; the two
   starred and unstarred forms each get one, for the same reason a back-reference to a named
   Alternatives is not a legal string pattern. *)
$figureEnvironments = { "figure", "figure*" }

figureRules[ ] :=
  Map[ name |->
      ( StartOfLine ~~ indent : ( " " | "\t" ) ... ~~ ( "\\begin{" <> name <> "}" ) ~~
          Shortest[ inner___ ] ~~ StartOfLine ~~ closingIndent : ( " " | "\t" ) ... ~~
          ( "\\end{" <> name <> "}" ) :>
        figureCells[ indent <> "\\begin{" <> name <> "}", inner,
          closingIndent <> "\\end{" <> name <> "}" ] ),
    $figureEnvironments ]

figureCells[ opening_String, inner_String, closing_String ] :=
  Replace[ captionCell[ opening, inner, closing ],
    { caption_Cell :> Append[ Map[ graphicCell, figureGraphics[ inner ] ], caption ],
      None :> MapAt[ retagged[ #, <| "Suppressed" -> "",
            "FigureTeX" -> opening <> inner <> closing |> ] &,
        Replace[ Map[ graphicCell, figureGraphics[ inner ] ], { } -> { graphicCell[ "" ] } ], -1 ] } ]

(* The graphic cells emit nothing: the markup that drew the picture — \centering, the
   \includegraphics options, a whole tikzpicture — rides verbatim in the caption cell's
   "FigurePrefix", which is what lets a TikZ figure survive a round trip it cannot render. *)
graphicCell[ code_String ] :=
  Cell[ BoxData[ code ], "Input", TaggingRules -> <| "MathNotebook" -> <| "Suppressed" -> "True" |> |> ]

figureGraphics[ inner_String ] :=
  Map[ file |-> "Import[ FileNameJoin @ { NotebookDirectory[], \"" <> file <> "\" } ]",
    Flatten @ StringCases[ inner,
      "\\includegraphics" ~~ ( "[" ~~ Except[ "]" ] ... ~~ "]" ) | "" ~~ "{" ~~
        file : Except[ "}" ] .. ~~ "}" :> file ] ]

(* The caption is the one part of a figure the notebook owns, so it is the cell the source hangs off:
   everything up to and including \caption{ goes in "FigurePrefix" and everything from its closing
   brace on goes in "Trailing", where labelledCell finds the \label and turns it into the cell's tag
   exactly as it does for a section. Editing the caption in the notebook therefore reaches the .tex,
   while the picture's own markup is returned untouched. A figure with no caption owns nothing, and
   its whole source is re-emitted from "FigureTeX". *)
captionCell[ opening_String, inner_String, closing_String ] :=
  Replace[ StringPosition[ inner, "\\caption{", 1 ],
    { { { _, brace_ } } :>
        With[ { caption = braceContent[ inner, brace ] },
          Cell[ inlineContent[ caption ], "Caption",
            TaggingRules -> <| "MathNotebook" -> <|
              "FigurePrefix" -> opening <> StringTake[ inner, brace ],
              "Trailing" -> StringDrop[ inner, brace + StringLength[ caption ] ] <> closing |> |> ] ],
      _ :> None } ]

(* A caption holds braces of its own — \textbf, \emph, a nested \cite — so it ends at the brace that
   closes it and not at the first "}": the same depth walk a .bib field needs. *)
braceContent[ text_String, brace_Integer ] :=
  With[ { characters = Characters @ StringDrop[ text, brace ] },
    StringJoin @@ Take[ characters,
      First @ FirstPosition[
        Accumulate @ Replace[ characters, { "{" -> 1, "}" -> -1, _ -> 0 }, { 1 } ], -1 ] - 1 ] ]

(* The bibliography is the one block of a paper whose content is not in the .tex at all: the source
   says \bibliography{refs} or \printbibliography and the entries live in a .bib. So the commands
   become the Reference cells of the entries the paper actually cites, and the last of them carries
   the commands verbatim while the rest emit nothing — the .tex gets its two lines back and the
   notebook shows a bibliography. The rule exists only when entries were found, so a paper whose
   .bib is missing is left exactly as it was before. *)
bibliographyRules[ entries_Association ] :=
  If[ entries === <| |>,
    { },
    { StartOfLine ~~ block : ( $bibliographyCommand ~~ ( "\n" ~~ $bibliographyCommand ) ... ) :>
        bibliographyCells[ entries, block ] } ]

$bibliographyCommand =
  ( " " | "\t" ) ... ~~ ( "\\bibliographystyle" | "\\printbibliography" | "\\bibliography" ) ~~ Except[ "\n" ] ...

bibliographyCells[ entries_Association, block_String ] :=
  MapAt[ retagged[ #, <| "Suppressed" -> "", "BibliographyTeX" -> block |> ] &,
    KeyValueMap[ bibliographyCell, entries ], -1 ]

bibliographyCell[ key_String, entry_Association ] :=
  Cell[ inlineContent @ bibliographyText[ entry ], "Reference", CellTags -> key,
    Sequence @@ referenceDingbat[ key ],
    TaggingRules -> <| "MathNotebook" -> <| "Suppressed" -> "True" |> |> ]

(* No bibliography style is emulated: the fields are riffled in a fixed order, and the entries come
   in the order of the .bib rather than in the order the style would sort them. What matters for
   reading is that the dingbat is referenceLabel's [key], so an entry and the citation pointing at it
   read alike. *)
bibliographyText[ entry_Association ] :=
  StringRiffle[
    DeleteCases[ {
      bibliographyAuthors @ Lookup[ entry, "author", "" ],
      Lookup[ entry, "title", "" ],
      Lookup[ entry, "journal", Lookup[ entry, "booktitle", "" ] ],
      bibliographyVolume[ entry ],
      Lookup[ entry, "pages", "" ],
      Lookup[ entry, "publisher", Lookup[ entry, "organization", "" ] ],
      Lookup[ entry, "year", "" ],
      Lookup[ entry, "url", "" ] }, "" ], ", " ] <> "."

bibliographyAuthors[ authors_String ] :=
  StringRiffle[ Map[ bibliographyName, StringSplit[ authors, " and " ] ], ", " ]

bibliographyName[ name_String ] :=
  Replace[ StringTrim /@ StringSplit[ name, "," ],
    { { last_, first_ } :> first <> " " <> last, _ :> StringTrim[ name ] } ]

bibliographyVolume[ entry_Association ] :=
  Replace[ Lookup[ entry, "volume", "" ],
    { "" -> "", volume_ :> volume <> Replace[ Lookup[ entry, "number", "" ], { "" -> "", number_ :> "(" <> number <> ")" } ] } ]

bibliographyEntries[ source_String, file_String ] :=
  Association @ Map[ Normal @ bibliographyDatabase @ Import[ #, "Text" ] &,
    Select[ bibliographyFiles[ source, file ], FileExistsQ ] ]

bibliographyFiles[ source_String, file_String ] :=
  Map[ bibliographyFile[ #, file ] &,
    Flatten @ StringCases[ source,
      StartOfLine ~~ ( " " | "\t" ) ... ~~ ( "\\bibliography{" | "\\addbibresource{" ) ~~
        names : Except[ "}" ] .. ~~ "}" :> StringTrim /@ StringSplit[ names, "," ] ] ]

bibliographyFile[ name_String, file_String ] :=
  FileNameJoin @ { DirectoryName @ AbsoluteFileName @ file,
    StringReplace[ name, "\\jobname" -> FileBaseName[ file ] ] <>
      If[ FileExtension[ name ] === "", ".bib", "" ] }

(* Only the cited keys become cells, as LaTeX prints only those; three of the specimen's seventeen
   entries are never cited. KeySelect rather than KeyTake so the order stays the .bib's. *)
citedEntries[ body_String, entries_Association ] :=
  With[ { cited = Flatten @ StringCases[ body, $citation :> StringTrim /@ StringSplit[ keys, "," ] ] },
    KeySelect[ entries, MemberQ[ cited, # ] & ] ]

(* A .bib entry's fields are separated by the commas at brace depth zero, and the entry ends at the
   brace that closes it — a value may hold both, so neither can be found by a string pattern. *)
bibliographyDatabase[ source_String ] :=
  Association @ Map[ bibliographyEntry, StringSplit[ source, StartOfLine ~~ "@" ] ]

bibliographyEntry[ chunk_String ] :=
  Replace[
    StringCases[ chunk,
      StartOfString ~~ type : LetterCharacter .. ~~ WhitespaceCharacter ... ~~ "{" ~~ body___ ~~ EndOfString :>
        { ToLowerCase[ type ], body }, 1 ],
    { { { type_, body_ } } :> bibliographyFields[ type, body ], _ :> Nothing } ]

bibliographyFields[ type_String, body_String ] :=
  With[ { parts = bibliographySplit[ body ] },
    StringTrim[ First @ parts ] ->
      Join[ <| "Type" -> type |>, Association @ Map[ bibliographyField, Rest @ parts ] ] ]

bibliographySplit[ body_String ] :=
  Module[ { characters = Characters[ body ], depths, limit, cuts },
    depths = Accumulate @ Replace[ characters, { "{" -> 1, "}" -> -1, _ -> 0 }, { 1 } ];
    limit = First[ FirstPosition[ depths, -1 ], Length[ characters ] + 1 ];
    cuts = Select[ Range[ limit - 1 ], characters[[ # ]] === "," && depths[[ # ]] === 0 & ];
    Map[ Apply[ { from, to } |-> StringJoin @@ Take[ characters, { from + 1, to - 1 } ] ],
      Partition[ Join[ { 0 }, cuts, { limit } ], 2, 1 ] ]
  ]

bibliographyField[ text_String ] :=
  Replace[
    StringCases[ text,
      StartOfString ~~ WhitespaceCharacter ... ~~ name : ( LetterCharacter | "-" ) .. ~~
        WhitespaceCharacter ... ~~ "=" ~~ value___ ~~ EndOfString :>
          ( ToLowerCase[ name ] -> bibliographyValue @ StringTrim[ value ] ), 1 ],
    { { field_ } :> field, _ :> Nothing } ]

(* The delimiters of a value go, and a TeX accent becomes the character it prints. That translation
   costs nothing on the return trip — a Reference cell comes from the .bib and the .tex gets its
   \bibliography command back verbatim — and without it the specimen's bibliography reads
   J{\"u}rgen. An accent the table does not have is left as source rather than silently flattened
   to the bare letter. *)
bibliographyValue[ value_String ] :=
  StringReplace[ bibliographyDelimited[ value ],
    Join[ $bibliographyAccents, { "---" -> "\[LongDash]", "--" -> "\[Dash]" } ] ]

bibliographyDelimited[ value_String ] :=
  If[ StringStartsQ[ value, "{" ] && bibliographyBalancedQ[ value ],
    StringTake[ value, { 2, -2 } ],
    StringTrim[ value, "\"" ] ]

bibliographyBalancedQ[ value_String ] :=
  First[ FirstPosition[
      Accumulate @ Replace[ Characters[ value ], { "{" -> 1, "}" -> -1, _ -> 0 }, { 1 } ], 0 ], 0 ] ===
    StringLength[ value ]

(* Longest form first, so {\"u} is matched before \"u; and a bare \c or \v would collide with a
   control word of the same name, so a letter accent is only recognised braced. *)
$bibliographyAccents =
  Flatten @ KeyValueMap[ { accent, table } |->
      KeyValueMap[ { letter, character } |->
          Join[
            { ( "{\\" <> accent <> "{" <> letter <> "}}" ) -> character,
              ( "{\\" <> accent <> letter <> "}" ) -> character,
              ( "\\" <> accent <> "{" <> letter <> "}" ) -> character },
            If[ StringMatchQ[ accent, LetterCharacter ], { }, { ( "\\" <> accent <> letter ) -> character } ] ],
        table ],
    <|
      "\"" -> <| "a" -> "\[ADoubleDot]", "e" -> "\[EDoubleDot]", "i" -> "\[IDoubleDot]",
        "o" -> "\[ODoubleDot]", "u" -> "\[UDoubleDot]", "y" -> "\[YDoubleDot]",
        "A" -> "\[CapitalADoubleDot]", "E" -> "\[CapitalEDoubleDot]", "I" -> "\[CapitalIDoubleDot]",
        "O" -> "\[CapitalODoubleDot]", "U" -> "\[CapitalUDoubleDot]" |>,
      "'" -> <| "a" -> "\[AAcute]", "c" -> "\[CAcute]", "e" -> "\[EAcute]", "i" -> "\[IAcute]",
        "o" -> "\[OAcute]", "u" -> "\[UAcute]", "y" -> "\[YAcute]",
        "A" -> "\[CapitalAAcute]", "E" -> "\[CapitalEAcute]", "I" -> "\[CapitalIAcute]",
        "O" -> "\[CapitalOAcute]", "U" -> "\[CapitalUAcute]" |>,
      "`" -> <| "a" -> "\[AGrave]", "e" -> "\[EGrave]", "i" -> "\[IGrave]", "o" -> "\[OGrave]",
        "u" -> "\[UGrave]", "A" -> "\[CapitalAGrave]", "E" -> "\[CapitalEGrave]",
        "O" -> "\[CapitalOGrave]", "U" -> "\[CapitalUGrave]" |>,
      "^" -> <| "a" -> "\[AHat]", "e" -> "\[EHat]", "i" -> "\[IHat]", "o" -> "\[OHat]",
        "u" -> "\[UHat]", "A" -> "\[CapitalAHat]", "E" -> "\[CapitalEHat]", "O" -> "\[CapitalOHat]" |>,
      "~" -> <| "a" -> "\[ATilde]", "n" -> "\[NTilde]", "o" -> "\[OTilde]",
        "A" -> "\[CapitalATilde]", "N" -> "\[CapitalNTilde]", "O" -> "\[CapitalOTilde]" |>,
      "c" -> <| "c" -> "\[CCedilla]", "C" -> "\[CapitalCCedilla]" |>,
      "v" -> <| "c" -> "\[CHacek]", "d" -> "\[DHacek]", "e" -> "\[EHacek]", "n" -> "\[NHacek]",
        "r" -> "\[RHacek]", "s" -> "\[SHacek]", "t" -> "\[THacek]", "z" -> "\[ZHacek]",
        "C" -> "\[CapitalCHacek]", "R" -> "\[CapitalRHacek]", "S" -> "\[CapitalSHacek]",
        "Z" -> "\[CapitalZHacek]" |>
    |> ]

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
  Replace[
    mergeStrings @ Flatten @ Replace[ splitInlineMath[ text ], part_String :> citationSplit[ part ], { 1 } ],
    { { unchanged_String } :> unchanged, parts_List :> TextData[ parts ] } ]

(* One pattern for what a citation is, used both to split the prose and to decide which .bib entries
   the paper cites, so the two halves cannot disagree. *)
$citation =
  "\\cite" ~~ optional : ( "[" ~~ Except[ "]" ] ... ~~ "]" ) | "" ~~ "{" ~~ keys : Except[ "}" ] .. ~~ "}"

citationSplit[ text_String ] :=
  StringSplit[ text, $citation :> citationBox[ optional, keys ] ]

(* \cite becomes a Citation button labelled with the key in brackets — referenceLabel's rendering, so
   a citation reads exactly as the dingbat of the entry it points at. Unlike \ref this is
   unconditional: the label is literal text and is right even in a paper with no bibliography, where
   a CounterBox would render the front end's XXX. The verbatim brace content rides along as the
   ButtonData, which is both what NotebookLocate navigates by and what the exporter writes back, so
   \cite{a, b} returns with its own spacing; the optional argument is the item before the closing
   bracket, and how many keys there are is what tells the two apart. *)
citationBox[ optional_String, keys_String ] :=
  ButtonBox[
    RowBox @ Flatten @ { "[", Riffle[ StringTrim /@ StringSplit[ keys, "," ], ", " ],
      If[ optional === "", { }, { ", ", StringTake[ optional, { 2, -2 } ] } ], "]" },
    BaseStyle -> "Citation", ButtonData -> keys ]

citationTeX[ RowBox[ parts_List ], keys_String ] :=
  "\\cite" <>
    If[ Length[ parts ] > 2 Length[ StringSplit[ keys, "," ] ] + 1, "[" <> parts[[ -2 ]] <> "]", "" ] <>
    "{" <> keys <> "}"

citationTeX[ label_String, keys_String ] :=
  "\\cite{" <> keys <> "}"

notebookCellList[ cells_List ] :=
  Flatten @ Replace[ cells, Cell[ CellGroupData[ inner_List, ___ ], ___ ] :> notebookCellList[ inner ], { 1 } ]

(* \label lands on the cell it labels as a CellTags, which is what the referencing palette and
   CounterBox both key on. The label is taken out of the stored source and written back from the
   tag, so retagging a cell in the notebook changes the exported \label. A label inside a display
   equation is the exception: the equation is re-emitted from its stored "SourceTeX", so there the
   tag is a mirror of the source rather than its origin. *)
labelledCell[ cell : Cell[ _, "DisplayFormula" | "DisplayFormulaNumbered", ___ ] ] :=
  Replace[ StringCases[ storedSourceTeX[ cell ], "\\label{" ~~ key : Except[ "}" ] .. ~~ "}" :> key, 1 ],
    { { key_ } :> Append[ cell, CellTags -> key ], _ :> cell } ]

labelledCell[ cell_Cell ] :=
  Replace[ StringCases[ cellTagging[ cell, "Trailing" ],
      Shortest[ before___ ] ~~ "\\label{" ~~ key : Except[ "}" ] .. ~~ "}" ~~ after___ :> { before, key, after } ],
    { { { before_, key_, after_ } } :>
        Append[ retagged[ cell, <| "Trailing" -> before, "TrailingAfter" -> after |> ], CellTags -> key ],
      _ :> cell } ]

retagged[ cell : Cell[ content_, style_, options___ ], extra_Association ] :=
  Cell[ content, style, TaggingRules -> <| "MathNotebook" -> Join[ storedTagging[ cell ], extra ] |>,
    Sequence @@ DeleteCases[ { options }, TaggingRules -> _ ] ]

labelStyles[ cells_List ] :=
  Association @ Cases[ cells, Cell[ _, style_String, ___, CellTags -> key_String, ___ ] :> key -> style ]

(* \ref and \eqref become the front end's own cross-reference: a CounterBox chain resolved at the
   labelled cell, so the number follows the target when cells move and is right in the PDF with no
   kernel. \ref is the bare number and \eqref parenthesises it, exactly as LaTeX prints them —
   authors write "Theorem~\ref{...}", so a prefix would say the word twice. A key no converted cell
   carries — the specimen paper's four figure labels — is left as source. *)
referenceCell[ Cell[ content_, style_, options___ ], labels_Association ] :=
  Cell[ referenceContent[ content, labels ], style, options ]

referenceContent[ text_String, labels_Association ] :=
  Replace[ referenceSplit[ text, labels ], { { one_String } :> one, parts_List :> TextData[ parts ] } ]

referenceContent[ TextData[ parts_ ], labels_Association ] :=
  TextData[ mergeStrings @ Flatten @ Replace[ Flatten @ { parts }, text_String :> referenceSplit[ text, labels ], { 1 } ] ]

referenceContent[ content_, _Association ] :=
  content

referenceSplit[ text_String, labels_Association ] :=
  StringSplit[ text,
    command : ( "\\eqref" | "\\ref" ) ~~ "{" ~~ key : Except[ "}" ] .. ~~ "}" :>
      referenceBox[ command, key, Lookup[ labels, key, None ] ] ]

referenceBox[ command_String, key_String, style_String ] :=
  ButtonBox[
    RowBox @ Join[ If[ command === "\\eqref", { "(" }, { } ],
      Riffle[ Map[ CounterBox[ #, key ] &, referenceCounters[ style ] ], "." ],
      If[ command === "\\eqref", { ")" }, { } ] ],
    BaseStyle -> "Citation", ButtonData -> key ]

referenceBox[ command_String, key_String, _ ] :=
  command <> "{" <> key <> "}"

referenceCounters[ style_String ] :=
  Replace[ Lookup[ $referenceLabelSpec, style, None ], { { _, counters_, _ } :> counters, _ :> { style } } ]

referenceTeX[ ButtonBox[ boxes_, ___, ButtonData -> key_String, ___ ] ] /; ! FreeQ[ boxes, _CounterBox ] :=
  If[ MatchQ[ boxes, RowBox[ { "(", ___, ")" } ] ], "\\eqref{", "\\ref{" ] <> key <> "}"

(* A Citation button with no counter in it is a citation: a cross-reference always resolves through
   one, and a citation never does — the bibliography is not numbered. *)
referenceTeX[ ButtonBox[ boxes_, ___, ButtonData -> key_String, ___ ] ] /; FreeQ[ boxes, _CounterBox ] :=
  citationTeX[ boxes, key ]

cellToLaTeX[ cell : Cell[ _, "Section" | "Subsection" | "Subsubsection", ___ ] ] :=
  cellTagging[ cell, "Indent" ] <> "\\" <> ToLowerCase[ cell[[ 2 ]] ] <> "{" <> cellTeXText[ cell ] <> "}" <>
    cellTrailing[ cell ]

(* The Reference cells of a .bib bibliography are not in the .tex; the commands that pulled them in
   are, and the last cell of the block carries them. *)
cellToLaTeX[ cell_Cell ] /; cellTagging[ cell, "BibliographyTeX" ] =!= "" :=
  cellTagging[ cell, "BibliographyTeX" ]

(* A captionless figure has no cell content to write back, so its source is returned whole. *)
cellToLaTeX[ cell_Cell ] /; cellTagging[ cell, "FigureTeX" ] =!= "" :=
  cellTagging[ cell, "FigureTeX" ]

cellToLaTeX[ cell_Cell ] /; cellTagging[ cell, "FigurePrefix" ] =!= "" :=
  cellTagging[ cell, "FigurePrefix" ] <> cellTeXText[ cell ] <> cellTrailing[ cell ]

cellToLaTeX[ cell_Cell ] /; cellTagging[ cell, "Environment" ] =!= "" :=
  With[ { name = cellTagging[ cell, "Environment" ] },
    cellTagging[ cell, "Indent" ] <> "\\begin{" <> name <> "}" <> cellTagging[ cell, "EnvironmentTitle" ] <>
      cellTrailing[ cell ] <> "\n" <> cellTagging[ cell, "BodyIndent" ] <> cellTeXText[ cell ] <>
      "\n" <> cellTagging[ cell, "ClosingIndent" ] <> "\\end{" <> name <> "}" ]

cellToLaTeX[ cell_Cell ] :=
  Replace[ convertMathCell @ referencesToTeX[ cell ],
    { Cell[ text_String, ___ ] :> text, other_ :> ToString[ other, InputForm ] } ]

cellTrailing[ cell_Cell ] :=
  cellTagging[ cell, "Trailing" ] <>
    Replace[ Cases[ cell, ( CellTags -> key_String ) :> "\\label{" <> key <> "}" ], { { label_ } :> label, _ :> "" } ] <>
    cellTagging[ cell, "TrailingAfter" ]

cellTeXText[ cell : Cell[ content_, ___ ] ] :=
  Replace[ convertMathCell @ referencesToTeX @ Cell[ content, "Text" ], { Cell[ text_String, ___ ] :> text, _ :> "" } ]

referencesToTeX[ Cell[ content_, rest___ ] ] :=
  Cell[ Replace[ content /. TextData[ parts_List ] :> TextData @ mergedButtons[ parts ],
      box_ButtonBox :> referenceTeX[ box ], { 0, Infinity } ], rest ]

(* Writing a notebook to disk and opening it again splits a ButtonBox[RowBox[...]] inside a TextData
   into one button per run — the same front-end behaviour NotebookWrite has — and it reaches every
   imported citation and cross-reference, so without this the round trip holds only for a notebook
   that was never saved. Measured: \cite{first, second} came back as five buttons and exported five
   \cite commands, and \eqref{eq:a} came back as three, the parentheses carried off into buttons of
   their own so that the counter no longer looked parenthesised and the brackets no longer looked
   like references at all — \cite{eq:a}\ref{eq:a}\cite{eq:a}. Consecutive buttons on one key are put
   back together before anything reads them; two adjacent citations to the same key, which no real
   paper writes, would merge into one. *)
mergedButtons[ parts_List ] :=
  Flatten @ Replace[ SplitBy[ parts, buttonKey ],
    run : { ButtonBox[ _, ___, ButtonData -> key_, ___ ], __ } :>
      { ButtonBox[ RowBox @ Flatten @ Map[ buttonBoxes, run ], BaseStyle -> "Citation", ButtonData -> key ] },
    { 1 } ]

buttonKey[ ButtonBox[ ___, ButtonData -> key_, ___ ] ] :=
  key

buttonKey[ _ ] :=
  None

buttonBoxes[ ButtonBox[ RowBox[ boxes_List ], ___ ] ] :=
  boxes

buttonBoxes[ ButtonBox[ boxes_, ___ ] ] :=
  { boxes }

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
