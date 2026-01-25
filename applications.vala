using Gtk;

namespace Topbar {

  public class Apps : Button {

    private string script;

    public Apps () {
      Object (tooltip_text: "Open Applications");
      set_css_classes ({ "bar-section", "apps" });
      this.child = new Label ("󰀻");
      this.clicked.connect (run_rofi_script_async);

      var relative_path = ".config/rofi/launchers/type-3/launcher.sh";
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
}
