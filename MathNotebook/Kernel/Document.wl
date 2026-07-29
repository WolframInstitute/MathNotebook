Package["WolframInstitute`MathNotebook`"]

PackageExport[ImportLaTeXDocument]
PackageExport[ExportLaTeXDocument]

PackageScope["latexToNotebook"]
PackageScope["notebookToLaTeX"]
PackageScope["theoremEnvironments"]
PackageScope["environmentNumbering"]
PackageScope["equationNumbering"]
PackageScope["documentStyleSheet"]
PackageScope["environmentCell"]
PackageScope["documentTagging"]
PackageScope["bibliographyDatabase"]
PackageScope["bibliographyNames"]
PackageScope["bibliographyFile"]
PackageScope["documentClass"]
PackageScope["citationBox"]
PackageScope["cellTagging"]
PackageScope["insertReferenceCells"]
PackageScope["bibliographyDatabaseQ"]
PackageScope["sortBibliographyCells"]
PackageScope["bibliographyAudit"]
PackageScope["citedTags"]
PackageScope["referenceKey"]
PackageScope["$bibliographySortMethods"]
PackageScope["$bibliographyAnchorTag"]
PackageScope["unescapedRun"]
PackageScope["escapedRun"]

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
  Module[ { preamble, body, postamble, numbering, equation, pieces, cells },
    { preamble, body, postamble } = documentParts[ source ];
    numbering = environmentNumbering[ preamble ];
    equation = equationNumbering[ preamble ];
    pieces = documentPieces[ body, numbering, citedEntries[ body, entries ] ];
    cells = numberedCells[ Map[ labelledCell, withSeparators[ pieces ] ], numbering, equation ];
    (* FrontEnd`FileName is HoldAll, so the name has to be substituted in by With: writing the call
       that computes it inside the option leaves that call in the notebook, unevaluated, along with
       the Module's own renamed local — and the front end then silently falls back to Default.nb. *)
    With[ { sheet = documentStyleSheet[ preamble ] <> ".nb" },
      Notebook[ Map[ referenceCell[ #, labelCounters[ cells ] ] &, cells ],
        StyleDefinitions -> FrontEnd`FileName[ { "MathNotebook" }, sheet, CharacterEncoding -> "UTF-8" ],
        TaggingRules -> <| "MathNotebook" -> <|
          "Preamble" -> preamble,
          "Postamble" -> postamble,
          "BodyPrefix" -> joinMarks @ TakeWhile[ pieces, MatchQ[ _separatorMark ] ] |> |> ] ]
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

(* Which source environment names this document uses, and what each is printed as — the printed name
   half of the numbering table below, which is where the \newtheorem lines are actually read. *)
theoremEnvironments[ preamble_String ] :=
  Map[ Lookup[ "Printed" ], environmentNumbering[ preamble ] ]

(* How the document numbers each of those environments, which is not what the stylesheets do unless
   the document happens to agree with them. A \newtheorem declares three things at once: the printed
   name, which counter the environment shares (its own by default, another's in the
   \newtheorem{cor}[thm]{Corollary} form), and — the optional [section] — which sectioning level
   resets that counter and is printed before it. The starred form declares an environment that is
   never numbered at all.

   The sheets declare one Theorem counter for all twelve styles, reset by Section and printed
   Section.Theorem, so exactly one of the document's counter groups can be the one the sheets are
   already right about: the first declared group that is numbered per section. Every other group
   deviates, and a deviation is written onto the cell that heads the environment — which is the one
   place the document, and not the sheet, owns the number. That is not the per-cell counter T11 rules
   out: the numbering is declared in the preamble, the preamble is carried verbatim, so swapping
   sheets to retarget a journal does not change what the compiled paper prints and must not change
   what the notebook shows either. The sheet owns typography; the preamble owns numbering.

   The two specimens are the two halves of this. Hodgepaper declares theorem[section] first and
   shares it with proposition, lemma, definition, remark and example, so 67 of its 71 environments are
   the sheets' own default and carry nothing; what moves is its four starred ones, which were being
   numbered and were stealing the shared counter, so every theorem after them read one too high. The
   causal paper declares four independent counters, all [subsection], so all 32 of its environments
   deviate and read Definition 3.5.2 where the sheets said Definition 3.5. *)
