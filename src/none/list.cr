require "wait_group"
require "uri"

module List
    alias Info = NamedTuple(duration: Float64,folder: String,local_song: Bool)
    alias Data = NamedTuple(name: String,uri: String,info: Info)
    alias PlayList = Hash(String,Array(String))

    DefaultData={name: "VCMusic",uri: "null",info: {duration: 0.0,folder: "VC365",local_song: false }}
    @@parallel=Fiber::ExecutionContext::Parallel.new("Discover",8)
    @@wg=WaitGroup.new

    class_getter data : Array(Data) = [] of Data
    class_getter favorite : Array(String) = [] of String
    class_getter queues : Array(Int32) = [] of Int32
    class_getter playlists : PlayList = PlayList.new
    class_getter recent : Array(String) = [] of String
    class_getter focused : VCMusic::Page=VCMusic::Page::Home
    def self.focused=(x : VCMusic::Page)
        Storage.update_config("focused_list",(@@focused=x).value,:state,false)
    end

    Formats = ("mp3 mp2 mp1 mpa wav wave flac ogg oga ogv ogm opus aac adts m4a m4b m4v wma wax asf asx amr awb" +
        " ac3 eac3 dts ra ram rm rmvb rv spx midi mid aiff aif aifc caf au snd voc gsm dff dsf ape mpc tta" +
        " wv shn mp4 mkv mka webm avi mov qt mpg mpeg ts mts m2ts 3gp 3g2 dv fli flc flv nsv mod s3m xm it" +
        " stm swf mxf sdp rp").gsub(" ", ",")
    private def self.files(folders : Array(String))
        list=[] of String
        folders.each do |folder|
            next if !Dir.exists?(folder)
            next if Dir.empty?(folder)
            Dir.glob("#{folder}/**/*.{#{Formats}}").map do |file|
                list << Path[file].to_uri.to_s
            end
        end
        puts list.size
        @@wg.add(list.size)
        list
    end
    AddSong=->(uri : String,ls : Bool){Xlib.call do
        discover=discover_new(5_u64 * 1_000_000_000_u64,nil)
        info = discover_sync(discover, uri)
        next unless info_result(info) == VC365::DisResult::Ok
        dir=Path[URI.parse(uri).path]
        name=dir.basename
        @@data |=[{name: name[0,name.rindex!(".")],uri: uri,
            info: {duration: info_duration(info) / 10 ** 9,folder: dir.dirname,local_song: ls}}]
        # CleanUP
        g_object_unref(info.as(VC365::GObject))
        g_object_unref(discover.as(VC365::GObject))
    end}

    def self.init(reload=false,dirs=Settings::Values.dirs,callback=->{})
        @@data.reject! { |dox| dox[:info][:local_song]}
        if Settings::Values.dirs.empty?
            @@data.clear
            Storage.update_data(:data,@@data)
            return
        end
        initD=->(uri : String){Settings::Values.load_mode!="async" ? AddSong.call(uri,false) :
            @@parallel.spawn do
                AddSong.call(uri,false)
            ensure
                @@wg.done
            end
        }
        if data.empty? || reload
            files(dirs).each do |uri|
                initD.call(uri)
            end
            unless Settings::Values.load_mode=="async"
                Storage.update_data(:data,@@data)
                callback.call
            else
                @@parallel.spawn do
                    @@wg.wait
                    Storage.update_data(:data,@@data)
                    callback.call
                end
            end
        end
    end
    def self.data_indexU!(s : String)
        data.index { |pl| pl[:uri] == s} || 0
    end
    def self.queues_cpush?(i : Int32)
        s=queues.size
        @@queues|=[i]
        Storage.update_data(:queues,queues)
        s!=queues.size
    end
    def self.focused_list
        begin
            case @@focused
            when .home?;      data
            when .favorites?; favorite
            when .recently?;  recent
            when .pl_page?;   playlists[Playlist.focused]
            end || data
        end
    end
    def self.current_list
        case VC365::UI.page
        in .home?;      data
        in .favorites?; favorite
        in .recently?;  recent
        in .playlist?;  playlists
        in .pl_page?
            playlists[String.new(Xlib.gtk_get_name(Playlist.plpage[:list].as(VC365::GtkElement)))]
        end
    end
end