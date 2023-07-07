class ProgressBar
{
    private float x, y, w, h;
    private vec4 fillColor, backColor;

    ProgressBar(float x, float y, float w, float h, const vec4&in fillColor, const vec4&in backColor)
    {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.fillColor = fillColor;
        this.backColor = backColor;
    }

    void render(float progress)
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
    }
}

void RenderProgressBars(ProgressBar@ pb, array<float>@ times, float target, float current)
{
    for (uint i = 0; i < times.Length; i++)
    {
        // Calculate progress based on target and current pb
        float progress = CalculateProgress(times[i], target, current);
        pb.render(progress);
    }
}

float CalculateProgress(float time, float target, float current)
{
    // Implement your progress calculation logic here
    // For example:
    float progress = (time - current) / (target - current);
    progress = Math::Clamp(progress, 0.0f, 1.0f); // Ensure progress is between 0 and 1
    return progress;
}

void RenderBars()
{
    vec4 fillColor = vec4(0.0f, 0.7f, 0.3f, 1.0f); // Green color
    vec4 backColor = vec4(0.2f, 0.2f, 0.2f, 1.0f); // Dark grey color
    ProgressBar@ pb = ProgressBar(50.0f, 50.0f, 300.0f, 30.0f, fillColor, backColor);

    array<float>@ times = {1.0f, 1.2f, 0.9f, 1.1f};
    float target = 1.3f;
    float current = 1.0f;

    RenderProgressBars(@pb, @times, target, current);
}
