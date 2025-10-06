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

const string pluginTitle = "Author Time Check";
string mapIDChecked = "";
string currentMapUID = "";
int[] times;
uint CPsToFinish;
uint CPsMetadata;
bool cpCntMatch;
uint authorTime;
int metadataAT;
bool lastIsAT;
bool force_notif = false;
CGameCtnApp@ app;

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

void MainLoop() {
    app = GetApp();
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
            continue;
        }

        currentMapUID = map.MapInfo.MapUid;
        if (currentMapUID == mapIDChecked) continue;

        if (map.ScriptMetadata is null) { // don't think this is possible, but just to be sure
            UI::ShowNotification(S_AT_Inconclusive_Header, S_AT_Inconclusive_Text, S_ColorInconclusive, S_NotifInconclusiveTime);
            mapIDChecked = currentMapUID;
            continue;
        }

        // Request ML via MLHook for the AT CP Times. Will write it to `times`
        MLHook::Queue_MessageManialinkPlayground("AT_Check", "Hook_AT_Check");
        while (currentMapUID != mapIDChecked) yield(); // yield until we have received the AT CP Times

        // Parse all information
        CPsToFinish = MLFeed::GetRaceData_V4().CPsToFinish;
        CPsMetadata = times.Length;
        authorTime = map.TMObjective_AuthorTime;
        metadataAT = times.Length > 0 ? times[times.Length - 1] : -1;
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