using Gtk;

namespace Topbar {

  private class Volume : Box {

    public class Volume () {
      Object (spacing: 8);
      set_css_classes ({ "bar-section", "volume" });

      var volume = VolumeService.get_default ();

      var icon = new Image.from_icon_name (volume.icon_name);
      var label = new Label (@"$(volume.level)%");
      append (icon);
      append (label);

      volume.updated.connect ((level, icon_name) => {
        icon.icon_name = icon_name;
        label.label = @"$(level)%";
      });

      var click_gesture = new GestureClick ();
      click_gesture.pressed.connect (() => volume.toggle_volume_mute ());

      var scroll_gesture = new EventControllerScroll (EventControllerScrollFlags.VERTICAL);
      scroll_gesture.scroll.connect ((dx, dy) => {
        if (dy < 0)volume.update_volume_level (true);
        else if (dy > 0)volume.update_volume_level (false);
        return true;
      });

      add_controller (click_gesture);
      add_controller (scroll_gesture);
    }
  }

  private class Battery : Box {

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

  private class PowerMenu : Button {

    public PowerMenu () {
      set_css_classes ({ "bar-section", "power" });
      child = new Image.from_icon_name ("system-shutdown-symbolic");
      clicked.connect (Utils.launch_power_menu);
    }
  }

  public class BarRight : Gtk.Box {

    public BarRight () {
      Object (spacing: 8);
      append (new Volume ());
      append (new Battery ());
      append (new PowerMenu ());
    }
  }
}
