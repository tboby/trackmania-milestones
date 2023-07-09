class PlayerStats{
    const Leaderboard@ leaderboard;
    PlayerStats(const Leaderboard@ leaderboard){
        @this.leaderboard = leaderboard;
    }
    // Get all records which were set in the last 24 hours, and have no more than one hour between timestamps
    private array<const RaceRecord@> sessionRecords {
        get {
            array<const RaceRecord@> records;
            auto now = Time::Stamp;
            auto oneDay = 24 * 60 * 60;
            int64 last = 0;
            for (uint i = leaderboard.racingData.records.Length - 1; i >= 0; i--) {
                const RaceRecord@ record = leaderboard.racingData.records[i];
                if ((now - record.timestamp) > oneDay) {
                    break;
                }
                if (last == 0 || (record.timestamp - last) < 60 * 60) {
                    records.InsertLast(record);
                    last = record.timestamp;
                }
            }
            return records;
        }
    }
    // Calculate the average time from the last "windowSize" races
    int Average(int windowSize){
        auto records = sessionRecords;
        int averageTime = 0;
        int count = 0;
        for (int i = records.Length - 1; i >= 0 && count < windowSize; i--){
            averageTime += records[i].time;
            count++;
        }
        if(count > 0){
            return averageTime / count;
        }
        return -1;
    }

}