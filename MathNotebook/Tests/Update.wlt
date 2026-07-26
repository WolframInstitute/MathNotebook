Needs[ "WolframInstitute`MathNotebook`" ]
AppendTo[ $ContextPath, "WolframInstitute`MathNotebook`PackageScope`" ]

VerificationTest[
  versionStringQ /@ { "0.1.8", "1", "12.3.4.5" },
  { True, True, True }
]

VerificationTest[
  versionStringQ /@ { "", "0.1.8beta", "<!DOCTYPE html>", $Failed },
  { False, False, False, False }
]

VerificationTest[
  MatchQ[ cloudVersion[ "https://www.wolframcloud.com/obj/hajek_pavel/MathNotebook-no-such-marker.txt" ],
    Missing[ "CloudUnreachable", _ ] ],
  True
]

VerificationTest[
  MatchQ[ $MathNotebookCloudVersion, _?versionStringQ | _Missing ],
  True
]
