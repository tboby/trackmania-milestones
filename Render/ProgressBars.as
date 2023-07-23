const float TAU = 6.283185307179586;

interface Drawable{
    void Draw(float x, float y, float w, float h, vec4 textColor) const;
}

class ProgressBarItem : Drawable{
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

    void Draw(float x, float y, float w, float h, vec4 textColor) const override {
        float tickPosition = position * w;
        nvg::BeginPath();
        nvg::StrokeColor(color);
        nvg::MoveTo(vec2(x + tickPosition, y + (h * (1 - height))));
        nvg::LineTo(vec2(x + tickPosition, y + h));
        nvg::Stroke();

        // Add text labels
        float labelStartPos = x + tickPosition;

        // transform the origin to the label's starting point
        nvg::Save();  // save the current state
        nvg::Translate(labelStartPos, y - 5);  // new origin at the label's start
        nvg::Rotate(-TAU / 8.0f);  // rotate by -45 degrees counterclockwise
        auto nCopies = 12;
        auto sw = 14.0f * 0.11f;
        // now we can render the text as if it started at the origin
        nvg::FillColor(vec4(0.0f, 0.0f, 0.0f, 1.0f));
        for (float j = 0; j < nCopies; j++) {
            float angle = TAU * float(j) / nCopies;
            vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * sw;
            nvg::Text(offs, label);  // changed the position to offs
        }
        nvg::FillColor(textColor);
        nvg::Text(vec2(0, 0), label);  // render text at the origin

        // restore the transformations
        nvg::Restore();  // restore the saved state, effectively undoing the translations and rotations

        float prettyTimeWidth = nvg::TextBounds(prettyTime).x;
        float prettyTimeStartPos = x + tickPosition - (prettyTimeWidth / 2.0f);
        float prettyTimeEndPos = prettyTimeStartPos + prettyTimeWidth;
        if (prettyTimeStartPos < x) prettyTimeStartPos = x;
        if (prettyTimeEndPos > x + w) prettyTimeStartPos = x + w - prettyTimeWidth;
        auto prettyTimePos = vec2(prettyTimeStartPos, y + h + 15);
        nvg::FillColor(vec4(0.0f, 0.0f, 0.0f, 1.0f));
        for (float j = 0; j < nCopies; j++) {
            float angle = TAU * float(j) / nCopies;
            vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * sw;
            nvg::Text(prettyTimePos + offs, prettyTime);
        }
        nvg::FillColor(textColor);
        nvg::Text(prettyTimePos, prettyTime);

    }
}

