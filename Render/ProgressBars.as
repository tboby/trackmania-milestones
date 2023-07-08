class ProgressBarItem {
    float position;
    vec4 color = vec4(1.0f, 1.0f, 1.0f, 1.0f);
    string label;
    ProgressBarItem(float position){
        this.position = position;
    }
    ProgressBarItem(float position, string label, vec4 color){
        this.position = position;
        this.label = label;
        this.color = color;
    }
}

class ProgressBar
{
    private float x, y, w, h;
    private vec4 fillColor, backColor, tickColor, textColor;
    private int font;

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
            nvg::MoveTo(vec2(x + tickPosition, y));
            nvg::LineTo(vec2(x + tickPosition, y + h));
            nvg::Stroke();

            // Add text labels
            nvg::Text(x + tickPosition, y - 5, items[i].label);
        }


    }
}

// void RenderProgressBar(ProgressBar@ pb, array<float>@ times, float bestTime)
// {
//     // Calculate progress based on best time
//     float progress = bestTime;
//     pb.render(progress, @times);
// }




// string ConvertTimeToDisplayFormat(int timeInMs)
// {
//     int minutes = timeInMs / (1000 * 60);
//     int seconds = (timeInMs / 1000) % 60;
//     int milliseconds = timeInMs % 1000;

//     return format("%02d:%02d.%03d", minutes, seconds, milliseconds);
// }

array<float> NormalizeTimes(array<int>@ times, int bestTime)
{
    array<float> retTimes;
    for(uint i = 0; i < times.Length; i++)
    {
        retTimes.InsertLast(float(times[i]) / float(bestTime));
    }
    return retTimes;
}


//A function which takes an array of medal times, an array of player times, and the best time
//and returns an array of ProgressBarItems
void RenderProgressBar(ProgressBar@ pb, array<LeaderboardEntry@> medals, array<LeaderboardEntry@> times, int bestTime, int playerCount)
{
    //medal color
    vec4 gold = vec4(1.0f, 0.8f, 0.0f, 1.0f);
    array<ProgressBarItem@> items;
    for(uint i = 0; i < medals.Length; i++)
    {
        items.InsertLast(ProgressBarItem(float(playerCount - medals[i].position) / float(playerCount), medals[i].desc, gold));
    }
    for(uint i = 0; i < times.Length; i++)
    {
        // if time is bestTime, set colour as yellow
        if(times[i].time == bestTime)
        {
            vec4 yellow = vec4(1.0f, 0.8f, 0.0f, 1.0f);
            items.InsertLast(ProgressBarItem(float(playerCount - times[i].position) / float(playerCount), TimeString(times[i].time), yellow));
        }
        else
        {
            items.InsertLast(ProgressBarItem(float(playerCount - times[i].position) / float(playerCount)));
        }
    }
    pb.render(1.0f, items);
}


// void RenderProgressBar(ProgressBar@ pb, array<int>@ times, int bestTime, array<string>@ labels)
// {
//     auto newTimes = NormalizeTimes(@times, bestTime);
//     float progress = 1.0f; // progress is always full when we use bestTime

//     pb.render(0.2f, @newTimes, labels);
// }

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
    ProgressBar@ pb = ProgressBar(0, screenSize.y - 50.0f, screenSize.x, 40.0f, fillColor, backColor, tickColor, textColor, "Arial");

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
    auto personalBest = mapWatcher.leaderboard.data.personalBest;
    // array<int>@ times = {60000, 120000, 240000, 180000}; // times in milliseconds
    //create four medal entries
    // array<LeaderboardEntry@> medals;
    // for(uint i = 0; i < times.Length; i++)
    // {
    //     auto entry = LeaderboardEntry();
    //     entry.position = (i + 1) * 100;
    //     entry.time = times[i];
    //     entry.desc = "Medal " + (i + 1);
    //     medals.InsertLast(entry);
    // }

    //create four player entries with different times
    // array<LeaderboardEntry@> playerTimes;
    // auto entry = LeaderboardEntry();
    // entry.position = 50;
    // entry.time = 50000;
    // entry.desc = "Player 1";
    // playerTimes.InsertLast(entry);
    // entry = LeaderboardEntry();
    // entry.position = 80;
    // entry.time = 80000;
    // entry.desc = "Player 2";
    // playerTimes.InsertLast(entry);
    // entry = LeaderboardEntry();
    // entry.position = 30;
    // entry.time = 90000;
    // entry.desc = "Player 3";
    // playerTimes.InsertLast(entry);
    // entry = LeaderboardEntry();
    // entry.position = 40;
    // entry.time = 180000;
    // entry.desc = "Player 4";
    // playerTimes.InsertLast(entry);


    // int bestTime = 90000;

    RenderProgressBar(@pb, medals, times, personalBest.time, playerCount);

    // array<string> labels;
    // for(uint i = 0; i < times.Length; i++)
    // {
    //     labels.InsertLast(TimeString(times[i]));
    // }

    // RenderProgressBar(@pb, @times, bestTime, @labels);

    // Print times in display format
    // for(uint i = 0; i < times.length(); i++)
    // {
    //     print(ConvertTimeToDisplayFormat(times[i]));
    // }
}
