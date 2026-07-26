repoDirectory = Replace[ $ScriptCommandLine,
  { { path_, ___ } :> DirectoryName[ ExpandFileName[ path ], 2 ], _ :> Environment[ "MATHNOTEBOOK_REPO" ] } ];
pacletDirectory = FileNameJoin[ { repoDirectory, "MathNotebook" } ];

PacletDirectoryLoad[ repoDirectory ];
Needs[ "WolframInstitute`MathNotebook`" ];

pacletURL = Replace[ Environment[ "MATHNOTEBOOK_PACLET_URL" ],
  Except[ _String ] :> WolframInstitute`MathNotebook`PackageScope`$pacletCloudURL ];
versionURL = Replace[ Environment[ "MATHNOTEBOOK_VERSION_URL" ],
  Except[ _String ] :> WolframInstitute`MathNotebook`PackageScope`$versionMarkerURL ];

If[ ! AllTrue[ { pacletURL, versionURL }, StringQ ],
  Print[ "the paclet did not load; cloud URLs unavailable" ]; Abort[] ];

If[ $CloudBase === None, $CloudBase = "https://www.wolframcloud.com" ];
If[ ! $CloudConnected, CloudConnect[] ];

version = PacletObject[ File @ FileNameJoin[ { pacletDirectory, "PacletInfo.wl" } ] ][ "Version" ];

archive = With[ { staging = FileNameJoin[ { $TemporaryDirectory, "MathNotebook-publish" } ] },
  If[ DirectoryQ[ staging ], DeleteDirectory[ staging, DeleteContents -> True ] ];
  CreateDirectory[ staging ];
  CopyFile[ FileNameJoin[ { pacletDirectory, "PacletInfo.wl" } ], FileNameJoin[ { staging, "PacletInfo.wl" } ] ];
  Scan[ { name } |-> CopyDirectory[ FileNameJoin[ { pacletDirectory, name } ], FileNameJoin[ { staging, name } ] ],
    { "Kernel", "FrontEnd", "Assets", "Tests" } ];
  Scan[ DeleteFile, FileNames[ ".DS_Store", staging, Infinity ] ];
  CreatePacletArchive[ staging, $TemporaryDirectory ] ];

CopyFile[ archive, CloudObject[ pacletURL ], OverwriteTarget -> True ];
SetPermissions[ CloudObject[ pacletURL ], "Public" ];

CloudExport[ version, "Text", CloudObject[ versionURL ], Permissions -> "Public" ];

Print[ "version: ", version ];
Print[ "archive: ", archive ];
Print[ "paclet: ", pacletURL ];
Print[ "marker: ", versionURL ]
