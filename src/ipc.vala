using Gtk;

namespace  Topbar {

  public class VolumeOSDIpc : Object {

    private static VolumeOSDIpc ? instance = null;

    private SocketService ipc_service;

    public static VolumeOSDIpc get_default () {
      if (instance == null)instance = new VolumeOSDIpc ();
      return instance;
    }

    private VolumeOSDIpc () {
      start_ipc_server ();
    }

    private void start_ipc_server () {

      try {
        ipc_service = new SocketService ();
        string path = Environment.get_user_runtime_dir () + "/topbar.sock";

        // Remove old socket if exists
        try {
          File.new_for_path (path).delete (null);
        } catch (Error e) {
        }

        SocketAddress ? effective_address = null;

        ipc_service.add_address (
          new UnixSocketAddress (path),
          SocketType.STREAM,
          SocketProtocol.DEFAULT,
          null,
          out effective_address
        );

        ipc_service.incoming.connect ((conn, source) => {
          handle_ipc_async.begin (conn);
          return true;
        });

        ipc_service.start ();
      } catch (Error e) {
        warning ("IPC error: %s", e.message);
      }
    }

    private async void handle_ipc_async (SocketConnection conn) {

      try {
        var input = new DataInputStream (conn.get_input_stream ());

        string ? message = yield input.read_line_async ();

        if (message == null)return;

        var vs = VolumeService.get_default ();

        switch (message.strip ()) {

          case "volume-up" :
            yield vs.update_volume_level (true, true);

            break;

          case "volume-down" :
            yield vs.update_volume_level (false, true);

            break;

          case "volume-mute":
            yield vs.toggle_volume_mute (true);

            break;
        }
      } catch (Error e) {
        warning ("IPC async error: %s", e.message);
      }
    }
  }
}
