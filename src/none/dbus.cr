enum XDXD
    DDD
end
module DBus
    XML = <<-XMLX
    <node>
        <interface name="org.mpris.MediaPlayer2">
          <property name="CanQuit" type="b" access="read"/>
          <property name="CanRaise" type="b" access="read"/>
          <property name="HasTrackList" type="b" access="read"/>
          <property name="Identity" type="s" access="read"/>
        </interface>

        <interface name="org.mpris.MediaPlayer2.Player">
          <method name="PlayPause"/>
          <method name="Play"/>
          <method name="Pause"/>
          <method name="Next"/>
          <method name="Previous"/>

          <property name="PlaybackStatus" type="s" access="read"/>
          <property name="CanControl" type="b" access="read"/>
          <property name="CanPlay" type="b" access="read"/>
          <property name="CanPause" type="b" access="read"/>
          <property name="CanGoNext" type="b" access="read"/>
          <property name="CanGoPrevious" type="b" access="read"/>
        </interface>
    </node>
    XMLX
    private def self.handler
        dbivt = Pointer(VC365::DBusIVT).malloc
        dbivt.value.method_call=->(_c : Void*,_s : Void*,_path : UInt8*,_i : UInt8*,method : UInt8*){
            case String.new(method)
            when "PlayPause","Play"
                Player.play(List.data[Player.index][:uri])
            when "Pause"
                Player.pause_play if Player.state.playing?
            when "Next"
                Player.next_song("next");VC365::UI.navigate
            when "Previous"
                Player.next_song("prev");VC365::UI.navigate
            end
        }.pointer.as(VC365::GFunc)
        dbivt.value.get_property =->(_c : Void*,_s : UInt8*,_path : UInt8*,_i : UInt8*,prop : UInt8*){
            case String.new(prop)
            when "PlaybackStatus"
                Xlib.g_variant_new_string(Player.state.to_s)
            when "CanControl","CanPlay","CanPause","CanGoNext","CanGoPrevious"
                Xlib.g_variant_new_boolean(!VC365::UI.prevent_default)
            end || Pointer(Void).null
        }.pointer.as(VC365::GFunc)
        dbivt.value.set_property = nil
        dbivt
    end
    def self.init
        Xlib.dbus_own_name(2,"org.mpris.MediaPlayer2.VCMusic",0,
            ->(dbc : VC365::DBusConnection){Xlib.call do
                dbus_connection_register(dbc,"/org/mpris/MediaPlayer2",
                    dbus_ni_get_interface(dbus_ni_new(XML,nil),"org.mpris.MediaPlayer2.Player"),
                    handler,nil,nil,nil
                )
            end}.pointer.as(VC365::GFunc),nil,nil,nil,nil
        )
    end
end