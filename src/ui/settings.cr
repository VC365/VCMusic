#handle SIGPWR nostop noprint pass
module Settings
    @@pdialog=uninitialized VC365::GtkElement
    @@gfdialog=uninitialized VC365::GFDialog
    @@style_mode=uninitialized VC365::ASType
    class_property need_reload=false
    def self.style_mode=(@@style_mode);end
    @@ts_values=uninitialized {style_manager: VC365::ASManager,follow: VC365::GtkElement,ts: VC365::GtkElement}
    class_getter! elements : {max_volume: VC365::GtkElement,
        rib: {e: VC365::GtkElement,icon_tray: VC365::GtkElement,kill_ui: VC365::GtkElement},
        load_mode: VC365::GtkElement,is_loading: VC365::GtkElement,
        visualizer: VC365::GtkElement,hz432: VC365::GtkElement,
        library: {add: VC365::GtkElement,reload: VC365::GtkElement,list: VC365::GtkElement}
    }
    class Values
        class_getter max_volume=3.0
        def self.max_volume=(@@max_volume);Storage.update_config("max_volume",@@max_volume);end
        class_property rib={:e => false,:icon_tray => false,:kill_ui => false}
        class_property load_mode="async"
        class_property is_loading=false
        class_property visualizer=false
        class_property hz432=false
        class_property dirs : Array(String)=["/home/VC365/موسیقی/Sonic.EXE"]
        def self.dirs_add(x : String)
            dood=@@dirs.size
                @@dirs |=[x];Storage.update_config("dirs",@@dirs.to_json,last_req: false)
            dood!=@@dirs.size
        end
    end
    private def self.style_modeX(@@style_mode)
        Storage.update_config("theme",@@style_mode.value)
        Xlib.call do
            gtk_cbutton_set_active(get_element("ts_follow"),@@style_mode.default?)
            gtk_cbutton_set_active(get_element("ts_light"),@@style_mode.light?)
            gtk_cbutton_set_active(get_element("ts_dark"),@@style_mode.dark?)
        end
    end
    private def self.menu(appX : VC365::GApp)
        Xlib.call do
            quit = g_action_new("quit", nil)
                g_signal(quit, "activate",->{Xlib.g_application_quit(VC365::UI.app)})
                g_action_map_add_action(appX.as(VC365::GSAGroup), quit)
            gtk_app_accels_action(appX, "app.quit", ["<primary>q".to_unsafe, Pointer(UInt8).null])

            about = g_action_new("about", nil)
            g_signal(about, "activate",
                ->{Xlib.call do
                    adw_show_about_dialog(VC365::UI.window,
                        "application-name", "VCMusic",
                        "application-icon", "ir.NonFree.VCMusic",
                        "developer-name", "VC365",
                        "artists", ["VC365".to_unsafe],
                        "designers", ["VC365".to_unsafe],
                        "version", VC365::Version,
                        "copyright", "© 2025 VC365",
                        "issue_url", "https://github.com/VC365/VCMusic/issues",
                        "translator_credits", gettext("translator-credits"),
                        "license_type",3,
                    nil)
                end}
            )
            g_action_map_add_action(appX.as(VC365::GSAGroup), about)

            gtk_pmenu_add_child(gtk_menu_get_popover(get_element("menu_primary")),get_element("themeselector"),
                "themeselector"
            )
            preferences = g_action_new("preferences", nil)
                g_signal(preferences, "activate",->{Xlib.adw_dialog_present(@@pdialog,VC365::UI.window)})
            g_action_map_add_action(appX.as(VC365::GSAGroup), preferences)

            cs = g_action_new("color-scheme", g_variant_type_new("i").as(Pointer(Void)))
                g_signal(cs, "activate", ->(act : Pointer(Void), param : VC365::GVType) {Xlib.call do
                    dood=VC365::ASType.new(g_variant_to_i32(param))
                    asmanager_set_color_scheme(@@ts_values[:style_manager],dood)
                    style_modeX(dood)
                end})
            g_action_map_add_action(appX.as(VC365::GSAGroup), cs)
        end
    end
    private def self.themeSelector
        Xlib.call do
            @@ts_values={style_manager: asmanager_get_default,follow: get_element("ts_follow"),
                ts: get_element("themeselector")
            }
            update_cssup=->{Xlib.call {b=asmanager_supports_color_schemes(@@ts_values[:style_manager])
                gtk_set_visible(@@ts_values[:follow],b)
                style_modeX(VC365::ASType::Default) if b
            }}
            update_dark=->{Xlib.call {style_modeX(if asmanager_get_dark(@@ts_values[:style_manager])
                gtk_add_classname(@@ts_values[:ts],"dark");VC365::ASType::Dark;else
                gtk_del_classname(@@ts_values[:ts],"dark");VC365::ASType::Light;end)
            }}
            g_signal(@@ts_values[:style_manager],"notify::dark",update_dark)
            g_signal(@@ts_values[:style_manager],"notify::system-supports-color-schemes",update_cssup)
            unless @@style_mode
                update_dark.call
                update_cssup.call
            else
                asmanager_set_color_scheme(@@ts_values[:style_manager],@@style_mode)
                style_modeX(@@style_mode)
            end
        end
    end
    private def self.library_list(address : String)
        Xlib.call do
            item_builder = gtk_resource("/ir/NonFree/VCMusic/ui/samples/AAR_settings.ui")
            row = get_element("row",item_builder)
            title = get_element("title",item_builder)
            state={ele: get_element("state",item_builder),exists: File.exists?(address)}
            name = Path[address].basename

            gtk_set_name(row,address)
            gtk_label_set_text(title, name)
            gtk_label_set_ellipsize(title, VC365::PEMode::END)
            gtk_label_set_text(get_element("subtitle",item_builder),address)
            gtk_add_classname(state[:ele],state[:exists] ? "blue_custom" : "destructive-action")
            gtk_set_tooltip_text(state[:ele],state[:exists] ? gettext("Folder exists") : gettext("Folder not found"))
            g_signal(get_element("del_src",item_builder),"clicked",
                ->(rowX : VC365::GtkElement){ Xlib.call do
                    val=String.new(gtk_get_name(rowX))
                    gtk_list_box_remove(elements[:library][:list].as(VC365::GtkList),rowX.as(VC365::GRList))
                    Values.dirs.delete(val);Storage.update_config("dirs",Values.dirs.to_json,last_req: false)

                    unless Values.dirs.empty?
                        List.data.reject! { |v| v[:info][:folder] == val}
                        Player.current=Player.index=List.data_indexU!(Player.current_song[:uri])
                        reload_lists
                    else
                        List.data.clear;Storage.update_data(:data,List.data)
                        Player.pause_play if Player.state.playing?
                        reload_lists(true)
                    end
                    VC365::UI.notify("#{val[0..50].strip}#{"..." if val.size-1>50}  deleted as list",3)
                end},row,
            true)
            gtk_list_box_prepend(elements[:library][:list].as(VC365::GtkList), row.as(VC365::GRList))
        end
    end
    private def self.set_values
        Xlib.call do
            aer_set_active(elements[:rib][:e],Values.rib[:e])
            asr_set_active(elements[:rib][:icon_tray],Values.rib[:icon_tray])
            asr_set_active(elements[:rib][:kill_ui],Values.rib[:kill_ui])
            atg_set_acname(elements[:load_mode],Values.load_mode)
            asr_set_active(elements[:is_loading],Values.is_loading)
            asr_set_active(elements[:visualizer],Values.visualizer)
            asr_set_active(elements[:hz432],Values.hz432)
            gtk_adj_set_value(elements[:max_volume],Values.max_volume*100)
            Values.dirs.each do |path|
                library_list(path)
            end
        end
    end
    private def self.get_values
        set_values
        Xlib.call do
            g_signal(elements[:rib][:e],"notify::enable-expansion",
                ->(e : VC365::GtkElement){val=Xlib.aer_get_active(e);Storage.update_config("rib",val)
                Values.rib[:e]=val})
            g_signal(elements[:rib][:icon_tray],"notify::active",
                ->(e : VC365::GtkElement){val=Xlib.asr_get_active(e);Storage.update_config("tray_icon",val)
                Values.rib[:icon_tray]=val})
            g_signal(elements[:rib][:kill_ui],"notify::active",
                ->(e : VC365::GtkElement){val=Xlib.asr_get_active(e);Storage.update_config("kill_ui",val)
                Values.rib[:kill_ui]=val})
            g_signal(elements[:is_loading],"notify::active",
                ->(e : VC365::GtkElement){val=Xlib.asr_get_active(e);Storage.update_config("is_loading",val)
                Values.is_loading=val})
            g_signal(elements[:hz432],"notify::active",
                ->(e : VC365::GtkElement){;Storage.update_config("hz432",Values.hz432=Xlib.asr_get_active(e))
                Player.audiofilter if Player.bin?})
            g_signal(elements[:visualizer],"notify::active",
                ->(e : VC365::GtkElement){Xlib.call do
                    Storage.update_config("visualizer",Values.visualizer=asr_get_active(e))
                    Player.audiofilter if Player.bin?
                    if Values.visualizer
                        VC365::UI.wave_tk=gtk_add_tick_callback(VC365::UI.upsheet[:wave_area],VC365::UI::WaveGFunc,
                            nil,nil)
                        avatar_set_size(VC365::UI.upsheet[:cover_art],225)
                        gtk_set_margin_top(VC365::UI.upsheet[:cover_art],28)
                        gtk_set_margin_bottom(VC365::UI.upsheet[:cover_art],28)
                        gtk_set_margin_top(VC365::UI.upsheet[:sheet_content],0)
                        gtk_box_set_spacing(VC365::UI.upsheet[:sheet_content],10)
                    else
                        gtk_remove_tick_callback(VC365::UI.upsheet[:wave_area],VC365::UI.wave_tk)
                        avatar_set_size(VC365::UI.upsheet[:cover_art],256)
                        gtk_set_margin_top(VC365::UI.upsheet[:cover_art],0)
                        gtk_set_margin_bottom(VC365::UI.upsheet[:cover_art],0)
                        gtk_set_margin_top(VC365::UI.upsheet[:sheet_content],18)
                        gtk_box_set_spacing(VC365::UI.upsheet[:sheet_content],12)
                    end
                end})
            g_signal(elements[:max_volume],"value-changed",
                ->(e : VC365::GtkElement){vol=Xlib.gtk_adj_get_value(e).clamp(50,1000)
                    Values.max_volume=vol/100;Xlib.gtk_adj_upper(VC365::UI.volume_adj,vol)})
            g_signal(elements[:load_mode],"notify::active",
                ->(e : VC365::GtkElement){val=String.new(Xlib.atg_get_acname(e))
                Storage.update_config("async_mode",val.includes?("async"));Values.load_mode= val})
        end
    end
    @@lock=false
    private def self.library
        Xlib.call do
            g_signal(elements[:library][:add],"clicked",
                ->{Xlib.call do
                    gtk_file_select_folders_init(@@gfdialog,VC365::UI.window,nil,
                        ->(src_obj : VC365::GObject,res : Pointer(Void)){Xlib.call do
                            data=gtk_file_select_folders_finish(@@gfdialog,res)
                            unless data.null?
                                dood=[] of String
                                g_list_model_count(data).times do |i|
                                    path=String.new(g_file_get_name(g_list_model_get_item(data,i)))
                                    if Values.dirs_add(path)
                                        library_list(path)
                                        dood << path
                                    end
                                end
                                reload(dood) unless dood.empty?
                            end
                        end}.pointer.as(VC365::GFunc),
                    nil) unless @@lock
                end}
            )
            g_signal(elements[:library][:reload],"clicked",->reload)
        end
    end
    def self.is_dark
        Xlib.asmanager_get_dark(@@ts_values[:style_manager])
    end
    def self.reload_lists(prevent_default=List.data.empty?,clear_lists=true,ign_root=false)
        VC365::UI.lists.each do |key,list|
            Xlib.gtk_list_remove_all(list) unless ign_root && key == :root
        end if clear_lists
        empty_list=List.data.map do |dood|
            VC365::UI.init_list(VC365::UI.lists[:root],dood[:uri],true)
        end.index(true).nil? unless ign_root
        List.playlists.each_key { |dood| Playlist.init_pl(dood) }
        List.favorite.each { |name| VC365::UI.init_list(VC365::UI.lists[:favorite],name,true) }
        List.recent.each { |name| VC365::UI.init_list(VC365::UI.lists[:recent],name,true) }
        Player.is_playing unless (Player.value_bar.zero? || prevent_default || List.focused.pl_page? || empty_list)
        VC365::UI.prevent_default(prevent_default || empty_list)
        @@lock=false
    end
    def self.reload(dood=Values.dirs)
        unless @@lock
            @@lock=true
            List.init(true,dood,callback:
                ->{
                    Player.current=Player.index=List.data_indexU!(Player.current_song[:uri])
                    Xlib.g_idle_add(->{reload_lists}.pointer.as(VC365::GFunc),nil)
                }
            )
        end
    end
    def self.init(appX : VC365::GApp)
        Xlib.call do
            @@gfdialog=gtk_file_dialog_new
            @@pdialog=get_element("settings")
            @@elements={max_volume: get_element("max_volume"),
                rib: {e: get_element("run_bg"),icon_tray: get_element("icon_tray"),
                kill_ui: get_element("kill_ui")},load_mode: get_element("load_mode"),
                is_loading: get_element("is_loading"),visualizer: get_element("visualizer"),
                hz432: get_element("hz432"),library: {add: get_element("add_src"),
                reload: get_element("reload_songs"),list: get_element("library_list")
            }}
            get_values
            menu(appX)
            themeSelector
            library
            adw_dialog_present(@@pdialog,VC365::UI.window) if List.data.empty?
        end
    end
end