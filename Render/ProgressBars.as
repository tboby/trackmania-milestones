class ProgressBarItem {
    float position;
    vec4 color = vec4(1.0f, 1.0f, 1.0f, 1.0f);
    string label;
    string prettyTime;
    float height = 1.0f;
    ProgressBarItem(float position){
        this.position = position;
    }
    ProgressBarItem(float position, string label, vec4 color, string prettyTime){
        this.position = position;
        this.label = label;
        this.color = color;
        this.prettyTime = prettyTime;
    }
}

class ProgressBar
{
    private float x, y, w, h;
    private vec4 fillColor, backColor, tickColor, textColor;
    private int font;
    private float TAU = 6.283185307179586;

    ProgressBar(float x, float y, float w, float h, const vec4&in fillColor, const vec4&in backColor, const vec4&in tickColor, const vec4&in textColor, const string&in fontName)
    {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.fillColor = fillColor;
        this.backColor = backColor;
        this.tickColor = tickColor;
        this.textColor = textColor;

                // Load the font and store the id
        this.font = nvg::LoadFont(fontName);

    }

    void render(float progress, array<ProgressBarItem@> items)
    {
        // Create the background bar
        nvg::BeginPath();
        nvg::FillColor(backColor);
        nvg::Rect(x, y, w, h);
        nvg::Fill();

        // Create the progress bar
        nvg::BeginPath();
        nvg::FillColor(fillColor);
        nvg::Rect(x, y, w * progress, h);
        nvg::Fill();

        // Create the ticks and labels
        nvg::FontFace(font);
        nvg::FontSize(14.0f);
        nvg::FillColor(textColor);



        // Create the ticks
        for(uint i = 0; i < items.Length; i++)
        {
            float tickPosition = items[i].position * w;
            nvg::BeginPath();
            nvg::StrokeColor(items[i].color);
            nvg::MoveTo(vec2(x + tickPosition, y + (h * (1 - items[i].height))));
            nvg::LineTo(vec2(x + tickPosition, y + h));
            nvg::Stroke();

            // Add text labels
            float textWidth = nvg::TextBounds(items[i].label).x;
            float labelStartPos = x + tickPosition - (textWidth / 2.0f);
            float labelEndPos = labelStartPos + textWidth;
            // Check and adjust positions so labels don't cross the progress bar boundaries
            if (labelStartPos < x) labelStartPos = x;
            if (labelEndPos > x + w) labelStartPos = x + w - textWidth;
            auto labelPos = vec2(labelStartPos, y - 5);

            float nCopies = 32; // this does not seem to be expensive
            float sw = 14.0f * 0.11;
            nvg::FillColor(vec4(0.0f, 0.0f, 0.0f, 1.0f));
            for (float j = 0; j < nCopies; j++) {
                float angle = TAU * float(j) / nCopies;
                vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * sw;
                nvg::Text(labelPos + offs, items[i].label);
            }
            nvg::FillColor(textColor);
            nvg::Text(labelPos, items[i].label);

            float prettyTimeWidth = nvg::TextBounds(items[i].prettyTime).x;
            float prettyTimeStartPos = x + tickPosition - (prettyTimeWidth / 2.0f);
            float prettyTimeEndPos = prettyTimeStartPos + prettyTimeWidth;
            if (prettyTimeStartPos < x) prettyTimeStartPos = x;
            if (prettyTimeEndPos > x + w) prettyTimeStartPos = x + w - prettyTimeWidth;
            auto prettyTimePos = vec2(prettyTimeStartPos, y + h + 15);
            nvg::FillColor(vec4(0.0f, 0.0f, 0.0f, 1.0f));
            for (float j = 0; j < nCopies; j++) {
                float angle = TAU * float(j) / nCopies;
                vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * sw;
                nvg::Text(prettyTimePos + offs, items[i].prettyTime);
            }
            nvg::FillColor(textColor);
            nvg::Text(prettyTimePos, items[i].prettyTime);
        }


    }
}

