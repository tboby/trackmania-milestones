class RaceRecord {
    uint64 time;
    int64 noRespawnTime = -1;
    uint64 target;
    bool pb;
    int64 timestamp;
    RaceRecord(uint64 time, uint64 target, bool pb, int64 timestamp, int64 noRespawnTime){
        this.time = time;
        this.target = target;
        this.pb = pb;
        this.timestamp = timestamp;
        this.noRespawnTime = noRespawnTime;
    }
    Json::Value@ to_json(){
        auto result = Json::Object();
        result["time"] = time;
        result["target"] = target;
        result["pb"] = pb;
        result["timestamp"] = timestamp;
        result["noRespawnTime"] = noRespawnTime;
        return result;
    }
    RaceRecord(Json::Value json){
        this.time = json.Get("time");
        this.target = json.Get("target");
        this.pb = json.Get("pb");
        if(json.HasKey("timestamp")){
            this.timestamp = json.Get("timestamp");
        }
        if(json.HasKey("noRespawnTime")){
            this.noRespawnTime = json.Get("noRespawnTime");
            if(this.noRespawnTime == 0){
                this.noRespawnTime = -1;
            }
        }
    }
}

class RacingData {
    array<RaceRecord@> records;
}

class PlayerLiveTracker {
    int bestTime = -1;

    PlayerLiveTracker(MLFeed::PlayerCpInfo_V4@ player) {
        bestTime = player.BestTime;
    }

    void UpdateFrom(MLFeed::PlayerCpInfo_V4@ player) {
        bestTime = player.BestTime;
    }
}



// OnlineStats.as
class OnlineStats : Component {
    dictionary playerLastCpCounts;
    int nbPlayers = 0;
    void handler() override {
        while(running){
            auto raceData = MLFeed::GetRaceData_V4();
            nbPlayers = raceData.SortedPlayers_Race.Length;
            if (nbPlayers == 0) {
                playerLastCpCounts.DeleteAll();
            }
            for (uint i = 0; i < raceData.SortedPlayers_Race.Length; i++) {
                auto player = cast<MLFeed::PlayerCpInfo_V4>(raceData.SortedPlayers_Race[i]);
                if(player.IsLocalPlayer){
                    continue;
                }
                if (!playerLastCpCounts.Exists(player.name)) {
                    playerLastCpCounts.Set(player.name, @PlayerLiveTracker(player));
                } else {
                    auto cpTracker = GetPlayersLiveTracker(player.name);
                    if (cpTracker is null) {
                        // warn("cp tracker exists but is null?? " + player.name);
                        continue;
                    }
                    cpTracker.UpdateFrom(player);
                }
            }

            yield();
        }
    }


    // Get list of all player times as leaderboardentries excluding the current player
    array<LeaderboardEntry@>@ GetLeaderboardEntries() {
        array<LeaderboardEntry@> entries;
        for (uint i = 0; i < playerLastCpCounts.GetKeys().Length; i++) {
            auto name = playerLastCpCounts.GetKeys()[i];
            auto cpTracker = GetPlayersLiveTracker(name);
            if (cpTracker is null) {
                // warn("cp tracker exists but is null?? " + name);
                continue;
            }
            auto entry = LeaderboardEntry();
            entry.desc = name;
            entry.time = cpTracker.bestTime;
            entries.InsertLast(entry);
        }
        return entries;
    }


    PlayerLiveTracker@ GetPlayersLiveTracker(const string &in name) {
        PlayerLiveTracker@ ret = null;
        if (playerLastCpCounts.Get(name, @ret)) {
            return ret;
        }
        // warn("playerLastCpCounts.Get failed: " + name);
        return null;
        // return cast<PlayerCpTracker>(playerLastCpCounts[name]);
    }
    string toString() override {
        string result = "";
        for (uint i = 0; i < playerLastCpCounts.GetKeys().Length; i++) {
            auto name = playerLastCpCounts.GetKeys()[i];
            auto cpTracker = GetPlayersLiveTracker(name);
            if (cpTracker is null) {
                // warn("cp tracker exists but is null?? " + name);
                continue;
            }
            result += name + ": " + cpTracker.bestTime + "\n";
        }
        return result;
    }

}

//Collect.as
// class Collect : Component {
//     RacingData racingData;
//     Collect() {}

//     Collect(RacingData racingData) {
//         this.racingData = racingData;
//         super();
//     }

//     // string toString() override {
//     //     string s = "";
//     //     if (setting_show_resets_session &&
//     //     !(session == total && !setting_show_duplicates)) {
//     //         s += "\\$bbb" + session;
//     //     }
//     //     if (setting_show_resets_session && setting_show_resets_total &&
//     //      !(session == total && !setting_show_duplicates)) {
//     //         s += "\\$fff  /  ";
//     //     }
//     //     if (setting_show_resets_total) {
//     //         s += "\\$bbb" + total;
//     //     }
//     //     return s;
//     // }
//     // void destroy() override {
//     //     // for(uint i = 0; i< times.Length; i++){
//     //     // print(times[i]);
//     //     // }
//     //     running = false;
//     // }

//     void handler() override {
//         while(running){
//             PlayerState::sTMData@ TMData = PlayerState::GetRaceData();
//             if(TMData.dEventInfo.FinishRun){
//                 print("finish" + TMData.dPlayerInfo.EndTime);
//                 times.InsertLast(TMData.dPlayerInfo.EndTime);
//             }
//             else if (TMData.dEventInfo.EndRun){
//                 print("end" + TMData.dPlayerInfo.EndTime);
//             }
//             // auto app = GetApp();
//             // auto playground = app.CurrentPlayground;
//             // auto network = cast<CTrackManiaNetwork>(app.Network);
//             // if (playground !is null && playground.GameTerminals.Length > 0) {
//             //     auto terminal = playground.GameTerminals[0];
//             //     auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
//             //     if (gui_player !is null) {
//             //         auto post = (cast<CSmScriptPlayer>(gui_player.ScriptAPI)).Post;
//             //         if (!handled && post == CSmScriptPlayer::EPost::Char) {
//             //             handled = true;
//             //             session += 1;
//             //             total += 1;
//             //         }
//             //         if (handled && post != CSmScriptPlayer::EPost::Char)
//             //             handled = false;
//             //         }
//             // }
//             yield();
//         }
//     }

//     string toString() override {
//         array<string> result;
//         for(uint i = 0; i< times.Length; i++){
//             result.InsertLast("" + TimeString(times[i]));
//         }
//         return string::Join(result, "\n");
//     };
// }