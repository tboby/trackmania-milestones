class MapWatcher {
    string mapUid = "";
    Collect@ collect = Collect();
    Leaderboard@ leaderboard;
    Files files;
    MapWatcher()  {
        collect.destroy();
        startnew(CoroutineFunc(map_handler));
    }
    ~MapWatcher() {
        save();
    }
    void map_handler() {
        string mapId = "";
        auto app = GetApp();
        while (true) {
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
        mapId = (playground is null || playground.Map is null) ? "" : playground.Map.IdName;
        if (mapId != mapUid && app.Editor is null) {
            //the map has changed and we are not in the editor.
            //the map has changed //we should save and then load the new map's data
            auto saving = startnew(CoroutineFunc(save));
            while (saving.IsRunning()) yield();
            validMap = true;
            mapUid = mapId;
            startnew(CoroutineFunc(load));
        }
        else {
            validMap = false;
        }
        yield();
        }
    }
    void start() {
        collect.start();
        leaderboard.start();
    }

    void save() {
        files.times = collect.times;
        files.write_file();
        collect.destroy();
        if(!(leaderboard is null)){
            leaderboard.destroy();
        }
    }


    void load() {
        if (mapUid == "" || mapUid == "Unassigned") return;
        {
            files = Files(mapUid);
            while (!files.loaded) yield();
            collect = Collect();
            collect.times = files.times;
            @leaderboard = Leaderboard(mapUid);
            start();
        }
    }

}