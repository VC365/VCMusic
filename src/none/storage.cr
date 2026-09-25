require "option_parser"
require "colorize"
require "json"
enum DoodXX
K
end
module Storage
    class_property open_local_song=false
    class Dirs
        Data=Linux ? Path[ENV["XDG_DATA_HOME"]? || Path["~/.local/share"].expand(home: true), 
            "VCMusic"] : Path[ENV["LOCALAPPDATA"],"VCMusic"]
        Config=Linux ? Path[ENV["XDG_CONFIG_HOME"]? || Path["~/.config"].expand(home: true), 
            "VCMusic"] : Path[ENV["APPDATA"],"VCMusic"]
        def self.check
            Dir.mkdir_p(Config)
            Dir.mkdir_p(Data)
        end
    end
    class Files
        Configs={settings: Dirs::Config/"settings.json",state: Dirs::Config/"state.json"}
        Data={
            data: Dirs::Data/"data.json",
            playlists: Dirs::Data/"playlists.json",
            recent: Dirs::Data/"recently.json",
            favorites: Dirs::Data/"favorites.json",
            queues: Dirs::Data/"queues.json"
        }
        def self.check
            Configs.each_value { |v| File.touch(v);File.empty?(v) && File.write(v,"{}")}
            Data.each_value { |v| File.touch(v)}
        end
    end
    def self.parse_arguments
        File.exists?((file=Path[ARGV.first? || "#"]).to_s
        ) && if List::Formats.index(file.extension.strip("."))
            @@open_local_song=true
            Player.current=-100
            Player.change_value_bar=false
            Player.volumeX=Player.volume
            uri=file.to_uri
            Player.current_song={name: Path[uri.path].stem,uri: uri.to_s}
            VC365::UI.before_ui=->{List::AddSong.call(uri.to_s,false)}
            VC365::UI.call=->(appX : VC365::GApp) { Player.play(uri.to_s);@@open_local_song=false;nil }
        end
        OptionParser.parse do |arg|
            arg.banner="Usage: VCMusic [-h --help] [-f --file]"
            arg.on("-f","--file FILE","Open Song file") do |file|
                File.exists?((fileX=Path[file]).to_s) && if List::Formats.index(fileX.extension.strip("."))
                    @@open_local_song=true
                    Player.current=-100
                    Player.change_value_bar=false
                    uri=fileX.to_uri
                    Player.volumeX=Player.volume
                    Player.current_song={name: Path[uri.path].stem,uri: uri.to_s}
                    VC365::UI.before_ui=->{List::AddSong.call(uri.to_s,false)}
                    VC365::UI.call=->(appX : VC365::GApp) { Player.play(uri.to_s);@@open_local_song=false;nil }
                end
            end
            arg.on("-h","--help","Show help message") do
                puts arg;exit
            end

            arg.invalid_option do |val|
                STDERR.puts "ERROR: #{val} is not a valid option.".colorize.light_red
                STDERR.puts arg
                exit(1)
            end
        end
    end
    def self.update_config(name : String,value : _,dood=:settings,last_req=true)
        #puts "#{name} saved!! #{value} //// #{caller}"
        Xlib.last_req((last_req ? 1 : 0).seconds,name) do
            #puts "#{name} saved!! #{value} //// #{caller}"
            begin
                config=Hash(String, JSON::Any).from_json(File.read(Files::Configs[dood]))
                config[name]=JSON::Any.new(value)
                Dirs.check
                File.write(Files::Configs[dood],config.to_json)
            rescue ex
                puts "ERROR: Please check #{Files::Configs[dood]}"
                puts ex
            end
        end
    end
    def self.update_data(name : Symbol,val : _)
        begin
            Dirs.check
            #puts "#{name} saved!! #{val} //// #{caller[2]}"
            File.write(Files::Data[name],val.to_json)
        rescue ex
            puts "ERROR: Please check #{Files::Data[name]}"
            puts ex
        end
    end
    def self.update_data(page : VCMusic::Page)
        dood=case page
            in .home?; {:data,List.data}
            in .favorites?; {:favorites,List.favorite}
            in .recently?; {:recent,List.recent}
            in .pl_page?,.playlist?; {:playlists,List.playlists}
        end
        Dirs.check
        Storage.update_data(dood[0],dood[1])
    end
    def self.init_state
        state=JSON.parse(File.read(Files::Configs[:state]))
            state["current_song"]?.try(&.as_s?).try do |uri|
                if File.exists?(URI.parse(uri).path)
                    Player.current_song={name: Path[URI.parse(uri).path].stem,uri: uri}
                    Player.index=List.data_indexU!(uri)
                end
            end &&
            state["value_bar"]?.try(&.as_f?).try { |v| v-=2
                unless (Player.value_bar=v.clamp(0.0..)).zero?
                    Player.current=Player.index
                    Player.change_value_bar=true
                    Player.state=VC365::GstState::Paused
                end
            }
            state["volume"]?.try(&.as_f?).try { |v| Player.volume=v}
            state["queue_state"]?.try(&.as_bool?).try { |v| Player.queue_state=v}
            state["play_mode"]?.try(&.as_i?).try { |v| Player.mode=PlayModes.new(v)}
            state["focused_list"]?.try(&.as_i?).try { |v| List.focused=VC365::UI.page=VCMusic::Page.new(v)}
            state["focused_playlist"]?.try(&.as_s?).try { |v| Playlist.focused=v}
    end
    def self.init
        Dirs.check
        Files.check
        settings=JSON.parse(File.read(Files::Configs[:settings]))
            settings["max_volume"]?.try(&.as_f?).try { |v| Settings::Values.max_volume=v}
            settings["theme"]?.try(&.as_i?).try { |v| Settings.style_mode=VC365::ASType.new(v)}
            settings["rib"]?.try(&.as_bool?).try { |v| Settings::Values.rib[:e]=v}
            #settings["tray_icon"]?.try(&.as_bool?).try { |v| Settings::Values.rib[:icon_tray]=v}
            #settings["kill_ui"]?.try(&.as_bool?).try { |v| Settings::Values.rib[:kill_ui]=v}
            #settings["is_loading"]?.try(&.as_bool?).try { |v| Settings::Values.is_loading=v}
            settings["visualizer"]?.try(&.as_bool?).try { |v| Settings::Values.visualizer=v}
            settings["hz432"]?.try(&.as_bool?).try { |v| Settings::Values.hz432=v}
            settings["async_mode"]?.try(&.as_bool?).try { |v| Settings::Values.load_mode="#{v ? "a" : ""}sync"}
            Settings::Values.dirs=Array(String).from_json(settings["dirs"]?.try(&.to_s) || "[]")
        List.data.concat(Array(List::Data).from_json(File.read(Files::Data[:data]).presence || "[]"))
        List.favorite.concat(Array(String).from_json(File.read(Files::Data[:favorites]).presence || "[]"))
        List.playlists.merge!(List::PlayList.from_json(File.read(Files::Data[:playlists]).presence || "{}"))
        List.recent.concat(Array(String).from_json(File.read(Files::Data[:recent]).presence || "[]"))
        List.queues.concat(Array(Int32).from_json(File.read(Files::Data[:queues]).presence || "[]"))
    end
end
