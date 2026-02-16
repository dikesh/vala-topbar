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

    public Orientation tray_orientation {
      get {
        return orientation;
      }
      set {
        orientation = value;
        update_layout ();
      }
    }

    public int icon_size { get; set; default = 24; }
    public int widget_spacing { get; set; default = 4; }

    construct {
      widgets = new HashTable<string, TrayItemWidget>(str_hash, str_equal);
      tray = TrayService.get_default ();

      set_spacing (widget_spacing);
      set_css_classes ({ "bar-section", "systray" });

      // Connect to tray signals
      tray.item_added.connect (on_item_added);
      tray.item_removed.connect (on_item_removed);

      // Add existing items
      foreach (var item in tray.items) {
        add_tray_item (item);
      }

      notify["spacing"].connect (() => set_spacing (widget_spacing));
    }

    public SystemTray () {
      Object (orientation: Orientation.HORIZONTAL);
    }

    public SystemTray.with_orientation (Orientation orientation) {
      Object (orientation: orientation);
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
        remove (widget);
        widgets.remove (item_id);
      }
    }

    private void add_tray_item (TrayItem item) {
      if (widgets.contains (item.item_id)) {
        return;
      }

      var widget = new TrayItemWidget (item);
      widgets.set (item.item_id, widget);
      append (widget);
    }

    private void update_layout () {
      queue_resize ();
    }

    /**
     * Filter items by category
     */
    public void filter_by_category (Category category) {
      foreach (var item in tray.items) {
        var widget = widgets.get (item.item_id);
        if (widget != null) {
          widget.visible = (item.category == category);
        }
      }
    }

    /**
     * Show all items
     */
    public void show_all_items () {
      foreach (var widget in widgets.get_values ()) {
        widget.visible = true;
      }
    }

    /**
     * Hide passive items
     */
    public void hide_passive_items () {
      foreach (var item in tray.items) {
        var widget = widgets.get (item.item_id);
        if (widget != null) {
          widget.visible = (item.status != Status.PASSIVE);
        }
      }
    }
  }
}
