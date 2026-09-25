require "base64"
require "levenshtein"
enum VCMusic::Page
    Home
    Playlist
    Recently
    Favorites
    PlPage
    def glist
        case self
        in .home?; VC365::UI.lists[:root]
        in .recently?; VC365::UI.lists[:recent]
        in .favorites?; VC365::UI.lists[:favorite]
        in .playlist?; VC365::UI.lists[:playlist]
        in .pl_page?; ::Playlist.plpage[:list]
        end
    end
    def index
        case self
        when .favorites?,.recently?
            List.focused_list.index(List.data[Player.index][:uri])
        when .pl_page?
            List.playlists[::Playlist.focused].index(List.data[Player.index][:uri])
        end || Player.index
    end
end

module VC365::UI
    WaveGFunc=->{Xlib.call do
        unless Player.volumeX.zero?
            VC365::UI.angle=VC365::UI.angle+0.025
            gtk_widget_queue_draw(VC365::UI.upsheet[:wave_area])
        end
    end}.pointer.as(VC365::GFunc)
    alias Func=(VC365::GApp) -> Void
    class_getter! app : VC365::AApp
    class_getter! window : VC365::AAWindow
    class_getter! builder : VC365::GtkBuilder
    class_getter! main_stack : VC365::GtkElement
    class_getter! prevent_default : Bool
    class_property! play_btns : Array(VC365::GtkElement)
    class_property! actions : {play: VC365::GSAction,prev: VC365::GSAction,next: VC365::GSAction}
    class_property! play_bar : {ring: VC365::GtkElement,sheet: VC365::GtkElement,sheet_box: VC365::GtkElement,
        timer: VC365::GtkElement}
    class_property! play_mode : VC365::GtkElement
    class_property! volume_adj : VC365::GtkElement
    class_property! navigate_btn : VC365::GtkElement
    class_setter volume_element : VC365::GtkElement?
    class_setter at_overlay : VC365::GtkElement?
    class_property! current_row : VC365::GRList
    class_property! menu_pop : {dialog: VC365::GtkElement,add: VC365::GtkElement,del: VC365::GtkElement,
        del_label: VC365::GtkElement,favorite: VC365::GtkElement,fav_icon: VC365::GtkElement}
    class_property! upsheet : {sheet: VC365::GtkElement,cover_art: VC365::GtkElement,duration: VC365::GtkElement,
        track_title: VC365::GtkElement,bar_title: VC365::GtkElement,track_dir: VC365::GtkElement,
        bar_dir: VC365::GtkElement,wave_area: VC365::GtkElement,sheet_content: VC365::GtkElement
    }
    class_property! lists : {root: VC365::GtkList,favorite: VC365::GtkList,playlist: VC365::GtkList,
        recent: VC365::GtkList}
    class_property page : VCMusic::Page=VCMusic::Page::Home
    class_property angle=0.0
    class_property! wave_tk : UInt32
    class_getter call : Array(Func) = [] of Func
    def self.call=(dood : Func);@@call << dood;end
    class_getter before_ui : Array(->Nil) = [] of ->Nil
    def self.before_ui=(dood : ->Nil);@@before_ui << dood;end

    def self.height_window
        Xlib.gtk_widget_get_height(window.as(VC365::GtkElement))
    end
    private def self.window(appX : VC365::GApp)
        Xlib.call do
            @@builder=gtk_resource("/ir/NonFree/VCMusic/ui/root/main.ui")
            @@window = gtk_get_object(builder, "vcmusic_root").as(VC365::AAWindow)
            @@main_stack=gtk_get_object(builder,"main_stack").as(VC365::GtkElement)
            gt=gtk_theme(gdk_display_get_default())
            ["symbolic","scalable/apps"].each { |i| gtk_theme_add(gt,"/ir/NonFree/VCMusic/icons/hicolor/#{i}")}
            gtk_application_add_window(appX,window)
        end
    end
    private def self.init(appX : VC365::GApp)
        unless @@window
            window(appX)
            Xlib.g_signal(window,"close-request",
                ->{if Settings::Values.rib[:e]
                    Xlib.gtk_widget_hide(window.as(VC365::GtkElement));true
                    else;false
                end}
            )
        end
        call.each do |block|
            block.call(appX)
        end
        call.clear
        Xlib.gtk_window_present(window)
    end
    def self.app_init(@@app)
        Xlib.call do
            appid=g_application_get_appid(app.as(VC365::GApp))
            setlocale(VC365::LC::ALL, "")
            bindtextdomain(appid,ENV["VCMUSIC_LOCALE_LOCATION"]? || "/usr/share/locale")
            textdomain(appid)
	        g_resources_register(GRESOURCE)
            g_signal(app,"activate",
                ->(ax : VC365::GApp,gpointer : Pointer(Void)){init(ax)})
        end
    end
    def self.notify(msg : String | UInt8*,timeout : Int32,one_toast=false,overlay=@@at_overlay.not_nil!)
        Xlib.adw_toast_cancel_all(overlay,true) if timeout.zero? || one_toast
        Xlib.adw_add_toast(overlay,Xlib.call do;t=adw_toast_new(msg)
            adw_toast_set_use_markup(t,false);adw_toast_set_timeout(t,timeout);t
        end)
    end
    def self.upsheet(data : List::Data)
        Xlib.call do
            gtk_label_set_text(upsheet[:bar_title],data[:name])
            gtk_label_set_text(upsheet[:track_title],data[:name])
            gtk_label_set_text(upsheet[:track_dir],data[:info][:folder])
            gtk_label_set_text(upsheet[:bar_dir],data[:info][:folder])
            gtk_label_set_text(upsheet[:duration],to_clock(data[:info][:duration]))
            gtk_adj_upper(play_bar[:sheet],data[:info][:duration])
            gtk_label_set_text(play_bar[:timer],to_clock(Player.value_bar))
            gtk_adj_set_value(play_bar[:sheet],Player.value_bar)
            avatar_set_text(upsheet[:cover_art],
                data[:name].strip.upcase.gsub(/[^A-Z0-9]/, "").[0,2] || "VC")
            gtk_label_set_ellipsize(upsheet[:bar_title], VC365::PEMode::END)
            gtk_label_set_ellipsize(upsheet[:bar_dir], VC365::PEMode::END)
        end
    end
    private def self.signal_btns(item_builder : VC365::GtkBuilder,row : GtkElement) Xlib.call do
        g_signal(gtk_get_object(item_builder, "menu_btn"),"clicked",
            ->(rowX : VC365::GRList){Xlib.call do
                @@current_row=rowX
                uri=String.new(gtk_get_name(current_row.as(VC365::GtkElement)))
                gtk_set_visible(menu_pop[:add],true)
                gtk_set_visible(menu_pop[:favorite],true)
                gtk_label_set_text(menu_pop[:del_label],case page
                    when .home?; gettext("Delete");when .recently?; gettext("Remove as Recently")
                end || gettext("Delete"))
                gtk_image_set_icon(menu_pop[:fav_icon],List.favorite.index(uri).nil? ?
                   "star-outline-rounded-symbolic" : "star-large-symbolic")
                adw_dialog_set_title(menu_pop[:dialog],Path[URI.parse(uri).path].stem)
                List.playlists.size.zero? ? gtk_set_sensitive(menu_pop[:add],false) :
                    gtk_set_sensitive(menu_pop[:add],true)
                adw_dialog_present(menu_pop[:dialog],window)
            end},row,
        true)
        g_signal(gtk_get_object(item_builder, "add_queue"),"clicked",
            ->(rowX : VC365::GtkElement){Xlib.call do
                uri=String.new(gtk_get_name(rowX))
                name=Path[URI.parse(uri).path].stem
                List.queues_cpush?(List.data_indexU!(uri)) &&
                    notify("#{name[0..50].strip}#{"..." if name.size-1>50}  #{String.new(gettext("added to queue"))}",
                    2,true)
            end},row,
        true)
    end;end
    def self.init_list(list : VC365::GtkList,uri : String,append : Bool)
        Xlib.call do
            data=List.data.find(List::DefaultData) { |i| i[:uri]==uri}
            name=(path=Path[URI.parse(uri).path]).stem
            enable=true if File.exists?(path) if uri==data[:uri] unless List.data.empty?
            item_builder = gtk_resource("/ir/NonFree/VCMusic/ui/samples/item.ui")
            title,row = get_element("title",item_builder),get_element("row",item_builder)

            gtk_set_name(row,uri)
            gtk_label_set_text(title, name)
            gtk_label_set_ellipsize(title, VC365::PEMode::END)
            enable ? gtk_label_set_text(get_element("time",item_builder),
                to_clock(data[:info][:duration])) : gtk_set_sensitive(row,false)
            gtk_button_set_label(get_element("action_btn",item_builder),
                name.strip.upcase.gsub(/[^A-Z0-9]/, "").[0,2] || "VC")
            signal_btns(item_builder,row)
            append ? gtk_list_box_append(list, row.as(VC365::GRList)) :
            gtk_list_box_prepend(list, row.as(VC365::GRList))
            enable
        end
    end
    def self.set_recent(uri : String)
        Xlib.call do
            unless i=List.recent.index(uri)
                index=List.data_indexU!(uri)
                List.recent.unshift(uri)
                init_list(VC365::UI.lists[:recent],uri,false)
            else
                row=gtk_get_row_at_index(VC365::UI.lists[:recent],i)
                gtk_list_box_remove(VC365::UI.lists[:recent],row)
                gtk_list_box_prepend(VC365::UI.lists[:recent],row)
                List.recent.delete(uri)
                List.recent.unshift(uri)
            end
        end
        Storage.update_data(:recent,List.recent)
    end
    def self.prevent_default(@@prevent_default)
        dox=!@@prevent_default
        Xlib.call do
            g_action_enable(actions[:play],dox)
            g_action_enable(actions[:next],dox)
            g_action_enable(actions[:prev],dox)
            Header.tool_bar(dox)
            gtk_set_sensitive(Playlist.queue[:open_queue],dox)
            gtk_set_sensitive(navigate_btn,dox)
            gtk_set_sensitive(Settings.elements[:library][:reload],!Settings::Values.dirs.empty?)

            view_stack_set_vischild_name(main_stack,dox ?
                if List.focused.pl_page? && (i=List.playlists.keys.index(Playlist.focused))
                    Playlist.plpage_init(Playlist.focused,gtk_get_row_at_index(VC365::UI.lists[:playlist],i))
                    Playlist.is_plpage=true
                    "playlist"
                end || List.focused.to_s.downcase : "home"
            )
            if dox && !(Storage.open_local_song || Player.change_value_bar)
                if List.data[Player.index][:uri]==Player.current_song[:uri] && !Player.value_bar.zero?
                    Player.change_value_bar=true
                    Player.state=VC365::GstState::Paused
                else
                    Player.value_bar=0
                    Player.current=-100
                    Storage.update_config("value_bar",Player.value_bar,:state,false)
                end
                gtk_widget_queue_draw(play_bar[:ring])
                gtk_label_set_text(play_bar[:timer],to_clock(Player.value_bar))
                gtk_adj_set_value(play_bar[:sheet],Player.value_bar)
            end
            upsheet(if dox
                if data=List.data[Player.index]?
                    Player.current_song={name: Path[URI.parse(data[:uri]).path].stem,uri: data[:uri]};data
                end
                end || List::DefaultData
            )
            update_counter
            update_placeholder
        end
    end
    def self.update_placeholder
        Xlib.call do
            gtk_list_box_set_placeholder(lists[:root],placeholder(gettext("No Songs Available"),
                gettext("You haven't added any songs yet."),"broken-playback-symbolic"))
            gtk_list_box_set_placeholder(lists[:recent],placeholder("No Recent Songs","","emoji-recent-symbolic"))
            gtk_list_box_set_placeholder(lists[:favorite],placeholder(gettext("No Favorite Songs Added"),
                gettext("Add songs to your favorites to view them here."),"star-filled-rounded-symbolic"))
            gtk_list_box_set_placeholder(lists[:playlist],placeholder(gettext("No Playlists Available"),
                gettext("Create your first playlist to organize your favorite tracks."),"library-music-symbolic"))
            gtk_list_box_set_placeholder(Playlist.plpage[:list],placeholder(gettext("No Songs Available"),
                gettext("You haven't added any songs yet."),"broken-playback-symbolic"))
            gtk_list_box_set_placeholder(Playlist.queue[:list],placeholder(gettext("Queue is Empty"),"",""))
            gtk_list_box_set_placeholder(Settings.elements[:library][:list].as(VC365::GtkList),
                placeholder(gettext("No Folders Available"),"","library-symbolic"))
            gtk_list_box_set_placeholder(Playlist.plpage[:list],VC365::UI.placeholder(gettext("No songs available"),
                gettext("You haven't added any songs yet."),"broken-playback-symbolic"))
        end
    end
    @@volume_icon=""
    def self.volume_icon
        Xlib.call do
            volume_icon=case Player.volume*100
                when 0;      "audio-volume-muted"
                when 1..30;  "audio-volume-low"
                when 31..70; "audio-volume-medium"
                when 71..100;"audio-volume-high"
                else;        "audio-volume-overamplified-symbolic"
            end
            gtk_menu_set_icon(@@volume_element.not_nil!,@@volume_icon=volume_icon) if volume_icon!=@@volume_icon
        end
    end
    def self.navigate
        Xlib.call do
            unless List.data.empty?
                adj=gtk_list_box_get_adjustment(List.focused.glist)
                max=gtk_adj_get_upper(adj)
                index=List.focused.index
                row=gtk_get_row_at_index(List.focused.glist,index).as(VC365::GtkElement)
                height_row=row ? gtk_widget_get_height(row) : 60
                tp=max/List.focused_list.size
                gtk_adj_set_value(adj,(index*tp-((height_window/2)-height_row)).clamp(0.0..max))
            end
        end
    end
    @@counter_element=uninitialized VC365::GtkElement
    def self.update_counter(e=nil)
        Xlib.call do
            e=view_stack_child_by_name(main_stack,page.pl_page? ? "playlist" : page.to_s.downcase) unless e
            view_stack_page_set_badge_number(@@counter_element,0) if @@counter_element
            view_stack_page_set_badge_number(@@counter_element=view_stack_page(main_stack,e),List.current_list.size)
        end
    end
    def self.placeholder(title : String | UInt8*,des : String | UInt8*,icon : String)
        Xlib.call do
            asp=adw_sp_new
            adw_sp_description(asp,des);adw_sp_icon(asp,icon);adw_sp_title(asp,title)
            asp
        end
    end
