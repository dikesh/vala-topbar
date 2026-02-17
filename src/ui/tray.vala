using Gtk;

namespace Topbar {
  /**
   * A single tray item button widget
   */
  public class TrayItemWidget : Box {
    private Button button;
    private TrayItem _item;

    public TrayItem item {
      get {
        return _item;
      }
      set {
        if (_item == value)return;

        // Disconnect old item
        if (_item != null)
          _item.changed.disconnect (on_item_changed);

        _item = value;

        if (_item != null) {
          _item.changed.connect (on_item_changed);
          update_widget ();
        }
      }
    }

    construct {
      orientation = Orientation.HORIZONTAL;

      button = new Button ();
      button.add_css_class ("tray-item");
      button.clicked.connect (on_left_click);

      append (button);
    }

    public TrayItemWidget (TrayItem item) {
      Object ();
      this.item = item;
    }

    private void update_widget () {
      var icon = new Image.from_gicon (_item.gicon);
      icon.pixel_size = 16;
      button.set_child (icon);
    }

    private void on_item_changed () {
      update_widget ();
    }

    private void on_left_click () {
      _item.activate (0, 0);
    }
  }

  /**
   * Main system tray widget containing all tray items
   */
  public class SystemTray : Box {
    private TrayService tray;
    private HashTable<string, TrayItemWidget> widgets;
    private Revealer revealer;
    private Box box;

    public Orientation tray_orientation {
      get {
        return box.orientation;
      }
      set {
        box.orientation = value;
      }
    }

    public int widget_spacing {
      get {
        return box.spacing;
      }
      set {
        box.spacing = value;
      }
    }

    construct {
      widgets = new HashTable<string, TrayItemWidget>(str_hash, str_equal);
      tray = TrayService.get_default ();

      visible = false;

      box = new Box (Orientation.HORIZONTAL, 4);
      box.set_css_classes ({ "bar-section", "systray" });

      revealer = new Revealer ();
      revealer.transition_type = RevealerTransitionType.SLIDE_RIGHT;
      revealer.transition_duration = 300;
      revealer.reveal_child = false;
      revealer.visible = false;
      revealer.set_child (box);

      append (revealer);

      // Connect to tray signals
      tray.item_added.connect (on_item_added);
      tray.item_removed.connect (on_item_removed);

      // Add existing items
      foreach (var item in tray.items) {
        add_tray_item (item);
      }
    }

    private void update_visibility () {
      bool has_items = widgets.size () > 0;
      visible = has_items;
      revealer.visible = has_items;
      revealer.reveal_child = has_items;
    }

    private void on_item_added (string item_id) {
      var item = tray.get_item (item_id);
      if (item != null) {
        add_tray_item (item);
      }
    }

    private void on_item_removed (string item_id) {
      var widget = widgets.get (item_id);
      if (widget != null) {
        box.remove (widget);
        widgets.remove (item_id);
        update_visibility ();
      }
    }

    private void add_tray_item (TrayItem item) {
      if (widgets.contains (item.item_id))return;

      var widget = new TrayItemWidget (item);
      widgets.set (item.item_id, widget);
      box.append (widget);
      update_visibility ();
    }
  }
}
