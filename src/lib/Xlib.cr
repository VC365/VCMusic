{% if flag?(:windows) %}
    Linux=false
    @[Link("gstpbutils-1.0")]
{% else %}
    Linux=true
    @[Link("gstreamer-pbutils-1.0")]
{% end %}
@[Link("gstreamer-1.0")]
@[Link("adwaita-1")]
@[Link("gio-2.0")]
@[Link("gtk-4")]
@[Link("cairo")]
#@[Link("notify")]

lib VC365
    Version="0.1.0"
    # Types
    alias GSourceFunc = Pointer(Void) -> Bool
    #type NotifyNotification = Void*
    type GObject=Void*
    type GFunc=Void*
    type GType=Void*
    type GstElement=GObject
    type GError=Void*
    type Discoverer=GObject
    type DisInfo=Void*
    type AudioInfo=Void*
    type GTList=Void*
    type WidgetClass=Void*
    type AApp=Void*
    type GApp=Void*
    type AAWindow=Void*
    type ASManager=Void*
    type GtkBuilder=Void*
    type GResource = Void*
    type GVType = Void*
    type GSAction = GObject
    type GSAGroup = GObject
    type GAMap = GObject
    type GtkElement=GObject
    type GRList=GObject
    type GtkList=GObject
    type CarioC = Void*
    type CarioS = Void*
    type GtkTheme = Void*
    type GtkG = Void*
    type GFDialog = Void*
    type GLModel = Void*
    type GBytes = Void*
    type DBusNI = Void*
    type DBusConnection = Void*
    type DBusII = Void*
    type GstBus = Void*
    type GstStr = Void*
    type GValue = Void*

    # Enums
    enum GstState
        Pending
        Null
        Ready
        Paused
        Playing
    end
    enum DisResult
        Ok
        Uri_invalid
        Error
        Timeout
        Busy
        Missing_plugins
    end
    enum PEMode
        NONE = 0
        START = 1
        MIDDLE = 2
        END = 3
    end
    enum GstFormat
        Undefined  =  0
        Default    =  1
        Bytes      =  2
        Time       =  3
        Buffers    =  4
        Percent    =  5
    end
    enum GSMode
        None
        Single
        Browes
        Multi
    end
    enum GSFlags
        None = 0
        Flush = 1
        Accurate = 2
        KeyUnit = 4
        TrickMode = 16
        NEAREST = 96
    end
    enum ASType
        Default= 0
        Light  = 1
        Dark   = 4
    end
    enum GdkEventType : Int32
        NOTHING = -1
        DELETE = 0
        DESTROY = 1
        EXPOSE = 2
        MOTION_NOTIFY = 3
        BUTTON_PRESS = 4
        BUTTON_RELEASE = 5
        SCROLL = 31
    end
    enum GstPFlags
        All              = 0x00001FFF
        Video            = 0x00000001
        Audio            = 0x00000002
        Text             = 0x00000004
        Vis              = 0x00000008
        SoftVolume       = 0x00000010
        NativeAudio      = 0x00000020
        NativeVideo      = 0x00000040
        Download         = 0x00000080
        Buffering        = 0x00000100
        Deinterlace      = 0x00000200
        SoftColorbalance = 0x00000400
        ForceFilters     = 0x00000800
        ForceSwDecoders  = 0x00001000
    end
    enum LC
        CTYPE
        NUMERIC
        TIME
        COLLATE
        MONETARY
        MESSAGES
        ALL
        PAPER
        NAME
        ADDRESS
        TELEPHONE
        MEASUREMENT
        IDENTIFICATION
    end

    # Struct
    struct GList
        data : Void*
    end
    struct DBusIVT
        method_call  : GFunc
        get_property : GFunc
        set_property : Void*
    end
    struct GstMiniObject
        type : UInt64
        refcount : Int32
        lockstate : Int32
        flags : UInt32
        copy : Void*
        dispose : Void*
        free : Void*
        n_qdata : UInt32
        qdata : Void*
    end
    struct GstMsg
        mini_object : GstMiniObject
        type : UInt32
        timestamp : UInt64
        src : Void*
        seqnum : UInt32
    end
    struct GVArray
      n_values : UInt32
      values   : GValue*
    end

    # C
    fun setlocale(category : LC, locale : UInt8*) : UInt8*
    fun bindtextdomain(domainname : UInt8*, dirname : UInt8*) : UInt8*
    fun bind_textdomain_codeset(domainname : UInt8*, codeset : UInt8*) : UInt8*
    fun textdomain(domainname : UInt8*) : UInt8*
    fun gettext(msgid : UInt8*) : UInt8*

    # GObject
    fun set_prop=g_object_set(obj : GObject,fprop : UInt8*, ...)
    fun get_prop=g_object_get(obj : GObject,fprop : UInt8*, ...)
    fun g_object_unref(obj : GObject)
    fun set_data=g_object_set_data(obj : GObject,name : UInt8*,data : Void*)
    fun get_data=g_object_get_data(obj : GObject,name : UInt8*) : Void*
    fun g_signal_connect=g_signal_connect_data(obj : GObject,signal : UInt8*,gfunc : GFunc,gpointer : Void*,gcn : Void*,cflags : Int32)
    fun g_value_get_boxed(gv : GValue) : GVArray*
    fun g_value_array_get_nth(gva : GVArray*,index : Int32) : GValue
    fun g_value_get_double(gv : GValue) : Float64

    # GLib
    fun g_bytes_new_static(bytes : UInt8*,len : Int64) : GBytes
    fun g_free(dood : Void*)

    # Notify
    #fun notify_init(app_name : UInt8*)
    #fun notify_uninit()
    #fun notify_new=notify_notification_new(summray : UInt8*,msg : UInt8*,icon : UInt8*) : NotifyNotification
    #fun notify_timeout=notify_notification_set_timeout(summray : NotifyNotification,timeout : Int32)
    #fun notify_show=notify_notification_show(notification : NotifyNotification,gerror : Void*)
    #fun notify_close=notify_notification_close(notification : NotifyNotification,gerror : Void*)
    #fun notify_update=notify_notification_update(notification : NotifyNotification,summray : UInt8*,msg : UInt8*,icon : UInt8*)

    # GStreamer
    fun gst_init(argc : Void* ,argv : Void*)
    fun gst_deinit
    fun make_element=gst_element_factory_make(fac : UInt8*,name : Void*) : GstElement
    fun find_element=gst_element_factory_find(fac : UInt8*) : GstElement
    fun set_state=gst_element_set_state(element : GstElement,state : GstState)
    fun get_state=gst_element_get_state(element : GstElement) : GstState
    fun gst_get_time=gst_element_query_position(element : GstElement,formatX : GstFormat,cur : Int64*) : Bool
    fun gst_get_duration=gst_element_query_duration(element : GstElement,formatX : GstFormat,cur : Int64*) : Bool
    fun gst_ele_seek=gst_element_seek_simple(element : GstElement,formatX : GstFormat,flags : GSFlags,cur : Int64)
    fun gst_object_unref(element : GstElement)
    fun gst_object_ref(element : GstElement) : GstElement
    fun discover_new=gst_discoverer_new(timeout : UInt64,gerror : GError) : Discoverer
    fun discover_sync=gst_discoverer_discover_uri(dis : Discoverer,uri : UInt8*) : DisInfo
    fun info_result=gst_discoverer_info_get_result(info : DisInfo) : DisResult
    fun info_duration=gst_discoverer_info_get_duration(info : DisInfo) : UInt64
    fun gst_get_bus=gst_element_get_bus(element : GstElement) : GstBus
    fun gst_bus_add_signal_watch(gb : GstBus)
    fun gst_msg_parse_state_changed=gst_message_parse_state_changed(message : GstMsg*,oldstate : GstState*,newstate : GstState*,pending : GstState*)
    fun gst_msg_get_str=gst_message_get_structure(message : GstMsg*) : GstStr
    fun gst_str_has_name=gst_structure_has_name(gs : GstStr,str : UInt8*) : Bool
    fun gst_str_get_value=gst_structure_get_value(gs : GstStr,val : UInt8*) : GValue
    fun gst_bin_add(bin : GstElement,ele : GstElement)
    fun gst_bin_new(name : UInt8*) : GstElement
    fun gst_bin_remove(bin : GstElement,ele : GstElement)
    fun gst_ele_unlink=gst_element_unlink(src_ele : GstElement,sink_ele : GstElement)
    fun gst_ele_link=gst_element_link(src_ele : GstElement,sink_ele : GstElement)
    fun gst_ele_get_static_pad=gst_element_get_static_pad(ele : GstElement,pad : UInt8*) : Void*
    fun gst_ele_remove_pad=gst_element_remove_pad(ele : GstElement,pad : Void*)
    fun gst_ghost_pad_new(name : UInt8*,pad : Void*) : Void*
    fun gst_ele_add_pad=gst_element_add_pad(ele : GstElement,pad : Void*)
    fun gst_ele_sync_state_with_parent=gst_element_sync_state_with_parent(ele : GstElement)

    ##    !!
    # fun discover_audio_new=gst_discoverer_info_get_audio_streams(info : DisInfo) : GList
    # fun audio_channels=gst_discoverer_audio_info_get_channels(ai : AudioInfo) : Int32
    # fun audio_sample_rate=gst_discoverer_audio_info_get_sample_rate(ai : AudioInfo) : Int32
    # fun taglist_new=gst_discoverer_info_get_tags(info : DisInfo) : GTList
    # fun taglist_get=gst_tag_list_get_string(list : GTList , name : UInt8* , point : UInt8**) : Bool
    #   🐌!!

    # Libadwaita
    fun aapp_new=adw_application_new(id : UInt8*, flags : UInt32) : AApp
    fun adw_show_about_dialog(parent : AAWindow, first_property_name : UInt8*, ...)
    fun avatar_set_text=adw_avatar_set_text(ele : GtkElement , val : UInt8*)
    fun avatar_set_icon=adw_avatar_set_icon_name(ele : GtkElement , icon : UInt8*)
    fun avatar_set_size=adw_avatar_set_size(ele : GtkElement , size : Int32)
    fun adw_dialog_present(dialog : GtkElement, parent : AAWindow)
    fun adw_dialog_close(dialog : GtkElement)
    fun view_stack_vischild_name=adw_view_stack_get_visible_child_name(ele : GtkElement) : UInt8*
    fun view_stack_set_vischild_name=adw_view_stack_set_visible_child_name(list : GtkElement,name : UInt8*)
    fun view_stack_page=adw_view_stack_get_page(list : GtkElement,listX : GtkElement) : GtkElement
    fun view_stack_vischild=adw_view_stack_get_visible_child(list : GtkElement) : GtkElement
    fun view_stack_child_by_name=adw_view_stack_get_child_by_name(list : GtkElement,name : UInt8*) : GtkElement
    fun view_stack_page_set_badge_number=adw_view_stack_page_set_badge_number(ele : GtkElement,n : Int32)
    fun abs_set_open=adw_bottom_sheet_set_open(abs : GtkElement,op : Bool)
    fun abs_get_open=adw_bottom_sheet_get_open(abs : GtkElement) : Bool
    fun adw_dialog_set_title(ele : GtkElement , val : UInt8*)
    fun asmanager_get_default=adw_style_manager_get_default : ASManager
    fun asmanager_get_dark=adw_style_manager_get_dark(asmanager : ASManager) : Bool
    fun asmanager_supports_color_schemes=adw_style_manager_get_system_supports_color_schemes(asmanager : ASManager) : Bool
    fun asmanager_set_color_scheme=adw_style_manager_set_color_scheme(asmanager : ASManager,acs : ASType)
    fun adw_add_toast=adw_toast_overlay_add_toast(ato : GtkElement,toast : GtkElement)
    fun adw_toast_new(title : UInt8*) : GtkElement
    fun adw_toast_set_timeout(toast : GtkElement,timeout : Int32)
    fun adw_toast_set_use_markup(toast : GtkElement,is : Bool)
    fun adw_toast_cancel_all=adw_toast_overlay_dismiss_all(toast : GtkElement,is : Bool)
    fun asr_get_active=adw_switch_row_get_active(asr : GtkElement) : Bool
    fun asr_set_active=adw_switch_row_set_active(asr : GtkElement,active : Bool)
    fun atg_set_acname=adw_toggle_group_set_active_name(atg : GtkElement,acname : UInt8*)
    fun atg_get_acname=adw_toggle_group_get_active_name(atg : GtkElement) : UInt8*
    fun aspr_set_value=adw_spin_row_set_value(aspr : GtkElement,val : Int32)
    fun aspr_get_value=adw_spin_row_get_value(aspr : GtkElement) : Int32
    fun aer_get_active=adw_expander_row_get_enable_expansion(aer : GtkElement) : Bool
    fun aer_set_active=adw_expander_row_set_enable_expansion(aer : GtkElement,active : Bool)
    fun adw_sp_new=adw_status_page_new : GtkElement
    fun adw_sp_description=adw_status_page_set_description(asp : GtkElement,des : UInt8*)
    fun adw_sp_icon=adw_status_page_set_icon_name(asp : GtkElement,icon : UInt8*)
    fun adw_sp_title=adw_status_page_set_title(asp : GtkElement,title : UInt8*)

    # GDK
    fun gdk_display_get_default() : Void*
    fun gdk_cairo_create(surface : Void*) : CarioC

    # GTK4
    fun gtk_window_set_default_icon_name(icon : UInt8*)
    fun gtk_window_present(window : AAWindow)
    fun gtk_widget_hide(ele : GtkElement)
    fun gtk_resource=gtk_builder_new_from_resource(path : UInt8*) : GtkBuilder
    fun gtk_get_object=gtk_builder_get_object(builder : GtkBuilder, name : UInt8*) : GObject
    fun gtk_application_add_window(app : GApp,window : AAWindow)
    fun gtk_app_accels_action=gtk_application_set_accels_for_action(application : GApp, name : UInt8*, accels : UInt8**)
    fun gtk_label_set_text(ele : GtkElement , val : UInt8*)
    fun gtk_label_get_text(ele : GtkElement) : UInt8*
    fun gtk_button_set_label(ele : GtkElement , val : UInt8*)
    fun gtk_button_set_icon=gtk_button_set_icon_name(ele : GtkElement , val : UInt8*)
    fun gtk_button_get_icon=gtk_button_get_icon_name(ele : GtkElement) : UInt8*
    fun gtk_button_get_child(ele : GtkElement) : GtkElement
    fun gtk_list_box_append(list : GtkList,row : GRList)
    fun gtk_list_box_prepend(list : GtkList,row : GRList)
    fun gtk_label_set_ellipsize(label : GtkElement, mode : PEMode) : Nil
    fun gtk_scale_button_set_value(ele : GtkElement,value : Float64)
    fun gtk_drawing_area_set_draw_func(area : GtkElement, func : GFunc, data : Void*, destroy : Void*)
    fun gtk_snapshot_append_cairo(snapshot : Void*) : CarioC
    fun gtk_widget_queue_draw(widget : GtkElement)
    fun gtk_adj_set_value=gtk_adjustment_set_value(ele : GtkElement,adj : Float64)
    fun gtk_adj_get_value=gtk_adjustment_get_value(ele : GtkElement) : Float64
    fun gtk_adj_upper=gtk_adjustment_set_upper(ele : GtkElement,adj : Float64)
    fun gtk_adj_get_upper=gtk_adjustment_get_upper(ele : GtkElement) : Float64
    fun gtk_theme=gtk_icon_theme_get_for_display(display : Void*) : GtkTheme
    fun gtk_theme_add=gtk_icon_theme_add_resource_path(theme : GtkTheme, path : UInt8*)
    fun gtk_get_row_at_index=gtk_list_box_get_row_at_index(list : GtkList,index : Int32) : GRList
    fun gtk_get_parent=gtk_widget_get_parent(ele : GtkElement) : GtkElement
    fun gtk_list_box_remove(list : GtkList,ele : GRList)
    fun gtk_set_name=gtk_widget_set_name(ele : GtkElement,name : UInt8*)
    fun gtk_get_name=gtk_widget_get_name(ele : GtkElement) : UInt8*
    fun gtk_row_get_child=gtk_list_box_row_get_child(row : GRList) : GtkElement
    fun gtk_first_child=gtk_widget_get_first_child(ele : GtkElement) : GtkElement
    fun gtk_last_child=gtk_widget_get_last_child(ele : GtkElement) : GtkElement
    fun gtk_cbox_end_widget=gtk_center_box_get_end_widget(ele : GtkElement) : GtkElement
    fun gtk_set_visible=gtk_widget_set_visible(ele : GtkElement,visible : Bool)
    fun gtk_menu_set_model=gtk_menu_button_set_menu_model(menu : GtkElement,model : GtkElement)
    fun gtk_editable_get_text(ele : GtkElement) : UInt8*
    fun gtk_set_sensitive=gtk_widget_set_sensitive(ele : GtkElement,sen : Bool)
    fun gtk_menu_set_popover=gtk_menu_button_set_popover(menu : GtkElement,popover : GtkElement)
    fun gtk_list_selection_mode=gtk_list_box_set_selection_mode(list : GtkList,mode : GSMode)
    fun gtk_row_is_selected=gtk_list_box_row_is_selected(row : GRList) : Bool
    fun gtk_list_select_row=gtk_list_box_select_row(list : GtkList,ele : GRList)
    fun gtk_list_unselect_row=gtk_list_box_unselect_row(list : GtkList,ele : GRList)
    fun gtk_list_remove_all=gtk_list_box_remove_all(list : GtkList)
    fun gtk_stack_set_vischild_name=gtk_stack_set_visible_child_name(list : GtkElement,name : UInt8*)
    fun gtk_widget_focus=gtk_widget_grab_focus(ele : GtkElement)
    fun gtk_menu_get_popover=gtk_menu_button_get_popover(menu : GtkElement) : GtkElement
    fun gtk_menu_set_icon=gtk_menu_button_set_icon_name(menu : GtkElement,name : UInt8*)
    fun gtk_pmenu_add_child=gtk_popover_menu_add_child(menup : GtkElement , child : GtkElement , id : UInt8*)
    fun gtk_set_tooltip_text=gtk_widget_set_tooltip_text(ele : GtkElement , txt : UInt8*)
    fun gtk_add_classname=gtk_widget_add_css_class(ele : GtkElement , classname : UInt8*)
    fun gtk_del_classname=gtk_widget_remove_css_class(ele : GtkElement , classname : UInt8*)
    fun gtk_cbutton_set_active=gtk_check_button_set_active(ele : GtkElement , set : Bool)
    fun gtk_image_set_icon=gtk_image_set_from_icon_name(ele : GtkElement , name : UInt8*)
    fun gtk_file_dialog_new() : GFDialog
    fun gtk_file_dialog_set_title(gfd : GFDialog , name : UInt8*)
    fun gtk_file_select_folders_init=gtk_file_dialog_select_multiple_folders(gfd : GFDialog,win : AAWindow,gcancel : Void*,func : GFunc,n : Void*)
    fun gtk_file_select_folders_finish=gtk_file_dialog_select_multiple_folders_finish(gfd : GFDialog,n : Void*) : GLModel
    fun gtk_list_box_get_adjustment(ele : GtkList) : GtkElement
    fun gtk_widget_get_height(ele : GtkElement) : Int32
    fun gtk_list_box_set_placeholder(list : GtkList,ele : GtkElement)
    fun gtk_list_box_select_all(list : GtkList)
    fun gtk_list_box_unselect_all=gtk_list_box_unselect_all(list : GtkList)
    fun gtk_get_ancestor=gtk_widget_get_ancestor(ele : GtkElement,type : GType) : GtkElement
    fun gtk_list_row_type=gtk_list_box_row_get_type : GType
    fun gtk_add_tick_callback=gtk_widget_add_tick_callback(ele : GtkElement,callback : GFunc,user_data : Void*,gdn : Void*) : UInt32
    fun gtk_remove_tick_callback=gtk_widget_remove_tick_callback(ele : GtkElement,id : UInt32)
    fun gtk_set_margin_top=gtk_widget_set_margin_top(ele : GtkElement,val : Int32)
    fun gtk_set_margin_bottom=gtk_widget_set_margin_bottom(ele : GtkElement,val : Int32)
    fun gtk_box_set_spacing(ele : GtkElement,val : Int32)
    fun gtk_widget_unparent(ele : GtkElement)
    fun gtk_listbox_run_filter=gtk_list_box_invalidate_filter(list : GtkList)
    fun gtk_listbox_set_filter_func=gtk_list_box_set_filter_func(list : GtkList,func : GFunc,data : Void*,gdn : Void*)

    # Gio
    fun g_resource_new_from_data(dood : GBytes, error : Void*) : GResource
    fun g_resource_load(path : UInt8*, error : Void*) : GResource
    fun g_variant_to_i32=g_variant_get_int32(gvt : GVType) : Int32
    fun g_variant_type_new(name : UInt8*) : GVType
    fun ui_run=g_application_run(app : AApp, argc : Void*, argv : Void*) : Int32
    fun g_resources_register(resource : GResource)
    fun g_action_new=g_simple_action_new(name : UInt8*, parameter_type : Void*) : GSAction
    fun g_actgroup_new=g_simple_action_group_new() : GSAGroup
    fun g_action_map_add_action(action_map : GSAGroup, action : GSAction)
    fun g_action_enable=g_simple_action_set_enabled(action : GSAction,enable : Bool)
    fun g_application_quit(app : AApp)
    fun g_timeout_add(interval : UInt32,func : GSourceFunc,data : Void*)
    fun g_idle_add(func : GFunc, data : Void*)
    fun g_list_model_count=g_list_model_get_n_items(glm : GLModel) : Int32
    fun g_list_model_get_item(glm : GLModel,index : Int32) : Void*
    fun g_file_get_name=g_file_get_parse_name(ele : Void*) : UInt8*
    fun dbus_own_name=g_bus_own_name(dbtype : Int32,name : UInt8*,flags : Int32,dbacquired_handler : GFunc,
        na_handler : Void*,nl_handler : Void*,user_data : Void*,gdnfunc : Void*) : UInt32
    fun dbus_connection_register=g_dbus_connection_register_object(dbc : DBusConnection,name : UInt8*,dbii : DBusII,
        vtable : DBusIVT*,user_data : Void*,gdnfunc : Void*,gerror : Void*) : UInt32
    fun dbus_ni_new=g_dbus_node_info_new_for_xml(xml : UInt8*,gerror : Void*) : DBusNI
    fun dbus_ni_get_interface=g_dbus_node_info_lookup_interface(dbni : DBusNI,name : UInt8*) : DBusII
    fun g_variant_new_boolean(bool : Bool) : Void*
    fun g_variant_new_string(st : UInt8*) : Void*
    fun g_application_get_default : GApp
    fun g_application_get_appid=g_application_get_application_id(app : GApp) : UInt8*

    # Cario
    fun cairo_arc(ctx : CarioC, xc : Float64, yc : Float64, radius : Float64, angle1 : Float64, angle2 : Float64)
    fun cairo_arc_negative(ctx : CarioC, xc : Float64, yc : Float64, radius : Float64, angle1 : Float64, angle2 : Float64)
    fun cairo_set_source_rgba(ctx : CarioC, r : Float64, g : Float64, b : Float64, a : Float64)
    fun cairo_set_line_width(ctx : CarioC, width : Float64)
    fun cairo_stroke(ctx : CarioC)
    fun cairo_move_to(ctx : CarioC, x : Float64, y : Float64)
    fun cairo_line_to(ctx : CarioC, x : Float64, y : Float64)
    fun cairo_close_path(ctx : CarioC)
    fun cairo_set_operator(ctx : CarioC,op : Int32)
    fun cairo_paint(ctx : CarioC)