// Progress bar item where multiple have the same time and we want to display them as a stack of labels
class StackedProgressBarItem : ProgressBarItem {
    array<string> labels;
    StackedProgressBarItem(float position, array<string> labels, vec4 color, string prettyTime){
        super(position, "", color, prettyTime);
        this.labels = labels;
    }

void Draw(float x, float y, float w, float h, vec4 textColor) const override {
    float tickPosition = position * w;
    nvg::BeginPath();
    nvg::StrokeColor(color);
    nvg::MoveTo(vec2(x + tickPosition, y + (h * (1 - height))));
    nvg::LineTo(vec2(x + tickPosition, y + h));
    nvg::Stroke();

    // Add text labels
    auto nCopies = 12;
    auto sw = 14.0f * 0.11f;
    float labelStartPos = x + tickPosition;

    float verticalLineLength = 20; // Length of the vertical line
    float angleLineLength = 10; // Length of the angled line

    for(uint i = 0; i < labels.Length; i++){
        // Draw vertical line upwards
        nvg::BeginPath();
        nvg::StrokeColor(color);
        nvg::MoveTo(vec2(labelStartPos, y - i * 20));
        nvg::LineTo(vec2(labelStartPos, y - i * 20 - verticalLineLength));
        nvg::Stroke();

        // Draw angled line to the label
        nvg::BeginPath();
        nvg::MoveTo(vec2(labelStartPos, y - i * 20 - verticalLineLength));
        nvg::LineTo(vec2(labelStartPos + angleLineLength, y - i * 20 - verticalLineLength - angleLineLength));
        nvg::Stroke();

        // transform the origin to the label's starting point
        nvg::Save();  // save the current state
        nvg::Translate(labelStartPos + angleLineLength, y - i * 20 - verticalLineLength - angleLineLength);  // new origin at the label's start
        nvg::Rotate(-TAU / 8.0f);  // rotate by -45 degrees counterclockwise

        // now we can render the text as if it started at the origin
        nvg::FillColor(vec4(0.0f, 0.0f, 0.0f, 1.0f));
        for (float j = 0; j < nCopies; j++) {
            float angle = TAU * float(j) / nCopies;
            vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * sw;
            nvg::Text(offs, labels[i]);
        }
        nvg::FillColor(textColor);
        nvg::Text(vec2(0, 0), labels[i]);  // render rotated text at the origin

        // restore the transformations
        nvg::Restore();  // restore the saved state, effectively undoing the translations and rotations
    }

    float prettyTimeWidth = nvg::TextBounds(prettyTime).x;
    // Rest of function
    float prettyTimeStartPos = x + tickPosition - (prettyTimeWidth / 2.0f);
    float prettyTimeEndPos = prettyTimeStartPos + prettyTimeWidth;
    if (prettyTimeStartPos < x) prettyTimeStartPos = x;
    if (prettyTimeEndPos > x + w) prettyTimeStartPos = x + w - prettyTimeWidth;
    auto prettyTimePos = vec2(prettyTimeStartPos, y + h + 15);
    nvg::FillColor(vec4(0.0f, 0.0f, 0.0f, 1.0f));
    for (float j = 0; j < nCopies; j++) {
        float angle = TAU * float(j) / nCopies;
        vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * sw;
        nvg::Text(prettyTimePos + offs, prettyTime);
    }
    nvg::FillColor(textColor);
    nvg::Text(prettyTimePos, prettyTime);
}
}

// A function which takes a list of progress bar items and returns a list of progress bar items where any items with positions are within a certain distance of each other
// are combined into a single item with a stack of labels. The items are already sorted by position and any uncombined items are inserted into the returned array
array<const ProgressBarItem@> CombineStackedItems(array<const ProgressBarItem@>@ items, float distance){
    array<const ProgressBarItem@> ret;
    array<const ProgressBarItem@> uncombinedItems;
    for(uint i = 0; i < items.Length; i++){
        if(i == 0){
            ret.InsertLast(items[i]);
        } else {
            if(items[i].position - items[i - 1].position < distance){
                // Combine the two items
                array<string> labels;
                labels.InsertLast(items[i - 1].label);
                labels.InsertLast(items[i].label);
                auto newItem = StackedProgressBarItem(items[i].position, labels, items[i].color, items[i].prettyTime);
                ret.RemoveLast();
                ret.InsertLast(newItem);
            } else {
                ret.InsertLast(items[i]);
            }
        }
    }
    return ret;
}









class ProgressBarInputItem {
    int time;
    string label;

    ProgressBarInputItem(int time, string label){
        this.time = time;
        this.label = label;
    }

    ProgressBarItem@ toProgressBarItem(float position) const{
        string prettyTime = TimeString(time);
        return ProgressBarItem(position, label, vec4(1.0f, 1.0f, 1.0f, 1.0f), prettyTime);
    }
}

class MedalProgressBarInputItem : ProgressBarInputItem {
    MedalProgressBarInputItem(const LeaderboardEntry@ entry){
        super(entry.time, entry.desc);
    }

