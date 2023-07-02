class MapLeaderboardData {
    array<LeaderboardEntry@> medals;
    array<LeaderboardEntry@> positionEntries;
    int playerCount;
    LeaderboardEntry personalBest;
    string mapUid;
    float personalBestPercentage { get {
        if(personalBest.time < 0){
            return 100.0f;
        }
        return 100.0f * personalBest.position / playerCount;
         }}

    MapLeaderboardData(string mapUid){
        this.mapUid = mapUid;
    }
    void Initialise(){
        LoadStaticInfo();
        RefreshPersonalBest();
    }

    void RefreshPersonalBest(){
        auto oldPb = this.personalBest;
        this.personalBest = GetPersonalBestEntry(this.mapUid);
        if(positionEntries.Length == 0 || oldPb.time != this.personalBest.time){
            LoadTargets();
        }
    }

    void LoadStaticInfo(){
        // Declare the response here to access it from the logging part later.
        ExtraLeaderboardAPI::ExtraLeaderboardAPIResponse@ respLog = ExtraLeaderboardAPI::ExtraLeaderboardAPIResponse();
        // if activated, call the extra leaderboardAPI
        if(ExtraLeaderboardAPI::Active && !ExtraLeaderboardAPI::failedAPI){
            ExtraLeaderboardAPI::ExtraLeaderboardAPIRequest@ req = null;
            try
            {
                @req = ExtraLeaderboardAPI::PrepareRequest(this.mapUid, true);
            }
            catch
            {
                // we can assume that something went wrong while trying to prepare the request. We abort the refresh and try again later
                // also warn in the log that something went wrong
                warn("Something went wrong while trying to prepare the request. Aborting the refresh and trying again later");
                warn("Error message : " + getExceptionInfo());
                failedRefresh = true;
                return;
            }

            ExtraLeaderboardAPI::ExtraLeaderboardAPIResponse@ resp = ExtraLeaderboardAPI::GetExtraLeaderboard(req);

            // We extract the times from the response if there's any
            if(resp is null){
                warn("response from ExtraLeaderboardAPI is null or empty");
                return;
            }

            respLog = resp;

            // if there's a player count, try to extract it and set the player count
            if(resp.playerCount > 0){
                playerCount = resp.playerCount;
            } else {
                playerCount = -1;
            }

            // extract the medal entries
            array<LeaderboardEntry@> medalEntries;
            for(uint i = 0; i< resp.positions.Length; i++){
                if(resp.positions[i].entryType != EnumLeaderboardEntryType::MEDAL){
                    continue;
                }
                medalEntries.InsertLast(resp.positions[i]);
            }
            // sort the medal entries then add the description to them
            medalEntries.SortAsc();

            array<string> medalDesc = {};
            // only add the medal description if the associated medal is activated
            medalDesc.InsertLast("AT");
            medalDesc.InsertLast("Gold");
            medalDesc.InsertLast("Silver");
            medalDesc.InsertLast("Bronze");

            for(uint i = 0; i< medalEntries.Length; i++){
                medalEntries[i].desc = medalDesc[i];
                medalEntries[i].percentage = (100 * medalEntries[i].position) / playerCount;
            }
            medals = medalEntries;
        }
    }

    void LoadTargets(){
        auto percentages = GetPercentagesAbovePB(personalBestPercentage);
        array<int> positions;
        for(uint i = 0; i< percentages.Length; i++){
            positions.InsertLast(Math::Round(playerCount * (percentages[i] / 100.0f)));
        }

        // Declare the response here to access it from the logging part later.
        ExtraLeaderboardAPI::ExtraLeaderboardAPIResponse@ respLog = ExtraLeaderboardAPI::ExtraLeaderboardAPIResponse();
        // if activated, call the extra leaderboardAPI
        if(ExtraLeaderboardAPI::Active && !ExtraLeaderboardAPI::failedAPI){
            ExtraLeaderboardAPI::ExtraLeaderboardAPIRequest@ req = null;
            try
            {
                @req = ExtraLeaderboardAPI::PrepareRequestPositions(this.mapUid, positions);
            }
            catch
            {
                // we can assume that something went wrong while trying to prepare the request. We abort the refresh and try again later
                // also warn in the log that something went wrong
                warn("Something went wrong while trying to prepare the request. Aborting the refresh and trying again later");
                warn("Error message : " + getExceptionInfo());
                failedRefresh = true;
                return;
            }

            ExtraLeaderboardAPI::ExtraLeaderboardAPIResponse@ resp = ExtraLeaderboardAPI::GetExtraLeaderboard(req);

            // We extract the times from the response if there's any
            if(resp is null){
                warn("response from ExtraLeaderboardAPI is null or empty");
                return;
            }

            respLog = resp;

            // extract the medal entries
            array<LeaderboardEntry@> newPositionEntries;
            for(uint i = 0; i< resp.positions.Length; i++){
                if(resp.positions[i].entryType != EnumLeaderboardEntryType::POSITION){
                    continue;
                }
                resp.positions[i].percentage = (100 * resp.positions[i].position) / playerCount;
                newPositionEntries.InsertLast(resp.positions[i]);
            }
            // sort the medal entries then add the description to them
            newPositionEntries.SortAsc();
            positionEntries = newPositionEntries;
        }

    }

    string toString() {
        array<string> result;
        result.InsertLast(personalBest.toString());
        for(uint i = 0; i< medals.Length; i++){
            result.InsertLast(medals[i].toString());
        }
        for(uint i = 0; i< positionEntries.Length; i++){
            result.InsertLast(positionEntries[i].toString());
        }
        result.InsertLast("PlayerCount: " + playerCount);
        return string::Join(result, "\n");
    };
}


