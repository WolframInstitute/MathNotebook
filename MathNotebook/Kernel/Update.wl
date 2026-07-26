Package["WolframInstitute`MathNotebook`"]

PackageExport[$MathNotebookCloudVersion]

PackageScope["$pacletCloudURL"]
PackageScope["$versionMarkerURL"]
PackageScope["cloudVersion"]
PackageScope["versionStringQ"]

$pacletCloudURL = "https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook.paclet"

$versionMarkerURL = "https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook-version.txt"

$MathNotebookCloudVersion :=
  cloudVersion[ $versionMarkerURL ]

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
