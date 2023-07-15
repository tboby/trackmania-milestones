class Goals {
    Leaderboard@ leaderboard;
    LeaderboardEntry@ target;
    PlayerStats@ playerStats;
    Goals(Leaderboard@ leaderboard){
        @this.leaderboard = leaderboard;
        @this.playerStats = PlayerStats(leaderboard);
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

    MissionType GetNextMission(){
        auto sessionRecords = playerStats.SessionRecords;
        auto sessionRecordCount = sessionRecords.Length;
        // Check latest five records, mark if any were a pb, and get the fastest time
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
        auto warmupTarget = fastestTime * 1.1f;
        if(!pb && (fastestTime > warmupTarget || fastestTime <= 0)){
            return MissionType::Warmup;
        }
        auto consistencyTarget = fastestTime * 1.05f;
        if(playerStats.Average(5) > consistencyTarget){
            return MissionType::Consistency;
        }
        return MissionType::Medal;
    }
}


enum MissionType {
    Warmup,
    Consistency,
    Medal
}