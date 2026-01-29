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

  // --------------- Temperature --------------------------
  private class Temperature : Box {

    public Temperature () {
      Object (spacing: 8);
      set_css_classes ({ "system-resource-widget" });

      var app = (Topbar.App) GLib.Application.get_default ();
      var cpu_temp = app.services.temperature;

      var cpu_temp_widget = new Label ("%d°C".printf ((int) cpu_temp.temp_c));
      cpu_temp.updated.connect (() => {
        cpu_temp_widget.label = "%d°C".printf ((int) cpu_temp.temp_c);
      });

      append (new Label (""));
      append (cpu_temp_widget);
    }
  }

  // --------------- Disk Usage --------------------------
  private class DiskUsage : Box {

    public DiskUsage () {
      Object (spacing: 8);
      set_css_classes ({ "system-resource-widget" });

      var app = (Topbar.App) GLib.Application.get_default ();
      var disk_usage = app.services.disk_usage;

      var root_usage = new Label (disk_usage.available_gi);
      disk_usage.updated.connect (() => {
        root_usage.label = disk_usage.available_gi;
        this.tooltip_text = "%s used out of %s".printf (disk_usage.used_gi, disk_usage.total_gi);
      });

      append (new Label ("󰍛"));
      append (root_usage);
    }
  }

  // --------------- System Resources --------------------------
  public class SystemResources : Gtk.Box {

    public SystemResources () {
      Object (spacing: 8);
      set_css_classes ({ "bar-section" });

      // Append widgets
      append (new CPU ());
      append (new RAM ());
      append (new Temperature ());
      append (new DiskUsage ());

      // Open btop on box click
      var gesture = new GestureClick ();
      gesture.pressed.connect (() => { Utils.run_script_async ({ "kitty", "-e", "btop" }); });
      add_controller (gesture);
    }
  }
}
