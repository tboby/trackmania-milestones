class Files {
    bool created = false;
    string folder_location = "";
    string map_id = "";
    string json_file = "";
    array<RaceRecord@> records;
    bool loaded = false;
    Json::Value json_obj = Json::Parse('{"times":[]}');
    Files() {}
    Files(const string &in id) {
        if (id == "" || id == "Unassigned") return;
        json_file = IO::FromStorageFolder(id);
        map_id = id;
        read_file();
        created = true;
    }
    void read_file() {
        if (IO::FileExists(json_file)) {
            auto content = Json::FromFile(json_file);
            if (content.GetType() != Json::Type::Null) {
                read_file_new(content);
            }
        }
        loaded = true;
    }
    void read_file_new(const Json::Value &in content) {
        auto rawTimes = content.Get('records');
        array<RaceRecord@> newTimes;
        for(uint i = 0; i < rawTimes.Length; i++){
            newTimes.InsertLast(RaceRecord(rawTimes[i]));
        }
        records = newTimes;
    }

    void write_file() {
        if (map_id == "" || map_id == "Unassigned") {
            return;
        }
        auto content = Json::Object();
        auto outTimes = Json::Array();
        for(uint i = 0; i < records.Length; i++){
            outTimes.Add(records[i].to_json());
        }
        content["records"] = outTimes;
        Json::ToFile(json_file,content);
    }

    string get_map_id() {
        return map_id;
    }
    string get_folder_location() {
        return folder_location;
    }
    void set_folder_location(const string &in loc) {
        folder_location = loc;
    }
    void set_map_id(const string &in i) {
        map_id = i;
    }
    void reset_file() {
        print(json_file);
        IO::Delete(json_file);
    }
    void reset_all() {
        auto files = IO::IndexFolder(folder_location,true);
        for (uint i = 0; i < files.Length; i++) {
            IO::Delete(files[i]);
        }
    }
    void debug_print(const string &in text) {
        print(text);
    }
}