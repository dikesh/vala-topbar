using Gtk;
using GtkLayerShell;

namespace Topbar {

  public class VolumeOSD : Window {

    private ProgressBar bar;
    private Image icon;
    private Label level_label;

    private uint timeout_id = 0;

    private static VolumeOSD ? instance;

    public static VolumeOSD get_default () {
      if (instance == null)instance = new VolumeOSD ();
      return instance;
    }

    private VolumeOSD () {
      Object (decorated : false, resizable: false, focusable: false);

      set_css_classes ({ "volume-osd-window" });

      GtkLayerShell.init_for_window (this);
      GtkLayerShell.set_layer (this, GtkLayerShell.Layer.OVERLAY);
      GtkLayerShell.set_exclusive_zone (this, -1);
      GtkLayerShell.set_keyboard_mode (this, GtkLayerShell.KeyboardMode.NONE);

      // Center content
      var outer = new Box (Orientation.HORIZONTAL, 0);

      // Actual pill container
      var container = new Box (Orientation.HORIZONTAL, 12);

      container.add_css_class ("volume-osd-container");
      container.set_valign (Align.CENTER);

      // Progress bar
      bar = new ProgressBar ();
      bar.set_size_request (240, 36);
      bar.add_css_class ("volume-osd-bar");

      // Volume text
      level_label = new Label ("");
      level_label.add_css_class ("volume-osd-label");

      // Icon
      icon = new Image ();
      icon.set_pixel_size (24);
      icon.add_css_class ("volume-osd-icon");

      container.append (icon);
      container.append (bar);
      container.append (level_label);

      outer.append (container);
      set_child (outer);
      set_visible (false);
    }

    public void show_volume (int level, string icon_name) {
      bar.set_fraction (level / 100.0);
      icon.set_from_icon_name (icon_name);
      level_label.set_text (@"$level%");

      set_visible (true);

      restart_timeout ();
    }

    private void restart_timeout () {

      if (timeout_id != 0)Source.remove (timeout_id);

      timeout_id = Timeout.add (1500, () => {
        set_visible (false);
        timeout_id = 0;
        return false;
      });
    }
  }
}
