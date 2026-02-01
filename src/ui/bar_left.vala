using Gtk;

namespace Topbar {

  // -------------- Apps ----------------
  private class Apps : Button {

    public Apps () {
      Object (tooltip_text: "Open Apps");
      set_css_classes ({ "bar-section", "apps" });
      child = new Label ("󰀻");
      clicked.connect (Utils.launch_apps);
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
