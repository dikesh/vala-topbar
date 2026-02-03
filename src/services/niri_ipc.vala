using Json;

namespace Topbar {

  // -------------------- Niri Window ----------------------------
  public class NiriWindow : GLib.Object {
    public int id;
    public int workspace_id;
    public string app_id;

    public NiriWindow (Json.Object window) {
      id = (int) window.get_int_member ("id");
      workspace_id = (int) window.get_int_member ("workspace_id");
      app_id = window.get_string_member ("app_id");
    }
  }

  // -------------------- Niri Workspace ----------------------------
  public class NiriWorkspace : GLib.Object {
    public int id;
    public int idx;
    public string output;
    public bool is_active;
    public bool is_focused;

    public NiriWorkspace (Json.Object workspace) {
      id = (int) workspace.get_int_member ("id");
      idx = (int) workspace.get_int_member ("idx");
      output = workspace.get_string_member ("output");
      is_active = (bool) workspace.get_boolean_member ("is_active");
      is_focused = (bool) workspace.get_boolean_member ("is_focused");
    }
  }

  public class NiriIPC : GLib.Object {

    private static NiriIPC ? instance = null;

    private SocketConnection conn;
    private DataOutputStream output_stream;
    private DataInputStream input_stream;

    public HashTable<int, NiriWorkspace> niri_workspaces;
    public HashTable<int, NiriWindow> niri_windows;

    public signal void workspaces_changed ();
    public signal void workspace_focus_changed (int workspace_id);
    public signal void windows_changed ();
    public signal void window_closed (int window_id);
    public signal void disconnected ();

    public static NiriIPC get_default () throws Error {
      if (instance == null)
        instance = new NiriIPC ();
      return instance;
    }

    private NiriIPC () throws Error {
      string ? path = Environment.get_variable ("NIRI_SOCKET");
      if (path == null)
        throw new IOError.NOT_FOUND ("NIRI_SOCKET not set");

      var client = new SocketClient ();
      conn = client.connect (new UnixSocketAddress (path), null);

      input_stream = new DataInputStream (conn.input_stream);
      output_stream = new DataOutputStream (conn.output_stream);

      // Request event stream
      send ("\"EventStream\"");

      // Init tables
      niri_workspaces = new HashTable<int, NiriWorkspace>(direct_hash, direct_equal);
      niri_windows = new HashTable<int, NiriWindow>(direct_hash, direct_equal);

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
          string ? line = input_stream.read_line_async.end (res);
          if (line == null) {
            disconnected ();
            return;
          }

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
        if (root.get_node_type () != Json.NodeType.OBJECT)return;

        var msg = root.get_object ();
        if (msg == null)return;

        if (msg.has_member ("WorkspacesChanged")) {
          on_workspaces_changed (msg);
        } else if (msg.has_member ("WorkspaceActivated")) {
          on_workspace_activated (msg);
        } else if (msg.has_member ("WindowsChanged")) {
          on_windows_changed (msg);
        } else if (msg.has_member ("WindowOpenedOrChanged")) {
          on_window_opened_or_changed (msg);
        } else if (msg.has_member ("WindowClosed")) {
          on_window_closed (msg);
        }
      } catch (Error e) {
        warning ("Failed to parse IPC message: %s", e.message);
      }
    }

    private void on_workspaces_changed (Json.Object msg) {
      // Get array of workspaces
      var workspaces = msg.get_object_member ("WorkspacesChanged").get_array_member ("workspaces");
      if (workspaces == null)return;

      // Remove all workspaces and replace with new ones
      niri_workspaces.remove_all ();

      workspaces.foreach_element ((arr, idx, element) => {
        var ws_obj = element.get_object ();
        var ws_id = (int) ws_obj.get_int_member ("id");
        niri_workspaces.insert (ws_id, new NiriWorkspace (ws_obj));
      });

      workspaces_changed ();
    }

    private void on_workspace_activated (Json.Object msg) {
      var workspace_id = (int) msg.get_object_member ("WorkspaceActivated").get_int_member ("id");

      niri_workspaces.for_each ((id, niri_workspace) => {
        niri_workspace.is_focused = id == workspace_id;
      });

      workspace_focus_changed (workspace_id);
    }

    private void on_windows_changed (Json.Object msg) {
      // Get array of windows
      var windows = msg.get_object_member ("WindowsChanged").get_array_member ("windows");

      windows.foreach_element ((arr, idx, element) => {
        var win_obj = element.get_object ();
        var win_id = (int) win_obj.get_int_member ("id");
        niri_windows.insert (win_id, new NiriWindow (win_obj));
      });

      windows_changed ();
    }

    private void on_window_opened_or_changed (Json.Object msg) {
      var win_obj = msg.get_object_member ("WindowOpenedOrChanged").get_object_member ("window");
      var win_id = (int) win_obj.get_int_member ("id");

      niri_windows.insert (win_id, new NiriWindow (win_obj));

      windows_changed ();
    }

    private void on_window_closed (Json.Object msg) {
      var window_id = (int) msg.get_object_member ("WindowClosed").get_int_member ("id");
      niri_windows.remove (window_id);
      window_closed (window_id);
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
