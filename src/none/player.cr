enum PlayModes
    Consecutive
    Shuffle
    Repeat
    RepeatSong
end
module Player
    class_property index = 0
    class_property value_bar : Float64 = 0
    class_property change_value_bar= false
    class_property change_mode= false
    class_getter volume : Float64 = 2.5
    class_property volumeX : Float64=0.0
    class_property current = -100
    class_getter queue_state=true
    def self.queue_state=(@@queue_state);Storage.update_config("queue_state",@@queue_state,:state,false);end
    class_property mode : PlayModes = PlayModes::Consecutive
    class_property state : VC365::GstState=VC365::GstState::Null
    class_property state_changed=[] of VC365::GstState->Bool
    class_property current_song={name: "",uri: ""}
    class_getter! bin : VC365::GstElement
    class_getter vis_level : Float64=0.0

    @@is_playing=uninitialized VC365::GtkElement

    private class AudioFilter
        class_property! bin : VC365::GstElement
        class_getter level=[] of VC365::GstElement
        class_getter rubberband=[] of VC365::GstElement
    end

    def self.volume=(vol : Float64)
        @@volume=vol.clamp(0.0,Settings::Values.max_volume)
        Storage.update_config("volume",@@volume,:state)
        Xlib.set_prop(bin.as(VC365::GObject),"volume",volume,nil) if @@bin
    end
    def self.audiofilter
        Xlib.call do
            Settings::Values.visualizer || Settings::Values.hz432 ? set_prop(bin.as(VC365::GObject),
                "audio-filter",gst_object_ref(
                    if Settings::Values.visualizer && Settings::Values.hz432
                        set_state(AudioFilter.rubberband.first,VC365::GstState::Null)
                        set_state(AudioFilter.level.first,VC365::GstState::Null)
                        AudioFilter.bin
                    else
                        set_state(AudioFilter.bin,VC365::GstState::Null) unless AudioFilter.rubberband.empty?
                        if Settings::Values.hz432
                            set_state(AudioFilter.level.first,VC365::GstState::Null)
                            AudioFilter.rubberband.first
                        else
                            set_state(AudioFilter.rubberband.first,VC365::GstState::Null
                            ) unless AudioFilter.rubberband.empty?
                            AudioFilter.level.first
                        end
                    end
                ),
            nil) : set_prop(bin.as(VC365::GObject),"audio-filter",nil,nil)
            unless change_value_bar || state.null? || Storage.open_local_song
                st=state
                set_state(bin,@@state=VC365::GstState::Null)
                set_state(bin,VC365::GstState::Playing)
                loop do
                    dood = uninitialized Int64
                    break if 0<dood if gst_get_time(bin,VC365::GstFormat::Time,pointerof(dood))
                end
                gst_ele_seek(bin,VC365::GstFormat::Time,VC365::GSFlags::Flush,
                        value_bar * 10**9)
                set_state(bin,@@state=st)
            end
        end
    end
    def self.is_playing(del=(List.focused.pl_page? && VC365::UI.page.playlist?))
        Xlib.call do
            gtk_set_visible(@@is_playing,false) if @@is_playing || del
            unless del
                @@is_playing=gtk_first_child(gtk_row_get_child(gtk_get_row_at_index(List.focused.glist,
                    List.focused.index
                )))
                gtk_set_visible(@@is_playing,true)
            end
        end
    end
    private def self.vc_volume(mode : String)
        spawn do
            @@volumeX= mode=="pause" ? volume : 0.0
            dood=volume/100
            sl=volume/1000
            loop do
                sleep sl.seconds
                case mode
                when "play";@@volumeX=(volumeX+dood).clamp(0.0..volume)
                    Xlib.set_prop(bin.as(VC365::GObject),"volume",volumeX,nil)
                    break if volumeX==volume
                when "pause"; @@volumeX=(volumeX-dood).clamp(0.0..volume)
                    Xlib.set_prop(bin.as(VC365::GObject),"volume",volumeX,nil)
                    if volumeX.zero?
                        Xlib.set_state(bin,@@state=VC365::GstState::Paused)
                        break
                    end
                end
            end
        end
    end
    def self.pause_play
        Xlib.call do
            vc_volume("pause")
            VC365::UI.play_btns.each do |e|
                Xlib.gtk_button_set_icon(e,"xmedia-playback-start-symbolic")
            end
            Playlist.playlist_up(state: false)
        end
    end
    def self.play(uri : String)
        Xlib.call do
            if @@bin.nil?
                @@bin=make_element("playbin",nil)
                rubberband=find_element("ladspa-ladspa-rubberband-so-rubberband-r3-pitchshifter-stereo")
                unless rubberband.null?
                    AudioFilter.bin=gst_bin_new("audio_filter")
                    2.times do |i|
                        AudioFilter.level.push(make_element("level",nil))
                        AudioFilter.rubberband.push(
                            make_element("ladspa-ladspa-rubberband-so-rubberband-r3-pitchshifter-stereo",nil))
                        set_prop(AudioFilter.rubberband[i].as(VC365::GObject),
                            "cents", 1200 * Math.log2(440.0 / 432.0),
                            "formant-preserving", true,
                            "wet-dry-mix", 1.0_f32,
                        nil)
                    end
                    gst_bin_add(AudioFilter.bin,AudioFilter.level.last)
                    gst_bin_add(AudioFilter.bin,AudioFilter.rubberband.last)
                    gst_ele_link(AudioFilter.rubberband.last,AudioFilter.level.last)
                        pad=gst_ele_get_static_pad(AudioFilter.level.last,"src")
                        gst_ele_add_pad(AudioFilter.bin,gst_ghost_pad_new("src",pad))
                    gst_object_unref(pad.as(VC365::GstElement))
                        pad=gst_ele_get_static_pad(AudioFilter.rubberband.last,"sink")
                        gst_ele_add_pad(AudioFilter.bin,gst_ghost_pad_new("sink",pad))
                    gst_object_unref(pad.as(VC365::GstElement))
                    gst_object_unref(rubberband)
                else
                    AudioFilter.level.push(make_element("level",nil))
                    asr_set_active(Settings.elements[:hz432],Settings::Values.hz432)
                    gtk_set_sensitive(Settings.elements[:hz432],Settings::Values.hz432=false)
                end
                AudioFilter.level.each do |l|
                    set_prop(l.as(VC365::GObject),
                        "post-messages",true,
                        "interval",10_000_000_u64,
                        "peak-ttl", 80_000_000_u64,
                        "peak-falloff", 4.0,
                    nil)
                end
                set_prop(bin.as(VC365::GObject),
                    "uri",uri,
                    "volume",volume,
                    "flags",VC365::GstPFlags::All &
                        ~(VC365::GstPFlags::Video | VC365::GstPFlags::Text | VC365::GstPFlags::Vis),
                nil)
                audiofilter if Settings::Values.visualizer || Settings::Values.hz432
                gst_bus_add_signal_watch(bus=gst_get_bus(bin))
                g_signal(bus,"message::eos",->{
                    @@state=VC365::GstState::Pending
                    next_song(case mode
                    in .consecutive?; "next"
                    in .shuffle?;     "random"
                    in .repeat?;      "queue"
                    in .repeat_song?; "current"
                    end)
                true})
                g_signal(bus,"message::element",->(bus : VC365::GstBus,msg : VC365::GstMsg*){Xlib.call do
                    return unless Settings::Values.visualizer
                    return unless str=gst_msg_get_str(msg)
                    return unless gst_str_has_name(str,"level")
                    rms_arr=g_value_get_boxed(gst_str_get_value(str,"rms"))
                    peak_arr=g_value_get_boxed(gst_str_get_value(str,"peak"))
                    decay_arr=g_value_get_boxed(gst_str_get_value(str,"decay"))
                    level=Hash(String,Float64).new
                    0.to(rms_arr.value.n_values-1) do |i|
                        rms_dB=g_value_get_double(g_value_array_get_nth(rms_arr,i))
                        peak_dB=g_value_get_double(g_value_array_get_nth(peak_arr,i))
                        decay_dB=g_value_get_double(g_value_array_get_nth(decay_arr,i))
                        if i.zero?
                            level["rms"]=10**(rms_dB/20)
                            level["peak"]=10**(peak_dB/20)
                            level["decay"]=10**(decay_dB/20)
                        else
                            level["rms"]=(level["rms"]+10**(rms_dB/20))/2.0
                            level["peak"]=(level["peak"]+10**(peak_dB/20))/2.0
                            level["decay"]=(level["decay"]+10**(decay_dB/20))/2.0
                        end
                    end
                    @@vis_level = level["peak"] - level["rms"] * 0.25 - level["decay"] * 0.1
                end})
                #g_signal(bus,"message::state-changed",->(bus : VC365::GstBus,msg : VC365::GstMsg*){
                #    Xlib.call do
                #        return if bin.address != msg.value.src.address || state_changed.empty?
                #        now=uninitialized VC365::GstState
                #        gst_msg_parse_state_changed(msg,nil,pointerof(now),nil)
                #        state_changed.each do |sc|
                #            state_changed.delete(sc) if sc.call(now)
                #        end
                #    end
                #})
                gst_object_unref(bus.as(VC365::GstElement))
            elsif current != index
                set_state(bin,@@state=VC365::GstState::Null)
                @@value_bar=0 unless change_value_bar
                gtk_widget_queue_draw(VC365::UI.play_bar[:ring])
                gtk_label_set_text(VC365::UI.play_bar[:timer],"0:00")
                gtk_adj_set_value(VC365::UI.play_bar[:sheet],value_bar)
                set_prop(bin.as(VC365::GObject),"uri",uri,nil)
            end

            current == index && case state
            when .playing?; pause_play
            when .paused?,.pending?,.null?
                set_state(bin,state) unless state.paused?
                set_state(bin,@@state=VC365::GstState::Playing)
                vc_volume("play")
                VC365::UI.play_btns.each do |e|
                    gtk_button_set_icon(e,"media-playback-pause-symbolic")
                end
                Playlist.playlist_up(state: true)
                if change_value_bar
                    loop do
                        dood = uninitialized Int64
                        break if 0<dood if gst_get_time(bin,VC365::GstFormat::Time,pointerof(dood))
                    end
                    gst_ele_seek(bin,VC365::GstFormat::Time,VC365::GSFlags::Flush,
                        value_bar * 10**9)
                    @@change_value_bar=false
                end
                is_playing unless @@is_playing
            end
            unless List.data[index][:info][:local_song]
                Storage.update_config("value_bar",value_bar,:state,false)
                Storage.update_config("current_song",uri,:state,false)
            end
            if current != index
                set_prop(bin.as(VC365::GObject),"volume",volume,nil)
                set_state(bin,@@state=VC365::GstState::Playing)
                VC365::UI.set_recent(uri) unless (List.focused.recently? || List.data[index][:info][:local_song])
                is_playing
                VC365::UI.play_btns.each do |e|
                    gtk_button_set_icon(e,"media-playback-pause-symbolic")
                end
                Playlist.playlist_up(state: true)
                if List.queues.size<=1
                    List.queues.clear
                    List.queues.push(index)
                    Storage.update_data(:queues,List.queues)
                end
            end
            @@current_song={name: Path[URI.parse(uri).path].stem,uri: uri}
            @@current=index
        end
    end
    def self.init_bar
        Xlib.g_signal(VC365::UI.play_bar[:sheet_box],"change-value",->{Player.change_mode=true;false})
        Xlib.g_timeout_add(45,->(data : Pointer(Void)){Xlib.call do
            if change_mode
                @@value_bar=gtk_adj_get_value(VC365::UI.play_bar[:sheet])
                gtk_label_set_text(VC365::UI.play_bar[:timer],to_clock(value_bar))
                gst_ele_seek(bin,VC365::GstFormat::Time,
                    VC365::GSFlags::Flush | VC365::GSFlags::KeyUnit | VC365::GSFlags::TrickMode,
                value_bar * 10**9) if @@bin
                Storage.update_config("value_bar",value_bar,:state)
                Player.change_mode=false
            elsif state.playing?
                dood = uninitialized Int64
                @@value_bar=(dood / 10**9) if gst_get_time(bin,VC365::GstFormat::Time,pointerof(dood))
                gtk_widget_queue_draw(VC365::UI.play_bar[:ring])
                gtk_label_set_text(VC365::UI.play_bar[:timer],to_clock(value_bar))
                gtk_adj_set_value(VC365::UI.play_bar[:sheet],value_bar)
            end;true
        end}.as(VC365::GSourceFunc),
        nil)
    end

    def self.next_song(pattern : String)
        @@volumeX=volume
        @@change_value_bar=false
        Player.queue_state=true if (index==List.queues.first || pattern=="queue" ||
            (index==List.queues.first+1 && pattern=="prev") || (index==List.queues.first-1 && pattern=="next")
        ) unless List.queues.empty?
        list=List.focused_list
        indexX=if List.queues.size>1 && queue_state
            qlist=List.queues
            cindex=List.focused.home? ? index : list.index!(current_song[:uri])
            if (index==qlist.first-1 && pattern=="next");   qlist.first
            elsif (index==qlist.first+1 && pattern=="prev");qlist.last
            elsif (index==qlist.last && pattern=="current");@@value_bar=0
                @@state=VC365::GstState::Null
                index
            else;i=qlist.index!(index)
                case pattern
                when "prev";i-=1
                    if mode.repeat?; i < 0 ? qlist.last : qlist[i]
                    elsif i>=0; qlist[i]
                    else
                        Player.queue_state=false
                        (cindex-=1) < 0 ? list.size-1 : cindex
                    end
                when "next","random","current","queue";i+=1
                    if mode.repeat?; i > qlist.size-1 ? qlist.first : qlist[i]
                    elsif !qlist[i]?.nil?; qlist[i]
                    else
                        Player.queue_state=false
                        (List.focused.home? ? (cindex=qlist.first.succ)
                        : (cindex=list.index!(List.data[qlist.first][:uri])+1)) > list.size-1 ? 0 : cindex
                    end
                end.not_nil!
            end
        else
            list=List.focused_list
            i=List.focused.home? ? index : list.index!(current_song[:uri])
            if (list.size<=1)
                @@state= pattern=="current" ? VC365::GstState::Paused : VC365::GstState::Playing
                0
            else
                case pattern
                when "prev"
                    (i-=1) < 0 ? list.size-1 : i
                when "next"
                    (i+=1) > list.size-1 ? 0 : i
                when "random"
                    loop do
                        r=rand(0..(list.size-1))
                        break r if r != i
                    end
                when "current","queue";@@value_bar=0
                    @@state=VC365::GstState::Null
                    i
                end.not_nil!
            end
        end
        @@index=loop do
            tmp_index=((List.queues.size>1 && queue_state) || List.focused.home?) ? indexX
                : List.data_indexU!(list[indexX].as(String))
            if File.exists?(URI.parse(List.data[tmp_index][:uri]).path) && ((List.queues.size>1 && queue_state) ||
                List.focused.home? || list[indexX]==List.data[tmp_index][:uri])
                break tmp_index
            else
                name=List.focused.home? ? List.data[tmp_index][:name]
                : Path[URI.parse(list[indexX].as(String)).path].stem
                VC365::UI.notify(
                    "#{name[0..50].strip}#{"..." if name.size-1>50}: #{String.new(Xlib.gettext("Song not found!"))}",1)
                indexX=case pattern
                when "prev"
                    (indexX-=1) < 0 ? list.size-1 : indexX
                when "next","random","current","queue"
                    (indexX+=1) > list.size-1 ? 0 : indexX
                end.not_nil!
            end
        end
        data=List.data[index]
        VC365::UI.upsheet(data) if pattern != "current" || List.queues.size>1
        play(data[:uri])
    end
    def self.set_mode
        begin
            case mode
            in .consecutive?
                @@mode=PlayModes::Shuffle
                msg=Xlib.gettext("Random playback")
                "xplaylist-shuffle-symbolic"
            in .shuffle?
                @@mode=PlayModes::Repeat
                msg=Xlib.gettext("Repeat queue")
                "xplaylist-repeat-symbolic"
            in .repeat?
                @@mode=PlayModes::RepeatSong
                msg=Xlib.gettext("Repeat current song")
                "xplaylist-repeat-song-symbolic"
            in .repeat_song?
                @@mode=PlayModes::Consecutive
                msg=Xlib.gettext("Consecutive playback")
                "xplaylist-consecutive-symbolic"
            end
        ensure
            Storage.update_config("play_mode",@@mode.value,:state)
            VC365::UI.notify(msg.not_nil!,1,true)
        end
    end
end
