require "./lib/Xlib"
require "./none/*"
require "./ui/*"

Storage.init
Storage.init_state unless List.data.empty?
Fiber::ExecutionContext::Isolated.new("GTK&GST") do
    Xlib.call do
        gst_init(nil,nil)
        List.init(callback: ->Storage.init_state)
        Storage.parse_arguments
        DBus.init
        VC365::UI.before_ui.each(&.call)
        VC365::UI.before_ui.clear
        VC365::UI.app_init(aapp_new("ir.NonFree.VCMusic",0_u32))
        i=ui_run(VC365::UI.app,nil,nil)
        Storage.update_config("value_bar",Player.value_bar,:state,false)
        exit(i) unless Settings::Values.rib[:kill_ui] && Settings::Values.rib[:e]
    end
end
Process.on_terminate { Storage.update_config("value_bar",Player.value_bar,:state,false);exit }
Signal::KILL.trap { Storage.update_config("value_bar",Player.value_bar,:state,false);exit }
Signal::SEGV.trap { Storage.update_config("value_bar",Player.value_bar,:state,false);exit }
sleep
