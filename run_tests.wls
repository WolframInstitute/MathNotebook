#!/usr/bin/env wolframscript

repoDirectory = DirectoryName[ ExpandFileName[ First[ $ScriptCommandLine ] ] ];
PacletDirectoryLoad[ FileNameJoin[ { repoDirectory, "MathNotebook" } ] ];
Needs[ "WolframInstitute`MathNotebook`" ];
reports = AssociationMap[ TestReport, FileNames[ "*.wlt", FileNameJoin[ { repoDirectory, "MathNotebook", "Tests" } ] ] ];
KeyValueMap[ Print[ FileNameTake[ #1 ], ": ", #2[ "TestsSucceededCount" ], " passed, ", #2[ "TestsFailedCount" ], " failed" ] &, reports ];
Exit[ Boole[ Total[ Through[ Values[ reports ][ "TestsFailedCount" ] ] ] > 0 ] ]
