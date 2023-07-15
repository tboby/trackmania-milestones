class Goals {
    Leaderboard@ leaderboard;
    LeaderboardEntry@ target;
    PlayerStats@ playerStats;
    IMission@ mission;
    array<IMission@> possibleMissions;
    Goals(Leaderboard@ leaderboard){
        @this.leaderboard = leaderboard;
        @this.playerStats = PlayerStats(leaderboard);
        this.possibleMissions = {
            DiscoveryFirstRun(playerStats),
            DiscoveryNoRespawn(playerStats),
            Warmup(),
            Consistency(),
            DefaultMission()
        };
    }

    void CalculateObjective(){
        if(leaderboard.data.medals.Length == 0){
            return;
        }
        auto medals = leaderboard.data.medals;
        auto pb = leaderboard.data.personalBest;
        LeaderboardEntry nextTarget = medals[0];
        for(uint i = 1; i< medals.Length; i++){
            auto entry = medals[i];
            if(entry.time > nextTarget.time && (entry.time < pb.time || pb.time < 0)){
                nextTarget = entry;
            }
        }

        @target = nextTarget;
    }

    void CheckMission(){
        if(mission is null){
            return;
        }
        if(mission.IsComplete(playerStats)){
            GetNextMission();
        }
    }

    void GetNextMission(){
        for(uint i = 0; i < possibleMissions.Length; i++){
            auto possibleMission = possibleMissions[i];
            if(possibleMission.IsEligible(playerStats)){
                @mission = possibleMission;
                return;
            }
        }
    }

    // MissionType GetNextMission(){
    //     auto sessionRecords = playerStats.SessionRecords;
    //     auto sessionRecordCount = sessionRecords.Length;
    //     // Check latest five records, mark if any were a pb, and get the fastest time
    //     bool pb = false;
    //     float fastestTime = -1;
    //     for(uint i = 0; i < sessionRecordCount; i++){
    //         auto record = sessionRecords[i];
    //         if(record.time < fastestTime || fastestTime <= 0){
    //             fastestTime = record.time;
    //         }
    //         if(record.pb){
    //             pb = true;
    //         }
    //     }
    //     auto warmupTarget = fastestTime * 1.1f;
    //     if(!pb && (fastestTime > warmupTarget || fastestTime <= 0)){
    //         return MissionType::Warmup;
    //     }
    //     auto consistencyTarget = fastestTime * 1.05f;
    //     if(playerStats.Average(5) > consistencyTarget){
    //         return MissionType::Consistency;
    //     }
    //     return MissionType::Medal;
    // }
}

interface IMission {
    bool IsEligible(PlayerStats@ playerStats);
    bool IsComplete(PlayerStats@ playerStats);
    string GetTitle();
    string GetDescription();
}



class DiscoveryFirstRun : IMission {
    PlayerStats@ playerStats;
    DiscoveryFirstRun(PlayerStats@ playerStats){
        @this.playerStats = playerStats;
    }

    bool IsEligible(PlayerStats@ playerStats){
        return playerStats.PersonalBest < 0 || playerStats.PlayedBeforePlugin;
    }
    bool IsComplete(PlayerStats@ playerStats){
        return playerStats.PersonalBest > 0 && !playerStats.PlayedBeforePlugin;
    }
    string GetTitle(){
        if(playerStats.PlayedBeforePlugin){
            return "(Re)Discovery I";
        }
        return "Discovery I";
    }
    string GetDescription(){
        return "Complete your first run";
    }
}

class DiscoveryNoRespawn : IMission {
    PlayerStats@ playerStats;
    DiscoveryNoRespawn(PlayerStats@ playerStats){
        @this.playerStats = playerStats;
    }
    bool IsEligible(PlayerStats@ playerStats){
        return playerStats.PersonalBest > 0 && !IsComplete(playerStats);
    }
    bool IsComplete(PlayerStats@ playerStats){
        // Check all runs for a no respawn run
        auto sessionRecords = playerStats.SessionRecords;
        auto sessionRecordCount = sessionRecords.Length;
        for(uint i = 0; i < sessionRecordCount; i++){
            auto record = sessionRecords[i];
            if(record.time == record.noRespawnTime){
                return true;
            }
        }
        return false;
    }
    string GetTitle(){
        if(playerStats.PlayedBeforePlugin){
            return "(Re)Discovery II";
        }
        return "Discovery II";
    }
    string GetDescription(){
        return "Complete your first run without respawning";
    }
}

// Warmup - Complete a run within 10% of your PB
class Warmup : IMission {
    // Don't use if this is the first session
    bool IsEligible(PlayerStats@ playerStats){
        return playerStats.OldRecords.Length > 0 && !IsComplete(playerStats);
    }
    // Check if a pb was set in the current session, or if the fastest time is within 10% of the PB
    bool IsComplete(PlayerStats@ playerStats){
        auto sessionRecords = playerStats.SessionRecords;
        auto sessionRecordCount = sessionRecords.Length;
        bool pb = false;
        float fastestTime = -1;
        for(uint i = 0; i < sessionRecordCount; i++){
            auto record = sessionRecords[i];
            if(record.time < fastestTime || fastestTime <= 0){
                fastestTime = record.time;
            }
            if(record.pb){
                pb = true;
            }
        }
        if(pb){
            return true;
        }
        auto warmupTarget = playerStats.PersonalBest * 1.1f;
        if((fastestTime < warmupTarget && fastestTime > 0)){
            return true;
        }
        return false;
    }
    string GetTitle(){
        return "Warmup";
    }
    string GetDescription(){
        return "Complete a run within 10% of your PB";
    }
}

// Consistency - Get your median time within 5% of your PB
class Consistency : IMission {
    bool IsEligible(PlayerStats@ playerStats){
        return !IsComplete(playerStats);
    }
    bool IsComplete(PlayerStats@ playerStats){
        return playerStats.Median(5) < playerStats.PersonalBest * 1.05f;
    }
    string GetTitle(){
        return "Consistency";
    }
    string GetDescription(){
        return "Get your median time within 5% of your PB";
    }
}

class DefaultMission : IMission {
    bool IsEligible(PlayerStats@ playerStats){
        return true;
    }
    bool IsComplete(PlayerStats@ playerStats){
        return false;
    }
    string GetTitle(){
        return "Default Mission";
    }
    string GetDescription(){
        return "Default Mission";
    }
}




enum MissionType {
    DiscoveryFirstRun,
    DiscoveryNoRespawn,
    Warmup,
    Consistency,
    Medal
}