environmentNumbering[ preamble_String ] :=
  Module[ { declarations = theoremDeclarations[ preamble ], levels, master },
    levels = Join[ <| "theorem" -> "section" |>,
      Association @ Map[ #[ "Counter" ] -> #[ "Within" ] &,
        Select[ declarations, #[ "Own" ] && #[ "Numbered" ] & ] ] ];
    master = FirstCase[ Select[ declarations, #[ "Numbered" ] & ],
      declaration_ /; declarationLevel[ levels, declaration ] === "section" :> declaration[ "Counter" ],
      "theorem" ];
    Join[
      Association @ Map[ ToLowerCase[ # ] -> numberingSpec[ #, "theorem", "section", True, master ] &,
        Keys @ $theoremEnvironments ],
      <| "proof" -> plainNumbering[ "Proof" ], "abstract" -> plainNumbering[ "Abstract" ] |>,
      Association @ Map[
        #[ "Name" ] -> numberingSpec[ #[ "Printed" ], #[ "Counter" ], declarationLevel[ levels, # ],
          #[ "Numbered" ], master ] &,
        declarations ] ]
  ]

(* An environment with a counter of its own says its own level; one sharing another's inherits that
   counter's. A shared counter the preamble never declares — \newtheorem{cor}[thm]{Corollary} with no
   thm — is an error in LaTeX, and falls back to the sheets' own level rather than to "never reset". *)
declarationLevel[ levels_Association, declaration_Association ] :=
  If[ declaration[ "Own" ],
    declaration[ "Within" ],
    Lookup[ levels, declaration[ "Counter" ], "section" ] ]

(* Four rules, and their order is what tells the forms apart: StringCases tries them in the order
   given at each position, so the [within] form has to precede the bare one or every declaration
   would match as bare and lose its level. *)
theoremDeclarations[ preamble_String ] :=
  StringCases[ preamble, {
    "\\newtheorem*{" ~~ name : Except[ "}" ] .. ~~ "}{" ~~ printed : Except[ "}" ] .. ~~ "}" :>
      theoremDeclaration[ name, printed, name, True, None, False ],
    "\\newtheorem{" ~~ name : Except[ "}" ] .. ~~ "}[" ~~ shared : Except[ "]" ] .. ~~ "]{" ~~
        printed : Except[ "}" ] .. ~~ "}" :>
      theoremDeclaration[ name, printed, shared, False, None, True ],
    "\\newtheorem{" ~~ name : Except[ "}" ] .. ~~ "}{" ~~ printed : Except[ "}" ] .. ~~ "}[" ~~
        within : Except[ "]" ] .. ~~ "]" :>
      theoremDeclaration[ name, printed, name, True, within, True ],
    "\\newtheorem{" ~~ name : Except[ "}" ] .. ~~ "}{" ~~ printed : Except[ "}" ] .. ~~ "}" :>
      theoremDeclaration[ name, printed, name, True, None, True ] } ]

theoremDeclaration[ name_String, printed_String, counter_String, ownQ_, within_, numberedQ_ ] :=
  <| "Name" -> name, "Printed" -> printed, "Counter" -> counter, "Own" -> ownQ,
     "Within" -> within, "Numbered" -> numberedQ |>

numberingSpec[ printed_String, counter_String, within_, numberedQ_, master_String ] :=
  With[ { name = If[ counter === master, "Theorem", "Theorem" <> Capitalize[ counter ] ],
      prefix = withinChain[ within ] },
    <| "Printed" -> printed, "Counter" -> name, "Prefix" -> prefix, "Reset" -> withinStyle[ within ],
       "Numbered" -> TrueQ[ numberedQ ],
       "Default" -> TrueQ[ numberedQ ] && name === "Theorem" && prefix === { "Section" } |> ]

(* Proof and Abstract are the two names outside the twelve that the sheets do declare a style for.
   Neither is numbered and each carries its own label, so there is nothing for a cell to say. *)
plainNumbering[ printed_String ] :=
  <| "Printed" -> printed, "Counter" -> None, "Prefix" -> { }, "Reset" -> None,
     "Numbered" -> False, "Default" -> True |>

$sectionLevels = { "section", "subsection", "subsubsection" }

(* \thesubsection is \thesection.\arabic{subsection} in both article and amsart, so the counters
   printed before a per-subsection one are the whole chain down to it and not just the level named. *)
withinChain[ within_ ] :=
  Map[ Capitalize,
    Take[ $sectionLevels,
      Replace[ FirstPosition[ $sectionLevels, within ], { { position_ } :> position, _ :> 0 } ] ] ]

withinStyle[ within_ ] :=
  If[ MemberQ[ $sectionLevels, within ], Capitalize[ within ], None ]

(* article numbers equations straight through the document, which is what the sheets do; amsart,
   amsbook and amsproc number them within the section, and \numberwithin says so explicitly for any
   class. Figures are left alone deliberately — both specimens are numbered straight through. *)
equationNumbering[ preamble_String ] :=
  With[ { within =
      First[
        StringCases[ preamble, "\\numberwithin{equation}{" ~~ level : Except[ "}" ] .. ~~ "}" :> level, 1 ],
        If[ StringMatchQ[ documentClass[ preamble ], "amsart" | "amsbook" | "amsproc" ],
          "section", None ] ] },
    <| "Prefix" -> withinChain[ within ], "Reset" -> withinStyle[ within ] |> ]

documentClass[ preamble_String ] :=
  First[
    StringCases[ preamble,
      "\\documentclass" ~~ ( "[" ~~ Except[ "]" ] ... ~~ "]" ) | "" ~~ "{" ~~
        class : Except[ "}" ] .. ~~ "}" :> class, 1 ],
    "" ]

(* Which template the class asks for. Only a class this repo has a template *for* is named: the
   templates are journal typography and claiming one for a paper that did not ask for it would be
   guessing. Everything else — article, book, a local class, no \documentclass at all — lands on
   PlainArticle, which is Default's typography with the environments added, so the paper opens live
   without pretending to be a journal. *)
$classStyleSheets = {
  "amsart" | "amsbook" | "amsproc" -> "AMSArticle",
  "revtex" ~~ ___ -> "RevTeXAPS",
  "svjour" ~~ ___ -> "SpringerJournal" }

documentStyleSheet[ preamble_String ] :=
  With[ { class = documentClass[ preamble ] },
    FirstCase[ $classStyleSheets,
      ( pattern_ -> sheet_ ) /; StringMatchQ[ class, pattern ] :> sheet,
      "PlainArticle" ] ]

documentParts[ source_String ] :=
  First[ StringCases[ source,
      Shortest[ preamble___ ] ~~ "\\begin{document}" ~~ body__ ~~ "\\end{document}" ~~ postamble___ :>
        { preamble <> "\\begin{document}", body, "\\end{document}" <> postamble } ],
    { "", source, "" } ]

(* Every cell carries the whitespace that followed it in the source, so the export is a plain
   StringJoin and the blocking survives exactly: the paper separates blocks with two newlines in
   most places and three in two of them, and a display equation lifted out of a paragraph rejoins
   with one. Riffling everything with "\n\n" was seven diff lines on the specimen. *)
documentPieces[ body_String, numbering_Association, entries_Association ] :=
  splitPieces[ body, structureRules[ numbering, entries ] ]

splitPieces[ text_String, rules_List ] :=
  Flatten @ Map[ Replace[ chunk_String :> paragraphPieces[ chunk ] ], StringSplit[ text, rules ] ]

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
   \begin{figure} and \begin{table} pass through as text. *)
structureRules[ numbering_Association, entries_Association ] :=
  Join[
    bibliographyRules[ entries ],
    entryRules[ ],
    figureRules[ ],
    commandRules[ ],
    nestedRules[ numbering, 1 ] ]

(* The rules that may apply inside another block's body as well as at document level: an environment,
   and a list. The depth is the list nesting, which is what chooses between Item, Subitem and
   Subsubitem; a theorem inside an item does not change it. *)
nestedRules[ numbering_Association, depth_Integer ] :=
  Join[ listRules[ numbering, depth ], environmentRules[ numbering, depth ] ]

(* One rule shape for every command whose braced argument is the cell's content — the three
   sectioning commands and the three front-matter ones. The style name lowercased is the command it
   came from, so cellToLaTeX needs no table to write it back. The argument is matched brace-balanced
   rather than up to the first "}", because the specimen's title is \title{\vspace{-1.5cm}...} and a
   section title may hold a $\mathcal{H}$; a deeper nesting than the pattern allows simply does not
   match, and the command stays literal source. *)
commandRules[ ] :=
  Map[ Apply[ { command, style } |->
      ( StartOfLine ~~ indent : ( " " | "\t" ) ... ~~ command ~~ "{" ~~ title : $braceBody ~~ "}" ~~
          trailing : Except[ "\n" ] ... :> sectionCell[ style, indent, title, trailing ] ) ],
    $commandStyles ]

$commandStyles = {
  { "\\subsubsection", "Subsubsection" }, { "\\subsection", "Subsection" }, { "\\section", "Section" },
  { "\\title", "Title" }, { "\\author", "Author" }, { "\\date", "Date" } }

$braceGroup = "{" ~~ ( Except[ "{" | "}" ] | ( "{" ~~ Except[ "{" | "}" ] ... ~~ "}" ) ) ... ~~ "}"

$braceBody = ( Except[ "{" | "}" ] | $braceGroup ) ...

(* Commands that print nothing. A paragraph made only of these and of comments is carried rather than
   shown (Pavel's R3 call), and a leading run of them is taken off the front of a front-matter
   argument — which is what gets \vspace{-1.5cm} out of the specimen's title. Only content-free
   commands may be listed: \printbibliography prints a bibliography and would be hidden along with
   it, which is why it is absent despite the specimen carrying one, commented out. *)
$carriedCommands = { "maketitle", "sloppy", "fussy", "tableofcontents", "listoffigures",
  "listoftables", "clearpage", "newpage", "pagebreak", "noindent", "bigskip", "medskip",
  "smallskip", "centering", "raggedright" }

$carriedArgumentCommands = { "vspace*", "vspace", "hspace*", "hspace" }

(* Built at call time rather than stored, because $braceBody has to be defined when it is used. *)
carriedToken[ ] :=
  ( "\\" ~~ Alternatives @@ $carriedCommands ) |
    ( "\\" ~~ Alternatives @@ $carriedArgumentCommands ~~ "{" ~~ $braceBody ~~ "}" )

carriedSourceQ[ text_String ] :=
  StringMatchQ[ text, ( WhitespaceCharacter | ( "%" ~~ Except[ "\n" ] ... ) | carriedToken[ ] ) .. ]

(* The prefix must hold at least one command and not merely whitespace, or every argument that opens
   with a space would acquire a tagging rule it does not need and every pinned cell would change. *)
commandPrefix[ title_String ] :=
  Replace[
    StringCases[ title,
      StartOfString ~~
        prefix : ( ( WhitespaceCharacter ... ~~ carriedToken[ ] ) .. ~~ WhitespaceCharacter ... ) ~~
        body___ :> { prefix, body }, 1 ],
    { { pair_List } :> pair, _ :> { "", title } } ]

(* The names inside an \author block. authblk writes one brace group per author — the specimen writes
   three of them in one block, under a comment — while a plain class writes the name bare with \and
   between several. The brace route is taken only when the block is *nothing but* brace groups, or a
   \thanks{...} inside a bare name would be read as the author. Comments are masked to spaces rather
   than deleted so a name never joins the one below it. *)
authorNames[ block_String ] :=
  With[ { text = StringTrim @ uncommented[ block ] },
    StringRiffle[
      Map[ StringTrim,
        If[ StringMatchQ[ text, ( WhitespaceCharacter | $braceGroup ) .. ],
          StringCases[ text, "{" ~~ inner : $braceBody ~~ "}" :> inner ],
          StringSplit[ text, "\\and" ] ] ],
      ", " ] ]

environmentRules[ numbering_Association, depth_Integer ] :=
  Map[ name |->
      ( StartOfLine ~~ indent : ( " " | "\t" ) ... ~~ ( "\\begin{" <> name <> "}" ) ~~
          title : ( "[" ~~ Except[ "]" ] ... ~~ "]" ) | "" ~~ trailing : Except[ "\n" ] ... ~~
          Shortest[ inner___ ] ~~ StartOfLine ~~ closingIndent : ( " " | "\t" ) ... ~~ ( "\\end{" <> name <> "}" ) :>
        environmentCell[ numbering, depth, name, indent, title, trailing, inner, closingIndent ] ),
    Keys[ numbering ] ]

(* An \author block is stored verbatim and the cell shows the names alone — Pavel's R3 call, and the
   .bib trade comes with it: an author edited in the notebook does not reach the .tex. Displayed raw
   it was the paper's second line, three brace groups under a comment. *)
sectionCell[ "Author", indent_String, title_String, trailing_String ] :=
  Cell[ inlineContent @ authorNames[ title ], "Author",
    TaggingRules -> <| "MathNotebook" ->
      <| "Indent" -> indent, "CommandTeX" -> title, "Trailing" -> trailing |> |> ]

(* A leading run of content-free layout commands is carried, so the title displays as its text. It is
   a prefix and not the whole argument, which is what keeps the title editable: an edit still reaches
   the .tex, where the Author block's does not. The key is written only when there is one. *)
sectionCell[ style_String, indent_String, title_String, trailing_String ] :=
  Module[ { prefix, body },
    { prefix, body } = commandPrefix[ title ];
    Cell[ inlineContent[ body ], style,
      TaggingRules -> <| "MathNotebook" -> Join[
        <| "Indent" -> indent |>,
        If[ prefix === "", <| |>, <| "CommandPrefix" -> prefix |> ],
        <| "Trailing" -> trailing |> ] |> ] ]

(* An environment body is split exactly as the document body is — the same display-math lift, the
   same recursion into a nested environment — so a theorem holding three equations becomes seven
   cells rather than one block of literal source. What kept it to one cell before was that the
   \end{...} had nowhere else to go; it goes on the LAST cell of the group now, as a plain string,
   with the \begin{...} on the first, so the export is still a StringJoin and the delimiters still
   land where the source had them. Nesting composes by concatenation: an outer \begin is prepended
   to whatever opening its first cell already carries and an outer \end appended to its closing. *)
environmentCell[ numbering_Association, depth_Integer, name_String, indent_String, title_String,
    trailing_String, inner_String, closingIndent_String ] :=
  environmentPieces[ numbering[ name ], name, indent, title, trailing, closingIndent,
    splitPieces[ inner, nestedRules[ numbering, depth ] ] ]

environmentPieces[ spec_Association, name_String, indent_String, title_String, trailing_String,
    closingIndent_String, pieces_List ] :=
  Module[ { positions = Flatten @ Position[ pieces, _Cell, { 1 }, Heads -> False ], first, last },
    If[ positions === { },
      environmentOpened[
        environmentClosed[
          Cell[ "", environmentStyle @ spec[ "Printed" ], Sequence @@ environmentDingbat[ spec ] ],
          closingIndent <> "\\end{" <> name <> "}" ],
        name, indent <> "\\begin{" <> name <> "}" <> title, trailing, joinMarks[ pieces ] ],
      first = First[ positions ]; last = Last[ positions ];
      Take[
        MapAt[ environmentClosed[ #,
            joinMarks @ Drop[ pieces, last ] <> closingIndent <> "\\end{" <> name <> "}" ] &,
          MapAt[ environmentOpened[ #, name, indent <> "\\begin{" <> name <> "}" <> title, trailing,
              joinMarks @ Take[ pieces, first - 1 ] ] &,
            environmentStyled[ pieces, spec ], first ],
          last ],
        { first, last } ] ]
  ]

environmentOpened[ cell_Cell, name_String, opening_String, trailing_String, leading_String ] :=
  retagged[ cell,
    If[ cellTagging[ cell, "EnvironmentOpen" ] === "",
      <| "Environment" -> name, "EnvironmentOpen" -> opening, "Trailing" -> trailing,
        "BodyIndent" -> leading |>,
      <| "EnvironmentOpen" ->
        opening <> trailing <> leading <> cellTagging[ cell, "EnvironmentOpen" ] |> ] ]

environmentClosed[ cell_Cell, closing_String ] :=
  retagged[ cell, <| "EnvironmentClose" -> cellTagging[ cell, "EnvironmentClose" ] <> closing |> ]

(* Only the cells still styled "Text" at this level are the environment's own prose — a nested
   environment has already restyled its own — so those are the ones that take the environment style
   and go on looking like one block. The style carries the dingbat, the counter and, for Proof, the
   QED square, all of which belong to the block and not to each of its cells: the first prose cell
   keeps the name and the number, the last keeps the square, and the ones between suppress both.
   Suppressing on the cell rather than declaring a continuation style is deliberate — "this cell
   continues the one above" is true under every stylesheet, so retargeting a journal by swapping
   sheets still works, which writing the positive counter onto each cell would break. *)
environmentStyled[ pieces_List, spec_Association ] :=
  With[ { positions = Flatten @ Position[ pieces, Cell[ _, "Text", ___ ], { 1 }, Heads -> False ] },
    Fold[ { current, index } |->
        MapAt[ environmentStyledCell[ #, spec, index === 1, index === Length[ positions ] ] &,
          current, positions[[ index ]] ],
      pieces, Range @ Length[ positions ] ] ]

environmentStyledCell[ Cell[ content_, "Text", options___ ], spec_Association, firstQ_, lastQ_ ] :=
  Cell[ content, environmentStyle @ spec[ "Printed" ],
    Sequence @@ If[ firstQ, environmentDingbat[ spec ],
      { CellDingbat -> None, CounterIncrements -> { } } ],
    Sequence @@ If[ lastQ, { }, { CellFrameLabels -> { { None, None }, { None, None } } } ],
    options ]

(* A declared environment whose printed name is none of the twelve — the specimen paper's ten
   Axioms — is written as a Theorem, which numbers it correctly, with a dingbat that says what it
   really is. The alternative was to leave a third of the paper's environments as literal text.
   Proof and Abstract are the two names outside the twelve that the stylesheets do declare: neither is
   numbered, and each carries the label it needs ("Proof." and "Abstract. ") in its own style. *)
$plainEnvironments = { "Proof", "Abstract" }

environmentStyle[ printed_String ] :=
  If[ KeyExistsQ[ $theoremEnvironments, printed ] || MemberQ[ $plainEnvironments, printed ],
    printed, "Theorem" ]

(* Nothing is written when the style already prints exactly the right thing: one of the twelve, or Proof
   or Abstract, numbered the way the sheets number it. Anything else — a printed name outside the twelve
   (the causal paper's ten Axioms), a counter of its own, a level other than the section, or no number at
   all (hodgepaper's four starred environments) — needs the label spelled out on the cell that heads the
   group, and with it the counter that label reads. An unnumbered environment must also stop incrementing
   the counter its style claims, or it steals a number from the theorems it shares it with. *)
environmentDingbat[ spec_Association ] :=
  With[ { printed = spec[ "Printed" ] },
    If[ TrueQ @ spec[ "Default" ] && environmentStyle[ printed ] === printed,
      { },
      Join[
        { CellDingbat -> environmentDingbatCell[ spec ] },
        Which[
          ! TrueQ @ spec[ "Numbered" ], { CounterIncrements -> { } },
          TrueQ @ spec[ "Default" ], { },
          True, { CounterIncrements -> spec[ "Counter" ] } ] ] ] ]

environmentDingbatCell[ spec_Association ] :=
  With[ { printed = spec[ "Printed" ], numberedQ = TrueQ @ spec[ "Numbered" ],
      class = Lookup[ $theoremEnvironments, spec[ "Printed" ], "Plain" ] },
    Cell[
      If[ numberedQ,
        TextData @ Flatten @ { printed <> " ",
          Riffle[ Map[ CounterBox, Append[ spec[ "Prefix" ], spec[ "Counter" ] ] ], "." ], "." },
        TextData[ printed <> "." ] ],
      FontWeight -> If[ class === "Remark", "Plain", "Bold" ],
      FontSlant -> If[ class === "Remark", "Italic", "Plain" ] ] ]

(* A list is an environment whose items are its cells, and it is recorded exactly as T7 records a
   theorem: the \begin{itemize} rides on the first cell of the group, the \end{itemize} on the last,
   and each \item on the cell it opens — all of them plain strings in the tagging rules, so the export
   stays a StringJoin. An item's content then goes through splitPieces like any other body, so its
   display math is lifted into its own cell and a nested environment or list is recursed into, and the
   markers come back out in source order because each wrapper is *prepended* to whatever opening the
   cell already carries: the outer \item, then the inner \begin, then the inner \item.
   description needs no case of its own — every one of its items carries the [label] that becomes the
   item's dingbat, which is the same thing an \item[(E)] inside an enumerate wants. *)
$listEnvironments = <| "itemize" -> "Item", "enumerate" -> "ItemNumbered", "description" -> "Item" |>

listRules[ numbering_Association, depth_Integer ] :=
  KeyValueMap[ { name, base } |->
      ( StartOfLine ~~ indent : ( " " | "\t" ) ... ~~ ( "\\begin{" <> name <> "}" ) ~~
          options : ( "[" ~~ Except[ "]" ] ... ~~ "]" ) | "" ~~ trailing : Except[ "\n" ] ... ~~
          Shortest[ inner___ ] ~~ StartOfLine ~~ closingIndent : ( " " | "\t" ) ... ~~
          ( "\\end{" <> name <> "}" ) :>
        listCells[ numbering, depth, name, itemFormat[ options ],
          indent <> "\\begin{" <> name <> "}" <> options, trailing,
          inner, closingIndent <> "\\end{" <> name <> "}" ] ),
    $listEnvironments ]

listCells[ numbering_Association, depth_Integer, name_String, format_String, opening_String,
    trailing_String, inner_String, closing_String ] :=
  Module[ { chunks = itemChunks[ inner ], leading, pieces, positions, first, last },
    leading = First[ chunks ];
    pieces = Flatten @ MapIndexed[
      itemPieces[ numbering, depth, name, format, First[ #2 ] === 1, #1 ] &, Rest[ chunks ] ];
    positions = Flatten @ Position[ pieces, _Cell, { 1 }, Heads -> False ];
    If[ positions === { },
      { environmentOpened[
          environmentClosed[ Cell[ "", listStyle[ $listEnvironments[ name ], depth ] ], closing ],
          name, opening, trailing, leading <> joinMarks[ pieces ] ] },
      first = First[ positions ]; last = Last[ positions ];
      Take[
        MapAt[ environmentClosed[ #, joinMarks @ Drop[ pieces, last ] <> closing ] &,
          MapAt[ environmentOpened[ #, name, opening, trailing,
              leading <> joinMarks @ Take[ pieces, first - 1 ] ] &,
            pieces, first ],
          last ],
        { first, last } ] ]
  ]

(* The item's own leading whitespace goes into its marker rather than staying a separator, because a
   separator belongs to the cell before it and the marker is what precedes this one; the whitespace
   that FOLLOWS the item's last cell is left as pieces, so it becomes that cell's separator and the
   next \item lands where the source had it. *)
itemPieces[ numbering_Association, depth_Integer, name_String, format_String, firstQ_,
    { marker_String, content_String } ] :=
  Module[ { pieces = splitPieces[ content, nestedRules[ numbering, depth + 1 ] ], positions, first },
    positions = Flatten @ Position[ pieces, _Cell, { 1 }, Heads -> False ];
    If[ positions === { },
      Prepend[ pieces,
        itemOpened[ itemStyledCell[ Cell[ "", "Text" ], name, format, depth, marker, firstQ, True ],
          marker, "" ] ],
      first = First[ positions ];
      Drop[
        MapAt[ itemOpened[ #, marker, joinMarks @ Take[ pieces, first - 1 ] ] &,
          itemStyled[ pieces, name, format, depth, marker, firstQ ],
          first ],
        first - 1 ] ]
  ]

itemOpened[ cell_Cell, marker_String, leading_String ] :=
  retagged[ cell, <| "EnvironmentOpen" -> marker <> leading <> cellTagging[ cell, "EnvironmentOpen" ] |> ]

(* As in an environment body, only the cells still styled "Text" at this level are the item's own
   prose: the first is the item, the rest are its continuation paragraphs. An item with no prose at all
   is the case T7's rule about environments left open, and here it is real — three of hodgepaper's
   description items are a \begin{align*} and nothing else — so it falls back to itemHead. *)
itemStyled[ pieces_List, name_String, format_String, depth_Integer, marker_String, firstQ_ ] :=
  With[ { positions = Flatten @ Position[ pieces, Cell[ _, "Text", ___ ], { 1 }, Heads -> False ] },
    If[ positions === { },
      MapAt[ itemHead[ #, name, format, depth, marker, firstQ ] &, pieces,
        First @ Flatten @ Position[ pieces, _Cell, { 1 }, Heads -> False ] ],
      Fold[ { current, index } |->
          MapAt[ itemStyledCell[ #, name, format, depth, marker, firstQ, index === 1 ] &, current, positions[[ index ]] ],
        pieces, Range @ Length[ positions ] ] ] ]

(* \item[label] prints the label instead of the bullet or the number and consumes no counter, so the
   label becomes the cell's dingbat — a mirror of the [label] stored in the marker, like a display
   formula's CellTags, not the origin of one. And LaTeX restarts every list, while the front end's
   counters run on until a section resets them, so the first item of a list carries the reset. *)
itemStyledCell[ Cell[ content_, "Text", options___ ], name_String, format_String, depth_Integer,
    marker_String, firstQ_, headQ_ ] :=
  With[ { style = listStyle[ $listEnvironments[ name ], depth ], label = itemLabel[ marker ] },
    If[ headQ,
      Cell[ content, style,
        Sequence @@ Which[
          label =!= "",
            { CellDingbat -> itemDingbat[ label, name === "description" ], CounterIncrements -> { } },
          format =!= "", { CellDingbat -> itemFormatDingbat[ format, style ] },
          True, { } ],
        Sequence @@ If[ firstQ, { CounterAssignments -> { { style, 0 } } }, { } ],
        options ],
      Cell[ content, listStyle[ "ItemParagraph", depth ], options ] ] ]

(* An item whose whole content is display math has no cell that could take the item style — a
   DisplayFormula restyled as an Item would lose its centering and its equation number — so the head
   is written onto whatever cell opens it. The dingbat is free there, since a display formula's number
   lives in CellFrameLabels and not in its dingbat, and a counter the cell already increments is added
   to rather than replaced. This is the one place a *positive* counter goes on a cell, which T11 rules
   out in general; it is bounded to a cell that has no other way to be headed, and without it a
   description item loses the label that is the whole of its content. *)
itemHead[ cell : Cell[ content_, style_String, options___ ], name_String, format_String,
    depth_Integer, marker_String, firstQ_ ] :=
  With[ { counter = listStyle[ $listEnvironments[ name ], depth ], label = itemLabel[ marker ],
      numberedQ = $listEnvironments[ name ] === "ItemNumbered" },
    Cell[ content, style,
      CellDingbat -> Which[
        label =!= "", itemDingbat[ label, name === "description" ],
        format =!= "", itemFormatDingbat[ format, counter ],
        numberedQ, Cell[ TextData[ { CounterBox[ counter ], "." } ], FontWeight -> "Bold" ],
        True, Cell[ TextData[ "\[FilledSmallSquare]" ] ] ],
      Sequence @@ If[ label === "" && numberedQ,
        { CounterIncrements -> Flatten @ { cellCounters[ cell ], counter } }, { } ],
      Sequence @@ If[ firstQ, { CounterAssignments -> { { counter, 0 } } }, { } ],
      Sequence @@ DeleteCases[ { options }, ( CellDingbat | CounterIncrements | CounterAssignments ) -> _ ] ] ]

(* enumitem's label= is the other half of "the numbering must match": an enumerate opened with
   label=(\alph[star]) prints (a), (b), (c) where the ItemNumbered style prints 1., 2., 3. — twice in
   hodgepaper. The marker is a CounterBox with a
   CounterFunction, so the front end still owns the counting and a \ref to the item still resolves — but
   the function has to be one the front end can evaluate with no kernel, and almost none are: measured,
   RomanNumeral and Part on a literal list work, while FromCharacterCode, StringTake, ToLowerCase and
   FEPrivate`FromCharacterCode each render as their own unevaluated expression. So every format is a
   literal table indexed by the counter. *)
itemFormat[ options_String ] :=
  First[ StringCases[ options, "label=" ~~ format : Except[ "," | "]" ] .. :> format, 1 ], "" ]

itemFormatDingbat[ format_String, counter_String ] :=
  Cell[
    TextData @ Flatten @ StringSplit[ format,
      KeyValueMap[ #1 :> CounterBox[ counter, CounterFunction :> Evaluate[ #2 ] ] &, $counterFormats ] ] ]

$counterFormats = <|
  "\\alph*" -> counterTable @ Alphabet[],
  "\\Alph*" -> counterTable @ ToUpperCase @ Alphabet[],
  "\\roman*" -> counterTable @ Map[ ToLowerCase @ RomanNumeral[ # ] &, Range[ 40 ] ],
  "\\Roman*" -> counterTable @ Map[ RomanNumeral, Range[ 40 ] ],
  "\\arabic*" -> Identity |>

counterTable[ values_List ] :=
  With[ { table = values }, Function[ table[[ # ]] ] ]

cellCounters[ cell_Cell ] :=
  Replace[ FirstCase[ cell, ( CounterIncrements -> counters_ ) :> counters ], _Missing -> { } ]

itemDingbat[ label_String, boldQ_ ] :=
  Cell[ TextData @ Flatten @ { Replace[ inlineContent[ label ], TextData[ parts_ ] :> parts ] },
    FontWeight -> If[ boldQ, "Bold", "Plain" ] ]

itemLabel[ marker_String ] :=
  First[ StringCases[ marker, "[" ~~ label___ ~~ "]" ~~ EndOfString :> label, 1 ], "" ]

listStyle[ base_String, depth_Integer ] :=
  Replace[ Min[ depth, 3 ],
    { 1 -> base, 2 -> "Sub" <> Decapitalize[ base ], _ -> "Subsub" <> Decapitalize[ base ] } ]

(* Which \item starts an item of THIS list: one nested inside a \begin{...} of the body — a table, an
   align, a list the Shortest pattern could not separate — is not one, and brace-style depth cannot be
   written as a string pattern, so the begins and ends are counted the way a .bib field's braces are.
   Both delimiters have to be counted wherever they stand, not only at the start of a line: the
   specimen writes \begin{cases} inline and its \end{cases} at the start of one, so counting only
   line-initial delimiters drove the depth negative and made items (b), (c) and (d) of that list
   continuation paragraphs of item (a). What the comment mask replaces is the StartOfLine anchor's
   other job — keeping a commented-out %\item, and both halves of a commented-out %\begin{enumerate},
   from counting; hodgepaper has three such blocks.

   The command and the length of what follows it that belongs to the marker are arguments because a
   thebibliography is the same shape one command down: its items are \bibitem[label]{key} rather than
   \item[label], and everything else — the depth filter, the comment mask, the slicing — is the same.
   \bibitem is not matched by the \item pattern: after the indent the next characters must be \item,
   and \bibitem's are \bibi. *)
itemChunks[ inner_String ] :=
  itemChunks[ inner, "\\item", itemLabelLength ]

itemChunks[ inner_String, command_String, markerLength_ ] :=
  Module[ { text = uncommented[ inner ], markers, delimiters, starts },
    markers = StringPosition[ text, StartOfLine ~~ ( " " | "\t" ) ... ~~ command ];
    delimiters = Join[
      Map[ { First[ # ], 1 } &, StringPosition[ text, "\\begin{" ] ],
      Map[ { First[ # ], -1 } &, StringPosition[ text, "\\end{" ] ] ];
    markers = Select[ markers,
      Total @ Cases[ delimiters, { position_, step_ } /; position < First[ # ] :> step ] === 0 & ];
    starts = Map[ First, markers ];
    If[ markers === { },
      { inner },
      Prepend[
        MapThread[ itemChunk[ inner, #1, #2, markerLength ] &,
          { markers, Append[ Rest[ starts ] - 1, StringLength[ inner ] ] } ],
        stringSlice[ inner, 1, First[ starts ] - 1 ] ] ]
  ]

(* A %-tail becomes spaces of its own length, so a depth walk can ignore comments while every position
   still refers to the same character of the source — the positions are what the slicing uses. An
   escaped \% is not a comment. *)
uncommented[ text_String ] :=
  StringReplace[ text,
    comment : RegularExpression[ "(?<!\\\\)%[^\n]*" ] :> StringRepeat[ " ", StringLength[ comment ] ] ]

itemChunk[ inner_String, { from_Integer, to_Integer }, until_Integer, markerLength_ ] :=
  With[ { length = markerLength @ stringSlice[ inner, to + 1, until ] },
    { stringSlice[ inner, from, to + length ], stringSlice[ inner, to + length + 1, until ] } ]

itemLabelLength[ rest_String ] :=
  First[
    StringCases[ rest, StartOfString ~~ label : ( "[" ~~ Except[ "]" ] ... ~~ "]" ) :> StringLength[ label ], 1 ],
    0 ]

stringSlice[ text_String, from_Integer, to_Integer ] :=
  If[ to < from, "", StringTake[ text, { from, to } ] ]

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

(* The other bibliography, and the opposite case: one written into the .tex itself, which is what a
   paper with no .bib does and what all four of the paclet's sample documents do. Here the entries
   ARE the source, so the notebook owns them and writes them back — editing an entry reaches the
   .tex, where a .bib entry's cell is suppressed and the .bib stays the source of truth.

   A \bibitem is recorded exactly as T8 records an \item: the \begin{thebibliography} rides on the
   first cell of the group, each \bibitem on the cell it opens, the \end{thebibliography} on the
   last, all of them plain strings in the tagging rules, so the export is still a StringJoin and
   entryCells is listCells with the item machinery pointed at a different command. *)
entryRules[ ] :=
  { StartOfLine ~~ indent : ( " " | "\t" ) ... ~~ "\\begin{thebibliography}" ~~
      widest : ( ( "{" ~~ Except[ "}" ] ... ~~ "}" ) | "" ) ~~ trailing : Except[ "\n" ] ... ~~
      Shortest[ inner___ ] ~~ StartOfLine ~~ closingIndent : ( " " | "\t" ) ... ~~
      "\\end{thebibliography}" :>
    entryCells[ indent <> "\\begin{thebibliography}" <> widest, trailing, inner,
      closingIndent <> "\\end{thebibliography}" ] }

entryCells[ opening_String, trailing_String, inner_String, closing_String ] :=
  Module[ { chunks = itemChunks[ inner, "\\bibitem", bibitemMarkerLength ], leading, pieces,
      positions, first, last },
    leading = First[ chunks ];
    pieces = Flatten @ Map[ entryPieces, Rest[ chunks ] ];
    positions = Flatten @ Position[ pieces, _Cell, { 1 }, Heads -> False ];
    If[ positions === { },
      { environmentOpened[ environmentClosed[ Cell[ "", "Reference" ], closing ],
          "thebibliography", opening, trailing, leading <> joinMarks[ pieces ] ] },
      first = First[ positions ]; last = Last[ positions ];
      Take[
        MapAt[ environmentClosed[ #, joinMarks @ Drop[ pieces, last ] <> closing ] &,
          MapAt[ environmentOpened[ #, "thebibliography", opening, trailing,
              leading <> joinMarks @ Take[ pieces, first - 1 ] ] &,
            pieces, first ],
          last ],
        { first, last } ] ]
  ]

(* An entry is prose and nothing else — no environment of the document's can open inside one — so its
   content goes through paragraphPieces rather than splitPieces, and a blank line inside an entry
   makes a continuation cell exactly as it does inside an item. *)
entryPieces[ { marker_String, content_String } ] :=
  Module[ { pieces = paragraphPieces[ content ], positions, first },
    positions = Flatten @ Position[ pieces, _Cell, { 1 }, Heads -> False ];
    If[ positions === { },
      Prepend[ pieces, itemOpened[ entryCell[ Cell[ "", "Text" ], marker ], marker, "" ] ],
      first = First[ positions ];
      Drop[
        MapAt[ itemOpened[ entryCell[ #, marker ], marker, joinMarks @ Take[ pieces, first - 1 ] ] &,
          pieces, first ],
        first - 1 ] ]
  ]

(* The dingbat is referenceLabel's [key], as it is for a .bib entry, so an entry and the citation
   pointing at it read alike; the printed label of a \bibitem[label]{key} rides in the marker for the
   return trip rather than being shown, because showing it would make the two disagree. The tag is
   therefore a mirror of the key stored in the marker, not the origin of a \label — cellTrailing must
   not write it back, or every entry exports a \label it never had. *)
entryCell[ Cell[ content_, "Text", options___ ], marker_String ] :=
  With[ { key = bibitemKey[ marker ] },
    Cell[ content, "Reference", CellTags -> key, Sequence @@ referenceDingbat[ key ], options ] ]

entryCell[ cell_Cell, _String ] :=
  cell

bibitemMarkerLength[ rest_String ] :=
  First[
    StringCases[ rest,
      StartOfString ~~
        marker : ( ( ( "[" ~~ Except[ "]" ] ... ~~ "]" ) | "" ) ~~ "{" ~~ Except[ "}" ] .. ~~ "}" ) :>
          StringLength[ marker ], 1 ],
    0 ]

bibitemKey[ marker_String ] :=
  First[ StringCases[ marker, "{" ~~ key : Except[ "}" ] .. ~~ "}" ~~ EndOfString :> key, 1 ], "" ]

(* Writing a bibliography the notebook did not import, which is the other direction of everything
   above and needs the same two strings. An entry added by hand has to arrive inside a
   thebibliography whether or not one exists yet, so there are three cases and they differ over
   where the delimiters are: a notebook with no Reference cell at all gets the anchor heading and a
   first entry carrying BOTH delimiters; a thebibliography paper gets the entry appended with the
   \end MOVED onto it, since the closing delimiter rides on whichever cell is last and appending
   without moving it emits the new entry after the \end; and a .bib paper's entry is suppressed and
   goes BEFORE the last cell, which carries the \bibliography commands verbatim and must stay last.
   Positions are taken with Position at any depth rather than over notebookCellList, so an inserted
   entry does not cost the document its CellGroupData. *)
insertReferenceCells[ Notebook[ cells_List, options___ ], tag_String ] :=
  Notebook[
    Replace[ Position[ cells, Cell[ _, "Reference", ___ ] ], {
      { } :> Join[ cells,
        { bibliographyAnchorCell[ ], openedBibliographyCell[ referenceEntryCell[ tag ], tag ] } ],
      positions_ :> appendedReferenceCell[ cells, Last[ positions ], tag ] } ],
    options ]

appendedReferenceCell[ cells_List, position_List, tag_String ] :=
  With[ { last = Extract[ cells, position ] },
    If[ cellTagging[ last, "BibliographyTeX" ] =!= "",
      Insert[ cells, retagged[ referenceEntryCell[ tag ], <| "Suppressed" -> "True" |> ], position ],
      Insert[
        ReplacePart[ cells, position -> retagged[ last, <| "EnvironmentClose" -> "" |> ] ],
        retagged[ referenceEntryCell[ tag ],
          <| "EnvironmentOpen" -> bibitemMarker[ tag ],
            "EnvironmentClose" -> cellTagging[ last, "EnvironmentClose" ] |> ],
        Append[ Most[ position ], Last[ position ] + 1 ] ] ] ]

bibitemMarker[ tag_String ] :=
  "\\bibitem{" <> tag <> "}\n"

openedBibliographyCell[ cell_Cell, tag_String ] :=
  retagged[ cell, <|
    "Environment" -> "thebibliography",
    "EnvironmentOpen" -> "\\begin{thebibliography}{99}\n\n" <> bibitemMarker[ tag ],
    "EnvironmentClose" -> "\n\n\\end{thebibliography}" |> ]

referenceEntryCell[ tag_String ] :=
  Cell[ "", "Reference", CellTags -> tag, Sequence @@ referenceDingbat[ tag ] ]

(* The heading a bibliography starts at, created once — by the first InsertReference into a notebook
   that has none — and every one of its three options is load-bearing. CounterIncrements -> { }
   because thebibliography prints an UNNUMBERED heading, and a plain Section would read "6
   References" in the notebook where the compiled paper has no number there at all. "Suppressed"
   because thebibliography prints that heading itself, so a cell emitting one too would put
   References in the PDF twice. And the tag, which is how SortBibliography finds where the block
   begins. Its CellTags is therefore a marker and not a \label — which costs nothing, since a
   suppressed cell reaches no exporter to write one. *)
bibliographyAnchorCell[ ] :=
  Cell[ "References", "Section", CellTags -> $bibliographyAnchorTag, CounterIncrements -> { },
    TaggingRules -> <| "MathNotebook" -> <| "Suppressed" -> "True" |> |> ]

$bibliographyAnchorTag = "MathNotebookBibliography"

(* T5. Reordering the block, which is three moving parts and only one of them travels with a cell.
   POSITIONAL: the \begin{thebibliography} prefix, which belongs to whichever entry is first; the
   \end, which belongs to whichever is last; and the recorded whitespace after each entry, which
   describes the gap at a place in the source rather than anything about the entry that happens to
   sit before it. TRAVELLING: the cell's own \bibitem marker, its text, its tag and its dingbat.
   Get that split wrong and the round trip still succeeds — the export is a StringJoin either way —
   it just emits a \begin in the middle of the list, which is why the test reads the delimiters off
   the reordered cells rather than asserting that the source comes back.

   A .bib paper is the exception at both ends: its entries are not the source, and its LAST cell
   carries the \bibliography commands verbatim, so that one is pinned and the rest sort around it. *)
sortBibliographyCells[ Notebook[ cells_List, options___ ], method_String ] :=
  With[ { positions = Position[ cells, Cell[ _, "Reference", ___ ] ] },
    Notebook[
      If[ Length[ positions ] < 2,
        cells,
        ReplacePart[ cells,
          MapThread[ Rule,
            { positions,
              sortedBibliographyEntries[ Notebook[ cells, options ],
                Map[ Extract[ cells, # ] &, positions ], method ] } ] ] ],
      options ] ]

sortedBibliographyEntries[ notebook_, entries_List, method_String ] :=
  If[ cellTagging[ Last @ entries, "BibliographyTeX" ] =!= "",
    Append[ Most[ entries ][[ bibliographyOrder[ notebook, Most @ entries, method ] ]], Last @ entries ],
    rehungBibliography[ entries, bibliographyOrder[ notebook, entries, method ] ] ]

rehungBibliography[ entries_List, order_List ] :=
  With[ { opening = bibliographyOpening @ First @ entries },
    MapThread[
      { cell, closing, separator, index } |->
        retagged[ cell, <|
          "EnvironmentOpen" -> If[ index === 1, opening, "" ] <> bibitemMarkerOf[ cell, opening ],
          "EnvironmentClose" -> closing,
          "Separator" -> separator |> ],
      { entries[[ order ]],
        Map[ cellTagging[ #, "EnvironmentClose" ] &, entries ],
        Map[ cellTagging[ #, "Separator" ] &, entries ],
        Range @ Length @ entries } ] ]

(* The first entry's stored opening is \begin{thebibliography}{99} and its own \bibitem run
   together in one string — environmentOpened composes them rather than keeping two keys — so the
   two are told apart at the LAST \bibitem in it. *)
bibliographyOpening[ cell_Cell ] :=
  With[ { stored = cellTagging[ cell, "EnvironmentOpen" ] },
    Replace[ StringPosition[ stored, "\\bibitem" ], {
      { ___, { start_Integer, _ } } :> StringTake[ stored, start - 1 ],
      _ :> stored } ] ]

bibitemMarkerOf[ cell_Cell, opening_String ] :=
  With[ { stored = cellTagging[ cell, "EnvironmentOpen" ] },
    If[ opening =!= "" && StringStartsQ[ stored, opening ],
      StringDrop[ stored, StringLength @ opening ],
      stored ] ]

(* Ordering rather than Sort, and every key is paired with the entry's current index so that a tie
   keeps document order instead of depending on whether the sort happens to be stable. *)
bibliographyOrder[ notebook_, entries_List, method_String ] :=
  Ordering @ Transpose @
    { bibliographySortKeys[ notebook, entries, method ], Range @ Length @ entries }

bibliographySortKeys[ notebook_, entries_List, "FirstUse" ] :=
  With[ { cited = citedTags[ notebook ] },
    Map[ cell |-> Replace[ FirstPosition[ cited, referenceKey[ cell ] ],
        { { n_Integer } :> n, _ :> Length[ cited ] + 1 } ],
      entries ] ]

bibliographySortKeys[ _, entries_List, "Key" ] :=
  Map[ ToLowerCase @ referenceKey[ # ] &, entries ]

bibliographySortKeys[ _, entries_List, "Entry" ] :=
  Map[ ToLowerCase @ referenceText[ # ] &, entries ]

$bibliographySortMethods = { "FirstUse", "Key", "Entry", "Uncited" }

referenceKey[ cell_Cell ] :=
  First[ Cases[ Flatten @ { Cases[ cell, ( CellTags -> tags_ ) :> tags, { 1 } ] }, _String ], "" ]

referenceText[ Cell[ content_, ___ ] ] :=
  StringJoin @ Cases[ { content }, _String, Infinity ]

(* Document order, and DeleteDuplicates keeps the FIRST use of each key — which is the whole of what
   unsrt means. A reopened notebook has split every ButtonBox into one per run, so the same key
   arrives many times over and is collapsed here rather than needing mergedButtons first. *)
citedTags[ notebook_ ] :=
  DeleteDuplicates @ Cases[ notebook,
    box : ButtonBox[ ___, BaseStyle -> "Citation", ___ ] :> buttonKey[ box ], Infinity ]

(* What a sort cannot fix and an author still wants to know: entries nothing points at, and
   citations pointing at no cell in the document. The second is deliberately measured against EVERY
   tag rather than against the bibliography's, since a \ref to a theorem is a Citation button too
   and is not a dangling reference. *)
bibliographyAudit[ notebook_ ] :=
  With[ {
      keys = Map[ referenceKey, Cases[ notebook, Cell[ _, "Reference", ___ ], Infinity ] ],
      tags = Cases[ Flatten @ Cases[ notebook, ( CellTags -> tags_ ) :> tags, Infinity ], _String ],
      cited = citedTags[ notebook ] },
    <| "Uncited" -> Sort @ DeleteCases[ Complement[ keys, cited ], "" ],
      "Dangling" -> Sort @ Complement[ cited, tags ] |> ]

(* Whether the entries belong to a .bib rather than to the notebook, which decides whether an entry
   added here can ever reach the .tex. The tell is the block's last cell carrying the \bibliography
   commands verbatim. *)
bibliographyDatabaseQ[ notebook_Notebook ] :=
  AnyTrue[ Cases[ notebook, Cell[ _, "Reference", ___ ], Infinity ],
    cellTagging[ #, "BibliographyTeX" ] =!= "" & ]

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

(* A declared .bib that is not on disk is the one gap in this converter that looks like nothing at
   all: the paper simply comes back with no Reference cells, its citations still reading as their
   keys, and the round trip is exact either way — the specimen hodgepaper declares \jobname.bib and
   ships without it. So it is reported rather than passed over, which is the Spec's "say what it
   could not handle". *)
bibliographyEntries[ source_String, file_String ] :=
  With[ { declared = DeleteDuplicates @ bibliographyFiles[ source, file ] },
    Scan[ Message[ ImportLaTeXDocument::nobib, #, FileNameTake[ file ] ] &,
      Select[ declared, ! FileExistsQ[ # ] & ] ];
    Association @ Map[ Normal @ bibliographyDatabase @ Import[ #, "Text" ] &,
      Select[ declared, FileExistsQ ] ] ]

ImportLaTeXDocument::nobib =
  "The bibliography file `1` declared by `2` was not found: its entries are not imported, and a \
citation to one of them reads as its key.";

bibliographyFiles[ source_String, file_String ] :=
  Map[ bibliographyFile[ #, DirectoryName @ AbsoluteFileName @ file, FileBaseName @ file ] &,
    bibliographyNames[ source ] ]

(* The names alone, with no directory and no file on disk: the export side needs them for a document
   whose .tex has not been written yet, so the pattern lives here and both sides read it. *)
bibliographyNames[ source_String ] :=
  Flatten @ StringCases[ source,
    StartOfLine ~~ ( " " | "\t" ) ... ~~ ( "\\bibliography{" | "\\addbibresource{" ) ~~
      names : Except[ "}" ] .. ~~ "}" :> StringTrim /@ StringSplit[ names, "," ] ]

bibliographyFile[ name_String, directory_String, jobName_String ] :=
  FileNameJoin @ { directory,
    StringReplace[ name, "\\jobname" -> jobName ] <>
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

(* A paragraph that prints nothing produces no cell: it becomes a separatorMark holding its own
   source verbatim, which is why this needs no export clause at all — the "Separator" tagging rule
   already carries arbitrary source, joinMarks concatenates it into the preceding cell's trailing
   whitespace, and a body-initial one lands in "BodyPrefix". \maketitle, \sloppy, \tableofcontents
   and a comment-only paragraph are the specimens' cases; they are invisible and uneditable in the
   notebook, which is the display Pavel chose over keeping them editable. *)
textPieces[ chunk_String ] :=
  With[ { core = StringTrim[ chunk ] },
    If[ core === "" || carriedSourceQ[ core ],
      { separatorMark[ chunk ] },
      { separatorMark @ First[ StringCases[ chunk, StartOfString ~~ space : WhitespaceCharacter .. :> space, 1 ], "" ],
        Cell[ inlineContent[ core ], "Text" ],
        separatorMark @ First[ StringCases[ chunk, space : WhitespaceCharacter .. ~~ EndOfString :> space, 1 ], "" ] } ] ]

(* ---- The TeX character escapes (FirstReadingDefects T2) ----------------------------------------
   \&, \%, \_, \#, \$ unescape into displayed text on import and re-escape on export, but a blanket
   inverse is impossible: the importer deliberately leaves raw TeX in displayed text — a comment
   line, a failed math span, a whole table glued to its paragraph by a line-continuation % — and
   raw TeX is full of the same five characters (hodgepaper displays 49 bare %s, a #1 macro
   parameter and a failed equation carrying _). So both directions scan a run with the SAME
   segmentation, rawSegments, and touch only the plain segments; the two cannot disagree, and a
   raw-TeX span goes back out verbatim. Three deliberate corners, each measured absent from the
   corpus and each still byte-exact on the round trip: a # adjacent to a digit is never touched
   (that shape is a macro parameter), a % is only a percent when strictly mid-line (line-initial
   and line-final %s are comments and continuations — measured 39 and 10 in hodgepaper, and 0
   mid-line), and every rule list opens with identity rules for the escaped forms so a \& the
   unescape left behind is never double-escaped. *)

(* U+F8FF, private use: \$ has to vanish before splitInlineMath reads its $ as a math delimiter,
   and a sentinel is the only rewrite that survives the split — the T1 pattern. The identity rule
   keeps \\$ (a line break, then a dollar) out of the mask. *)
$dollarSentinel = FromCharacterCode[ 63743 ]

dollarMasked[ text_String ] :=
  StringReplace[ text, { "\\\\" -> "\\\\", "\\$" -> $dollarSentinel } ]

(* One regex, shared by both directions: a complete environment (back-reference, so a nested
   \end{gathered} cannot close a \begin{equation}), a failed display or inline span still wearing
   its dollars, a comment line (line-initial or run-initial %), and the line-continuation %. *)
(* The environment back-reference is a NAMED group: binding the whole regex to a pattern variable
   wraps it in a group of its own, renumbering \1 out from under a numeric back-reference. *)
$rawTeXSpan = RegularExpression @ StringJoin[
  "(?s)\\\\begin\\{(?P<mnenv>[^}]*)\\}.*?\\\\end\\{(?P=mnenv)\\}",
  "|\\$\\$.+?\\$\\$",
  "|(?<!\\\\)\\$[^$]+(?<!\\\\)\\$",
  "|(?:(?<=\n)|^)%[^\n]*",
  "|%(?=\n|$)" ]

rawSegments[ run_String ] :=
  StringSplit[ run, span : $rawTeXSpan :> rawSpan[ span ] ]

$unescapeRules = {
  "\\\\" -> "\\\\",
  "\\&" -> "&",
  "\\_" -> "_",
  RegularExpression[ "\\\\#(?![0-9])" ] -> "#",
  RegularExpression[ "(?<=[^\n])\\\\%(?=[^\n])" ] -> "%",
  $dollarSentinel -> "$" }

$escapeRules = {
  "\\\\" -> "\\\\",
  "\\&" -> "\\&", "\\%" -> "\\%", "\\_" -> "\\_", "\\#" -> "\\#", "\\$" -> "\\$",
  "&" -> "\\&",
  "_" -> "\\_",
  "$" -> "\\$",
  RegularExpression[ "#(?![0-9])" ] -> "\\#",
  RegularExpression[ "(?<=[^\n])%(?=[^\n])" ] -> "\\%" }

unescapedRun[ run_String ] :=
  StringJoin @ Replace[ rawSegments[ run ],
    { plain_String :> StringReplace[ plain, $unescapeRules ],
      rawSpan[ span_String ] :> StringReplace[ span, $dollarSentinel -> "\\$" ] },
    { 1 } ]

escapedRun[ run_String ] :=
  StringJoin @ Replace[ rawSegments[ run ],
    { plain_String :> StringReplace[ plain, $escapeRules ],
      rawSpan[ span_String ] :> span },
    { 1 } ]

(* A \$ inside a math span rides the mask into the island: its SourceTeX must give the escape
   back or the export writes a private-use character into the .tex. The With-condition idiom
   forces the replacement string to evaluate before insertion, so a held box takes a plain
   string rather than an unevaluated call. *)
dollarRestoredPart[ part_String ] :=
  part

dollarRestoredPart[ part_ ] :=
  If[ FreeQ[ part, s_String /; StringContainsQ[ s, $dollarSentinel ] ],
    part,
    part /. s_String /; StringContainsQ[ s, $dollarSentinel ] :>
      With[ { restored = StringReplace[ s, $dollarSentinel -> "\\$" ] }, restored /; True ] ]

(* StringSplit of the empty string is {} and not {""}, so an empty environment body — or an empty
   section title — would otherwise become TextData[{}], which no exporter reads back as text. *)
inlineContent[ text_String ] :=
  Replace[ inlineParts[ text ],
    { { unchanged_String } :> unchanged, { } :> text, parts_List :> TextData[ parts ] } ]

(* Font commands split before inline math because their argument may hold a math span whole
   (\emph{degree $n$}); the argument recurses through the same pipeline, so math and nested
   commands inside a styled run come out converted too. The escapes unescape on the final plain
   runs, after every splitter has taken its pieces, so a ButtonData key and a SourceTeX mirror
   stay verbatim. *)
inlineParts[ text_String ] :=
  mergeStrings @ Map[ dollarRestoredPart,
    Flatten @ Replace[ fontSplit @ dollarMasked[ text ],
      part_String :> Replace[ splitInlineMath[ part ],
        piece_String :> Replace[ citationSplit[ piece ], run_String :> unescapedRun[ run ], { 1 } ],
        { 1 } ],
      { 1 } ] ]

$fontCommands = <|
  "textbf" -> { FontWeight -> "Bold" },
  "textit" -> { "TextItalic", FontSlant -> "Italic" },
  "emph" -> { FontSlant -> "Italic" } |>

fontSplit[ text_String ] :=
  StringSplit[ text,
    "\\" ~~ command : ( "textbf" | "textit" | "emph" ) ~~ "{" ~~ body : $braceBody ~~ "}" :>
      fontBox[ command, body ] ]

(* A plain run rides in the front end's native StyleBox; a run holding math or a nested command has
   to be an inline Cell instead — a saved and reopened StyleBox with list content is split into one
   run per part with the math cell escaping the style (measured), where the Cell island comes back
   identical. \textit is told apart from \emph by the style name, which survives the reopen too. *)
fontBox[ command_String, "" ] :=
  "\\" <> command <> "{}"

fontBox[ command_String, body_String ] :=
  Replace[ inlineParts[ body ],
    { { one_String } :> StyleBox[ one, Sequence @@ $fontCommands[ command ] ],
      parts_List :> Cell[ TextData[ parts ], Sequence @@ $fontCommands[ command ] ] } ]

(* One pattern for what a citation is, used both to split the prose and to decide which .bib entries
   the paper cites, so the two halves cannot disagree. *)
$citation =
  "\\cite" ~~ optional : ( "[" ~~ Except[ "]" ] ... ~~ "]" ) | "" ~~ "{" ~~ keys : Except[ "}" ] .. ~~ "}"

citationSplit[ text_String ] :=
  StringSplit[ text, $citation :> citationBox[ optional, keys ] ]

(* \cite becomes a Citation button labelled with the key in brackets — referenceLabel's rendering, so
   a citation reads exactly as the dingbat of the entry it points at. Unlike \ref this is
   unconditional: the label is literal text and is right even in a paper with no bibliography, where
   a CounterBox would render the front end's XXX. A single key rides verbatim as the ButtonData,
   which is both what NotebookLocate navigates by and what the exporter writes back; the optional
   argument is the item before the closing bracket.
   A compound \cite{a, b} is one button PER key — a compound ButtonData resolves to no cell, so the
   click silently did nothing (FirstReadingDefects T3) — with the display separators as literal ", "
   text between the buttons. Each member's ButtonData is its own trimmed key, and the command's bytes
   ride in ButtonNote: the opener carries "\cite[opt]{" up through its raw key, each continuation its
   "," plus raw key, so recomposedCitations can put the one command back byte for byte however the
   source spaced its keys — and a member whose neighbours are deleted still exports alone. ButtonNote
   is measured to survive a save exactly as ButtonData does: the reopen-split copies it onto every
   fragment, and mergedButtons keeps the first fragment's. The one compound that cannot recompose
   from splits — a key list StringSplit does not reconstruct, such as a trailing comma's empty key —
   keeps the old single-button shape rather than trading the round trip for the click. *)
citationBox[ optional_String, keys_String ] :=
  With[ { raws = StringSplit[ keys, "," ] },
    If[ Length[ raws ] > 1 && StringRiffle[ raws, "," ] === keys,
      Riffle[ MapIndexed[ citationKeyButton[ #1, First[ #2 ], Length[ raws ], optional ] &, raws ], ", " ],
      ButtonBox[
        RowBox @ Flatten @ { "[", Riffle[ StringTrim /@ raws, ", " ],
          If[ optional === "", { }, { ", ", StringTake[ optional, { 2, -2 } ] } ], "]" },
        BaseStyle -> "Citation", ButtonData -> keys ] ] ]

citationKeyButton[ raw_String, index_Integer, count_Integer, optional_String ] :=
  ButtonBox[
    RowBox @ Flatten @ { "[", StringTrim[ raw ],
      If[ index === count && optional =!= "", { ", ", StringTake[ optional, { 2, -2 } ] }, { } ], "]" },
    BaseStyle -> "Citation", ButtonData -> StringTrim[ raw ],
    ButtonNote -> If[ index === 1, "\\cite" <> optional <> "{" <> raw, "," <> raw ] ]

(* What referenceTeX writes back for a citation button carrying no recomposition run: the ButtonData
   verbatim, with the optional argument read off the label — how many keys there are is what tells
   \cite{a, b} from \cite[note]{a}. A pre-split compound button — a notebook saved before the keys
   were split — still exports through this clause byte-exact, its click as dead as it always was. *)
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

(* What a \ref to a cell has to print is exactly what that cell's own number prints, so the chain is
   read off the cell rather than looked up from its style: a definition numbered per subsection carries
   Section, Subsection and its own counter in its dingbat, and the reference is those same three boxes
   resolved at the tag instead of at the reference's own position. A cell carrying no number of its own
   — which is most of them — falls back to the style's spec in Referencing.wl. *)
labelCounters[ cells_List ] :=
  Association @ Cases[ cells,
    cell : Cell[ _, style_String, ___, CellTags -> key_String, ___ ] :> key -> cellCounterBoxes[ cell, style ] ]

cellCounterBoxes[ cell : Cell[ _, "DisplayFormula" | "DisplayFormulaNumbered", ___ ], style_String ] :=
  counterBoxChain[ FirstCase[ cell, ( CellFrameLabels -> value_ ) :> value, None ], style ]

cellCounterBoxes[ cell_Cell, style_String ] :=
  counterBoxChain[ FirstCase[ cell, ( CellDingbat -> value_ ) :> value, None ], style ]

counterBoxChain[ value_, style_String ] :=
  Replace[ Cases[ value, _CounterBox, Infinity ],
    { { } :> Map[ CounterBox, referenceCounters[ style ] ], boxes_List :> boxes } ]

(* A counter the sheets reset at the wrong level is reset on the first cell that increments it after each
   resetting cell, which is the shape T8 already uses for a list rather than a per-cell option on the
   sectioning cell: a theorem style declares no CounterAssignments of its own where a Section style
   declares three, and the front end has no way to add to a style's list — writing one on the cell would
   replace it and quietly stop resetting Subsection, Subsubsection and Theorem. An equation numbered
   within the section needs the same reset plus a CellFrameLabels of its own, because that is where its
   number lives and not in a dingbat. *)
numberedCells[ cells_List, numbering_Association, equation_Association ] :=
  Module[ { resets = counterResets[ numbering, equation ], pending = { } },
    Map[
      cell |->
        With[ { assignments = Cases[ resets,
              { counter_, _ } /; MemberQ[ pending, counter ] && incrementsQ[ cell, counter ] :> { counter, 0 } ] },
          pending = Union[
            Complement[ pending, Map[ First, assignments ] ],
            Cases[ resets, { counter_, cellStyle[ cell ] } :> counter ] ];
          numberedCell[ cell, assignments, equation ] ],
      cells ] ]

counterResets[ numbering_Association, equation_Association ] :=
  DeleteDuplicates @ Join[
    Cases[ Values[ numbering ],
      spec_ /; ! TrueQ[ spec[ "Default" ] ] && TrueQ[ spec[ "Numbered" ] ] && spec[ "Reset" ] =!= None :>
        { spec[ "Counter" ], spec[ "Reset" ] } ],
    If[ equation[ "Reset" ] === None, { }, { { "DisplayFormulaNumbered", equation[ "Reset" ] } } ] ]

(* A cell increments what its own CounterIncrements says, and a cell that says nothing increments its
   style's counter — which for DisplayFormulaNumbered is its own name. *)
incrementsQ[ cell : Cell[ _, style_String, ___ ], counter_String ] :=
  Replace[ FirstCase[ cell, ( CounterIncrements -> counters_ ) :> Flatten @ { counters } ],
    { counters_List :> MemberQ[ counters, counter ], _ :> style === counter } ]

incrementsQ[ _, _ ] :=
  False

cellStyle[ Cell[ _, style_String, ___ ] ] :=
  style

cellStyle[ _ ] :=
  None

numberedCell[ cell : Cell[ content_, style_, options___ ], assignments_List, equation_Association ] :=
  With[ {
      existing = FirstCase[ cell, ( CounterAssignments -> value_ ) :> value, { } ],
      labels = If[ style === "DisplayFormulaNumbered" && equation[ "Prefix" ] =!= { } &&
          incrementsQ[ cell, "DisplayFormulaNumbered" ],
        { CellFrameLabels -> equationFrameLabels @ equation[ "Prefix" ] }, { } ] },
    If[ assignments === { } && labels === { },
      cell,
      Cell[ content, style,
        Sequence @@ labels,
        Sequence @@ If[ assignments === { }, { },
          { CounterAssignments -> Join[ existing, assignments ] } ],
        Sequence @@ DeleteCases[ { options },
          Alternatives @@ Join[
            If[ assignments === { }, { }, { CounterAssignments -> _ } ],
            If[ labels === { }, { }, { CellFrameLabels -> _ } ] ] ] ] ] ]

numberedCell[ cell_, _, _ ] :=
  cell

equationFrameLabels[ prefix_List ] :=
  { { None,
      Cell[
        TextData @ Flatten @ { "(",
          Riffle[ Map[ CounterBox, Append[ prefix, "DisplayFormulaNumbered" ] ], "." ], ")" },
        "DisplayFormulaEquationNumber" ] },
    { None, None } }

(* \ref and \eqref become the front end's own cross-reference: a CounterBox chain resolved at the
   labelled cell, so the number follows the target when cells move and is right in the PDF with no
   kernel. \ref is the bare number and \eqref parenthesises it, exactly as LaTeX prints them —
   authors write "Theorem~\ref{...}", so a prefix would say the word twice. A key no converted cell
   carries — the specimen paper's four figure labels — is left as source. *)
referenceCell[ Cell[ content_, style_, options___ ], labels_Association ] :=
  Cell[ referenceContent[ content, labels ], style, options ]

referenceContent[ text_String, labels_Association ] :=
  Replace[ referenceSplit[ text, labels ],
    { { one_String } :> one, { } :> text, parts_List :> TextData[ parts ] } ]

referenceContent[ TextData[ parts_ ], labels_Association ] :=
  TextData[ mergeStrings @ Flatten @ Replace[ Flatten @ { parts }, text_String :> referenceSplit[ text, labels ], { 1 } ] ]

referenceContent[ content_, _Association ] :=
  content

(* A \ref inside a failed inline span must stay in the span: splitting it into a button strands the
   span's two dollars in separate runs, where the T2 export escape reads each as a loose \$-dollar
   and the round trip breaks. The span is exactly the text a $-pair still delimits — converted
   mathematics is an island by now — so it is matched with the same pattern rawSegments uses. *)
referenceSplit[ text_String, labels_Association ] :=
  mergeStrings @ Flatten @ Replace[
    StringSplit[ text, span : RegularExpression[ "(?s)(?<!\\\\)\\$[^$]+(?<!\\\\)\\$" ] :> rawSpan[ span ] ],
    { rawSpan[ span_String ] :> span,
      plain_String :>
        StringSplit[ plain,
          command : ( "\\eqref" | "\\ref" ) ~~ "{" ~~ key : Except[ "}" ] .. ~~ "}" :>
            referenceBox[ command, key, Lookup[ labels, key, None ] ] ] },
    { 1 } ]

referenceBox[ command_String, key_String, counters_List ] :=
  ButtonBox[
    RowBox @ Join[ If[ command === "\\eqref", { "(" }, { } ],
      Riffle[ Map[ Insert[ #, key, 2 ] &, counters ], "." ],
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

(* The style name lowercased is the command, which is what commandRules matched, so the six styles
   whose whole content is a braced argument share one clause.
   A stored "CommandTeX" is the whole argument, carried verbatim because the cell shows something
   else (the Author block); a "CommandPrefix" is a leading run of layout commands with the cell still
   owning the rest. One clause reads both rather than two clauses differing by a condition, which WL
   is free to order either way. *)
cellToLaTeX[ cell : Cell[ _, "Section" | "Subsection" | "Subsubsection" | "Title" | "Author" | "Date", ___ ] ] :=
  cellTagging[ cell, "Indent" ] <> "\\" <> ToLowerCase[ cell[[ 2 ]] ] <> "{" <>
    Replace[ cellTagging[ cell, "CommandTeX" ],
      "" :> cellTagging[ cell, "CommandPrefix" ] <> cellTeXText[ cell ] ] <> "}" <>
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

(* The two halves of an environment wrapper. A cell can carry both — a one-cell environment, or a
   nested one whose body is a single cell — and a cell in the middle of a body carries neither and
   simply writes itself out. *)
cellToLaTeX[ cell_Cell ] /; cellTagging[ cell, "EnvironmentOpen" ] =!= "" :=
  cellTagging[ cell, "EnvironmentOpen" ] <> cellTrailing[ cell ] <> cellTagging[ cell, "BodyIndent" ] <>
    cellBodyLaTeX[ cell ] <> cellTagging[ cell, "EnvironmentClose" ]

cellToLaTeX[ cell_Cell ] /; cellTagging[ cell, "EnvironmentClose" ] =!= "" :=
  cellBodyLaTeX[ cell ] <> cellTagging[ cell, "EnvironmentClose" ]

cellToLaTeX[ cell_Cell ] :=
  cellBodyLaTeX[ cell ]

cellBodyLaTeX[ cell_Cell ] :=
  Replace[ convertMathCell @ referencesToTeX @ escapedTextCell[ cell ],
    { Cell[ text_String, ___ ] :> text, other_ :> ToString[ other, InputForm ] } ]

(* The export half of the T2 escape pair, applied to displayed text only — before referencesToTeX,
   because that pass turns every ButtonBox into a command string (\cite{a_key}) whose underscore is
   not prose. A BoxData island re-exports from its SourceTeX mirror and a ButtonBox from its
   ButtonData, so both pass through untouched; a font run is displayed text and recurses. *)
escapedTextCell[ Cell[ text_String, rest___ ] ] :=
  Cell[ escapedRun @ text, rest ]

escapedTextCell[ Cell[ TextData[ parts_ ], rest___ ] ] :=
  Cell[ TextData @ escapedTextParts @ Flatten @ { parts }, rest ]

escapedTextCell[ cell_ ] :=
  cell

escapedTextParts[ parts_List ] :=
  Map[ escapedTextPart, parts ]

escapedTextPart[ text_String ] :=
  escapedRun[ text ]

escapedTextPart[ StyleBox[ text_String, rest___ ] ] :=
  StyleBox[ escapedRun @ text, rest ]

escapedTextPart[ StyleBox[ TextData[ parts_ ], rest___ ] ] :=
  StyleBox[ TextData @ escapedTextParts @ Flatten @ { parts }, rest ]

escapedTextPart[ StyleBox[ parts_List, rest___ ] ] :=
  StyleBox[ escapedTextParts @ parts, rest ]

escapedTextPart[ Cell[ TextData[ parts_ ], rest___ ] ] :=
  Cell[ TextData @ escapedTextParts @ Flatten @ { parts }, rest ]

escapedTextPart[ part_ ] :=
  part

(* A display formula's tag is a mirror of the \label already inside its stored source, not the
   origin of one, so writing it back out again would emit the label twice — which is what happens
   the moment such a cell is the first of an environment body and carries the \begin. A Reference
   cell's tag is the same kind of mirror, of the key inside its \bibitem or of the .bib entry it
   came from, and neither is a \label at all. *)
cellTrailing[ cell : Cell[ _, "DisplayFormula" | "DisplayFormulaNumbered" | "Reference", ___ ] ] :=
  cellTagging[ cell, "Trailing" ] <> cellTagging[ cell, "TrailingAfter" ]

cellTrailing[ cell_Cell ] :=
  cellTagging[ cell, "Trailing" ] <>
    Replace[ Cases[ cell, ( CellTags -> key_String ) :> "\\label{" <> key <> "}" ], { { label_ } :> label, _ :> "" } ] <>
    cellTagging[ cell, "TrailingAfter" ]

cellTeXText[ cell : Cell[ content_, ___ ] ] :=
  Replace[ convertMathCell @ referencesToTeX @ escapedTextCell @ Cell[ content, "Text" ],
    { Cell[ text_String, ___ ] :> text, _ :> "" } ]

(* The TextData pass is a levelled Replace rather than a ReplaceAll: ReplaceAll never descends into
   what it has replaced, so an inline island's own TextData — a citation inside \emph{...} — was
   reached by neither the merge nor the recomposition. Bottom-up, the island is processed before the
   run that holds it. *)
referencesToTeX[ Cell[ content_, rest___ ] ] :=
  Cell[ Replace[
      Replace[ content, TextData[ parts_List ] :> TextData @ recomposedCitations @ mergedButtons[ parts ],
        { 0, Infinity } ],
      box_ButtonBox :> referenceTeX[ box ], { 0, Infinity } ], rest ]

(* A compound's members go back to being the one command. The run is keyed on the ButtonNotes and
   never on the separators — the literal ", " between two members is indistinguishable from prose
   between two SEPARATE \cite commands, which must stay two commands — and the separators are
   dropped: they are display mirrors of the bytes the notes already carry. Folding is pairwise and
   leftmost-first, one continuation into its opener per pass, so however many keys the command had
   the fixed point is one opener holding the whole command's bytes; closedCitations then writes each
   opener out with its closing brace. An opener alone still closes over its own key, and an orphaned
   continuation falls through to referenceTeX's per-button \cite. *)
recomposedCitations[ parts_List ] :=
  closedCitations @ FixedPoint[ citationPairFold, parts ]

citationPairFold[ { before___, opener_ButtonBox ? citationOpenerQ, _String, cont_ButtonBox ? citationContinuationQ, after___ } ] :=
  { before, appendedCitation[ opener, cont ], after }

citationPairFold[ parts_List ] :=
  parts

appendedCitation[ ButtonBox[ label_, options___ ], cont_ButtonBox ] :=
  ButtonBox[ label,
    Sequence @@ Replace[ { options },
      ( ButtonNote -> note_String ) :> ( ButtonNote -> note <> citationNote[ cont ] ), { 1 } ] ]

closedCitations[ parts_List ] :=
  Replace[ parts, opener_ButtonBox ? citationOpenerQ :> citationNote[ opener ] <> "}", { 1 } ]

citationOpenerQ[ box_ ] :=
  StringStartsQ[ citationNote[ box ], "\\cite" ]

citationContinuationQ[ box_ ] :=
  StringStartsQ[ citationNote[ box ], "," ]

citationNote[ ButtonBox[ ___, ButtonNote -> note_String, ___ ] ] :=
  note

citationNote[ _ ] :=
  ""

(* Writing a notebook to disk and opening it again splits a ButtonBox[RowBox[...]] inside a TextData
   into one button per run — the same front-end behaviour NotebookWrite has — and it reaches every
   imported citation and cross-reference, so without this the round trip holds only for a notebook
   that was never saved. Measured: \cite{first, second} came back as five buttons and exported five
   \cite commands, and \eqref{eq:a} came back as three, the parentheses carried off into buttons of
   their own so that the counter no longer looked parenthesised and the brackets no longer looked
   like references at all — \cite{eq:a}\ref{eq:a}\cite{eq:a}. Consecutive buttons on one key are put
   back together before anything reads them; two adjacent citations to the same key, which no real
   paper writes, would merge into one. The merged button keeps the FIRST fragment's whole option
   sequence rather than restating BaseStyle and ButtonData: the split copies every option onto every
   fragment — ButtonNote among them, which is what recomposedCitations reads — so dropping the rest
   here would lose a compound's bytes on its first save. *)
mergedButtons[ parts_List ] :=
  Flatten @ Replace[ SplitBy[ parts, buttonKey ],
    run : { ButtonBox[ _, options___, ButtonData -> key_, rest___ ], __ } :>
      { ButtonBox[ RowBox @ Flatten @ Map[ buttonBoxes, run ], options, ButtonData -> key, rest ] },
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
