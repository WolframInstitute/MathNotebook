repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];
tutorialPath = FileNameJoin[ { repoDirectory, "MathNotebook", "Assets", "MathNotebookTutorial.nb" } ];

(* The Credits section is a bibliography, so it is labelled by the same code the palette runs,
   and the tutorial demonstrates the labels it describes. *)
PacletDirectoryLoad[ repoDirectory ];
Needs[ "WolframInstitute`MathNotebook`" ];
labelReferences = WolframInstitute`MathNotebook`PackageScope`labelReferenceCells;

key[ text_String ] := StyleBox[ text, FontWeight -> "Bold" ];
name[ text_String ] := StyleBox[ text, FontSlant -> "Italic" ];
link[ label_String, url_String ] :=
  ButtonBox[ label, BaseStyle -> "Hyperlink", ButtonData -> { URL[ url ], None }, ButtonNote -> url ];

tutorialNotebook = Notebook[ {
  Cell[ "Writing Mathematics in Notebooks", "Title" ],
  Cell[ "MathNotebook Tutorial", "Author" ],
  Cell[ "How to write a mathematics paper in a Wolfram notebook: journal stylesheets, live referencing, and conversion between LaTeX source and native typeset math. Whether the mathematics is written as LaTeX or as built-in typeset math is your choice throughout \[LongDash] the palette only moves a selection from one to the other.", "Abstract" ],

  Cell[ "Getting Started", "Section" ],
  Cell[ TextData[ { "After installing the paclet, restart the front end so that ", name[ "Palettes \[RightArrow] MathNotebook" ], " and the stylesheet menu appear." } ], "Item" ],
  Cell[ TextData[ { "Give a notebook a journal style with ", name[ "Format \[RightArrow] Stylesheet \[RightArrow] MathNotebook" ], ", or the palette's ", name[ "Apply stylesheet" ], " menu; ", name[ "Default" ], " in that menu takes it back." } ], "Item" ],
  Cell[ TextData[ { "Style the opening cells ", name[ "Title" ], ", ", name[ "Author" ], ", ", name[ "Abstract" ], ", then write in ", name[ "Section" ], " and ", name[ "Text" ], " cells." } ], "Item" ],
  Cell[ "Every palette button acts on the notebook you were last editing, and on its current selection.", "Item" ],
  Cell[ TextData[ { "The journal stylesheets are light-only; applying one from the palette also sets the notebook to light mode, so printed and exported output matches the screen." } ], "Item" ],
  Cell[ TextData[ { name[ "Update from cloud" ], ", in the palette's ", name[ "Setup" ], " group, asks the Wolfram Cloud which version is published and installs it only when it is newer than the one you have \[LongDash] so checking costs a line of text, not a download. It then rebuilds the front end menus and reopens the palette, which makes the new palette, stylesheets and tutorial live immediately." } ], "Item" ],
  Cell[ TextData[ { "It always says which of three things happened: updated, with the old and new version numbers; already current; or the cloud could not be reached. Kernel code from the new version loads after ", name[ "Evaluation \[RightArrow] Quit Kernel" ], " \[LongDash] the button will not quit the kernel out from under your session." } ], "Item" ],
  Cell[ TextData[ { "A copy loaded from a development directory shadows anything installed from the cloud, so the button reports that and downloads nothing. The same check from code: ", name[ "UpdateMathNotebook[]" ], "." } ], "Item" ],

  Cell[ "Referencing", "Section" ],
  Cell[ TextData[ { "Select a numbered cell \[LongDash] an equation, a theorem, a section, a numbered item \[LongDash] and press ", name[ "Copy reference" ], ", then paste into your text." } ], "Item" ],
  Cell[ "The pasted reference is a live button showing the current number, so reordering cells renumbers every reference to them.", "Item" ],
  Cell[ TextData[ { "Clicking a reference jumps to its target; ", name[ "\[UpArrow] Go back" ], " returns to where you clicked from." } ], "Item" ],
  Cell[ TextData[ { name[ "Tag cell" ], " names a cell, and ", name[ "Insert citation" ], " inserts a red bracketed link to that name \[LongDash] the two together give a bibliography: style each entry ", name[ "Reference" ], ", tag it, cite it." } ], "Item" ],
  Cell[ TextData[ { "A citation to a numbered environment shows its number instead of its tag: tag a theorem, cite it, and the citation reads ", name[ "Theorem 1.1" ], " \[LongDash] renumbering itself when cells move, in the exported PDF as on screen. A tag no cell carries yet keeps its brackets, so a citation written before its target is still readable." } ], "Item" ],
  Cell[ TextData[ { "Tagging a ", name[ "Reference" ], " cell also labels it: the entry shows its tag in brackets in the margin, which is exactly what a citation to it reads, so the bibliography and the body agree without your typing either." } ], "Item" ],
  Cell[ TextData[ { "For a bibliography tagged before that was true \[LongDash] or tagged through the Cell Tags dialog rather than the palette \[LongDash] ", name[ "LabelReferences[]" ], " labels every entry of a notebook at once, and clears the label of an entry whose tag you removed." } ], "Item" ],
  Cell[ TextData[ { "Existing tags are listed under ", name[ "Cell \[RightArrow] Cell Tags" ], "." } ], "Item" ],
  Cell[ "The theorem below and the equation after it are practice targets: select either one and copy a reference to it.", "Item" ],
  Cell[ "The exponential map is surjective onto the unit circle.", "Theorem" ],
  Cell[ BoxData[ FormBox[ RowBox[ { SuperscriptBox[ "e", RowBox[ { "\[ImaginaryI]", "\[Pi]" } ] ], "+", "1", "=", "0" } ], TraditionalForm ] ], "DisplayFormulaNumbered" ],

  Cell[ "Stylesheets", "Section" ],
  Cell[ TextData[ { "Four templates: ", name[ "AMSArticle" ], " (amsart, Palatino), ", name[ "ArXivArticle" ], " (article, Latin Modern), ", name[ "SpringerJournal" ], " and ", name[ "RevTeXAPS" ], " (Times)." } ], "Item" ],
  Cell[ "All four define the same style names, so switching between them is instant and changes nothing but the typography.", "Item" ],
  Cell[ TextData[ { name[ "PlainArticle" ], " is a fifth sheet and not a template: it is the notebook's own typography with the paper structure added, and it is what an imported paper opens on when its \\documentclass names no journal above." } ], "Item" ],
  Cell[ "Theorem, Lemma, Proposition, Corollary, Conjecture, Claim, Definition, Example, Construction, Remark, Question, and Observation share a single counter that resets at each section, exactly as in LaTeX; numbered equations count continuously through the document.", "Item" ],
  Cell[ TextData[ { "Insert environments from the palette's ", name[ "Insert environment" ], " menu, or with the ", name[ "Proof" ], ", ", name[ "Equation" ], ", and ", name[ "Equation (n)" ], " buttons." } ], "Item" ],
  Cell[ TextData[ { "Latin Modern and TeX Gyre are LaTeX fonts, not system fonts: press ", name[ "Install LaTeX fonts" ], " once to copy them out of a local TeX distribution (", link[ "tug.org/texlive", "https://tug.org/texlive/" ], ") into your user font directory, then restart the front end. They are installed for the whole machine, not inside Mathematica, so any application can use them." } ], "Item" ],

  Cell[ "Reading and Writing Comfortably", "Section" ],
  Cell[ "Each palette group folds: click its opener or its name to collapse it, so only the buttons you are using take up room. The palette remembers which groups are open across front end restarts.", "Item" ],
  Cell[ TextData[ { "The ", name[ "Document view" ], " group holds two sliders and a reset. Like every other palette control they act on the notebook you were last editing, so leave the palette open beside your paper and drag while you read it." } ], "Item" ],
  Cell[ TextData[ { name[ "Text size" ], " sets the size of ", name[ "Text" ], " and scales the rest of the prose with it \[LongDash] the title, the headings, the abstract, the theorem environments, proofs, bibliography entries, and both kinds of list \[LongDash] so the document keeps its proportions instead of one style growing alone." } ], "Item" ],
  Cell[ TextData[ { name[ "Math size" ], " does the same for displayed equations and their numbers, independently of the prose \[LongDash] the usual reason to reach for it is an equation left too small to read beside text you have just enlarged." } ], "Item" ],
  Cell[ TextData[ { "Both set real font sizes, so they reach the exported PDF. ", name[ "Format \[RightArrow] Magnification" ], " is a different thing entirely \[LongDash] it zooms the screen and never changes print." } ], "Item" ],
  Cell[ "The settings are stored in the notebook itself, so they survive saving and reopening and travel with the file to a coauthor.", "Item" ],
  Cell[ TextData[ { name[ "Reset view" ], " returns the notebook to its stylesheet defaults and leaves no trace of the overrides; applying a stylesheet clears them too, since the new sheet replaces them." } ], "Item" ],
  Cell[ TextData[ { "MaTeX cells are images and cannot inherit a style, so ", name[ "Math size" ], " re-renders each of them through LaTeX at the new size, from the TeX the cell stores." } ], "Item" ],
  Cell[ TextData[ { "The same from code, on any notebook: ", name[ "SetDocumentFontSize[nb, 16]" ], ", ", name[ "SetMathFontSize[nb, 16]" ], " \[LongDash] each takes ", name[ "Automatic" ], " to drop its own override \[LongDash] and ", name[ "ResetDocumentView[nb]" ], " to drop all of them. They work on a notebook still using ", name[ "Default" ], " too." } ], "Item" ],

  Cell[ "Math Input Shortcuts", "Section" ],
  Cell[ TextData[ { key[ "Ctrl+9" ], " inline math in text, ", key[ "Ctrl+0" ], " exits." } ], "Item" ],
  Cell[ TextData[ { key[ "Ctrl+/" ], " fraction, ", key[ "Ctrl+2" ], " square root." } ], "Item" ],
  Cell[ TextData[ { key[ "Ctrl+^" ], " superscript, ", key[ "Ctrl+_" ], " subscript, ", key[ "Ctrl+%" ], " switches between them." } ], "Item" ],
  Cell[ TextData[ { key[ "esc" ], " ", name[ "name" ], " ", key[ "esc" ], " enters symbols: ", name[ "a" ], " \[RightArrow] \[Alpha], ", name[ "el" ], " \[RightArrow] \[Element], ", name[ "->" ], " \[RightArrow] \[Rule]." } ], "Item" ],
  Cell[ TextData[ { key[ "Cmd+Shift+E" ], " shows the cell expression (", key[ "Ctrl+Shift+E" ], " on Windows)." } ], "Item" ],

  Cell[ "Working with Cells", "Section" ],
  Cell[ TextData[ { "Click a cell bracket to select the cell; drag across brackets to select several; ", key[ "Delete" ], " removes them." } ], "Item" ],
  Cell[ TextData[ { key[ "Ctrl+." ], " extends the selection outward; repeat to reach the whole cell." } ], "Item" ],
  Cell[ TextData[ { key[ "Cmd+1" ], "/", key[ "4" ], "/", key[ "5" ], "/", key[ "7" ], "/", key[ "9" ], " restyle a cell: Title, Section, Subsection, Text, Input." } ], "Item" ],
  Cell[ TextData[ { key[ "Cmd+Shift+D" ], " divides a cell at the cursor; ", key[ "Cmd+Shift+M" ], " merges selected cells." } ], "Item" ],
  Cell[ TextData[ { key[ "Ctrl+G" ], " groups selected cells; ", key[ "Ctrl+Shift+G" ], " ungroups." } ], "Item" ],
  Cell[ TextData[ { "Double-click a group bracket to close or open the group; ", key[ "Cmd+Shift+{" ], " and ", key[ "Cmd+Shift+}" ], " open and close all subgroups." } ], "Item" ],
  Cell[ TextData[ { "Double-click a closed group's remaining bracket to reopen it; use Cell \[RightArrow] Delete All Output before sharing a notebook." } ], "Item" ],

  Cell[ "LaTeX Conversion", "Section" ],
  Cell[ TextData[ { "Three palette groups convert, and the heading of each says what it moves between: ", name[ "Whole paper (LaTeX)" ], " is the route for a paper, ", name[ "Selection: LaTeX \[LeftRightArrow] math" ], " and ", name[ "Selection: math \[LeftRightArrow] MaTeX" ], " act on the cells you have selected. The buttons are named by the verb alone \[LongDash] hover one for a sentence on what it does." } ], "Item" ],
  Cell[ TextData[ { name[ "Import .tex file\[Ellipsis]" ], " reads a whole paper into a new notebook: ", name[ "\\section" ], " and the theorem-like environments the preamble declares become cells of the matching style, mathematics is typeset, ", name[ "\\label" ], " becomes a cell tag, and ", name[ "\\ref" ], " and ", name[ "\\cite" ], " become live links. Anything it does not convert is carried verbatim, so what it cannot read it also does not damage." } ], "Item" ],
  Cell[ TextData[ { "The front matter comes with it: ", name[ "\\title" ], ", ", name[ "\\author" ], " and ", name[ "\\date" ], " become Title, Author and Date cells you can edit \[LongDash] the edit reaches the ", name[ ".tex" ], " \[LongDash] and an ", name[ "abstract" ], " becomes Abstract cells, headed once however many paragraphs it runs to. ", name[ "\\maketitle" ], " has no content of its own, so it stays as text beside ", name[ "\\sloppy" ], " and ", name[ "\\tableofcontents" ], "." } ], "Item" ],
  Cell[ TextData[ { name[ "itemize" ], ", ", name[ "enumerate" ], " and ", name[ "description" ], " become Item and ItemNumbered cells, one per ", name[ "\\item" ], ", nesting into Subitem and Subsubitem. Each list restarts its numbering as LaTeX does, an ", name[ "\\item[label]" ], " prints the label instead of the number, and a second paragraph of one item becomes an ItemParagraph cell." } ], "Item" ],
  Cell[ TextData[ { "A ", name[ "figure" ], " becomes its caption plus an ", name[ "Input" ], " cell holding the code that draws the picture \[LongDash] an ", name[ "Import" ], " of the file the paper shipped, which you replace with the Wolfram code that generates it. Evaluate the cell and the figure is live; the picture's own markup, TikZ included, still goes back into the ", name[ ".tex" ], " untouched, so the generating code stays the notebook's alone." } ], "Item" ],
  Cell[ TextData[ { "The bibliography comes in whichever way the paper writes it. A ", name[ "thebibliography" ], " becomes one Reference cell per ", name[ "\\bibitem" ], ", each showing its key in brackets exactly as the citations to it read, and each is yours to edit \[LongDash] the edit reaches the ", name[ ".tex" ], ". Entries pulled from a ", name[ ".bib" ], " become the same cells, but there the ", name[ ".bib" ], " stays the source of truth: only the ", name[ "\\bibliography" ], " commands go back out, so edit the ", name[ ".bib" ], " and re-import. A declared ", name[ ".bib" ], " that is not beside the ", name[ ".tex" ], " is reported rather than passed over in silence." } ], "Item" ],
  Cell[ TextData[ { name[ "Export to .tex\[Ellipsis]" ], " writes the whole notebook back out as a paper. An imported one comes back as the source it was read from, edits and all; a notebook you wrote here comes out as LaTeX built from its styles. This is the export route \[LongDash] the two buttons below are for a handful of cells, not for a submission." } ], "Item" ],
  Cell[ TextData[ { name[ "Export submission\[Ellipsis]" ], " writes the paper into a directory instead of into a file, and puts everything it needs to compile beside it: each figure file the ", name[ "\\includegraphics" ], " commands name, each ", name[ ".bib" ], " the preamble declares, and \[LongDash] where a local ", name[ "pdflatex" ], " is found \[LongDash] the ", name[ ".bbl" ], ", which arXiv needs because it runs LaTeX but does not run BibTeX. That directory is the upload. A ", name[ ".tex" ], " on its own names files that stayed behind and compiles nowhere but the paper's original directory, which is the whole reason this button exists beside the one above." } ], "Item" ],
  Cell[ TextData[ { "Nothing arXiv rejects goes into it: no ", name[ ".aux" ], " or ", name[ ".log" ], ", and no compiled PDF \[LongDash] the LaTeX run happens in a scratch copy and only the ", name[ ".bbl" ], " comes back. A file the paper names that is not on disk is reported by name, never quietly left out and never re-rendered from the notebook: the format and size the ", name[ "\\includegraphics" ], " assumes are not recoverable, and guessing them would be guessing at how you compile." } ], "Item" ],
  Cell[ TextData[ { name[ "Typeset" ], " reads the selected cells as LaTeX and replaces the mathematics in them with editable typeset math; ", name[ "Show source" ], " turns it back into LaTeX you can read or paste elsewhere. With nothing selected, the whole notebook." } ], "Item" ],
  Cell[ TextData[ { name[ "Typeset" ], " parses inline ", name[ "$\[Ellipsis]$" ], " and ", name[ "\\(\[Ellipsis]\\)" ], ", and displayed ", name[ "$$\[Ellipsis]$$" ], ", ", name[ "\\[\[Ellipsis]\\]" ], ", ", name[ "equation" ], ", and ", name[ "align" ], "; the starred forms stay unnumbered, the unstarred ones become numbered equations." } ], "Item" ],
  Cell[ TextData[ { "A display environment written inside a paragraph, with prose on the lines around it, is lifted out into its own equation cell and the prose stays in Text cells on either side." } ], "Item" ],
  Cell[ TextData[ { "An ", name[ "align" ], " environment becomes a grid aligned on its ", name[ "&" ], ", so it stays editable as one equation cell." } ], "Item" ],
  Cell[ TextData[ { "Each converted cell keeps its original TeX, so ", name[ "Show source" ], " gives back what you typed rather than a re-serialization of the boxes. Anything the parser cannot read is left untouched." } ], "Item" ],
  Cell[ TextData[ { "Input, Code, and Output cells are skipped, so ", name[ "$" ], " in code is safe." } ], "Item" ],
  Cell[ TextData[ { "The same from code, on any notebook: ", name[ "ImportLaTeXDocument[\"paper.tex\"]" ], ", ", name[ "ExportLaTeXDocument[nb, \"paper.tex\"]" ], " and ", name[ "ExportLaTeXBundle[nb, \"directory\"]" ], " for the whole paper, ", name[ "ConvertLaTeXCells[]" ], " and ", name[ "ConvertMathCells[]" ], " for a selection." } ], "Item" ],

  Cell[ "MaTeX", "Section" ],
  Cell[ TextData[ { "MaTeX (", link[ "github.com/szhorvat/MaTeX", "https://github.com/szhorvat/MaTeX" ], ") is optional, and needs a TeX distribution and Ghostscript. It is used only by the ", name[ "Selection: math \[LeftRightArrow] MaTeX" ], " group; referencing, stylesheets, and LaTeX conversion do not." } ], "Item" ],
  Cell[ TextData[ { "Use it when an equation has to come out of real LaTeX \[LongDash] macros, ", name[ "tikz-cd" ], " diagrams, exact journal metrics." } ], "Item" ],
  Cell[ TextData[ { name[ "Install MaTeX" ], " installs the paclet and points it at the local ", name[ "pdflatex" ], " and ", name[ "gs" ], "." } ], "Item" ],
  Cell[ TextData[ { name[ "Render" ], " sends the selected display equations through LaTeX, at whatever size ", name[ "Math size" ], " is showing mathematics at; ", name[ "Restore" ], " gives back editable typeset math from the TeX stored in each cell." } ], "Item" ],
  Cell[ TextData[ { name[ "MaTeX preferences" ], " opens your ", name[ "init.m" ], " in the front end \[LongDash] deliberately not through the system handler for ", name[ ".m" ], " files. Set the preamble, the magnification, and ", name[ "$useMaTeXQ = True" ], " to route TeX typed into a notebook through LaTeX instead of the built-in parser." } ], "Item" ],
  Cell[ "MaTeX cells are images: convert them back before editing, and keep rendering for last.", "Item" ],

  Cell[ "Best Practices", "Section" ],
  Cell[ "One environment per cell, inserted from the palette, keeps the styles and counters consistent.", "Item" ],
  Cell[ "Tag cells as you write them; tagging a theorem after fifty pages means finding it again.", "Item" ],
  Cell[ "Do not strip cell tagging rules: they hold the TeX source that makes the round trip lossless.", "Item" ],
  Cell[ TextData[ { name[ "Export to .tex\[Ellipsis]" ], " at submission time, not continuously \[LongDash] the notebook is the source. Use ", name[ "Export submission\[Ellipsis]" ], " when the destination is arXiv: a ", name[ ".tex" ], " alone is not a submission." } ], "Item" ],
  Cell[ TextData[ { "Before sharing: ", name[ "Cell \[RightArrow] Delete All Output" ], ", and ", name[ "Restore" ], " the MaTeX cells so a coauthor can edit them." } ], "Item" ],

  Cell[ "Credits", "Section" ],
  Cell[ TextData[ { "The referencing scheme and the MaTeX integration are originally due to Nik Murzin, ",
    link[ "github.com/sw1sh", "https://github.com/sw1sh" ], "; this paclet packages and extends that work." } ], "Text" ],
  Cell[ TextData[ { "Nik Murzin, ", link[ "https://github.com/sw1sh", "https://github.com/sw1sh" ] } ], "Reference", CellTags -> "murzin" ],
  Cell[ TextData[ { "Szabolcs Horvat, MaTeX: LaTeX labels in Mathematica, ", link[ "https://github.com/szhorvat/MaTeX", "https://github.com/szhorvat/MaTeX" ] } ], "Reference", CellTags -> "matex" ],
  Cell[ TextData[ { "TeX Live, ", link[ "https://tug.org/texlive/", "https://tug.org/texlive/" ], " \[LongDash] on macOS, MacTeX, ", link[ "https://tug.org/mactex/", "https://tug.org/mactex/" ] } ], "Reference", CellTags -> "texlive" ],
  Cell[ TextData[ { "Latin Modern, ", link[ "https://ctan.org/pkg/lm", "https://ctan.org/pkg/lm" ], " and TeX Gyre, ", link[ "https://ctan.org/pkg/tex-gyre", "https://ctan.org/pkg/tex-gyre" ] } ], "Reference", CellTags -> "lm" ]
  },
  StyleDefinitions -> FrontEnd`FileName[ { "MathNotebook" }, "AMSArticle.nb", CharacterEncoding -> "UTF-8" ],
  LightDark -> "Light"
];

Export[ tutorialPath, labelReferences @ tutorialNotebook, "NB" ];
Print[ "Tutorial written to ", tutorialPath ]
