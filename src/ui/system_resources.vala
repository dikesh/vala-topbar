using Gtk;
using GLib;

namespace Topbar {

  // --------------- CPU --------------------------
  private class CPU : Box {

    public CPU () {
      Object (spacing: 8);
      set_css_classes ({ "system-resource-widget" });

      var app = (Topbar.App) GLib.Application.get_default ();
      var cpu = app.services.avg_cpu;

      var cpu_usage = new Label (cpu.avg_cpu);
      cpu.updated.connect (() => { cpu_usage.label = cpu.avg_cpu; });

      append (new Label ("󰌢"));
      append (cpu_usage);
    }
  }

  // --------------- Memory --------------------------
  private class RAM : Box {

    public RAM () {
      Object (spacing: 8);
      set_css_classes ({ "system-resource-widget" });

      var app = (Topbar.App) GLib.Application.get_default ();
      var memory = app.services.memory;

      var mem_usage = new Label (memory.used_gi);
      memory.updated.connect (() => {
        mem_usage.label = memory.used_gi;
        this.tooltip_text = "Available: %s / %s".printf (memory.available_gi, memory.total_gi);
      });

      append (new Label ("󰍛"));
      append (mem_usage);
    }
  }

  public class SystemResources : Gtk.Box {

    public SystemResources () {
      Object (spacing: 8);
      set_css_classes ({ "bar-section" });

      // Append widgets
      append (new CPU ());
      append (new RAM ());
    }
  }
}
