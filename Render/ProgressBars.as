class ProgressBar
{
    private float x, y, w, h;
    private vec4 fillColor, backColor, tickColor;

    ProgressBar(float x, float y, float w, float h, const vec4&in fillColor, const vec4&in backColor, const vec4&in tickColor)
    {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.fillColor = fillColor;
        this.backColor = backColor;
        this.tickColor = tickColor;
    }

    void render(float progress, array<float>@ times)
    {
        // Create the background bar
        nvg::BeginPath();
        nvg::FillColor(backColor);
        nvg::Rect(x, y, w, h);
        nvg::Fill();

        // Create the ticks
        for(uint i = 0; i < times.Length; i++)
        {
            float tickPosition = times[i] * w;

            nvg::BeginPath();
            nvg::StrokeColor(tickColor);
            nvg::MoveTo(vec2(x + tickPosition, y));
            nvg::LineTo(vec2(x + tickPosition, y + h));
            nvg::Stroke();
        }

        // Create the progress bar
        nvg::BeginPath();
        nvg::FillColor(fillColor);
        nvg::Rect(x, y, w * progress, h);
        nvg::Fill();
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

void RenderProgressBar(ProgressBar@ pb, array<int>@ times, int bestTime)
{
    auto newTimes = NormalizeTimes(@times, bestTime);
    float progress = 1.0f; // progress is always full when we use bestTime

    pb.render(0.2f, @newTimes);
}

void RenderBars()
{
    vec4 fillColor = vec4(0.0f, 0.7f, 0.3f, 1.0f); // Green color
    vec4 backColor = vec4(0.2f, 0.2f, 0.2f, 1.0f); // Dark grey color
    vec4 tickColor = vec4(1.0f, 0.0f, 0.0f, 1.0f); // Red color
    ProgressBar@ pb = ProgressBar(800.0f, 1000.0f, 200.0f, 30.0f, fillColor, backColor, tickColor);

    array<int>@ times = {60000, 120000, 240000, 180000}; // times in milliseconds
    int bestTime = 240000;

    RenderProgressBar(@pb, @times, bestTime);

    // Print times in display format
    // for(uint i = 0; i < times.length(); i++)
    // {
    //     print(ConvertTimeToDisplayFormat(times[i]));
    // }
}
