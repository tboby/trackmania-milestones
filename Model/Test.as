// class Test {
//     string mapUid = "";
//     Resets@ resets = Resets();
//     Test()  {
//         startnew(CoroutineFunc(map_handler));
//     }
//     void map_handler() {
//         string mapId = "";
//         auto app = GetApp();
//         while (true) {
//         auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
//         mapId = (playground is null || playground.Map is null) ? "" : playground.Map.IdName;
//         if (mapId != mapUid && app.Editor is null) {
//             //the map has changed and we are not in the editor.
//             //the map has changed //we should save and then load the new map's data
//             mapUid = mapId;
//             startnew(CoroutineFunc(load));

//         }
//         yield();
//         }
//     }
//     void start() {
//         resets.start();
//     }


//     void load() {
//         if (mapUid == "" || mapUid == "Unassigned") return;
//         {
//             resets = Resets();
//             start();
//         }
//     }

// }