array<float> NormalizeTimes(array<int>@ times, int bestTime)
{
    array<float> retTimes;
    for(uint i = 0; i < times.Length; i++)
    {
        retTimes.InsertLast(float(times[i]) / float(bestTime));
    }
    return retTimes;
}

class FixedPointPositioning {
    private array<int> times;
    private array<float> points;
    FixedPointPositioning(array<int>@ times, array<float>@ points) {
        this.times = times;
        this.points = points;
    }
    // Interpolate between the fixed points either side
    float getPosition(float time) {
        // print(TimeString(time));
        for (uint i = 0; i < times.Length; i++) {
            if (time > times[i]) {
                if (i == 0) {
                    return points[0];
                } else {
                    float t = float(times[i - 1] - time) / float(times[i - 1] - times[i]);
                    return points[i - 1] + t * (points[i] - points[i - 1]);
                }
            }
        }
        return points[points.Length - 1];
    }
}
// 100, 50, 10
// 0,   1,  2
// 60 -> i = 1
//


// A function like RenderProgressBar which uses the four medal values as fixed points and scales the rest of the times evenly
// between them
void RenderProgressBarTwo(ProgressBar@ pb, array<const LeaderboardEntry@> medals, array<LeaderboardEntry@> times,
     LeaderboardEntry@ personalBest, int playerCount, LeaderboardEntry@ worldRecord,
     array<LeaderboardEntry@> percentageEntries, LeaderboardEntry@ noRespawnBest)
{
    array<int> fixedTimes;
    array<float> fixedPoints;
    for(uint i = 0; i < medals.Length; i++)
    {
        fixedTimes.InsertLast(medals[i].time);
        fixedPoints.InsertLast(float(playerCount - medals[i].position) / float(playerCount));
    }
    fixedTimes.InsertLast(worldRecord.time);
    fixedPoints.InsertLast(1.0f);
    fixedTimes.SortDesc();
    fixedPoints.SortAsc();
    //print times and points
    // for(uint i = 0; i < fixedTimes.Length; i++)
    // {
        // print("time: " + TimeString(fixedTimes[i]) + " point: " + fixedPoints[i]);
    // }

    auto interpolation = FixedPointPositioning(fixedTimes, fixedPoints);
    //medal color
    vec4 gold = vec4(1.0f, 0.8f, 0.0f, 1.0f);
    // percentage blue color
    vec4 blue = vec4(0.0f, 0.0f, 1.0f, 1.0f);
    array<ProgressBarItem@> items;
    for(uint i = 0; i < medals.Length; i++)
    {
        items.InsertLast(ProgressBarItem(float(playerCount - medals[i].position) / float(playerCount), medals[i].desc, gold, TimeString(medals[i].time)));
    }
    vec4 yellow = vec4(1.0f, 0.8f, 0.0f, 1.0f);
    if(personalBest.time > 0){
        items.InsertLast(ProgressBarItem(interpolation.getPosition(personalBest.time), "PB", yellow, TimeString(personalBest.time)));
    }
    vec4 red = vec4(1.0f, 0.0f, 0.0f, 1.0f);
    if(noRespawnBest.time > 0 && noRespawnBest.time != personalBest.time){
        items.InsertLast(ProgressBarItem(interpolation.getPosition(noRespawnBest.time), "Cope", red, TimeString(noRespawnBest.time)));
    }
    items.InsertLast(ProgressBarItem(1.0f, "WR", yellow, TimeString(worldRecord.time)));
    for(uint i = 0; i < times.Length; i++)
    {
        items.InsertLast(ProgressBarItem(interpolation.getPosition(times[i].time)));
    }
    for(uint i = 0; i < percentageEntries.Length; i++)
    {
        auto item = ProgressBarItem(interpolation.getPosition(percentageEntries[i].time), percentageEntries[i].desc, blue, TimeString(percentageEntries[i].time));

        if((percentageEntries[i].percentage) % 10 == 0.0f){
            item.height = 0.75f;
        }
        else {
            item.height = 0.5f;
        }
        items.InsertLast(item);
    }
    pb.render(interpolation.getPosition(personalBest.time), items);
}



