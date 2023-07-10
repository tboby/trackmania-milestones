class MapLeaderboardData {
    array<const LeaderboardEntry@> medals;
    array<LeaderboardEntry@> positionEntries;
    array<LeaderboardEntry@> percentageEntries;
    array<LeaderboardEntry@> timeEntryCache;
    int playerCount;
    LeaderboardEntry personalBest;
    LeaderboardEntry noRespawnLast;
    LeaderboardEntry worldRecord;
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
    void Initialise(RacingData@ racingData){
        LoadStaticInfo(racingData.records);
        LoadKeyPositions();
        RefreshPersonalBest();
    }

    void RefreshPersonalBest(){
        auto oldPb = this.personalBest;
        this.personalBest = GetPersonalBestEntry(this.mapUid);
        if(positionEntries.Length == 0 || oldPb.time != this.personalBest.time){
            LoadTargets();
        }
    }

    // Get the leaderboard entry for the given time, caching
    // the result for future calls.
    LeaderboardEntry@ GetTimeEntry(int time){
        for(uint i = 0; i< timeEntryCache.Length; i++){
            if(timeEntryCache[i].time == time){
                return timeEntryCache[i];
            }
        }
        auto entry = GetSpecificPositionEntry(this.mapUid, time);
        timeEntryCache.InsertLast(entry);
        return entry;
    }

    // Get the leaderboard entry for the given time, reading from cache only
    LeaderboardEntry@ GetTimeEntryFromCache(int time){
        for(uint i = 0; i< timeEntryCache.Length; i++){
            if(timeEntryCache[i].time == time){
                return timeEntryCache[i];
            }
        }
        return null;
    }
    // void UpdatePersonalBest(int newPb){
    //     int maxTries = 10;
    //     int i = 0;
    //     while(i < maxTries){
    //         i++;
    //         auto remotePb = GetSpecificTimeEntry(this.mapUid);
    //         if(remotePb.time == newPb && (this.personalBest.time < 0 || newPb < this.personalBest.time) && newPb > 0){
    //             this.personalBest = remotePb;
    //             LoadTargets();
    //             return;
    //         }
    //         sleep(50);
    //     }
    // }
     void UpdatePersonalBest(int newPb){
        auto positionEntry = GetSpecificPositionEntry(this.mapUid, newPb);
        this.personalBest.position = positionEntry.position;
        this.personalBest.time = positionEntry.time;
        LoadTargets();
    }


     void UpdateNoRespawnLast(int newNoRespawn){
        auto positionEntry = GetSpecificPositionEntry(this.mapUid, newNoRespawn);
        this.noRespawnLast.position = positionEntry.position;
        this.noRespawnLast.time = positionEntry.time;
        print("asd");
        print(this.noRespawnLast.time);
        print(newNoRespawn);
    }

    void LoadStaticInfo(array<RaceRecord@> records){
        // Declare the response here to access it from the logging part later.
        ExtraLeaderboardAPI::ExtraLeaderboardAPIResponse@ respLog = ExtraLeaderboardAPI::ExtraLeaderboardAPIResponse();
        // if activated, call the extra leaderboardAPI
        if(ExtraLeaderboardAPI::Active && !ExtraLeaderboardAPI::failedAPI){
            ExtraLeaderboardAPI::ExtraLeaderboardAPIRequest@ req = null;
            try
            {
                @req = ExtraLeaderboardAPI::PrepareRequest(this.mapUid, true);
                //Add score requests from records
                for(uint i = 0; i < records.Length; i++){
                    if(records[i].time > 0){
                        req.scores.InsertLast(records[i].time);
                    }
                }
                req.positions.InsertLast(1);
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
                if(playerCount % 100000 == 0){
                    playerCount += 100000;
                }
                else if(playerCount % 10000 == 0){
                    playerCount += 10000;
                }
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
            // clone medals
            array<const LeaderboardEntry@> newMedals;
            for(uint i = 0; i< medalEntries.Length; i++){
                newMedals.InsertLast(medalEntries[i].clone());
            }

            medals = newMedals;

            // extract all the time entries into the class position entries
            array<LeaderboardEntry@> timeEntries;
            for(uint i = 0; i< resp.positions.Length; i++){
                if(resp.positions[i].entryType != EnumLeaderboardEntryType::TIME){
                    continue;
                }
                timeEntries.InsertLast(resp.positions[i]);
            }
            timeEntryCache = timeEntries;

            // Add world record to field
            for(uint i = 0; i< resp.positions.Length; i++){
                if(resp.positions[i].position != 1){
                    continue;
                }
                worldRecord = resp.positions[i];
            }

        }
    }

    // Get the time at every 5% from 0 to 100
    void LoadKeyPositions(){
        array<int> positions;
        for(uint i = 0; i< 21; i++){
            positions.InsertLast(Math::Round(playerCount * (i * 5 / 100.0f)));
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
                resp.positions[i].percentage = Math::Round((100.0f * resp.positions[i].position) / playerCount);
                newPositionEntries.InsertLast(resp.positions[i]);
            }
            // sort the medal entries then add the description to them
            newPositionEntries.SortAsc();
            percentageEntries = newPositionEntries;
        }

    }

    void LoadTargets(){
        auto percentages = GetPercentagesAbovePB(personalBestPercentage);
        array<int> positions;
        for(uint i = 0; i< percentages.Length; i++){
            auto input = Math::Round(playerCount * (percentages[i] / 100.0f));
            auto position = GetSpecificTimeEntry(this.mapUid, input);
            print(input);
            print(TimeString(position.time));
            print(position.position);
            positions.InsertLast(Math::Round(playerCount * (percentages[i] / 100.0f)));
        }
        // print("10k" + GetSpecificTimeEntry(this.mapUid, 10000).toString());
        // print("20k" + GetSpecificTimeEntry(this.mapUid, 20000).toString());
        // print("30k" + GetSpecificTimeEntry(this.mapUid, 30000).toString());
        // print("40k" + GetSpecificTimeEntry(this.mapUid, 40000).toString());
        // print("" + GetSpecificPositionEntry(this.mapUid, 32000).toString());
        // print("" + GetSpecificPositionEntry(this.mapUid, 33000).toString());
        // print("" + GetSpecificPositionEntry(this.mapUid, 34000).toString());



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
    RacingData racingData;

    Leaderboard(const string &in mapUid, RacingData racingData) {
        @data = MapLeaderboardData(mapUid);
        this.racingData = racingData;
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
        data.Initialise(this.racingData);
        Component::start();
    }

    void handler() override {
        while(running){
            PlayerState::sTMData@ TMData = PlayerState::GetRaceData();
            if(TMData.dEventInfo.FinishRun){
                print("finish" + TMData.dPlayerInfo.EndTime);
                auto goals = Goals(this);
                goals.CalculateObjective();
                auto pb = TMData.dPlayerInfo.EndTime < data.personalBest.time;
                auto mlf = MLFeed::GetRaceData_V4();
            	auto plf = mlf.GetPlayer_V4(MLFeed::LocalPlayersName);
                racingData.records.InsertLast(RaceRecord(TMData.dPlayerInfo.EndTime, goals.target.time, pb, Time::Stamp, plf.LastTheoreticalCpTime));

                // yield();
                // data.RefreshPersonalBest();
                data.GetTimeEntry(plf.LastCpTime);
                data.UpdatePersonalBest(plf.LastCpTime);
                data.GetTimeEntry(plf.LastTheoreticalCpTime);
                data.UpdateNoRespawnLast(plf.LastTheoreticalCpTime);
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