end

module Tools
    def to_clock(val : Float64)
        m,s = (val//60).to_i.to_s+":",(val%60).to_i
        m + (s < 10 ? "0#{s}" : s.to_s)
    end
    def g_signal(ele : _,sig : String, block : Proc,data : _=nil,swapped=false)
        VC365.g_signal_connect(ele.as(VC365::GObject),sig,block.pointer.as(VC365::GFunc),
            data.as(Pointer(Void)),nil,swapped.to_unsafe * 2)
    end
    def get_element(name : String,builder=VC365::UI.builder) : VC365::GtkElement
        VC365.gtk_get_object(builder, name).as(VC365::GtkElement)
    end
end

module Xlib
    extend Tools
    # Maybe I will package it
    class_getter requests=[] of {group: String,id: Int64}
    private Concurrent=Fiber::ExecutionContext::Concurrent.new("VCT")
    def self.last_req(timeout : Time::Span,group : String,&b)
        random={group: group,id: rand(0_i64..Int64::MAX)}
        @@requests << random
        Concurrent.spawn do
            sleep timeout
            if requests.size-1 == requests.index(random)
                requests.reject! {|i| i[:group]==group}
                b.call
            end
        end
    end

    {% for m in VC365.methods %}
        def self.{{ m.name }}(*args)
            VC365.{{ m.name }}(*args)
        end
    {% end %}

    def self.call(&)
        with self yield
    end
end