//Collect.as
class Leaderboard : Component {
    MapLeaderboardData@ data;

    Leaderboard(const string &in mapUid) {
        @data = MapLeaderboardData(mapUid);
        super();
    }

    // string toString() override {
    //     string s = "";
    //     if (setting_show_resets_session &&
    //     !(session == total && !setting_show_duplicates)) {
    //         s += "\\$bbb" + session;
    //     }
    //     if (setting_show_resets_session && setting_show_resets_total &&
    //      !(session == total && !setting_show_duplicates)) {
    //         s += "\\$fff  /  ";
    //     }
    //     if (setting_show_resets_total) {
    //         s += "\\$bbb" + total;
    //     }
    //     return s;
    // }
    // void destroy() override {
    //     running = false;
    // }

    void start() override {
        data.Initialise();
        Component::start();
    }

    void handler() override {
        while(running){
            PlayerState::sTMData@ TMData = PlayerState::GetRaceData();
            if(TMData.dEventInfo.FinishRun){
                print("finish" + TMData.dPlayerInfo.EndTime);
                data.RefreshPersonalBest();
                print(data.toString());
            }
            else if (TMData.dEventInfo.EndRun){
                print("end" + TMData.dPlayerInfo.EndTime);
                print(data.toString());
            }
            // auto app = GetApp();
            // auto playground = app.CurrentPlayground;
            // auto network = cast<CTrackManiaNetwork>(app.Network);
            // if (playground !is null && playground.GameTerminals.Length > 0) {
            //     auto terminal = playground.GameTerminals[0];
            //     auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
            //     if (gui_player !is null) {
            //         auto post = (cast<CSmScriptPlayer>(gui_player.ScriptAPI)).Post;
            //         if (!handled && post == CSmScriptPlayer::EPost::Char) {
            //             handled = true;
            //             session += 1;
            //             total += 1;
            //         }
            //         if (handled && post != CSmScriptPlayer::EPost::Char)
            //             handled = false;
            //         }
            // }
            yield();
        }
    }

    string toString() override {
        return data.toString();
    }
}

