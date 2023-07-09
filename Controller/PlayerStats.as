class PlayerStats{
    const Leaderboard@ leaderboard;
    PlayerStats(const Leaderboard@ leaderboard){
        @this.leaderboard = leaderboard;
    }

    // Calculate the average time from the last "windowSize" races
    int Average(int windowSize){
        auto records = leaderboard.racingData.records;
        int averageTime = 0;
        int count = 0;
        for (int i = records.Length - 1; i >= 0 && count < windowSize; i--){
            averageTime += records[i].time;
            count++;
        }
        return averageTime / count;
    }

}