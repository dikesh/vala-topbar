using Gtk;
using GLib;

namespace Topbar {

  // --------------- CPU --------------------------
  private class CPU : Box {

    public CPU () {
      Object (spacing: 8);
      set_css_classes ({ "system-resource-widget" });

      var app = (Topbar.App) GLib.Application.get_default ();
      var avg_cpu = app.services.avg_cpu;

      var cpu_usage = new Label (avg_cpu.current ());
      avg_cpu.updated.connect ((load) => { cpu_usage.label = load; });

      append (new Label ("󰌢"));
      append (cpu_usage);
    }
  }

  public class SystemResources : Gtk.Box {

    public SystemResources () {
      Object (spacing: 8);
      set_css_classes ({ "bar-section" });

      // Append widgets
      append (new CPU ());
    }
  }
}
