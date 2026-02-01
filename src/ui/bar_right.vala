using Gtk;

namespace Topbar {

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
      append (new PowerMenu ());
    }
  }
}
