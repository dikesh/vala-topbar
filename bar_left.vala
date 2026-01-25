namespace Topbar {

  public class WorkspaceBar : Gtk.Box {

    public WorkspaceBar() {
      orientation = Gtk.Orientation.HORIZONTAL;
      spacing = 6;

      var app = (Topbar.App) GLib.Application.get_default();
      var niri = app.services.niri;
      niri.event_received.connect(on_event);

      this.destroy.connect(() => {
        niri.event_received.disconnect(on_event);
      });
    }

    string json_object_to_string(Json.Object obj) {
      var node = new Json.Node(Json.NodeType.OBJECT);
      node.set_object(obj);

      var gen = new Json.Generator();
      gen.set_root(node);

      return gen.to_data(null);
    }

    private void on_event(Json.Object msg) {
      // Events to notice
      string[] events = {
        "WorkspacesChanged",
        "WorkspaceActivated",
        "WindowsChanged",
        "WindowOpenedOrChanged",
        "WindowClosed",
      };

      foreach (var event in events) {
        if (msg.has_member(event + "1")) {
          print("\n=================\n");
          print(new DateTime.now_local().to_string() + " | " + json_object_to_string(msg));
        }
      }
    }

    private void refresh(Json.Array workspaces) {
      stdout.printf("Hello");

      var child = get_first_child();

      while (child != null) {
        remove(child);
        child = child.get_next_sibling();
      }

      for (uint i = 0; i < workspaces.get_length(); i++) {
        var ws = workspaces.get_object_element(i);
        var btn = new Gtk.Button.with_label(ws.get_string_member("name"));

        if (ws.get_boolean_member("focused"))
          btn.add_css_class("focused");

        append(btn);
      }
    }
  }
}
