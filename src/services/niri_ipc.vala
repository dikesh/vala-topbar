using GLib;
using Json;

namespace Topbar {

  public class NiriIPC : GLib.Object {

    private static NiriIPC? instance = null;

    private SocketConnection conn;
    private DataOutputStream output_stream;
    private DataInputStream input_stream;

    public signal void event_received (Json.Object event);
    public signal void disconnected ();

    public static NiriIPC get_default () throws Error {
      if (instance == null)
        instance = new NiriIPC ();
      return instance;
    }

    private NiriIPC () throws Error {
      string? path = Environment.get_variable ("NIRI_SOCKET");
      if (path == null)
        throw new IOError.NOT_FOUND ("NIRI_SOCKET not set");

      var client = new SocketClient ();
      conn = client.connect (new UnixSocketAddress (path), null);

      input_stream = new DataInputStream (conn.input_stream);
      output_stream = new DataOutputStream (conn.output_stream);

      // Request event stream
      send ("\"EventStream\"");

      // Start async read loop
      read_next_line ();
    }

    private void send (string line) throws Error {
      output_stream.put_string (line + "\n");
      output_stream.flush ();
    }

    private void read_next_line () {
      input_stream.read_line_async.begin (Priority.DEFAULT, null, (obj, res) => {
        try {
          string? line = input_stream.read_line_async.end (res);
          if (line == null) {
            disconnected ();
            return;
          }

          print ("\n=========\n");
          print (@"$(new DateTime.now_local().to_string ()) | $line");

          handle_line (line);

          // Schedule next read
          read_next_line ();
        } catch (Error e) {
          warning ("IPC read error: %s", e.message);
          disconnected ();
        }
      });
    }

    private void handle_line (string line) {
      try {
        var parser = new Json.Parser ();
        parser.load_from_data (line, -1);

        var root = parser.get_root ();
        if (root.get_node_type () != Json.NodeType.OBJECT)
          return;

        event_received (root.get_object ());
      } catch (Error e) {
        warning ("Failed to parse IPC message: %s", e.message);
      }
    }

    public void focus_workspace (int index) throws Error {
      var inner = new Json.Object ();
      inner.set_int_member ("index", index);

      var obj = new Json.Object ();
      obj.set_object_member ("FocusWorkspace", inner);

      var node = new Json.Node (Json.NodeType.OBJECT);
      node.set_object (obj);

      var gen = new Json.Generator ();
      gen.set_root (node);

      send (gen.to_data (null));
    }
  }
}
