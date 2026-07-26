Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

(* The other test files are kernel-only and stub every chain read. This one is the opposite on
   purpose: both defects in ViewAndReferenceDefects passed their unit tests and still shipped
   broken, because "the call wrote an override cell" is not "the style changed size". Everything
   here is measured through a real front end and a real stylesheet chain, so the assertions are the
   reproductions Pavel reported rather than restatements of the code.

   The sheets are embedded with Get rather than named: a paclet stylesheet resolved by name has
   been seen to fall back to Default.nb in a headless run, so every measurement asserts the sheet
   really loaded before it is trusted. While a view override is installed, the private sheet's
   parent is an embedded notebook, and styles it does NOT override then fall through to Default.nb
   — harmless here because every style asserted is one the override writes. *)

$sheetDirectory = FileNameJoin[ { PacletObject[ "WolframInstitute/MathNotebook" ][ "Location" ],
  "FrontEnd", "StyleSheets", "MathNotebook" } ];

$templates = { "AMSArticle.nb", "ArXivArticle.nb", "RevTeXAPS.nb", "SpringerJournal.nb" };

resolvedSizes[ notebook_, styles_ ] := <|
  "Screen" -> AssociationMap[ CurrentValue[ notebook, { StyleDefinitions, #, FontSize } ] &, styles ],
  "Printout" -> AssociationMap[ CurrentValue[ notebook, { StyleDefinitions, { #, "Printout" }, FontSize } ] &, styles ]
|>

(* One front-end session measures every sheet; the tests below are pure comparisons on the result,
   so a front-end failure surfaces as a failed assertion rather than as a message storm. *)
viewMeasurements[ parent_ ] :=
  Module[ { notebook, prose, base, scaled, restored },
    notebook = CreateDocument[ { }, Visible -> False, StyleDefinitions -> parent ];
    prose = Complement[ Keys @ baseFontSizes[ parent ][ "Screen" ], $mathStyleNames ];
    base = resolvedSizes[ notebook, prose ];
    SetDocumentFontSize[ notebook, 20 ];
    scaled = resolvedSizes[ notebook, prose ];
    ResetDocumentView[ notebook ];
    restored = resolvedSizes[ notebook, prose ];
    NotebookClose[ notebook ];
    <| "Prose" -> prose, "Base" -> base, "Scaled" -> scaled, "Restored" -> restored |>
  ]

citationMeasurements[ parent_ ] :=
  Module[ { notebook, styles },
    notebook = NotebookPut @ Notebook[ {
      Cell[ "A section", "Section", CellTags -> "sec" ],
      Cell[ "A theorem", "Theorem", CellTags -> "thm" ],
      Cell[ "A definition", "Definition", CellTags -> "def" ],
      Cell[ "Ollivier, Ricci curvature", "Reference", CellTags -> "ollivier" ],
      Cell[ "Prose", "Text", CellTags -> "prose" ] },
      StyleDefinitions -> parent, Visible -> False ];
    styles = AssociationMap[
      Symbol[ "WolframInstitute`MathNotebook`Referencing`PackagePrivate`citationTargetStyle" ][ notebook, # ] &,
      { "sec", "thm", "def", "ollivier", "prose", "absent" } ];
    NotebookClose[ notebook ];
    styles
  ]

(* Inline Math Converter Defects, requirement 4: assert what a converted cell *displays*. The
   round trip reads back the stored "SourceTeX" rather than the boxes, so a cell that renders as a
   blank still exports byte-identically — display fidelity has to be measured on its own. Ink area
   is the measurement: a converted span carries less ink than the literal "$...$" it replaces (the
   two delimiters are gone) and more than an empty box. *)

inkArea[ cell_ ] :=
  Total @ Flatten @ Unitize @ Subtract[ 255,
    ImageData[ ColorConvert[ Rasterize[ cell, ImageResolution -> 72, LightDark -> "Light" ], "Grayscale" ], "Byte" ] ]

inlineInk[ text_String ] := <|
  "Converted" -> inkArea @ Cell[ TextData @ splitInlineMath[ text ], "Text" ],
  "Literal" -> inkArea @ Cell[ text, "Text" ],
  "Blank" -> inkArea @ Cell[ TextData @ { First @ StringSplit[ text, "$" ],
    Cell[ BoxData[ FormBox[ "", TraditionalForm ] ] ], Last @ StringSplit[ text, "$" ] }, "Text" ]
|>

$measured = UsingFrontEnd @ <|
  "InlineInk" -> AssociationMap[ inlineInk, { "A pair $(V, E)$ here.", "A list $x_1, x_2$ here." } ],
  "Sheets" -> AssociationMap[ viewMeasurements @ Get @ FileNameJoin[ { $sheetDirectory, # } ] &, $templates ],
  "Default" -> viewMeasurements[ "Default.nb" ],
  "SheetLoaded" -> AssociationMap[
    Module[ { notebook = CreateDocument[ { }, Visible -> False,
        StyleDefinitions -> Get @ FileNameJoin[ { $sheetDirectory, # } ] ], size },
      size = CurrentValue[ notebook, { StyleDefinitions, "Title", FontSize } ];
      NotebookClose[ notebook ];
      size ] &,
    $templates ],
  "Citations" -> citationMeasurements @ Get @ FileNameJoin[ { $sheetDirectory, "AMSArticle.nb" } ]
|>;

(* Nothing below is meaningful unless the template sheets actually loaded: Default.nb sizes Title
   at 45, every MathNotebook template at 26. *)
VerificationTest[
  Union @ Values @ $measured[ "SheetLoaded" ],
  { 26 }
]

(* The reported defect, literally: on every template, Theorem, Proof, Reference, Item and
   ItemNumbered stayed at their base size while Text moved. *)
VerificationTest[
  AssociationMap[
    Complement[ { "Theorem", "Proof", "Reference", "Item", "ItemNumbered" }, $measured[ "Sheets", #, "Prose" ] ] &,
    $templates ],
  AssociationMap[ { } &, $templates ]
]

VerificationTest[ (* Text lands exactly on the requested size, on screen and in print *)
  AssociationMap[ $measured[ "Sheets", #, "Scaled", "Screen", "Text" ] &, $templates ],
  AssociationMap[ 20 &, $templates ]
]

VerificationTest[ (* every prose style moved — screen AND "Printout", or the PDF is unchanged *)
  Union @ Flatten @ Table[
    With[ { m = $measured[ "Sheets", sheet ] },
      Table[ m[ "Scaled", environment, style ] > m[ "Base", environment, style ],
        { environment, { "Screen", "Printout" } }, { style, m[ "Prose" ] } ] ],
    { sheet, $templates } ],
  { True }
]

VerificationTest[ (* reset restores every base size exactly, not approximately *)
  AssociationMap[ $measured[ "Sheets", #, "Restored" ] === $measured[ "Sheets", #, "Base" ] &, $templates ],
  AssociationMap[ True &, $templates ]
]

(* A plain Default.nb document has no theorem environments; the control must still reach the prose
   it does have, and writing cells for absent styles must stay harmless. *)
VerificationTest[
  { $measured[ "Default", "Scaled", "Screen", "Text" ],
    SubsetQ[ $measured[ "Default", "Prose" ], { "Text", "Item", "ItemNumbered" } ],
    Union @ Table[ $measured[ "Default", "Scaled", "Screen", style ] > $measured[ "Default", "Base", "Screen", style ],
      { style, $measured[ "Default", "Prose" ] } ],
    $measured[ "Default", "Restored" ] === $measured[ "Default", "Base" ] },
  { 20, True, { True }, True }
]

(* T3: the style a citation renders from is resolved from the tag through the live notebook. *)
VerificationTest[
  $measured[ "Citations" ],
  <| "sec" -> "Section", "thm" -> "Theorem", "def" -> "Definition",
     "ollivier" -> "Reference", "prose" -> "Text", "absent" -> None |>
]

(* ... so a numbered environment cites by number and everything else keeps the tag. *)
VerificationTest[
  KeyValueMap[ FreeQ[ citationButton[ #1, #2 ], _CounterBox ] &, $measured[ "Citations" ] ],
  { False, False, False, True, True, True }
]

(* Inline Math Converter Defects T1: a comma-bearing span really renders as mathematics — visible
   ink, and the "$" delimiters gone. Blank < Converted < Literal on every specimen. *)
VerificationTest[
  Map[ #[ "Blank" ] < #[ "Converted" ] < #[ "Literal" ] &, $measured[ "InlineInk" ] ],
  AssociationMap[ True &, { "A pair $(V, E)$ here.", "A list $x_1, x_2$ here." } ]
]
