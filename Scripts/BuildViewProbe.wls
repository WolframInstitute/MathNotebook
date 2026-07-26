#!/usr/bin/env wolframscript

(* Builds Work/Active/PaletteUsability-T6.nb — a one-screen probe document holding every style
   the two Document view sliders touch, so a size change is visible at a glance and the styles
   that do NOT follow are equally visible. Regenerate rather than editing the .nb. *)

repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];

text[ string_ ] :=
  Cell[ string, "Text" ];

probeCells = {
  Cell[ "A Probe for the Document View Controls", "Title" ],
  Cell[ "MathNotebook", "Author" ],
  Cell[ "T6 — feedback round", "Date" ],
  Cell[ "Every style the two sliders are supposed to reach appears below exactly once, in the \
order the stylesheet declares them. Drag a slider and read down the page: a style that does not \
move is a defect. The text slider should move everything except the two displays and the equation \
number; the math slider should move only those three.", "Abstract" ],

  Cell[ "What to Check", "Section" ],
  text[ "These are the things no script can verify, because a headless front end has no window and \
nothing ever gets clicked. They are the whole reason this round runs by hand." ],
  Cell[ "Clicking a group header folds it, and the palette window refits to the new height \
immediately rather than on the next open.", "Item" ],
  Cell[ "Fold state comes back after quitting and reopening the front end.", "Item" ],
  Cell[ "Both sliders follow the focused document: click into another notebook and the readouts \
change to that document's sizes.", "Item" ],
  Cell[ "Releasing a slider actually applies the size \[Dash] dragging alone should not, and the \
release should.", "Item" ],
  Cell[ "Reset view returns this document to the sizes it has right now, with no trace left \
behind.", "Item" ],
  Cell[ "The palette is comfortable to keep open beside a paper you are actually writing.", "Item" ],

  Cell[ "Prose and Sectioning", "Section" ],
  text[ "Body text, the anchor of the text slider. This paragraph is deliberately long enough to \
wrap several times at every size in the slider's range, because the number of wrapped lines is the \
only honest read on whether a font size actually changed — the glyphs alone are easy to misjudge \
by eye." ],
  Cell[ "A Subsection", "Subsection" ],
  text[ "A second paragraph under a subsection, with inline mathematics \[Sum] \[Alpha] \[CenterDot] \
\[Beta] \[Element] \[DoubleStruckCapitalR] set in the body font, so prose and mathematics can be \
compared in one line." ],
  Cell[ "A Subsubsection", "Subsubsection" ],
  text[ "Prose under a subsubsection." ],

  Cell[ "Mathematics", "Section" ],
  text[ "An unnumbered display follows, then a numbered one. The equation number is its own style \
and has to grow with the mathematics, not with the prose." ],
  Cell[ BoxData[ RowBox[ {
      SubscriptBox[ "\[Integral]", "\[CapitalOmega]" ], "d", "\[Omega]", "=",
      SubscriptBox[ "\[Integral]", "\[PartialD]\[CapitalOmega]" ], "\[Omega]" } ] ],
    "DisplayFormula" ],
  Cell[ BoxData[ RowBox[ {
      SuperscriptBox[ "\[CapitalDelta]", "k" ], "=", "d", SuperscriptBox[ "d", "*" ], "+",
      SuperscriptBox[ "d", "*" ], "d" } ] ],
    "DisplayFormulaNumbered" ],

  Cell[ "Environments", "Section" ],
  Cell[ "A plain-class environment. It is declared to inherit from Text, so it carries no bare font \
size of its own and was one of the styles the text slider used to miss entirely.", "Theorem" ],
  Cell[ "The proof style, which inherits from Text in the same way. Both should now track the text \
slider; if either stays put, that is the session 6 fix regressing.", "Proof" ],
  Cell[ "A definition-class environment, upright rather than italic.", "Definition" ],
  Cell[ "A remark-class environment, with an italic dingbat.", "Remark" ],

  Cell[ "Lists", "Section" ],
  text[ "The three list styles come from Default.nb, not from LaTeXBase.nb." ],
  Cell[ "An item.", "Item" ],
  Cell[ "A numbered item.", "ItemNumbered" ],
  Cell[ "An item paragraph.", "ItemParagraph" ],

  Cell[ "References", "Section" ],
  Cell[ "Ollivier, Ricci curvature of Markov chains on metric spaces, \
https://arxiv.org/abs/0810.5625", "Reference" ],
  Cell[ "Forman, Bochner's method for cell complexes and combinatorial Ricci curvature, \
Discrete Comput. Geom. 29 (2003) 323\[Dash]374", "Reference" ]
};

Export[
  FileNameJoin[ { repoDirectory, "Work", "Active", "PaletteUsability-T6.nb" } ],
  Notebook[ probeCells,
    StyleDefinitions -> "MathNotebook/AMSArticle.nb",
    WindowSize -> { 900, 800 } ],
  "NB" ];

Print[ "Wrote Work/Active/PaletteUsability-T6.nb with ", Length @ probeCells, " cells." ];
