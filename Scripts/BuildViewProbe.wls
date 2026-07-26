#!/usr/bin/env wolframscript

(* Builds Work/Active/PaletteUsability-T6.nb — a one-screen probe document holding every style
   the three Document view controls touch, so a size or width change is visible at a glance and
   the styles that do NOT follow are equally visible. Regenerate rather than editing the .nb. *)

repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];

text[ string_ ] :=
  Cell[ string, "Text" ];

probeCells = {
  Cell[ "A Probe for the Document View Controls", "Title" ],
  Cell[ "MathNotebook", "Author" ],
  Cell[ "T6 — feedback round", "Date" ],
  Cell[ "Every style the three sliders are supposed to reach appears below exactly once, in the \
order the stylesheet declares them. Drag a slider and read down the page: a style that does not \
move is a defect, and the ones already known to stay put are named in the checklist.", "Abstract" ],

  Cell[ "Prose and Sectioning", "Section" ],
  text[ "Body text, the anchor of the text slider. This paragraph is deliberately long enough to \
wrap several times at every size in the slider's range, because the number of wrapped lines is the \
only honest read on whether a font size actually changed — the glyphs alone are easy to misjudge \
by eye, and the column width changes the count too." ],
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
  Cell[ "A plain-class environment. Its dingbat is drawn to the left of its own cell margin, so it \
is the style that reveals whether the column-width offsets keep the label on the page.", "Theorem" ],
  Cell[ "The proof style, which is declared to inherit from Text and therefore does not pick up a \
child sheet's override of Text — one of the two causes of the sizes that do not move.", "Proof" ],
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
