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

VerificationTest[
  { newerVersionQ[ "0.1.9", "0.1.8" ], newerVersionQ[ "0.2", "0.1.12" ], newerVersionQ[ "1", "0.9.9" ] },
  { True, True, True }
]

VerificationTest[
  { newerVersionQ[ "0.1.8", "0.1.8" ], newerVersionQ[ "0.1.7", "0.1.8" ], newerVersionQ[ "0.1.8", "0.1.8.1" ] },
  { False, False, False }
]

VerificationTest[
  developmentPacletQ /@ { FileNameJoin[ { $UserBasePacletsDirectory, "Repository", "WolframInstitute__MathNotebook-0.1.8" } ],
    "/Users/somebody/Desktop/MathNotebook/MathNotebook" },
  { False, True }
]

VerificationTest[
  updateAction[ "/Users/somebody/Desktop/MathNotebook/MathNotebook", "0.1.8", "0.1.9" ],
  "Development"
]

VerificationTest[
  updateAction[ #, "0.1.8", Missing[ "CloudUnreachable", 404 ] ] & @
    FileNameJoin[ { $UserBasePacletsDirectory, "Repository", "WolframInstitute__MathNotebook-0.1.8" } ],
  "Unreachable"
]

VerificationTest[
  updateAction[ #, "0.1.8", "0.1.9" ] & @
    FileNameJoin[ { $UserBasePacletsDirectory, "Repository", "WolframInstitute__MathNotebook-0.1.8" } ],
  "Install"
]

VerificationTest[
  updateAction[ #, "0.1.8", "0.1.8" ] & @
    FileNameJoin[ { $UserBasePacletsDirectory, "Repository", "WolframInstitute__MathNotebook-0.1.8" } ],
  "Current"
]

VerificationTest[
  AllTrue[
    { updateMessage[ "Development", "/dev/MathNotebook", "0.1.8", "0.1.9" ],
      updateMessage[ "Unreachable", "", "0.1.8", Missing[ "CloudUnreachable", 404 ] ],
      updateMessage[ "Current", "", "0.1.8", "0.1.8" ],
      updateMessage[ "Updated", "", "0.1.8", "0.1.9" ],
      updateMessage[ "Failed", "", "0.1.8", Missing[ "DownloadFailed", $pacletCloudURL ] ] },
    StringQ ],
  True
]

VerificationTest[
  StringContainsQ[ updateMessage[ "Updated", "", "0.1.8", "0.1.9" ], "0.1.8" ] &&
    StringContainsQ[ updateMessage[ "Updated", "", "0.1.8", "0.1.9" ], "0.1.9" ],
  True
]

VerificationTest[
  FileExistsQ @ palettePath @ PacletObject[ "WolframInstitute/MathNotebook" ],
  True
]
