module Header
    enum Mode
        None
        All
        Add
        Delete
    end
    class_property! state : VCMusic::Page
    class_getter! default_header : {root: VC365::GtkElement,del_plmode: VC365::GtkElement,create_btn: VC365::GtkElement,
        back_btn: VC365::GtkElement,add_btn: VC365::GtkElement,search_btn: VC365::GtkElement
    }
    class_getter! select_header : {root: VC365::GtkElement,cancel_btn: VC365::GtkElement,
        del_btn: VC365::GtkElement,select_count: VC365::GtkElement,add_btn: VC365::GtkElement,
        select_all: VC365::GtkElement,fav_btn: VC365::GtkElement
    }
    class_getter! search_header : {root: VC365::GtkElement,back_btn: VC365::GtkElement,
        search_input: VC365::GtkElement,select_mode: VC365::GtkElement
    }
    class_property selected_rows : Array(VC365::GRList)=[] of VC365::GRList
    class_property add_rows : Array(String)=[] of String
    class_getter selection_mode : Bool=false
    class_getter select_all : Bool=false
    class_getter search_mode : Bool=false
    class_getter! search_values : {sv: String,sv_tokens: Array(String)}
    class_property mode : Mode=Mode::None

    def self.init
        Xlib.call do
            @@select_header={root: get_element("select_header"),cancel_btn: get_element("cancel_select_btn"),
                del_btn: get_element("delete_selected_btn"),select_count: get_element("select_count"),
                add_btn: get_element("add_selected_btn"),select_all: get_element("select_all_btn"),
                fav_btn: get_element("fav_selected_btn")
            }
            @@default_header={root: get_element("default_header"),del_plmode: get_element("del_plmode"),
                create_btn: get_element("create_playlist"),back_btn: get_element("playlist_back_btn"),
                add_btn: get_element("select_mode"),search_btn: get_element("search_btn")
            }
            @@search_header={root: get_element("search_header"),back_btn: get_element("search_back_btn"),
                search_input: get_element("search_input"),select_mode: get_element("search_select_mode")
            }

            ## Default Header
            g_signal(default_header[:search_btn],"clicked",
                ->{Xlib.call do
                    gtk_set_visible(search_header[:root],@@search_mode=true)
                    gtk_set_visible(default_header[:root],!search_mode)
                    gtk_app_accels_action(g_application_get_default, "app.play_song", [Pointer(UInt8).null])
                    gtk_widget_focus(search_header[:search_input])
                end}
            )
            g_signal(default_header[:add_btn],"clicked",
                ->{Xlib.call do
                    @@mode=Mode::All
                    gtk_set_sensitive(select_header[:del_btn],false)
                    gtk_set_visible(select_header[:del_btn],true)
                    gtk_set_sensitive(select_header[:add_btn],false)
                    gtk_set_visible(select_header[:add_btn],true)
                    gtk_set_sensitive(select_header[:fav_btn],false)
                    gtk_set_visible(select_header[:fav_btn],!VC365::UI.page.favorites?)
                    gtk_button_set_icon(select_header[:select_all],"unselect-all-symbolic")
                    Header.state=VC365::UI.page
                    selection_modeX(true)
                end}
            )
            g_signal(default_header[:del_plmode],"clicked",
                ->{Xlib.call do
                    gtk_set_sensitive(select_header[:del_btn],false)
                    @@mode=Mode::Delete
                    selection_modeX(true)
                    add_mode(false)
                end}
            )
            g_signal(default_header[:back_btn],"clicked",->{Playlist.set_plist(false)})

            ## Select Header
            g_signal(select_header[:select_all],"clicked",
                ->(btn : VC365::GtkElement){Xlib.call do
                    selected_rows.clear if selected_rows.size < List.current_list.size
                    gtk_button_set_icon(btn,if selected_rows.size == List.current_list.size || select_all
                        @@select_all=false
                        gtk_list_box_unselect_all(VC365::UI.page.glist)
                        selected_rows.clear
                        "unselect-all-symbolic"
                    else
                        if search_mode
                            @@select_all=true
                            gtk_listbox_run_filter(VC365::UI.page.glist)
                        else
                            gtk_list_box_select_all(VC365::UI.page.glist)
                            @@selected_rows=List.current_list.map_with_index do |val,i|
                                gtk_get_row_at_index(VC365::UI.page.glist,i)
                            end
                        end
                        "select-all-symbolic"
                    end)
                    gtk_label_set_text(select_header[:select_count],
                        "#{selected_rows.size} #{String.new(gettext("Selected"))}")
                    case mode
                    when .all?
                        gtk_set_sensitive(select_header[:del_btn],!selected_rows.size.zero?)
                        gtk_set_sensitive(select_header[:fav_btn],!selected_rows.size.zero?)
                        gtk_set_sensitive(select_header[:add_btn],
                            !selected_rows.size.zero? && !List.playlists.empty?)
                    when .add?
                        gtk_set_sensitive(select_header[:add_btn],!selected_rows.size.zero?)
                    when .delete?
                        gtk_set_sensitive(select_header[:del_btn],!selected_rows.size.zero?)
                    end
                end}
            )
            g_signal(select_header[:cancel_btn],"clicked",
                ->{Xlib.call do
                    selection_modeX(false)
                    gtk_label_set_text(select_header[:select_count],"0 #{String.new(gettext("Selected"))}")
                    selected_rows.clear
                    add_rows.clear
                    Playlist.set_plist(true) if state.pl_page? if @@state
                end}
            )
            g_signal(select_header[:del_btn],"clicked",
                ->{Xlib.call do
                    selection_modeX(false)
                    unless selected_rows.size==List.current_list.size
                        next_song=selected_rows.map do |row|
                            uri=String.new(gtk_get_name(row.as(VC365::GtkElement)))
                            VC365::UI.page.home? ? List.data.delete_at(List.data_indexU!(uri))
                                : List.current_list.delete(uri)
                            gtk_list_box_remove(VC365::UI.page.glist,row)
                            uri
                        end.index(Player.current_song[:uri]).nil?
                        if !next_song && List.focused==VC365::UI.page
                            Player.current=-100
                            Player.play(List.data[Player.index][:uri])
                        end
                        Settings.reload_lists(ign_root: true) if VC365::UI.page.home?
                    else
                        List.current_list.clear
                        VC365::UI.page.home? ? Settings.reload_lists(prevent_default: true)
                        : gtk_list_remove_all(VC365::UI.page.glist)
                        if List.focused==VC365::UI.page
                            Player.pause_play if Player.state.playing?
                            List.focused=VCMusic::Page::Home
                        end
                        VC365::UI.update_placeholder
                    end
                    gtk_label_set_text(select_header[:select_count],"0 #{String.new(gettext("Selected"))}")
                    gtk_label_set_text(Playlist.plpage[:count],
                        "#{String.new(gettext("Songs"))} #{List.playlists[String.new(
                            gtk_get_name(Playlist.plpage[:list].as(VC365::GtkElement)))].size}"
                    ) if VC365::UI.page.pl_page?
                    Storage.update_data(VC365::UI.page)
                    gtk_set_sensitive(default_header[:del_plmode],false) if List.playlists.empty?
                    VC365::UI.update_counter
                    selected_rows.clear
                end}
            )
            g_signal(select_header[:fav_btn],"clicked",
                ->{Xlib.call do
                    selection_modeX(false)
                    selected_rows.each do |row|
                        add_rows.unshift(String.new(gtk_get_name(row.as(VC365::GtkElement))))
                    end
                    @@add_rows-=List.favorite
                    add_rows.each do |uri|
                        List.favorite.unshift(uri)
                        VC365::UI.init_list(VC365::UI.lists[:favorite],uri,false)
                    end
                    add_rows.clear
                    selected_rows.clear
                    gtk_label_set_text(select_header[:select_count],"0 #{String.new(gettext("Selected"))}")
                    Storage.update_data(:favorites,List.favorite)
                end}
            )
            g_signal(select_header[:add_btn],"clicked",
                ->{Xlib.call do
                    selection_modeX(false)
                    if add_rows.empty?
                        selected_rows.each do |row|
                            add_rows.unshift(String.new(gtk_get_name(row.as(VC365::GtkElement))))
                        end
                        selected_rows.clear
                        gtk_label_set_text(select_header[:select_count],"0 #{String.new(gettext("Selected"))}")
                        @@mode=Mode::Add
                        gtk_set_sensitive(select_header[:add_btn],false)
                        add_mode(true)
                        VC365::UI.page.pl_page? ? Playlist.set_plist(false)
                            : view_stack_set_vischild_name(VC365::UI.main_stack,"playlist")
                        selection_modeX(true)
                    else
                        selected_rows.each do |row|
                            name=String.new(gtk_get_name(row.as(VC365::GtkElement)))
                            List.playlists[name]=add_rows | List.playlists[name]
                            Playlist.update_count(row,List.playlists[name].size)
                        end
                        Storage.update_data(:playlists,List.playlists)
                        selected_rows.clear
                        add_rows.clear
                        gtk_label_set_text(select_header[:select_count],"0 #{String.new(gettext("Selected"))}")
                        state.pl_page? ? Playlist.set_plist(true)
                            : view_stack_set_vischild_name(VC365::UI.main_stack,state.to_s.downcase)
                    end
                end}
            )

            ## Search Header
            g_signal(search_header[:back_btn],"clicked",
                ->{Xlib.call do
                    gtk_app_accels_action(g_application_get_default, "app.play_song",
                        ["space".to_unsafe, Pointer(UInt8).null])
                    gtk_set_visible(search_header[:root],@@search_mode=false)
                    gtk_listbox_run_filter(VC365::UI.page.glist)
                    gtk_set_visible(default_header[:root],!search_mode)
                end}
            )
            g_signal(search_header[:select_mode],"clicked",
                ->{Xlib.call do
                    @@mode=Mode::All
                    gtk_set_sensitive(select_header[:del_btn],false)
                    gtk_set_visible(select_header[:del_btn],true)
                    gtk_set_sensitive(select_header[:add_btn],false)
                    gtk_set_visible(select_header[:add_btn],true)
                    gtk_set_sensitive(select_header[:fav_btn],false)
                    gtk_set_visible(select_header[:fav_btn],!VC365::UI.page.favorites?)
                    gtk_button_set_icon(select_header[:select_all],"unselect-all-symbolic")
                    Header.state=VC365::UI.page
                    selection_modeX(true)
                end}
            )
            g_signal(search_header[:search_input],"search-changed",
                ->{Xlib.call do
                    @@search_values={sv: sv=String.new(gtk_editable_get_text(search_header[:search_input])).downcase,
                        sv_tokens: sv.gsub(/[!"#$%&'()*+,\-\.\/:;<=>?@\[\\\]^_`{|}~]+/," ").split.uniq # X"
                    }
                    gtk_listbox_run_filter(VC365::UI.page.glist)
                end}
            )
            g_signal(search_header[:search_input],"activate",
                ->{Xlib.call do
                    @@search_values={sv: sv=String.new(gtk_editable_get_text(search_header[:search_input])).downcase,
                        sv_tokens: sv.gsub(/[!"#$%&'()*+,\-\.\/:;<=>?@\[\\\]^_`{|}~]+/," ").split.uniq # X"
                    }
                    gtk_listbox_run_filter(VC365::UI.page.glist)
                end}
            )
        end
    end
    def self.add_mode(b : Bool)
        Xlib.call do
            gtk_set_visible(select_header[:del_btn],!b)
            gtk_set_visible(select_header[:fav_btn],!b)
            gtk_set_visible(select_header[:add_btn],b)
        end
    end
    def self.tool_bar(select_mode=!List.current_list.empty?)
        Xlib.call do
            gtk_set_visible(default_header[:back_btn],VC365::UI.page.pl_page?)
            gtk_set_visible(default_header[:del_plmode],VC365::UI.page.playlist?)
            gtk_set_visible(default_header[:create_btn],VC365::UI.page.playlist?)
            gtk_set_visible(default_header[:add_btn],!VC365::UI.page.playlist?)
            gtk_set_sensitive(default_header[:add_btn],select_mode)
            gtk_set_visible(search_header[:select_mode],!VC365::UI.page.playlist?)
            gtk_set_sensitive(search_header[:select_mode],select_mode)
        end
    end
    def self.selection_modeX(@@selection_mode)
        unless selection_mode
            @@mode=Mode::None
            @@select_all=false
        end
        Xlib.call do
            gtk_set_visible(select_header[:root],selection_mode)
            search_mode ? gtk_set_visible(search_header[:root],!selection_mode)
            : gtk_set_visible(default_header[:root],!selection_mode)
            gtk_list_selection_mode(VC365::UI.page.glist,
                selection_mode ? VC365::GSMode::Multi : VC365::GSMode::None)
        end
    end
    def self.select_mode(row : VC365::GRList,list : VC365::GtkList)
        Xlib.call do
            unless selected_rows.index(row)
                selected_rows.push(row)
            else
                gtk_list_unselect_row(list,row)
                selected_rows.delete(row)
            end
            gtk_button_set_icon(select_header[:select_all],
                %Q(#{selected_rows.size != List.current_list.size ? "un" : ""}select-all-symbolic))
            gtk_label_set_text(select_header[:select_count],"#{selected_rows.size} #{String.new(gettext("Selected"))}")
            srempty=selected_rows.empty?
            case mode
            when .all?
                gtk_set_sensitive(select_header[:del_btn],!srempty)
                gtk_set_sensitive(select_header[:fav_btn],!srempty)
                gtk_set_sensitive(select_header[:add_btn],!(srempty || List.playlists.empty?))
            when .add?
                gtk_set_sensitive(select_header[:add_btn],!srempty)
            when .delete?
                gtk_set_sensitive(select_header[:del_btn],!srempty)
            end
        end
    end
end