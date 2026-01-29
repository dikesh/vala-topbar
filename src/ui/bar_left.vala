using Gtk;

namespace Topbar {

  // -------------- Apps ----------------
  private class Apps : Button {

    private string script;

    public Apps () {
      Object (tooltip_text: "Open Applications");
      set_css_classes ({ "bar-section", "apps" });

      child = new Label ("󰀻");

      var relative_path = ".config/rofi/launchers/type-3/launcher.sh";
      script = Path.build_filename (Environment.get_home_dir (), relative_path);
      clicked.connect (() => { Utils.run_script_async ({ script }); });
    }
  }

  // -------------- BarLeft ----------------
  public class BarLeft : Gtk.Box {

    public BarLeft () {
      Object (spacing: 8);
      append (new SystemResources ());
      append (new Apps ());
    }
  }
}
