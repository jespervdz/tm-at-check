const string RACE_AT_TIMES_SCRIPT_TXT = "";
// const string RACE_AT_TIMES_SCRIPT_TXT = """

// Void MLHookLog(Text msg) {
//     SendCustomEvent("MLHook_LogMe_ATCheck", [msg]);
// }

// Void GetTimes() {
//     declare metadata Integer[] Race_AuthorRaceWaypointTimes for Map;
//     SendCustomEvent("MLHook_Event_ATTimesResult" , ["test"]);
// }

// Void CheckIncoming() {
//     declare Text[][] MLHook_Inbound_ATCheck for LocalUser;
//     foreach (Event in MLHook_Inbound_ATCheck) {
//         if (Event[0] == "GetTimes") {
//             MLHookLog("Processing event: " ^ Event);
//             GetTimes();
//         } else {
//             MLHookLog("Skipped unknown incoming event: " ^ Event);
//             continue;
//         }
//         MLHookLog("Processed Incoming Event: "^Event[0]);
//     }
//     MLHook_Inbound_ATCheck = [];
// }

// main() {
//     MLHookLog("Reached ATCheck Main!");
//     while (True) {
//         yield;
//         CheckIncoming();
//     }
// }

// """;