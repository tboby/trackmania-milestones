class PlayerStats{
    const Leaderboard@ leaderboard;
    PlayerStats(const Leaderboard@ leaderboard){
        @this.leaderboard = leaderboard;
    }
    // Get all records which were set in the last 24 hours, and have no more than one hour between timestamps
    array<const RaceRecord@> SessionRecords {
        get {
            array<const RaceRecord@> records;
            auto now = Time::Stamp;
            auto oneDay = 24 * 60 * 60;
            int64 last = 0;
            for (int i = leaderboard.racingData.records.Length - 1; i >= 0; i--) {
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

// Inverse of SessionRecords, returning all records which were set more than 24 hours ago, or have more than one hour between timestamps
    array<const RaceRecord@> OldRecords {
        get {
             array<const RaceRecord@> records;
            auto now = Time::Stamp;
            auto oneDay = 24 * 60 * 60;
            int64 last = 0;
            bool foundOld = false;
            for (int i = leaderboard.racingData.records.Length - 1; i >= 0; i--) {
                const RaceRecord@ record = leaderboard.racingData.records[i];
                if(foundOld){
                    records.InsertLast(record);
                    continue;
                }
                if ((now - record.timestamp) > oneDay) {
                    foundOld = true;
                    records.InsertLast(record);
                    continue;
                }
                if (last != 0 && (record.timestamp - last) > 60 * 60) {
                    foundOld = true;
                    records.InsertLast(record);
                    last = record.timestamp;
                }
                else {
                    last = record.timestamp;
                }
            }
            return records;


        }
    }

    // Calculate the average time from the last "windowSize" races
    int Average(int windowSize){
        auto records = SessionRecords;
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