Package["WolframInstitute`MathNotebook`"]

PackageExport[UpdateMathNotebook]
PackageExport[$MathNotebookCloudVersion]

PackageScope["$pacletCloudURL"]
PackageScope["$versionMarkerURL"]
PackageScope["cloudVersion"]
PackageScope["versionStringQ"]
PackageScope["versionList"]
PackageScope["newerVersionQ"]
PackageScope["developmentPacletQ"]
PackageScope["updateAction"]
PackageScope["updateMessage"]
PackageScope["palettePath"]
PackageScope["reopenPalette"]

$pacletCloudURL = "https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook.paclet"

$versionMarkerURL = "https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook-version.txt"

UpdateMathNotebook[] :=
  With[ { paclet = PacletObject[ "WolframInstitute/MathNotebook" ], cloud = $MathNotebookCloudVersion },
    MessageDialog @
      Replace[ updateAction[ paclet[ "Location" ], paclet[ "Version" ], cloud ],
        { "Install" :> installUpdate[ paclet[ "Version" ] ],
          action_ :> updateMessage[ action, paclet[ "Location" ], paclet[ "Version" ], cloud ] } ];
  ]

$MathNotebookCloudVersion :=
  cloudVersion[ $versionMarkerURL ]

updateAction[ location_String, version_String, cloud_ ] :=
  Which[
    developmentPacletQ[ location ], "Development",
    MissingQ[ cloud ], "Unreachable",
    newerVersionQ[ cloud, version ], "Install",
    True, "Current" ]

installUpdate[ version_String ] :=
  Replace[ PacletInstall[ $pacletCloudURL, ForceVersionInstall -> True ],
    { paclet_PacletObject :> (
        FrontEndExecute[ FrontEnd`ResetMenusPacket[ { Automatic, Automatic } ] ];
        reopenPalette @ palettePath @ paclet;
        updateMessage[ "Updated", paclet[ "Location" ], version, paclet[ "Version" ] ] ),
      _ :> updateMessage[ "Failed", "", version, Missing[ "DownloadFailed", $pacletCloudURL ] ] } ]

updateMessage[ "Development", location_String, version_String, _ ] :=
  "MathNotebook " <> version <> " is loaded from a development directory:\n" <> location <>
  "\nAn install from the cloud would sit behind it, so nothing was downloaded."

updateMessage[ "Unreachable", _, version_String, cloud_Missing ] :=
  "Could not read the published version from the Wolfram Cloud (" <> missingReason[ cloud ] <> ").\n" <>
  "MathNotebook " <> version <> " is installed and unchanged."

updateMessage[ "Current", _, version_String, cloud_String ] :=
  "MathNotebook " <> version <> " is up to date; " <> cloud <> " is the version published in the cloud."

updateMessage[ "Updated", _, version_String, newVersion_String ] :=
  "MathNotebook updated: " <> version <> " \[RightArrow] " <> newVersion <> ".\n" <>
  "The front end menus were rebuilt and the palette reopened, so the new palette, stylesheets and tutorial are live.\n" <>
  "Quit the kernel (Evaluation \[FilledRightTriangle] Quit Kernel) to load the new version's kernel code."

updateMessage[ "Failed", _, version_String, cloud_Missing ] :=
  "The download from the Wolfram Cloud failed (" <> missingReason[ cloud ] <> ").\n" <>
  "MathNotebook " <> version <> " is unchanged."

missingReason[ cloud_Missing ] :=
  StringRiffle[ ToString /@ Apply[ List, cloud ], ": " ]

developmentPacletQ[ location_String ] :=
  ! StringStartsQ[ location, $UserBasePacletsDirectory | $BasePacletsDirectory ]

newerVersionQ[ version_String, reference_String ] :=
  Order[ versionList @ version, versionList @ reference ] === -1

versionList[ version_String ] :=
  PadRight[ ToExpression @ StringSplit[ version, "." ], 4 ]

palettePath[ paclet_PacletObject ] :=
  FileNameJoin[ { paclet[ "Location" ], "FrontEnd", "Palettes", "MathNotebook.nb" } ]

reopenPalette[ path_String ] :=
  With[ { open = Select[ Notebooks[], FileNameTake[ Quiet @ NotebookFileName[ # ] ] === "MathNotebook.nb" & ] },
    NotebookClose /@ open;
    If[ open =!= { }, NotebookOpen[ path ] ]
  ]

cloudVersion[ url_String ] :=
  Replace[
    Quiet @ URLRead[
      HTTPRequest[ url, <| "Headers" -> { "Cache-Control" -> "no-cache" } |> ],
      { "StatusCode", "Body" } ],
    { KeyValuePattern[ { "StatusCode" -> 200, "Body" -> body_String } ] :>
        Replace[ StringTrim[ body ],
          { version_?versionStringQ :> version, _ :> Missing[ "MalformedVersionMarker", url ] } ],
      KeyValuePattern[ "StatusCode" -> code_Integer ] :> Missing[ "CloudUnreachable", code ],
      _ :> Missing[ "CloudUnreachable", url ] } ]

versionStringQ[ version_ ] :=
  StringQ[ version ] && StringMatchQ[ version, DigitCharacter .. ~~ ( "." ~~ DigitCharacter .. ) ... ]
