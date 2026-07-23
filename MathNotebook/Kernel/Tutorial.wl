Package["WolframInstitute`MathNotebook`"]

PackageExport[OpenTutorial]

PackageScope["tutorialPath"]

tutorialPath[] :=
  PacletObject[ "WolframInstitute/MathNotebook" ][ "AssetLocation", "Tutorial" ]

OpenTutorial[] :=
  NotebookPut @ Import[ tutorialPath[], "NB" ]
