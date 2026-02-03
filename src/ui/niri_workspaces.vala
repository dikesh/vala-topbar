using Gtk;

namespace Topbar {

  // -------------------- Niri Window ----------------------------
  private class WindowBox : Box {
    public int id;
    public int workspace_id;

    public WindowBox (NiriWindow ? window = null) {
      if (window == null)return;

      id = window.id;
      workspace_id = window.workspace_id;
      append (new Image.from_icon_name (window.app_id.ascii_down ()));
    }
  }

  // -------------------- Niri Workspace ----------------------------
  private class WorkspaceBox : Box {
    public int id;
    public int idx;
    public bool is_active;
    public bool is_focused { get; set; }
    private int children_count = 0;

    public WorkspaceBox (NiriWorkspace workspace, NiriIPC niri) {
      Object (spacing: 8);
      set_css_classes ({ "hl-workspace" });

      id = workspace.id;
      idx = workspace.idx;
      is_active = workspace.is_active;
      is_focused = workspace.is_focused;

      niri.niri_windows.for_each ((_, niri_win) => {
        if (niri_win.workspace_id == id)
          append (new WindowBox (niri_win));
      });

      // Watch for change in focus and active status
      if (is_focused)update_css_classes ();

      notify["is-focused"].connect ((s, p) => {
        update_css_classes ();
      });
    }

    public int add_window_box (NiriWindow niri_window) {
      append (new WindowBox (niri_window));
      return ++children_count;
    }

    public int remove_window_box (WindowBox win_box) {
      remove (win_box);
      return --children_count;
    }

    private void update_css_classes () {
      const string class_to_update = "hl-workspace-active";
      if (is_focused && (!(class_to_update in css_classes)))add_css_class (class_to_update);
      else if (!is_focused && class_to_update in css_classes)remove_css_class (class_to_update);
    }

    public bool remove_window_box_by_id (int window_id) {
      if (children_count == 0)return false; // Nothing to remove

      var win_box = (WindowBox) get_first_child ();
      while (win_box != null) {
        if (win_box.id == window_id) {
          remove_window_box (win_box);
          return true;
        }
        win_box = (WindowBox) win_box.get_next_sibling ();
      }

      return false;
    }

    public void remove_other_workspace_windows (NiriIPC niri) {
      if (children_count == 0)return; // Nothing to remove

      var win_box = (WindowBox) get_first_child ();
      while (win_box != null) {
        var niri_win = niri.niri_windows.get (win_box.id);
        if (win_box.workspace_id != niri_win.workspace_id)remove_window_box (win_box);
        win_box = (WindowBox) win_box.get_next_sibling ();
      }
    }

    public void append_window_if_missing (NiriWindow niri_window) {
      // Check Workspace ID first
      if (niri_window.workspace_id != id)return;

      // If workspace is empty
      if (children_count == 0) {
        add_window_box (niri_window);
        return;
      }

      // Check whether Window exists, if yes return from function
      var win_box = (WindowBox) get_first_child ();
      while (win_box != null) {
        if (win_box.id == niri_window.id)return;
        win_box = (WindowBox) win_box.get_next_sibling ();
      }

      // Window does not exist, hence append
      add_window_box (niri_window);
    }
  }

  // -------------------- Main ----------------------------
  public class NiriWorkspaces : Box {

    private string output;
    private NiriIPC niri;

    public NiriWorkspaces (Gdk.Monitor monitor) {
      Object (orientation: Orientation.HORIZONTAL, spacing: 4);
      set_css_classes ({ "bar-section" });

      output = monitor.get_connector ();

      try {
        niri = NiriIPC.get_default ();
        niri.workspaces_changed.connect (on_workspaces_changed);
        niri.workspace_focus_changed.connect (on_workspace_focus_changed);
        niri.windows_changed.connect (on_windows_changed);
        niri.window_closed.connect (on_window_closed);

        destroy.connect (() => {
          niri.workspaces_changed.disconnect (on_workspaces_changed);
          niri.windows_changed.disconnect (on_windows_changed);
        });
      } catch (Error e) {
        critical ("Failed to init Niri IPC: %s", e.message);
      }
    }

    private void on_workspaces_changed () {
      // Get workspaces
      var ws_li = niri.niri_workspaces.get_values ();

      // Filter by output
      ws_li.foreach (niri_ws => {
        if (niri_ws.output != output)ws_li.remove (niri_ws);
      });

      // Sort by Index first
      ws_li.sort ((a, b) => {
        if (a.idx > b.idx)return 1;
        if (a.idx < b.idx)return -1;
        return 0;
      });

      // Update workspaces
      var ws_box = (WorkspaceBox) get_first_child ();
      var idx = 0;

      while (true) {
        var niri_ws = ws_li.nth_data (idx++);

        // End of loop
        if (ws_box == null && niri_ws == null)break;

        // Next sibling
        var next_ws_box = ws_box == null ? null : (WorkspaceBox) ws_box.get_next_sibling ();

        // Remove extra workspace boxes
        if (niri_ws == null && ws_box != null)remove (ws_box);
        // Append new workspace boxes
        else if (niri_ws != null && ws_box == null)append (new WorkspaceBox (niri_ws, niri));
        // Update workspace boxes
        else if (niri_ws.id != ws_box.id) {
          var prev = (WorkspaceBox) ws_box.get_prev_sibling ();
          remove (ws_box);
          insert_child_after (new WorkspaceBox (niri_ws, niri), prev);
        }

        // When a window is moved to last empty workspace,
        // Niri does not fire WorkspaceActivated event.
        // Instead it fires WorkspacesChanged event as it adds new workspace after the last one.
        if (ws_box != null && niri_ws != null)ws_box.is_focused = niri_ws.is_focused;

        // Update next box as current
        ws_box = next_ws_box;
      }
    }

    private void on_workspace_focus_changed (int workspace_id) {
      // Iterate on each workspace
      var ws_box = (WorkspaceBox) get_first_child ();
      while (ws_box != null) {
        ws_box.is_focused = ws_box.id == workspace_id;
        ws_box = (WorkspaceBox) ws_box.get_next_sibling ();
      }
    }

    private void on_windows_changed () {
      // Iterate on each workspace
      var ws_box = (WorkspaceBox) get_first_child ();
      while (ws_box != null) {

        // Remove window first if required
        ws_box.remove_other_workspace_windows (niri);

        // Append window if required
        niri.niri_windows.for_each ((win_id, niri_win) => {
          ws_box.append_window_if_missing (niri_win);
        });

        // Next Workspace Box
        ws_box = (WorkspaceBox) ws_box.get_next_sibling ();
      }
    }

    private void on_window_closed (int window_id) {
      // Iterate on each workspace
      var ws_box = (WorkspaceBox) get_first_child ();
      while (ws_box != null) {
        if (ws_box.remove_window_box_by_id (window_id))return;
        ws_box = (WorkspaceBox) ws_box.get_next_sibling ();
      }
    }
  }
}
