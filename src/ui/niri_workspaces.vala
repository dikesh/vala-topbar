namespace Topbar {

  public class NiriWorkspaces : Gtk.Box {

    public NiriWorkspaces () {
      Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 6);

      try {
        var niri = NiriIPC.get_default ();
        niri.event_received.connect (on_event);
        this.destroy.connect (() => { niri.event_received.disconnect (on_event); });
      } catch (Error e) {
        critical ("Failed to init Niri IPC: %s", e.message);
      }
    }

    private void on_event (Json.Object msg) {
      // Events to notice
      string[] events = {
        "WorkspacesChanged",
        "WorkspaceActivated",
        "WindowsChanged",
        "WindowOpenedOrChanged",
        "WindowClosed",
      };

      foreach (var event in events) {
        if (msg.has_member (event + "1")) {
          print ("\n=================\n");
          print (new DateTime.now_local ().to_string ());
        }
      }
    }

    private void refresh (Json.Array workspaces) {
      stdout.printf ("Hello");

      var child = get_first_child ();

      while (child != null) {
        remove (child);
        child = child.get_next_sibling ();
      }

      for (uint i = 0; i < workspaces.get_length (); i++) {
        var ws = workspaces.get_object_element (i);
        var btn = new Gtk.Button.with_label (ws.get_string_member ("name"));

        if (ws.get_boolean_member ("focused"))
          btn.add_css_class ("focused");

        append (btn);
      }
    }
  }
}
