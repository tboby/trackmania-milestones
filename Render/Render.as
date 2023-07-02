
void RenderMenu() {
  if(UI::BeginMenu(pluginName)) {
  if (UI::MenuItem("My first menu item!")) {
    mapWatcher.debug_print();
  }

        UI::EndMenu();
    }

}


void Render() {

    if(!UserCanUseThePlugin()){
        return;
    }
    RenderWindows();
}



void RenderWindows(){
    auto app = cast<CTrackMania>(GetApp());

    int windowFlags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;

    if (!UI::IsOverlayShown()) {
        windowFlags |= UI::WindowFlags::NoInputs;
    }

    if(mapWatcher is null || mapWatcher.leaderboard is null || mapWatcher.mapUid == ""){
        return;
    }

    // //if this is true, we're probably on a map not uploaded to nadeo's server. we don't want to show the window
    // if(cutoffArray.Length == 1 && cutoffArray[0].position == -1){
    //     return;
    // }


    if(windowVisible && app.CurrentPlayground !is null){
        UI::Begin(pluginName, windowFlags);

        UI::BeginGroup();

        UI::Text("Hunt Helper");

        RenderTab();

        UI::EndGroup();

        UI::BeginGroup();

        RenderTarget();

        UI::EndGroup();

        UI::End();


    }
}

void RenderTime(LeaderboardEntry entry){
            //We skip the pb if there's none
        if( (entry.entryType == EnumLeaderboardEntryType::PB && entry.time == -1)){
            return;
        }

        // If the current record is a medal one, we make a display string based on the display mode
        string displayString = "";

        if(entry.entryType == EnumLeaderboardEntryType::MEDAL){
            switch(medalDisplayMode){
                case EnumDisplayMedal::NORMAL:
                    break;
                case EnumDisplayMedal::IN_GREY:
                    displayString = greyColor;
                    break;
                default:
                    break;
            }
        }

        //------------POSITION ICON--------
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text(GetIconForPosition(entry.position));

        //------------POSITION-------------
        UI::TableNextColumn();
        if(entry.position > 10000){
            UI::Text(displayString + "<" + entry.position);
        }else{
            UI::Text(displayString + "" + entry.position);
        }

        //------------TIME-----------------
        UI::TableNextColumn();
        UI::Text(displayString + TimeString(entry.time));

        //------------HAS DESC-------------
        UI::TableNextColumn();
        if(entry.desc != ""){
            UI::Text(displayString + entry.desc);
        }

        //------------%--------------------
        UI::TableNextColumn();
        if(entry.percentage != 0.0f){
            UI::Text(displayString + entry.percentageDisplay);
        }

        //------------TIME DIFFERENCE------
        UI::TableNextColumn();

            // if(entry.time == -1 || timeDifferenceCutoff.time == -1){
            //     //Nothing here, no time to compare to
            // }else if(entry.position == timeDifferenceCutoff.position){
            //     //Nothing here, the position is the same, it's the same time
            //     //still keeping the if in case we want to print/add something here
            // }else{
            //     int timeDifference = entry.time - timeDifferenceCutoff.time;
            //     string timeDifferenceString = TimeString(Math::Abs(timeDifference));

            //     if(inverseTimeDiffSign){
            //         if(timeDifference < 0){
            //             UI::Text((showColoredTimeDifference ? redColor : "") + "+" + timeDifferenceString);
            //         }else{
            //             UI::Text((showColoredTimeDifference ? blueColor : "") + "-" + timeDifferenceString);
            //         }
            //     }else{
            //         if(timeDifference < 0){
            //             UI::Text((showColoredTimeDifference ? blueColor : "") + "-" + timeDifferenceString);
            //         }else{
            //             UI::Text((showColoredTimeDifference ? redColor : "") + "+" + timeDifferenceString);
            //         }
            //     }
            // }


}

void RenderTab(){

    UI::BeginTable("Main", 6);

    UI::TableNextRow();
    UI::TableNextColumn();
    UI::TableNextColumn();
    UI::Text("Position");
    UI::TableNextColumn();
    UI::Text("Time");
    UI::TableNextColumn();
    UI::TableNextColumn();
        UI::Text("%");


    for(uint i = 0; i < mapWatcher.leaderboard.data.medals.Length; i++) {
        RenderTime(mapWatcher.leaderboard.data.medals[i]);
    }


    for(uint i = 0; i < mapWatcher.leaderboard.data.positionEntries.Length; i++) {
        RenderTime(mapWatcher.leaderboard.data.positionEntries[i]);
    }

    RenderTime(mapWatcher.leaderboard.data.personalBest);


    UI::EndTable();
}

void RenderTarget(){
    UI::BeginTable("Target", 6);
    UI::TableNextRow();
    auto goals = Goals(mapWatcher.collect, mapWatcher.leaderboard);
    goals.CalculateObjective();
    if(!(goals.target is null)){
        RenderTime(goals.target);
    }
    UI::EndTable();
}
