string S_AT_Invalid_Header = "\\$o\\$sAT set by a plugin  \\$z\\$n\\$555" + pluginTitle;
string S_AT_Invalid_Text = "AT likely set by a plugin\nCheck the plugin for details\nReminder: it could still be valid!";
string S_AT_Valid_Header = "\\$o\\$sAT Valid  \\$z\\$n\\$555" + pluginTitle;
string S_AT_Valid_Text = "AT likely valid\nCheck the plugin for details\nReminder: it could still be invalid!";
string S_AT_Inconclusive_Header = "\\$o\\$sAT inconclusive  \\$z\\$n\\$555" + pluginTitle;
string S_AT_Inconclusive_Text = "AT could be valid or invalid\nCheck the plugin for details";

vec4 S_ColorValid = vec4(0.0f, 0.7f, 0.0f, 1.0f);
vec4 S_ColorInconclusive = vec4(1.0f, 0.5f, 0.0f, 1.0f);
vec4 S_ColorInvalid = vec4(1.0f, 0.0f, 0.0f, 1.0f);
vec4 S_ColorError = vec4(0.5f, 0.5f, 0.5f, 1.0f);

const uint MAX_UINT = 4294967295;
const string pluginTitle = "Author Time Check";
string mapIDChecked = "";
string currentMapUID = "";
int[] times;
uint CPsToFinish;
uint CPsMetadata;
bool cpCntMatch;
uint authorTime;
uint metadataAT;
bool lastIsAT;
bool force_notif = false;

void Reset() {
    mapIDChecked = "";
    times = {};
    CPsToFinish = 0;
    CPsMetadata = 0;
    cpCntMatch = true;
    authorTime = 0;
    metadataAT = MAX_UINT;
    lastIsAT = true;
    WRTime = MAX_UINT;
    WRTimeMapUID = "";
}

bool ATValid() { return cpCntMatch && lastIsAT; }
bool ATInvalid() { return !cpCntMatch || !lastIsAT; }
bool ATInconclusive() { return !ATValid() && !ATInvalid(); }

_ATWaypointTimesFeed@ ATWaypointTimesFeed = _ATWaypointTimesFeed();

class _ATWaypointTimesFeed : MLHook::HookMLEventsByType {
    _ATWaypointTimesFeed() { super("AT_Check"); }

    void OnEvent(MLHook::PendingEvent@ event) override {
        Json::Value parsed = Json::Parse(event.data[0]);
        if (parsed.GetType() == Json::Type::Array) {
            times.Resize(parsed.Length);
            for (uint i = 0; i < parsed.Length; i++)
                times[i] = int(parsed[i]);
        } else {
            times.Resize(0);
        }
        mapIDChecked = currentMapUID;
    }
}

uint WRTime = MAX_UINT;
string WRTimeMapUID = "";

bool TryGetWR() {
    // no checks, just try catch. TODO: better checks and logs
    try {
        const string route = NadeoServices::BaseURLLive() + "/api/token/leaderboard/group/Personal_Best/map/" + currentMapUID + "/top?length=1&onlyWorld=true&offset=0";
        NadeoServices::AddAudience("NadeoLiveServices");
        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();

        auto request = NadeoServices::Get("NadeoLiveServices", route);
        request.Start();
        while(!request.Finished()) yield();

        auto json = Json::Parse(request.String());
        WRTimeMapUID = json["mapUid"];
        WRTime = json["tops"][0]["top"][0]["score"]; // just assume all this exists
        return true;
    } catch {
        warn("Unable to retrieve WR");
        WRTimeMapUID = currentMapUID;
        WRTime = MAX_UINT;
        return false;
    }
}

void MainLoop() {
    auto app = GetApp();
    while (true) {
        sleep(200); // No need to check every frame
        if (!S_Enabled && !force_notif) continue;
        if (app is null) continue;

        CGameCtnChallenge@ map = app.RootMap;
        CSmArenaClient@ playground = cast<CSmArenaClient>(app.CurrentPlayground);
        bool isPlayingMap = !(playground is null) && playground.Arena.Players.Length > 0;

        if (map is null || !isPlayingMap || map.MapInfo.MapUid == "")
        {
            Reset();
            force_notif = false;
            continue;
        }

        currentMapUID = map.MapInfo.MapUid;
        if (currentMapUID == mapIDChecked) continue;
        authorTime = map.TMObjective_AuthorTime;

        // First check if AT is already beaten
        if (S_HideIfATBeaten)
        {
            if (currentMapUID != WRTimeMapUID)
            {
                if (!TryGetWR())
                    warn("WR unavailabe, assuming AT is unbeaten.");
            }

            if (WRTime < authorTime && !force_notif)
                continue;
        }

        if (map.ScriptMetadata is null) { // don't think this is possible, but just to be sure
            UI::ShowNotification(S_AT_Inconclusive_Header, S_AT_Inconclusive_Text, S_ColorInconclusive, S_NotifInconclusiveTime);
            mapIDChecked = currentMapUID;
            force_notif = false;
            continue;
        }

        // Request ML via MLHook for the AT CP Times. Will write it to `times`
        MLHook::Queue_MessageManialinkPlayground("AT_Check", "Hook_AT_Check");
        while (currentMapUID != mapIDChecked) yield(); // yield until we have received the AT CP Times

        // Parse all information
        CPsToFinish = MLFeed::GetRaceData_V4().CPsToFinish;
        CPsMetadata = times.Length;
        metadataAT = times.Length > 0 ? times[times.Length - 1] : MAX_UINT;
        cpCntMatch = CPsToFinish == CPsMetadata;
        lastIsAT = authorTime == metadataAT;

        if (ATInvalid()) {
            if (S_NotifInvalid || force_notif)
                UI::ShowNotification(S_AT_Invalid_Header, S_AT_Invalid_Text, S_ColorInvalid, S_NotifInvalidTime);
        }
        else if (ATValid()) {
            if (S_NotifValid || force_notif)
                UI::ShowNotification(S_AT_Valid_Header, S_AT_Valid_Text, S_ColorValid, S_NotifValidTime);
        }
        else {
            if (S_NotifInconclusive || force_notif)
                UI::ShowNotification(S_AT_Inconclusive_Header, S_AT_Inconclusive_Text, S_ColorInconclusive, S_NotifInconclusiveTime);
        }

        force_notif = false;
    }
}

void Main() {
    MLHook::RequireVersionApi("0.5.2");
    MLHook::RegisterMLHook(ATWaypointTimesFeed, ATWaypointTimesFeed.type);
    MLHook::InjectManialinkToPlayground("Hook_AT_Check", script, true);
    startnew(MainLoop);
}

void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {
    trace('_Unload, unloading all hooks and removing all injected ML');
    MLHook::UnregisterMLHooksAndRemoveInjectedML();
}