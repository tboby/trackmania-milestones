class Goals {
    Leaderboard@ leaderboard;
    LeaderboardEntry@ target;
    Goals(Leaderboard@ leaderboard){
        @this.leaderboard = leaderboard;
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
}