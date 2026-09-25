module Playlist
    class_getter focused : String=""
    class_getter! avatar : VC365::GtkElement
    class_getter! dialog : {root: VC365::GtkElement,ok: VC365::GtkElement,input: VC365::GtkElement}
    class_getter! plpage : {list: VC365::GtkList,title: VC365::GtkElement,count: VC365::GtkElement,
        avatar: VC365::GtkElement,play_btn: VC365::GtkElement}
    class_getter! queue : {dialog: VC365::GtkElement,list: VC365::GtkList,open_queue: VC365::GtkElement}
    class_getter! stack : VC365::GtkElement
    class_setter is_plpage : Bool=false
    @@current_playlist=uninitialized VC365::GRList
    @@is_playing=uninitialized VC365::GtkElement
    @@set_plist : Bool?

    def self.focused=(x : String)
        Storage.update_config("focused_playlist",@@focused=x,:state,false)
    end
    def self.set_plist(b : Bool)
        if @@is_plpage
            @@is_plpage=false
            b=true
        end
        if b
            VC365::UI.page=VCMusic::Page::PlPage
        elsif VC365::UI.page.pl_page?
            VC365::UI.page=VCMusic::Page::Playlist
        end
        VC365::UI.update_counter
        Xlib.gtk_stack_set_vischild_name(stack,b ? "plist" : "list") unless @@set_plist == b
        @@set_plist=b
        Header.tool_bar
        Xlib.gtk_set_visible(VC365::UI.navigate_btn,if List.focused==VC365::UI.page
            VC365::UI.navigate;false;else;true;end
        ) unless b
        Storage.update_config("value_bar",Player.value_bar,:state,false)
    end
    private def self.signal_btns(item_builder : VC365::GtkBuilder,row : VC365::GtkElement) Xlib.call do
        g_signal(gtk_get_object(item_builder,"menu_btn"),"clicked",
            ->(rowX : VC365::GRList){Xlib.call do
                VC365::UI.current_row=rowX
                gtk_set_visible(VC365::UI.menu_pop[:add],false)
                gtk_set_visible(VC365::UI.menu_pop[:favorite],false)
                gtk_label_set_text(VC365::UI.menu_pop[:del_label],gettext("Delete playlist"))
                adw_dialog_set_title(VC365::UI.menu_pop[:dialog],gtk_get_name(
                    VC365::UI.current_row.as(VC365::GtkElement)))
                adw_dialog_present(VC365::UI.menu_pop[:dialog],VC365::UI.window)
            end},row,
        true)
        g_signal(gtk_get_object(item_builder,"avatar_btn"),"clicked",
            ->(rowX : VC365::GtkElement){Xlib.call do
                name=String.new(gtk_get_name(rowX))
                unless List.playlists[name].empty? || VC365::UI.prevent_default
                    Player.play(List.data[Player.index][:uri]
                    ) if List.focused.pl_page? && focused == name
                    Playlist.focused=name
                    List.focused=VCMusic::Page::PlPage
                    pre_index=Player.index
                    Player.index=List.data_indexU!(List.focused_list[0].as(String)
                    ) if List.focused_list.index(List.data[Player.index][:uri]).nil?
                    VC365::UI.upsheet(List.data[Player.index])
                    if Player.index == pre_index
                        playlist_up
                        Player.is_playing(del: true) if Player.state.playing?
                    elsif Player.index != pre_index
                        Player.play(List.data[Player.index][:uri])
                    end
                end
                Storage.update_config("focused_playlist",@@focused,:state,false)
            end},row,
        true)
    end;end
    def self.init_pl(val : String)
        Xlib.call do
            item_builder = gtk_resource("/ir/NonFree/VCMusic/ui/samples/playlist-item.ui")
            title = get_element("title",item_builder)
            row = get_element("row",item_builder)

            gtk_set_name(row,val)
            gtk_label_set_text(title, val)
            gtk_label_set_ellipsize(title, VC365::PEMode::END)
            gtk_label_set_text(get_element("subtitle",item_builder),
                "#{String.new(gettext("Song"))} #{List.playlists[val].size}")
            avatar_set_text(get_element("avatar",item_builder),
                val.strip.upcase.gsub(/[^A-Z0-9]/, "").[0,2] || "VC")
            signal_btns(item_builder,row)
            gtk_list_box_append(VC365::UI.lists[:playlist], row.as(VC365::GRList))
        end
    end
    private def self.is_playing(ele : VC365::GtkElement | VC365::GRList)
        Xlib.call do
            gtk_set_visible(@@is_playing,false) if @@is_playing
            @@is_playing=case ele
                in VC365::GtkElement;ele
                in VC365::GRList;gtk_first_child(gtk_row_get_child(ele))
            end
            gtk_set_visible(@@is_playing,true)
        end
    end
    private def self.init_dialog
        Xlib.call do
            g_signal(Header.default_header[:create_btn],"clicked",
                ->{Xlib.call do
                    val=String.new(gtk_editable_get_text(dialog[:input]))
                    gtk_set_sensitive(dialog[:ok],false) if List.playlists.has_key?(val) || val.blank?
                    adw_dialog_present(dialog[:root],VC365::UI.window)
                    gtk_widget_focus(dialog[:input])
                end}
            )
            g_signal(gtk_get_object(VC365::UI.builder, "cancel_create_btn"),"clicked",
                ->{Xlib.adw_dialog_close(dialog[:root])}
            )
            g_signal(dialog[:input],"changed",
                ->{Xlib.call do
                    dood = String.new(gtk_editable_get_text(dialog[:input]))
                    gtk_set_sensitive(dialog[:ok],!(dood.blank? || List.playlists.has_key?(dood)))
                end}
            )
            g_signal(dialog[:ok],"clicked",
                ->{Xlib.call do
                    gtk_set_sensitive(Header.default_header[:del_plmode],true)
                    val=String.new(gtk_editable_get_text(dialog[:input])).strip
                    List.playlists[val]= [] of String
                    Storage.update_data(:playlists,List.playlists)
                    init_pl(val)
                    adw_dialog_close(dialog[:root])
                end}
            )
        end
    end
    private def self.plpage_signals(appX : VC365::GApp)
        Xlib.call do
            del_pl = g_action_new("del_pl", nil)
            g_signal(del_pl, "activate",
                ->{Xlib.call do
                    gtk_list_box_remove(VC365::UI.lists[:playlist],@@current_playlist)
                    set_plist(false)
                    List.playlists.delete(String.new(gtk_get_name(@@current_playlist.as(VC365::GtkElement))))
                    gtk_set_sensitive(Header.default_header[:del_plmode],false) if List.playlists.empty?
                end}
            )
            g_action_map_add_action(appX.as(VC365::GSAGroup), del_pl)
            g_signal(plpage[:play_btn],"clicked",->{
                Playlist.focused=String.new(Xlib.gtk_get_name(plpage[:list].as(VC365::GtkElement)))
                Player.play(List.data[Player.index][:uri]) if List.focused.pl_page?
                List.focused=VCMusic::Page::PlPage
                pre_index=Player.index
                Player.index=List.data_indexU!(List.focused_list[0].as(String)) if List.focused_list.index(
                    List.data[Player.index][:uri]).nil?
                VC365::UI.upsheet(List.data[Player.index])
                if Player.index == pre_index && Player.state.playing?
                    Player.is_playing
                elsif Player.index != pre_index
                    Player.play(List.data[Player.index][:uri])
                end
                VC365::UI.navigate
            })
        end
    end
    private def self.queue_init
        Xlib.call do
            g_signal(queue[:open_queue],"clicked",
                ->{Xlib.call do
                    gtk_list_remove_all(queue[:list])
                    List.queues.each do |val|
                        data=List.data[val]
                        item_builder = gtk_resource("/ir/NonFree/VCMusic/ui/samples/queue_item.ui")
                        title,row = get_element("title",item_builder),get_element("row",item_builder)

                        gtk_set_visible(@@is_playing=get_element("is_playing",item_builder),
                            true) if Player.queue_state && Player.index==val
                        gtk_set_name(row,data[:uri])
                        gtk_label_set_text(title, data[:name])
                        gtk_label_set_ellipsize(title, VC365::PEMode::END)
                        gtk_label_set_text(get_element("time",item_builder),
                            to_clock(data[:info][:duration]))
                        gtk_button_set_label(get_element("action_btn",item_builder),
                            data[:name].strip.upcase.gsub(/[^A-Z0-9]/, "").[0,2] || "VC")
                        g_signal(gtk_get_object(item_builder,"del_queue"),"clicked",
                            ->(queue_row : VC365::GtkElement){Xlib.call do
                                List.queues.delete(List.data_indexU!(String.new(gtk_get_name(queue_row))))
                                gtk_list_box_remove(queue[:list],queue_row.as(VC365::GRList))
                                Storage.update_data(:queues,List.queues)
                            end},row,
                        true)
                        gtk_list_box_append(queue[:list], row.as(VC365::GRList))
                    end
                    if List.queues.empty?
                        List.queues.push(Player.index)
                        Storage.update_data(:queues,List.queues)
                    end
                    adw_dialog_set_title(queue[:dialog],List.data[List.queues.first][:name])
                    adw_dialog_present(queue[:dialog],VC365::UI.window)
                end}
            )
            g_signal(get_element("queue_clear"),"clicked",
                ->{List.queues.clear;Xlib.gtk_list_remove_all(queue[:list])
                    Storage.update_data(:queues,List.queues)
                }
            )
        end
    end
    def self.playlist_up(state=Player.state.playing?)
        Xlib.call do
            unless List.playlists.empty? || @@focused.empty?
                avatar_btn=gtk_first_child(gtk_first_child(gtk_row_get_child(
                    gtk_get_row_at_index(VC365::UI.lists[:playlist],List.playlists.keys.index!(focused)
                ))))
                icon=%Q(xmedia-playback-#{state && List.focused.pl_page? ? "pause" : "start"}-symbolic)
                if @@avatar
                    avatar_set_icon(avatar,"xlibrary-music-symbolic")
                    gtk_del_classname(gtk_get_parent(avatar),"current")
                end
                @@avatar=gtk_first_child(avatar_btn)
                [[avatar,avatar_btn],[plpage[:avatar],plpage[:play_btn]]].each do |a|
                    avatar_set_icon(a.first,if List.focused.pl_page?
                        gtk_add_classname(a.last,"current")
                        icon
                    else
                        gtk_del_classname(a.last,"current")
                        "xlibrary-music-symbolic"
                    end)
                end
            end
        end
    end
    def self.plpage_init(name : String,row : VC365::GRList)
        Xlib.call do
            gtk_list_remove_all(plpage[:list])
            gtk_list_box_set_placeholder(plpage[:list],VC365::UI.placeholder(gettext("No songs available"),
                gettext("You haven't added any songs yet."),"broken-playback-symbolic"))
            @@current_playlist=row
            gtk_set_name(plpage[:list].as(VC365::GtkElement),name)
            gtk_set_sensitive(plpage[:play_btn],gss=!(List.playlists[name].empty? || VC365::UI.prevent_default))
            List.playlists[name].each do |val|
                VC365::UI.init_list(plpage[:list],val,true)
            end
            playlist_up
            avatar_set_icon(plpage[:avatar],x=(gss ?
                if name==@@focused && List.focused.pl_page?
                    gtk_add_classname(plpage[:play_btn],"current")
                    Player.is_playing(false) unless Player.value_bar.zero?
                    Player.state.playing? ? "xmedia-playback-pause-symbolic" : "xmedia-playback-start-symbolic"
                end || "xlibrary-music-symbolic" : "xlibrary-music-symbolic")
            )
            gtk_del_classname(plpage[:play_btn],"current") if x=="xlibrary-music-symbolic"
            gtk_label_set_text(plpage[:title],name)
            gtk_label_set_text(plpage[:count],
                "#{String.new(gettext("Songs"))} #{List.playlists[name].size}")
            set_plist(true)
            gtk_set_visible(VC365::UI.navigate_btn,if name==@@focused
                VC365::UI.navigate;false;else;true;end
            )
        end
    end
    def self.update_count(row : VC365::GRList,val : Int32)
        Xlib.call do
            gtk_label_set_text(gtk_last_child(gtk_last_child(gtk_first_child(gtk_row_get_child(row)
            ))),"#{String.new(gettext("Song"))} #{val}")
        end
    end
    def self.init(appX : VC365::GApp)
        Xlib.call do
            @@stack=get_element("playlist_stack")
            @@queue={dialog: get_element("queue"),
                list: gtk_get_object(VC365::UI.builder, "list_queue").as(VC365::GtkList),
                open_queue: get_element("open_queue")
            }
            @@dialog={root: get_element("create_dialog"),ok: get_element("ok_create_btn"),
                input: get_element("create_input")
            }
            @@plpage={list: gtk_get_object(VC365::UI.builder, "plpage_list").as(VC365::GtkList),
                title: get_element("plpage_title"),count: get_element("plpage_count"),
                avatar: get_element("plpage_avatar"),play_btn: get_element("plpage_play_btn")
            }
            gtk_set_sensitive(Header.default_header[:del_plmode],false) if List.playlists.empty?
            init_dialog
            queue_init
            plpage_signals(appX)
            g_signal(VC365::UI.lists[:playlist],"row-activated",
                ->(list : VC365::GtkList, row : VC365::GRList){Xlib.call do
                    if Header.mode.none?
                        plpage_init(String.new(gtk_get_name(row.as(VC365::GtkElement))),row)
                    else
                        Header.select_mode(row,list)
                    end
                end}
            )
            g_signal(queue[:list],"row-activated",
                ->(list : VC365::GtkList, row : VC365::GRList){Xlib.call do
                    Player.index=List.data_indexU!(String.new(gtk_get_name(row.as(VC365::GtkElement))))
                    data=List.data[Player.index]
                    if (Player.current != Player.index)
                        if Player.change_value_bar
                            Player.state=VC365::GstState::Null
                            Player.change_value_bar=false
                            Player.value_bar=0
                            Player.is_playing(true)
                        end
                        gtk_widget_queue_draw(VC365::UI.play_bar[:ring])
                        VC365::UI.upsheet(data)
                        Player.play(data[:uri]) if Player.state.playing? || Player.state.paused?
                        is_playing(row)
                    else
                        VC365::UI.set_recent(data[:name]) unless List.focused.recently?
                        Player.is_playing
                        is_playing(row)
                    end
                end}
            )
        end
    end
end