    ProgressBarItem@ toProgressBarItem(float position) const override {
        string prettyTime = TimeString(time);
       if(this.label == "Gold"){
            return ProgressBarItem(position, label, vec4(1.0f, 0.8f, 0.0f, 1.0f), prettyTime);
        } else if(this.label == "Silver"){
            return ProgressBarItem(position, label, vec4(0.75f, 0.75f, 0.75f, 1.0f), prettyTime);
        } else if(this.label == "Bronze"){
            return ProgressBarItem(position, label, vec4(0.8f, 0.5f, 0.2f, 1.0f), prettyTime);
        } else if(this.label == "AT"){
            return ProgressBarItem(position, label, vec4(0.0f, 1.0f, 0.0f, 1.0f), prettyTime);
        } else {
            return ProgressBarItem(position, label, vec4(1.0f, 1.0f, 1.0f, 1.0f), prettyTime);
        }
    }
}

class PBProgressBarInputItem : ProgressBarInputItem {
    PBProgressBarInputItem(const LeaderboardEntry@ entry){
        super(entry.time, entry.desc);
    }

    ProgressBarItem@ toProgressBarItem(float position) const override {
        string prettyTime = TimeString(time);
        return ProgressBarItem(position, label, vec4(1.0f, 1.0f, 1.0f, 1.0f), prettyTime);
    }
}

class PreviousRecordProgressBarInputItem : ProgressBarInputItem {

    bool wasPb;
    bool currentSession;
    PreviousRecordProgressBarInputItem(int time, bool wasPb, bool currentSession){
        super(time, "");
        this.wasPb = wasPb;
        this.currentSession = currentSession;
    }

    ProgressBarItem@ toProgressBarItem(float position) const override {
        // Dark grey for previous session, light grey for current session, white for previous PB
        if(wasPb){
            return ProgressBarItem(position, "", vec4(1.0f, 1.0f, 1.0f, 1.0f), TimeString(time));
        } else if(currentSession){
            return ProgressBarItem(position, "", vec4(0.75f, 0.75f, 0.75f, 1.0f), TimeString(time));
        } else {
            return ProgressBarItem(position, "", vec4(0.5f, 0.5f, 0.5f, 1.0f), TimeString(time));
        }
    }
}

class PercentageTickProgressBarInputItem : ProgressBarInputItem {
    float percentage;
    PercentageTickProgressBarInputItem(const LeaderboardEntry@ entry){
        super(entry.time, "");
        this.percentage = entry.percentage;
    }

    ProgressBarItem@ toProgressBarItem(float position) const override {
        // Blue
        auto item = ProgressBarItem(position);
        item.prettyTime = TimeString(time);
        item.color = vec4(0.0f, 0.0f, 1.0f, 1.0f);
        if((percentage) % 10 == 0.0f){
            item.height = 0.75f;
        }
        else {
            item.height = 0.5f;
        }
        return item;
    }
}

class SpecialProgressBarInputItem : ProgressBarInputItem {
    vec4 color;
    SpecialProgressBarInputItem(int time, string label, vec4 color){
        super(time, label);
        this.color = color;
    }

