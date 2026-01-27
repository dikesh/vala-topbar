using Gtk;

namespace Topbar {

  public class PowerMenu : Button {

    private string script;

    public PowerMenu () {
      set_css_classes ({ "bar-section", "power" });
      this.child = new Image.from_icon_name ("system-shutdown-symbolic");
      this.clicked.connect (run_rofi_script_async);

      var relative_path = ".config/rofi/powermenu/type-5/powermenu.sh";
      script = Path.build_filename (Environment.get_home_dir (), relative_path);
    }

    private void run_rofi_script_async () {
      try {
        // Launches and immediately continues - NON-BLOCKING
        new Subprocess (SubprocessFlags.STDERR_SILENCE, script);
      } catch (Error e) {
        warning ("Failed to start rofi: %s", e.message);
      }
    }
  }


  public class BarRight : Gtk.Box {

    public BarRight () {
      Object (spacing: 8);
      append (new PowerMenu ());
    }
  }
}
