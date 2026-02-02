using Gtk;

namespace Topbar {

  public class Battery : Box {

    Image icon;
    Label label;

    public Battery () {
      Object (spacing: 4);
      set_css_classes ({ "bar-section", "battery" });

      icon = new Gtk.Image ();
      label = new Gtk.Label ("");

      append (icon);
      append (label);

      try {
        var battery = BatteryService.get_default ();
        battery.updated.connect (() => update (battery));
        update (battery);
      } catch (Error e) {
        warning ("Error: %s".printf (e.message));
      }
    }

    private void update (BatteryService b) {
      icon.set_from_icon_name (b.battery_icon_name);
      label.set_text ("%d%%".printf (b.percentage));
    }
  }

  public class PowerMenu : Button {

    public PowerMenu () {
      set_css_classes ({ "bar-section", "power" });
      child = new Image.from_icon_name ("system-shutdown-symbolic");
      clicked.connect (Utils.launch_power_menu);
    }
  }

  public class BarRight : Gtk.Box {

    public BarRight () {
      Object (spacing: 8);
      append (new Battery ());
      append (new PowerMenu ());
    }
  }
}