//A function which takes an array of medal times, an array of player times, and the best time
//and returns an array of ProgressBarItems
void RenderProgressBar(ProgressBar@ pb, array<LeaderboardEntry@> medals, array<LeaderboardEntry@> times,
     LeaderboardEntry@ personalBest, int playerCount, LeaderboardEntry@ worldRecord,
     array<LeaderboardEntry@> percentageEntries)
{
    //medal color
    vec4 gold = vec4(1.0f, 0.8f, 0.0f, 1.0f);
    // percentage blue color
    vec4 blue = vec4(0.0f, 0.0f, 1.0f, 1.0f);
    array<ProgressBarItem@> items;
    for(uint i = 0; i < medals.Length; i++)
    {
        items.InsertLast(ProgressBarItem(float(playerCount - medals[i].position) / float(playerCount), medals[i].desc, gold, TimeString(medals[i].time)));
    }
    vec4 yellow = vec4(1.0f, 0.8f, 0.0f, 1.0f);
    items.InsertLast(ProgressBarItem(float(playerCount - personalBest.position) / float(playerCount), "PB", yellow, TimeString(personalBest.time)));
    items.InsertLast(ProgressBarItem(1.0f, "WR", yellow, TimeString(worldRecord.time)));
    for(uint i = 0; i < times.Length; i++)
    {
        items.InsertLast(ProgressBarItem(float(playerCount - times[i].position) / float(playerCount)));
    }
    for(uint i = 0; i < percentageEntries.Length; i++)
    {
        auto item = ProgressBarItem(float(playerCount - percentageEntries[i].position) / float(playerCount), percentageEntries[i].desc, blue, TimeString(percentageEntries[i].time));

        if((percentageEntries[i].percentage) % 10 == 0.0f){
            item.height = 0.75f;
        }
        else {
            item.height = 0.5f;
        }
        items.InsertLast(item);
    }
    pb.render(float(playerCount - personalBest.position) / float(playerCount), items);
}


void RenderBars()
{
    if(mapWatcher.leaderboard.data.playerCount == 0)
    {
        return;
    }
    vec4 fillColor = vec4(0.0f, 0.7f, 0.3f, 1.0f); // Green color
    vec4 backColor = vec4(0.2f, 0.2f, 0.2f, 1.0f); // Dark grey color
    vec4 tickColor = vec4(1.0f, 0.0f, 0.0f, 1.0f); // Red color
    vec4 textColor = vec4(1.0f, 1.0f, 1.0f, 1.0f); // White color
    // Calculate trackmania openplanet screen width from api
    vec2 screenSize = vec2(Draw::GetWidth(), Draw::GetHeight());
    ProgressBar@ pb = ProgressBar(0, screenSize.y - 60.0f, screenSize.x, 40.0f, fillColor, backColor, tickColor, textColor, "Arial");

    auto medals = mapWatcher.leaderboard.data.medals;
    auto playerCount = mapWatcher.leaderboard.data.playerCount;
    array<RaceRecord@> playerTimes = mapWatcher.leaderboard.racingData.records;
    // For each player time, create a leaderboardentry with the position, time, and name
    array<LeaderboardEntry@> times;
    for(uint i = 0; i < playerTimes.Length; i++)
    {
        auto entry = LeaderboardEntry();
        entry.time = playerTimes[i].time;
        auto cacheHit = mapWatcher.leaderboard.data.GetTimeEntryFromCache(playerTimes[i].time);
        if(!(cacheHit is null)){
            entry.position = cacheHit.position;
            times.InsertLast(entry);
        }
    }

    auto percentageEntries = mapWatcher.leaderboard.data.percentageEntries;
    auto personalBest = mapWatcher.leaderboard.data.personalBest;
    auto worldRecord = mapWatcher.leaderboard.data.worldRecord;
    auto noRespawnBest = mapWatcher.leaderboard.data.noRespawnBest;


    RenderProgressBarTwo(@pb, medals, times, personalBest, playerCount, worldRecord, percentageEntries, noRespawnBest);


}