    ProgressBarItem@ toProgressBarItem(float position) const override {
        return ProgressBarItem(position, label, color, TimeString(time));
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

    void render(float progress, array<const ProgressBarItem@> items)
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
            items[i].Draw(x, y, w, h, textColor);
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
    private array<int>@ times;
    private array<float>@ points;
    FixedPointPositioning(array<int>@ times, array<float>@ points) {
        this.times = times;
        this.points = points;
    }
    FixedPointPositioning(array<ScalingPoint@> scalingPoints) {
        scalingPoints.SortAsc();
        @this.times = array<int>(scalingPoints.Length);
        @this.points = array<float>(scalingPoints.Length);
        // print("x");
        for (uint i = 0; i < scalingPoints.Length; i++) {
            // print("time: " + scalingPoints[i].time + " pos: " + scalingPoints[i].position);

            this.times[i] = scalingPoints[i].time;
            this.points[i] = scalingPoints[i].position;
        }
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
     array<LeaderboardEntry@> percentageEntries, LeaderboardEntry@ noRespawnBest, int average)
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
    array<const ProgressBarItem@> items;
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
    if(average > 0){
        items.InsertLast(ProgressBarItem(interpolation.getPosition(average), "Avg", red, TimeString(average)));
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

// Take an array of floats between 0 and 1 which indicate incresing thresholds and rescale the second till the end so that they cover the range 0.2 to 1 with the same
// relative spacing, so that the second threshold is at 0.2
array<float> RescaleThresholds(array<float>@ thresholds, float pivot)
{
    array<float> ret;
    ret.InsertLast(0.0f);
    for(uint i = 1; i < thresholds.Length; i++)
    {
        ret.InsertLast(pivot + (thresholds[i] - thresholds[1]) * (1.0f - pivot) / (thresholds[thresholds.Length - 1] - thresholds[1]));
    }
    return ret;
}

// Take an array of scaling points, along with a min and max value and rescale the  points so that they cover that range
// E.g. If we hae positions of 0.6, 0.8, 1, and we are given a min of 0.5 and a max of 1.0, we will return 0.5, 0.75, 1.0
array<float> RescalePoints(array<ScalingPoint@>@ points, float min, float max)
{
    array<float> ret;
    for(uint i = 0; i < points.Length; i++)
    {
        ret.InsertLast(min + points[i].position * (max - min));
    }
    return ret;
}

// Evenly space the ScalingPoints between the min and max
array<float> EvenlySpacePoints(array<ScalingPoint@>@ points, float min, float max)
{
    array<float> ret;
    for(uint i = 0; i < points.Length; i++)
    {
        // print("i: " + i + " time: " + points[i].time + " position: " + points[i].position);
        ret.InsertLast(min + ((max - min) * float(i) / float(points.Length - 1)));
    }
    return ret;
}




class ScalingPoint {
    float time;
    float position;
    ScalingPoint(float time, float position)
    {
        this.time = time;
        this.position = position;
    }
    int opCmp(ScalingPoint@ other){
        if(other.position > position)
            return -1;
        else if(other.position == position){
            return 0;
        }
        return 1;
    }
}

FixedPointPositioning CreateScaling(array<const LeaderboardEntry@> medals, int playerCount, int worldRecordTime, int slowestTime, float indeterinatePivot)
{
    array<ScalingPoint@> indeterminatePoints;
    array<ScalingPoint@> fixedPoints;
    array<float> thresholds;
    // print("playerCount: " + playerCount);
    for(uint i = 0; i < medals.Length; i++)
    {
        if(medals[i].position == playerCount && playerCount % 10000 == 0)
        {
            indeterminatePoints.InsertLast(ScalingPoint(medals[i].time, 1.0f));
        }
        else
        {
            fixedPoints.InsertLast(ScalingPoint(medals[i].time, float(playerCount - medals[i].position) / float(playerCount)));
        }
    }
    fixedPoints.InsertLast(ScalingPoint(worldRecordTime, 1.0f));
    // If no indeterminate, add the slowest tie as a fixed point at the beginning
    if(indeterminatePoints.Length == 0){
        fixedPoints.InsertAt(0, ScalingPoint(slowestTime, 0.0f));
        return FixedPointPositioning(fixedPoints);
    }
    // If any indeterminate, add the slowest time as a fixed point at the beginning, as long as it is slower than any time already in there

    indeterminatePoints.Reverse();
    if(indeterminatePoints[0].time < slowestTime)
    {
        indeterminatePoints.InsertAt(0, ScalingPoint(slowestTime, 0.0f));
    }
    else {
        // Add the slowest time by adding  difference between the first and last
        indeterminatePoints.InsertAt(0, ScalingPoint(indeterminatePoints[0].time + (indeterminatePoints[0].time - indeterminatePoints[indeterminatePoints.Length - 1].time) / 2.0f, 0.0f));

    }
    // Then rescale both sets of points around the pivot value, so that the last indeterminate point is at the pivot
    float pivot = indeterinatePivot;
    thresholds = EvenlySpacePoints(indeterminatePoints, 0.0f, pivot);
    for(uint i = 0; i < indeterminatePoints.Length; i++)
    {
        // print("indeterminatePoints[i].position = " + indeterminatePoints[i].position + " thresholds[i] = " + thresholds[i]);
        // print("indeterminatePoints[i].time = " + indeterminatePoints[i].time);
        indeterminatePoints[i].position = thresholds[i];
    }
    thresholds = RescalePoints(fixedPoints, pivot, 1.0f);
    for(uint i = 0; i < fixedPoints.Length; i++)
    {
        fixedPoints[i].position = thresholds[i];
    }
    // Then combine the two sets of points
    for(uint i = 0; i < indeterminatePoints.Length; i++)
    {
        fixedPoints.InsertLast(indeterminatePoints[i]);
    }

    return FixedPointPositioning(fixedPoints);
}


// A function like RenderProgressBarTwo which takes ProgressBarInputItems instead
void RenderProgressBarFromInputs(ProgressBar@ pb, array<const ProgressBarInputItem@> inputs, int playerCount, array<const LeaderboardEntry@> medals, int worldRecord, int personalBest, int lastPlaceEstimate){

    // array<int> fixedTimes;
    // array<float> fixedPoints;
    // for(uint i = 0; i < medals.Length; i++)
    // {
    //     fixedTimes.InsertLast(medals[i].time);
    //     // print(playerCount - medals[i].position);
    //     fixedPoints.InsertLast(float(playerCount - medals[i].position) / float(playerCount));
    // }
    // // Get max time from inputs
    // int maxTime = 0;
    // for(uint i = 0; i < inputs.Length; i++)
    // {
    //     if(inputs[i].time > maxTime){
    //         maxTime = inputs[i].time;
    //     }
    // }
    // fixedTimes.InsertAt(0, maxTime);
    // fixedPoints.InsertAt(0, 0.0f);
    // fixedTimes.InsertLast(worldRecord);
    // fixedPoints.InsertLast(1.0f);
    // fixedTimes.SortDesc();
    // fixedPoints.SortAsc();
    // fixedPoints = RescaleThresholds(fixedPoints);

    // auto interpolation = FixedPointPositioning(fixedTimes, fixedPoints);
    auto interpolation = CreateScaling(medals, playerCount, worldRecord, lastPlaceEstimate, 0.2f);
    array<const ProgressBarItem@> items;

    for(uint i = 0; i < inputs.Length; i++)
    {
        inputs[i].toProgressBarItem(1.0f);
        items.InsertLast(inputs[i].toProgressBarItem(interpolation.getPosition(inputs[i].time)));
    }
    items = CombineStackedItems(items, 0.01f);
    // //medal color
    // vec4 gold = vec4(1.0f, 0.8f, 0.0f, 1.0f);
    // // percentage blue color
    // vec4 blue = vec4(0.0f, 0.0f, 1.0f, 1.0f);
    // array<ProgressBarItem@> items;
    // for(uint i = 0; i < medals.Length; i++)
    // {
    //     items.InsertLast(ProgressBarItem(float(playerCount - medals[i].position) / float(playerCount), medals[i].desc, gold, TimeString(medals[i].time)));
    // }
    // vec4 yellow = vec4(1.0f, 0.8f, 0.0f, 1.0f);
    // if(personalBest.time > 0){
    //     items.InsertLast(ProgressBarItem(interpolation.getPosition(personalBest.time), "PB", yellow, TimeString(personalBest.time)));
    // }
    // vec4 red = vec4(1.0f, 0.0f, 0.0f, 1.0f);
    // if(noRespawnBest.time > 0 && noRespawnBest.time != personalBest.time){
    //     items.InsertLast(ProgressBarItem(interpolation.getPosition(noRespawnBest.time), "Cope", red, TimeString(noRespawnBest.time)));
    // }
    // if(average > 0){
    //     items.InsertLast(ProgressBarItem(interpolation.getPosition(average), "Avg", red, TimeString(average)));
    // }
    // items.InsertLast(ProgressBarItem(1.0f, "WR", yellow, TimeString(worldRecord.time)));
    // for(uint i = 0; i < times.Length; i++)
    // {
    //     items.InsertLast(ProgressBarItem(interpolation.getPosition(times[i].time)));
    // }
    // for(uint i = 0; i < percentageEntries.Length; i++)
    // {
    //     auto item = ProgressBarItem(interpolation.getPosition(percentageEntries[i].time), percentageEntries[i].desc, blue, TimeString(percentageEntries[i].time));

    //     if((percentageEntries[i].percentage) % 10 == 0.0f){
    //         item.height = 0.75f;
    //     }
    //     else {
    //         item.height = 0.5f;
    //     }
    //     items.InsertLast(item);
    // }
    pb.render(personalBest < 0 ? 0 : interpolation.getPosition(personalBest), items);

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
    array<const ProgressBarItem@> items;
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

    array<const LeaderboardEntry@> medals = mapWatcher.leaderboard.data.medals;
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
    auto lastPlaceEstimate = mapWatcher.leaderboard.data.lastPlaceEstimate;

    PlayerStats@ stats = PlayerStats(mapWatcher.leaderboard);
    auto average = stats.Average(5);
    auto noRespawnBest = stats.BestNoRespawnTime;
    auto lastSessionTime = stats.LastSessionRun;
    auto noRespawnLast = stats.LastSessionNoRespawnTime;

    array<const ProgressBarInputItem@> inputItems;
    if(personalBest.time > 0){
        inputItems.InsertLast(PBProgressBarInputItem(personalBest));
    }



    inputItems.InsertLast(SpecialProgressBarInputItem(worldRecord.time, "WR", vec4(1.0f, 0.8f, 0.0f, 1.0f)));

    // if(noRespawnBest > 0 && personalBest.time != noRespawnBest){
        inputItems.InsertLast(SpecialProgressBarInputItem(noRespawnBest, "Best NR", vec4(1.0f, 0.8f, 0.0f, 1.0f)));
    // }
    // if(noRespawnLast > 0 && lastSessionTime != noRespawnLast && noRespawnBest != noRespawnLast){
        inputItems.InsertLast(SpecialProgressBarInputItem(noRespawnLast, "Last NR", vec4(1.0f, 0.8f, 0.0f, 1.0f)));
    // }
    if(average > 0){
        inputItems.InsertLast(SpecialProgressBarInputItem(average, "Avg", vec4(1.0f, 0.8f, 0.0f, 1.0f)));
    }
    for(uint i = 0; i < medals.Length; i++)
    {
        inputItems.InsertLast(MedalProgressBarInputItem(medals[i]));
    }
    auto currentSession = stats.SessionRecords;
    auto oldRecords = stats.OldRecords;

    for(uint i = 0; i < currentSession.Length; i++)
    {
        if(i == currentSession.Length - 1){
            inputItems.InsertLast(SpecialProgressBarInputItem(currentSession[i].time, "Last", vec4(1.0f, 0.8f, 0.0f, 1.0f)));
        }
        else {
            inputItems.InsertLast(PreviousRecordProgressBarInputItem(currentSession[i].time, currentSession[i].pb, true));
        }
    }
    for(uint i = 0; i < oldRecords.Length; i++)
    {
        inputItems.InsertLast(PreviousRecordProgressBarInputItem(oldRecords[i].time, oldRecords[i].pb, false));
    }

    RenderProgressBarFromInputs(@pb, inputItems, playerCount, medals, worldRecord.time, personalBest.time, lastPlaceEstimate.time);

    // RenderProgressBarTwo(@pb, medals, times, personalBest, playerCount, worldRecord, percentageEntries, noRespawnBest, average);



}
