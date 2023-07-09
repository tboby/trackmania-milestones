class RaceRecord {
    uint64 time;
    uint64 target;
    bool pb;
    int64 timestamp;
    RaceRecord(uint64 time, uint64 target, bool pb, int64 timestamp){
        this.time = time;
        this.target = target;
        this.pb = pb;
        this.timestamp = timestamp;
    }
    Json::Value@ to_json(){
        auto result = Json::Object();
        result["time"] = time;
        result["target"] = target;
        result["pb"] = pb;
        result["timestamp"] = timestamp;
        return result;
    }
    RaceRecord(Json::Value json){
        this.time = json.Get("time");
        this.target = json.Get("target");
        this.pb = json.Get("pb");
        if(json.HasKey("timestamp")){
            this.timestamp = json.Get("timestamp");
        }
    }
}

class RacingData {
    array<RaceRecord@> records;
}

//Collect.as
// class Collect : Component {
//     RacingData racingData;
//     Collect() {}

//     Collect(RacingData racingData) {
//         this.racingData = racingData;
//         super();
//     }

//     // string toString() override {
//     //     string s = "";
//     //     if (setting_show_resets_session &&
//     //     !(session == total && !setting_show_duplicates)) {
//     //         s += "\\$bbb" + session;
//     //     }
//     //     if (setting_show_resets_session && setting_show_resets_total &&
//     //      !(session == total && !setting_show_duplicates)) {
//     //         s += "\\$fff  /  ";
//     //     }
//     //     if (setting_show_resets_total) {
//     //         s += "\\$bbb" + total;
//     //     }
//     //     return s;
//     // }
//     // void destroy() override {
//     //     // for(uint i = 0; i< times.Length; i++){
//     //     // print(times[i]);
//     //     // }
//     //     running = false;
//     // }

//     void handler() override {
//         while(running){
//             PlayerState::sTMData@ TMData = PlayerState::GetRaceData();
//             if(TMData.dEventInfo.FinishRun){
//                 print("finish" + TMData.dPlayerInfo.EndTime);
//                 times.InsertLast(TMData.dPlayerInfo.EndTime);
//             }
//             else if (TMData.dEventInfo.EndRun){
//                 print("end" + TMData.dPlayerInfo.EndTime);
//             }
//             // auto app = GetApp();
//             // auto playground = app.CurrentPlayground;
//             // auto network = cast<CTrackManiaNetwork>(app.Network);
//             // if (playground !is null && playground.GameTerminals.Length > 0) {
//             //     auto terminal = playground.GameTerminals[0];
//             //     auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
//             //     if (gui_player !is null) {
//             //         auto post = (cast<CSmScriptPlayer>(gui_player.ScriptAPI)).Post;
//             //         if (!handled && post == CSmScriptPlayer::EPost::Char) {
//             //             handled = true;
//             //             session += 1;
//             //             total += 1;
//             //         }
//             //         if (handled && post != CSmScriptPlayer::EPost::Char)
//             //             handled = false;
//             //         }
//             // }
//             yield();
//         }
//     }

//     string toString() override {
//         array<string> result;
//         for(uint i = 0; i< times.Length; i++){
//             result.InsertLast("" + TimeString(times[i]));
//         }
//         return string::Join(result, "\n");
//     };
// }