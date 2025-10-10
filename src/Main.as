const uint MAX_UINT = 4294967295;
const string pluginTitle = "Author Time Check";
string mapIDChecked = "";
string currentMapUID = "";
int[] CPTimesAT = {};
uint authorTime = 0;
bool force_notif = false;
bool ATGhostInMap = false;
_ATWaypointTimesFeed@ ATWaypointTimesFeed = _ATWaypointTimesFeed();

uint get_CPsToFinish() { return MLFeed::GetRaceData_V4().CPsToFinish; }
uint get_CPsMetadata() { return CPTimesAT.Length; }
bool get_cpCntMatch() { return CPsToFinish == CPsMetadata; }
uint get_metadataAT() { return CPTimesAT.Length > 0 ? CPTimesAT[CPTimesAT.Length - 1] : MAX_UINT; }
bool get_lastIsAT() { return authorTime == metadataAT; }

void Reset() {
    mapIDChecked = "";
    CPTimesAT = {};
    authorTime = 0;
    ATGhostInMap = false;
}

bool ATGhostPresent() { return ATGhostInMap; }
bool ATValid() { return cpCntMatch && lastIsAT; }
bool ATInvalid() { return !cpCntMatch || !lastIsAT; }
bool ATInconclusive() { return !ATValid() && !ATInvalid(); }

class _ATWaypointTimesFeed : MLHook::HookMLEventsByType {
    _ATWaypointTimesFeed() { super("AT_Check"); }

    void OnEvent(MLHook::PendingEvent@ event) override {
        Json::Value parsed = Json::Parse(event.data[0]);
        if (parsed.GetType() == Json::Type::Array) {
            CPTimesAT.Resize(parsed.Length);
            for (uint i = 0; i < parsed.Length; i++)
                CPTimesAT[i] = int(parsed[i]);
        } else {
            CPTimesAT.Resize(0);
        }
        mapIDChecked = currentMapUID;
    }
}

void GetATCPTimes() {
    // Request ML via MLHook for the AT CP Times. Will write it to `CPTimesAT`
    MLHook::Queue_MessageManialinkPlayground("AT_Check", "Hook_AT_Check");
    while (currentMapUID != mapIDChecked) yield(); // yield until we have received the AT CP Times
}

bool WRbeatAT() {
    try {
        const string route = NadeoServices::BaseURLLive() + "/api/token/leaderboard/group/Personal_Best/map/" + currentMapUID + "/top?length=1&onlyWorld=true&offset=0";
        NadeoServices::AddAudience("NadeoLiveServices");
        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();

        auto request = NadeoServices::Get("NadeoLiveServices", route);
        request.Start();
        while(!request.Finished()) yield();

        auto json = Json::Parse(request.String());
        uint WRTime = json["tops"][0]["top"][0]["score"]; // just assume all this exists
        return WRTime < authorTime;
    } catch {
        warn("Unable to retrieve WR");
        return false;
    }
}

// Taken from Xertrov's G++ plugin: https://github.com/XertroV/tm-ghosts-plus-plus
bool MapHasMediaClipATGhost(CGameCtnChallenge@ map) {
    if (map.ClipGroupInGame is null) return false;
    for (uint i = 0; i < map.ClipGroupInGame.Clips.Length; i++) {
        CGameCtnMediaClip@ clip = map.ClipGroupInGame.Clips[i];
        if (clip is null) continue;
        for (uint i = 0; i < clip.Tracks.Length; i++) {
            auto track = clip.Tracks[i];
            if (track is null) continue;
            for (uint j = 0; j < track.Blocks.Length; j++) {
                auto block = track.Blocks[j];
                if (block is null) continue;

                auto entBlock = cast<CGameCtnMediaBlockEntity>(block);
                if (entBlock is null) continue; // not a ghost/entity track

                if (authorTime == Dev::GetOffsetUint32(block, 0x7C))
                    return true;
            }
        }
    }
    return false;
}

void MainLoop() {
    auto app = GetApp();
    while (true) {
        sleep(200); // No need to check every frame
        if (app is null || (!S_Enabled && !force_notif)) continue;

        CGameCtnChallenge@ map = app.RootMap;
        CSmArenaClient@ playground = cast<CSmArenaClient>(app.CurrentPlayground);
        bool isPlayingMap = !(playground is null) && playground.Arena.Players.Length > 0;

        if (map is null || !isPlayingMap || map.MapInfo.MapUid == "") {
            Reset();
            force_notif = false;
            continue;
        }

        currentMapUID = map.MapInfo.MapUid;
        if (currentMapUID == mapIDChecked) continue;
        authorTime = map.TMObjective_AuthorTime;

        if (S_HideIfATBeaten && !force_notif && WRbeatAT())
            continue;

        if (map.ScriptMetadata is null) { // don't think this is possible, but just to be sure
            NotifyInconclusive();
            mapIDChecked = currentMapUID;
            force_notif = false;
            continue;
        }

        GetATCPTimes();
        ATGhostInMap = MapHasMediaClipATGhost(map);
        Notify();
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