end

# initialize
VC365::UI.call=->(appX : VC365::GApp) do Xlib.call do
    gtk_window_set_default_icon_name("ir.NonFree.VCMusic")
    g_signal(VC365::UI.main_stack,"notify::visible-child-name",
        ->(e : VC365::GtkElement){
            VC365::UI.page=case String.new(Xlib.view_stack_vischild_name(e))
                when "home";      VCMusic::Page::Home
                when "playlist";  VCMusic::Page::Playlist
                when "recently";  VCMusic::Page::Recently
                when "favorites"; VCMusic::Page::Favorites
            end || VCMusic::Page::Home
            VC365::UI.update_counter(Xlib.view_stack_vischild(e))
            Playlist.set_plist(false)
        }
    )
    VC365::UI.upsheet={sheet: get_element("sheet"),cover_art: get_element("cover_art"),
        duration: get_element("duration"),track_title: get_element("track_title"),
        bar_title: get_element("bar_title"),track_dir: get_element("track_dir"),
        bar_dir: get_element("bar_dir"),wave_area: get_element("wave_area"),
        sheet_content: get_element("sheet_content")
    }
    VC365::UI.menu_pop={dialog: get_element("menu_pop"),add: get_element("menu_pop_add"),
        del: get_element("menu_pop_del"),del_label: get_element("menu_pop_del_label"),
        favorite: get_element("menu_pop_favorite"),fav_icon: get_element("menu_pop_fav_icon")
    }
    VC365::UI.lists={root: gtk_get_object(VC365::UI.builder, "music_list").as(VC365::GtkList),
        favorite: gtk_get_object(VC365::UI.builder, "fav_list").as(VC365::GtkList),
        playlist: gtk_get_object(VC365::UI.builder, "play_list").as(VC365::GtkList),
        recent: gtk_get_object(VC365::UI.builder, "rec_list").as(VC365::GtkList)
    }
    VC365::UI.actions={play: g_action_new("play_song", nil),prev: g_action_new("prev_song", nil),
        next: g_action_new("next_song", nil)
    }
    VC365::UI.play_mode=get_element("play_mode")
    VC365::UI.volume_adj=get_element("volume_scale")
    VC365::UI.volume_element=get_element("volume")
    VC365::UI.at_overlay=get_element("at_overlay")
    VC365::UI.navigate_btn=get_element("navigate_btn")
    VC365::UI.play_btns=([get_element("splay_btn"),get_element("fplay_btn")])
    VC365::UI.play_bar=({ring: get_element("ring_bar"),sheet: get_element("sheet_bar"),
        sheet_box: get_element("sheet_box"),timer: get_element("timer")
    });end
    Settings.init(appX)
    Header.init
    Playlist.init(appX)
