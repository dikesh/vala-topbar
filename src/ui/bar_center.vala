using Gtk;
using GLib;

namespace Topbar {

  public class BarCenter : Box {

    private bool show_utc = false;

    public BarCenter () {
      // Init
      Object (spacing: 8, tooltip_text: "Click to toggle between UTC and Local Timezone");
      set_css_classes ({ "bar-section", "clock" });

      // Time Box
      var time_box = new Box (Orientation.HORIZONTAL, 8);
      var time_button = new Button ();
      time_button.clicked.connect (() => { show_utc = !show_utc; });

      time_box.append (new Image.from_icon_name ("preferences-system-time-symbolic"));
      time_box.append (time_button);

      // Time Box
      var date_box = new Box (Orientation.HORIZONTAL, 8);
      var date_button = new Button ();
      date_button.clicked.connect (() => { show_utc = !show_utc; });

      date_box.append (new Image.from_icon_name ("x-office-calendar-symbolic"));
      date_box.append (date_button);

      // Add Children
      append (time_box);
      append (date_box);

      // Update time every 100 ms
      Timeout.add (100, () => {
        // Datetime
        var now = show_utc ? new DateTime.now_utc () : new DateTime.now_local ();
        time_button.set_label (now.format ("%T"));
        date_button.set_label (now.format ("%a %d %b %Y"));
        return true;
      });
    }
  }
}
