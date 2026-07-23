(* ::Package:: *)

PacletObject[
  <|
    "Name" -> "WolframInstitute/MathNotebook",
    "Description" -> "Write mathematics papers in Wolfram notebooks: referencing palette, LaTeX journal stylesheets, LaTeX conversion, MaTeX integration",
    "Creator" -> "Pavel Hajek",
    "License" -> "MIT",
    "PublisherID" -> "WolframInstitute",
    "Version" -> "0.1.0",
    "WolframVersion" -> "14.3+",
    "PrimaryContext" -> "WolframInstitute`MathNotebook`",
    "Extensions" -> {
      {
        "Kernel",
        "Root" -> "Kernel",
        "Context" -> {
          {
            "WolframInstitute`MathNotebook`",
            "MathNotebookLoader.wl"
          }
        },
        "Symbols" -> {
          "WolframInstitute`MathNotebook`CopyCellReference",
          "WolframInstitute`MathNotebook`TagSelectedCell",
          "WolframInstitute`MathNotebook`GoBack",
          "WolframInstitute`MathNotebook`InsertEnvironment",
          "WolframInstitute`MathNotebook`InsertCitation",
          "WolframInstitute`MathNotebook`ConvertLaTeXCells",
          "WolframInstitute`MathNotebook`ConvertMathCells",
          "WolframInstitute`MathNotebook`ConvertToMaTeX",
          "WolframInstitute`MathNotebook`ConvertFromMaTeX",
          "WolframInstitute`MathNotebook`InstallMaTeX",
          "WolframInstitute`MathNotebook`InstallLaTeXFonts",
          "WolframInstitute`MathNotebook`OpenTutorial"
        }
      },
      {"FrontEnd", "Root" -> "FrontEnd", "Prepend" -> True},
      {"Asset", "Root" -> "Assets", "Assets" -> {{"Tutorial", "MathNotebookTutorial.nb"}}}
    }
  |>
]