end

# Lists
VC365::UI.call=->(appX : VC365::GApp) do
    VC365::UI.lists.each do |key,val|
        Xlib.call do
            (key == :playlist ? 2 : 1).times do |i|
                val=Playlist.plpage[:list] if i == 1
                gtk_listbox_set_filter_func(val,
                    ->(row : VC365::GRList){Xlib.call do
                        dood=if Header.search_mode
                            path=URI.parse(String.new(gtk_get_name(row.as(VC365::GtkElement)))).path.downcase
                            unless path.includes?(Header.search_values[:sv])
                                tokens=path.gsub(/[!"#$%&'()*+,\-\.\/:;<=>?@\[\\\]^_`{|}~]+/," ").split.uniq # X"
                                match=[] of Float64
                                Header.search_values[:sv_tokens].each do |s|
                                    match << if s.empty?; -1.0
                                    elsif !tokens.find(&.includes?(s)).nil?; 1.0
                                    else
                                        dis=case s.size
                                            when 1..3 then 0
                                            when 4..5 then 1
                                            when 6..7 then 2
                                            else 3
                                        end
                                        Levenshtein.find(s,tokens,dis).nil? ? -1.0
                                        : Math.exp(-dis.to_f / [s.size,tokens.size].max)
                                    end
                                end
                                match.sum / Header.search_values[:sv_tokens].size >= 0.5
                            else; true
                            end
                        else; true
                        end
                        if Header.selection_mode && Header.search_mode
                            if dood
                                gtk_list_select_row(VC365::UI.page.glist,row)
                                Header.selected_rows.push(row)
                            else
                                gtk_list_unselect_row(VC365::UI.page.glist,row)
                            end
                        end
                        dood ? true : nil
                    end}.pointer.as(VC365::GFunc),nil,
                nil)
            end
            g_signal(gtk_list_box_get_adjustment(val),
                "value-changed",->(adj : VC365::GtkElement){Xlib.call do
                    indexX=List.focused.index
                    row=gtk_get_row_at_index(List.focused.glist,indexX).as(VC365::GtkElement)
                    height_row=row ? gtk_widget_get_height(row) : 60
                    value=gtk_adj_get_value(adj)
                    max=(gtk_adj_get_upper(adj)/List.focused_list.size)*indexX+height_row
                    min=(max+height_row)-VC365::UI.height_window
                    gtk_set_visible(VC365::UI.navigate_btn,
                        value != value.clamp(min,max) || List.focused != VC365::UI.page
                    )
                end}
            )
            g_signal(val,"row-activated",
                ->(list : VC365::GtkList, row : VC365::GRList){
                    Xlib.call do
                        unless Header.mode.all?
                            List.focused=case list
                            when VC365::UI.lists[:root];VCMusic::Page::Home
                            when VC365::UI.lists[:recent];VCMusic::Page::Recently
                            when VC365::UI.lists[:favorite];VCMusic::Page::Favorites
                            when Playlist.plpage[:list]
                                VCMusic::Page::PlPage
                            end.not_nil!
                            Playlist.focused=String.new(gtk_get_name(list.as(VC365::GtkElement))
                            ) if list==Playlist.plpage[:list]
                            uri=String.new(gtk_get_name(row.as(VC365::GtkElement)))
                            Player.index=List.data_indexU!(uri)
                            if (Player.current != Player.index)
                                List.queues.clear
                                List.queues.push(Player.index)
                                Storage.update_data(:queues,List.queues)
                                if Player.change_value_bar
                                    Player.state=VC365::GstState::Null
                                    Player.change_value_bar=false
                                    Player.value_bar=0
                                    Player.is_playing(true)
                                end
                                gtk_widget_queue_draw(VC365::UI.play_bar[:ring])
                                VC365::UI.upsheet(List.data[Player.index])
                                Player.play(uri) if Player.state.playing? || Player.state.paused?
                            else
                                VC365::UI.set_recent(uri) unless List.focused.recently?
                                Player.is_playing
                                Playlist.playlist_up
                            end
                            gtk_set_visible(VC365::UI.navigate_btn,false)
                        else
                            Header.select_mode(row,list)
                        end
                    end
                }
            )
        end
    end
    Player.index=List.data_indexU!(Player.current_song[:uri])
    Settings.reload_lists(clear_lists: false)
    Storage.open_local_song && Xlib.abs_set_open(VC365::UI.upsheet[:sheet],true)
end

# Play Buttons
VC365::UI.call=->(appX : VC365::GApp) do
    Xlib.call do
        g_signal(VC365::UI.actions[:play],"activate",->{Player.play(List.data[Player.index][:uri])})
            gtk_app_accels_action(appX, "app.play_song", ["space".to_unsafe, Pointer(UInt8).null])
        g_action_map_add_action(appX.as(VC365::GSAGroup), VC365::UI.actions[:play])
            g_signal(VC365::UI.actions[:prev], "activate",->{Player.next_song("prev");VC365::UI.navigate})
            g_signal(VC365::UI.actions[:next], "activate",->{Player.next_song("next");VC365::UI.navigate})
        g_action_map_add_action(appX.as(VC365::GSAGroup), VC365::UI.actions[:prev])
        g_action_map_add_action(appX.as(VC365::GSAGroup), VC365::UI.actions[:next])

        gtk_adj_upper(VC365::UI.volume_adj,Settings::Values.max_volume*100)
        gtk_adj_set_value(VC365::UI.volume_adj,Player.volume*100)
        VC365::UI.volume_icon
        g_signal(VC365::UI.volume_adj,"value-changed",
            ->{
                Player.volume=Xlib.gtk_adj_get_value(VC365::UI.volume_adj)/100
                VC365::UI.volume_icon
            }
        )
        gtk_button_set_icon(VC365::UI.play_mode,case Player.mode
            in .consecutive?;"xplaylist-consecutive-symbolic"
            in .shuffle?;    "xplaylist-shuffle-symbolic"
            in .repeat?;     "xplaylist-repeat-symbolic"
            in .repeat_song?;"xplaylist-repeat-song-symbolic"
        end)
        g_signal(VC365::UI.play_mode,"clicked",
            ->(btn : VC365::GtkElement){Xlib.gtk_button_set_icon(btn,Player.set_mode)}
        )
        g_signal(VC365::UI.navigate_btn,"clicked",
            ->{Xlib.call do
                view_stack_set_vischild_name(VC365::UI.main_stack,
                    if List.focused.pl_page? && (i=List.playlists.keys.index(Playlist.focused))
                        Playlist.plpage_init(Playlist.focused,
                            gtk_get_row_at_index(VC365::UI.lists[:playlist],i))
                        "playlist"
                    end || List.focused.to_s.downcase
                )
                VC365::UI.navigate
            end}
        )
        g_signal(gtk_list_box_get_adjustment(List.focused.glist),"notify::upper",
            ->{unless List.data.empty? || List.focused.pl_page?
                Xlib.last_req(0.5.seconds,"Navigate") {
                    VC365::UI.navigate
                    Xlib.gtk_set_visible(VC365::UI.navigate_btn,false)
                }
            end}
        )
    end
end

# Visualizer
POINTS = 360 # 256
BASE_RADIUS = 115.0
MAX_AMPLITUDE = 30.0
VC365::UI.call=->(appX : VC365::GApp) do
    Xlib.call do
        gtk_drawing_area_set_draw_func(
            VC365::UI.upsheet[:wave_area],
            ->(area : VC365::GObject, ctx : VC365::CarioC, w : Int32, h : Int32, data : Void*) {
                Xlib.call do
                    cx = w / 2.0
                    cy = h / 2.0

                    level = Player.vis_level.clamp(0.0..)
                    #level = level * level
                    volume = Player.volumeX.clamp(0.0, 1.0)

                    cairo_set_line_width(ctx, 2.3)
                    cairo_set_source_rgba(ctx, 0.2078, 0.5176, 0.8941, 1.0)

                    peaks = [0,1.2,2.4,3.6,4.8]
                    0.upto(POINTS) do |i|
                        a = 2.0 * Math::PI * i / POINTS
                        wave = 0.0
                        peaks.each_with_index do |base_angle, n|
                            peak_angle= base_angle + Math.sin(VC365::UI.angle * 1.8 - n * 1.1) * 0.20

                            d = Math.atan2(Math.sin(a - peak_angle), Math.cos(a - peak_angle))
                            wave += Math.exp(-(d * d) / 0.055)
                        end

                        radius =
                            BASE_RADIUS + wave.clamp(0.0, 1.0) * MAX_AMPLITUDE * level * volume
                        draw_angle = a + VC365::UI.angle * 0.12
                        x = cx + Math.cos(draw_angle) * radius
                        y = cy + Math.sin(draw_angle) * radius

                        i.zero? ? cairo_move_to(ctx, x, y) : cairo_line_to(ctx, x, y)
                    end
                    cairo_close_path(ctx)
                    cairo_stroke(ctx)
                    unless Settings::Values.visualizer
                        cairo_set_operator(ctx, 0)
                        cairo_paint(ctx)
                        cairo_set_operator(ctx, 2)
                    end
                end
            }.pointer.as(VC365::GFunc),
            nil,
            nil
        )
        unless Settings::Values.visualizer
            avatar_set_size(VC365::UI.upsheet[:cover_art],256)
            gtk_set_margin_top(VC365::UI.upsheet[:cover_art],0)
            gtk_set_margin_bottom(VC365::UI.upsheet[:cover_art],0)
            gtk_set_margin_top(VC365::UI.upsheet[:sheet_content],18)
            gtk_box_set_spacing(VC365::UI.upsheet[:sheet_content],12)
        else
            VC365::UI.wave_tk=gtk_add_tick_callback(VC365::UI.upsheet[:wave_area],VC365::UI::WaveGFunc,nil,nil)
        end
    end
end
# Play Bar
VC365::UI.call=->(appX : VC365::GApp) do Xlib.call do
    gtk_drawing_area_set_draw_func(VC365::UI.play_bar[:ring],
        ->(area : VC365::GObject, ctx : VC365::CarioC, w : Int32, h : Int32, data : Void*) { Xlib.call do
            radius = (w < h ? w : h) // 2 - 4
            cx,cy = w / 2,h / 2

            # Border
            is_dark=Settings.is_dark ? 1 : 0
            cairo_set_source_rgba(ctx, is_dark, is_dark, is_dark, 0.2)
            cairo_set_line_width(ctx, 4.0)
            cairo_arc(ctx, cx, cy, radius, 0, 2 * Math::PI)
            cairo_stroke(ctx)

            # PBar
            dood=-Math::PI/2 -((Player.value_bar /
                (List.data.empty? ? 0 : List.data[Player.index][:info][:duration])) * 2 * Math::PI)
            cairo_set_source_rgba(ctx, 0.2078, 0.5176, 0.8941, 1.0)
            cairo_arc_negative(ctx, cx, cy, radius, -Math::PI/2, dood )
            cairo_stroke(ctx)
        end}.pointer.as(VC365::GFunc),
        nil,
        nil
    )
    Player.init_bar
end;end

# Menu Pop
VC365::UI.call=->(appX : VC365::GApp) do
    Xlib.call do
        g_signal(get_element("sheet_menu_btn"),"clicked",
            ->{Xlib.call do
                gtk_set_visible(VC365::UI.menu_pop[:add],true)
                gtk_set_visible(VC365::UI.menu_pop[:favorite],true)
                gtk_label_set_text(VC365::UI.menu_pop[:del_label],case List.focused
                    when .home?; gettext("Delete");when .recently?; gettext("Remove as Recently")
                end || gettext("Delete"))
                VC365::UI.current_row=gtk_get_row_at_index(List.focused.glist,List.focused.index)
                uri=String.new(gtk_get_name(VC365::UI.current_row.as(VC365::GtkElement)))
                gtk_image_set_icon(VC365::UI.menu_pop[:fav_icon],List.favorite.index(uri).nil? ?
                   "star-outline-rounded-symbolic" : "star-large-symbolic")
                adw_dialog_set_title(VC365::UI.menu_pop[:dialog],Path[URI.parse(uri).path].stem)
                List.playlists.size.zero? ? gtk_set_sensitive(VC365::UI.menu_pop[:add],false) :
                    gtk_set_sensitive(VC365::UI.menu_pop[:add],true)
                adw_dialog_present(VC365::UI.menu_pop[:dialog],VC365::UI.window)
            end}
        )
        g_signal(gtk_get_object(VC365::UI.builder,"menu_pop_list"),"row-activated",
            ->(list : VC365::GtkList, row : VC365::GRList){Xlib.call do
                name=String.new(gtk_get_name(VC365::UI.current_row.as(VC365::GtkElement)))
                sheet=abs_get_open(VC365::UI.upsheet[:sheet])
                page=sheet ? List.focused : VC365::UI.page
                case String.new(gtk_get_name(row.as(VC365::GtkElement)))
                when "add"
                    Header.mode=Header::Mode::Add
                    Header.state=page
                    gtk_set_sensitive(Header.select_header[:add_btn],false)
                    Header.add_mode(true)
                    Header.add_rows.unshift(name)
                    adw_dialog_close(VC365::UI.menu_pop[:dialog])
                    view_stack_set_vischild_name(VC365::UI.main_stack,"playlist")
                    Playlist.set_plist(false)
                    Header.selection_modeX(true)
                    abs_set_open(VC365::UI.upsheet[:sheet],false) if sheet
                when "delete"
                    page.home? ? List.data.delete_at(List.data_indexU!(name))
                        : List.current_list.delete(name)
                    gtk_list_box_remove(page.glist,VC365::UI.current_row)
                    gtk_set_sensitive(Header.default_header[:del_plmode],
                        false) if List.playlists.empty? && page.playlist?
                    adw_dialog_close(VC365::UI.menu_pop[:dialog])
                    abs_set_open(VC365::UI.upsheet[:sheet],false) if sheet
                    if Playlist.focused==name && page.playlist?
                        Playlist.focused=""
                        Player.pause_play if Player.state.playing?
                        List.focused=VCMusic::Page::Home
                        Player.index=List.data_indexU!(Player.current_song[:uri])
                        Player.is_playing
                    else
                        Player.next_song("next") if name==Player.current_song[:uri]
                    end
                    VC365::UI.update_counter
                    Storage.update_data(page)
                when "favorite"
                    if List.favorite.index(name).nil?
                        gtk_image_set_icon(VC365::UI.menu_pop[:fav_icon],"star-large-symbolic")
                        List.favorite.unshift(name)
                        VC365::UI.init_list(VC365::UI.lists[:favorite],name,false)
                    else
                        gtk_image_set_icon(VC365::UI.menu_pop[:fav_icon],"star-outline-rounded-symbolic")
                        gtk_list_box_remove(VC365::UI.lists[:favorite],
                            gtk_get_row_at_index(VC365::UI.lists[:favorite],
                                List.favorite.index!(name)))
                        List.favorite.delete(name)
                    end
                    Storage.update_data(:favorites,List.favorite)
                end
            end}
        )
    end
end
