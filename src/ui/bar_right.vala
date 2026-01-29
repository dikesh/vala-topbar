using Gtk;

namespace Topbar {

  public class PowerMenu : Button {

    private string script;

    public PowerMenu () {
      set_css_classes ({ "bar-section", "power" });
      child = new Image.from_icon_name ("system-shutdown-symbolic");

      var relative_path = ".config/rofi/powermenu/type-5/powermenu.sh";
      script = Path.build_filename (Environment.get_home_dir (), relative_path);

      clicked.connect (() => Utils.run_script_async ({ script }));
    }
  }

  public class BarRight : Gtk.Box {

    public BarRight () {
      Object (spacing: 8);
      append (new PowerMenu ());
    }
  }
}
