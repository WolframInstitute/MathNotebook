#!/usr/bin/env wolframscript

repoDirectory = DirectoryName[ ExpandFileName[ First[ $ScriptCommandLine ] ] ];
PacletDirectoryLoad[ FileNameJoin[ { repoDirectory, "MathNotebook" } ] ];
Needs[ "WolframInstitute`MathNotebook`" ];
reports = AssociationMap[ TestReport, FileNames[ "*.wlt", FileNameJoin[ { repoDirectory, "MathNotebook", "Tests" } ] ] ];
(* A file may ABORT rather than report. Tests/FrontEnd.wlt does exactly that when the service front
   end does not survive a measurement group (FrontEndTestIsolation T3), so that a dead front end can
   never be read as a content mismatch about the paclet. TestReport then answers $Aborted, whose
   "TestsFailedCount" is not a number: Total stays symbolic, the comparison never evaluates, and
   Exit[ Boole[ ... ] ] would leave a non-reporting file exiting 0 — green, silently. Count it as a
   failure and say so by name. *)
failedCount[ report_TestReportObject ] := report[ "TestsFailedCount" ]
failedCount[ _ ] := 1

KeyValueMap[
  Print[ FileNameTake[ #1 ], ": ",
    Replace[ #2, {
      report_TestReportObject :>
        StringJoin[ ToString @ report[ "TestsSucceededCount" ], " passed, ",
          ToString @ report[ "TestsFailedCount" ], " failed" ],
      other_ :> StringJoin[ "DID NOT REPORT (", ToString @ Head[ other ],
        ") - counted as a failure; read the messages above" ] } ] ] &,
  reports ];
Exit[ Boole[ Total[ failedCount /@ Values[ reports ] ] > 0 ] ]
