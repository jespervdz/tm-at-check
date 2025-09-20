const uint16 OFFSET_MAP_SCRIPTMD = GetOffset("CGameCtnChallenge", "ScriptMetadata");
const uint OFFSET_MD_BUFFER = 0x28;

const uint TYPE_INT_ARRAY = 0x1247;

const uint SZ_METADATA_ROW = 0x88;      // size of a metadata row
const uint OFFSET_TYPE = 0x10;          // type id offset
const uint OFFSET_VALUE_EL0 = 0x68;     // pointer to element[0]
const uint OFFSET_VALUE_COUNT = 0x70;   // array length
const uint OFFSET_ARRAY_VALUES = 0x8;   // pointer to element entries inside array header
const uint SZ_INT_ARRAY_ENTRY = 0x10;   // size of each element

string S_AT_Cheated_Header = "\\$o\\$sAT set by a plugin  \\$z\\$n\\$555" + pluginTitle;
string S_AT_Cheated_Text = "AT likely set by a plugin\nCheck the plugin for details\nReminder: it could still be valid!";
string S_AT_Valid_Header = "\\$o\\$sAT Valid  \\$z\\$n\\$555" + pluginTitle;
string S_AT_Valid_Text = "AT likely valid\nCheck the plugin for details\nReminder: it could still be cheated!";
string S_AT_Inconclusive_Header = "\\$o\\$sAT inconclusive  \\$z\\$n\\$555" + pluginTitle;
string S_AT_Inconclusive_Text = "AT could be valid or cheated\nCheck the plugin for details";

vec4 S_ColorValid = vec4(0.0f, 0.7f, 0.0f, 1.0f);
vec4 S_ColorInconclusive = vec4(1.0f, 0.5f, 0.0f, 1.0f);
vec4 S_ColorCheated = vec4(1.0f, 0.0f, 0.0f, 1.0f);
vec4 S_ColorError = vec4(0.5f, 0.5f, 0.5f, 1.0f);

const string pluginTitle = "Author Time Check";
string mapIDChecked = "";
int[] times;
uint CPsToFinish;
uint CPsMetadata;
bool cpCntMatch;
uint authorTime;
int metadataAT;
bool lastIsAT;
bool force_notif = false;
CGameCtnApp@ app = GetApp();

uint16 GetOffset(const string &in className, const string &in memberName) {
    auto ty = Reflection::GetType(className);
    auto memberTy = ty.GetMember(memberName);
    if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
    return memberTy.Offset;
}

int[]@ ReadIntArray(uint64 ptr) {
    uint type = Dev::ReadUInt32(ptr + OFFSET_TYPE);
    if (type != TYPE_INT_ARRAY)  throw("Type mismatch! IntArray expected (0x1247), got " + tostring(type));

    uint64 el0Ptr = Dev::ReadUInt64(ptr + OFFSET_VALUE_EL0);
    uint bufLen = Dev::ReadUInt32(ptr + OFFSET_VALUE_COUNT);
    if (bufLen == 0 || el0Ptr == 0) return {};

    int[] arr(bufLen);
    for (uint i = 0; i < bufLen; i++) {
        uint64 elValuePtr = Dev::ReadUInt64(el0Ptr + OFFSET_ARRAY_VALUES + i * SZ_INT_ARRAY_ENTRY);
        arr[i] = Dev::ReadInt32(elValuePtr);
    }
    return arr;
}

int[] Get_Race_AuthorRaceWaypointTimes(uint32 len, uint64 basePtr) {
    for (uint i = 0; i < len; i++) {
        uint64 ptr = basePtr + i * SZ_METADATA_ROW;
        uint traitNameLen = Dev::ReadUInt32(ptr + 0xC);
        if (traitNameLen == 28) { // length of "Race_AuthorRaceWaypointTimes"
            string traitName = Dev::ReadCString(Dev::ReadUInt64(ptr), traitNameLen);
            if (traitName == "Race_AuthorRaceWaypointTimes") {
                return ReadIntArray(ptr);
            }
        }
    }
    return {};
}

void Reset() {
    mapIDChecked = "";
    times = {};
    CPsToFinish = 0;
    CPsMetadata = 0;
    cpCntMatch = true;
    authorTime = 0;
    metadataAT = 0;
    lastIsAT = true;
}

bool ATValid() { return cpCntMatch && lastIsAT; }
bool ATCheated() { return !cpCntMatch || !lastIsAT; }
bool ATInconclusive() { return !ATValid() && !ATCheated(); }

void MainLoop() {
    while (true) {
        sleep(500); // only check twice a seccond
        if (!S_Enabled && !force_notif) {
            continue;
        }
        if (app is null) continue;

        CGameCtnChallenge@ map = app.RootMap;
        if (map is null ) continue;
        string currentMapUID = map.MapInfo.MapUid;

        if (currentMapUID == mapIDChecked) continue;

        CSmArenaClient@ playground = cast<CSmArenaClient>(app.CurrentPlayground);
        bool isPlayingMap = !(playground is null) && !(playground.Arena.Players.Length == 0);

        if (!isPlayingMap || currentMapUID == "") {
            Reset();
            continue;
        }

        if (map.ScriptMetadata is null) {
            UI::ShowNotification(pluginTitle, "This validity of this AT could not be determined", S_ColorError, S_NotifCheatedTime);
            mapIDChecked = currentMapUID;
            continue;
        }

        // Get Metadata location
        uint64 scriptMDPtr = Dev::GetOffsetUint64(map, OFFSET_MAP_SCRIPTMD);
        uint64 bufLocation = scriptMDPtr + OFFSET_MD_BUFFER;
        uint64 ptr = Dev::ReadUInt64(bufLocation);
        uint32 len = Dev::ReadUInt32(bufLocation + 8);

        times = Get_Race_AuthorRaceWaypointTimes(len, ptr);

        // Parse all information
        CPsToFinish = MLFeed::GetRaceData_V4().CPsToFinish;
        CPsMetadata = times.Length;
        authorTime = map.TMObjective_AuthorTime;
        metadataAT = times.Length > 0 ? times[times.Length - 1] : -1;
        cpCntMatch = CPsToFinish == CPsMetadata;
        lastIsAT = authorTime == metadataAT;

        if (ATCheated()) {
            if (S_NotifCheated || force_notif)
                UI::ShowNotification(S_AT_Cheated_Header, S_AT_Cheated_Text, S_ColorCheated, S_NotifCheatedTime);
        }
        else if (ATValid()) {
            if (S_NotifValid || force_notif)
                UI::ShowNotification(S_AT_Valid_Header, S_AT_Valid_Text, S_ColorValid, S_NotifValidTime);
        }
        else {
            if (S_NotifInconclusive || force_notif)
                UI::ShowNotification(S_AT_Inconclusive_Header, S_AT_Inconclusive_Text, S_ColorInconclusive, S_NotifInconclusiveTime);
        }

        mapIDChecked = currentMapUID;
        force_notif = false;
    }
}

void Main() {
    startnew(MainLoop);
}