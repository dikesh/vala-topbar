using Gtk;

namespace Topbar {

  public class App : Gtk.Application {

    private HashTable<Gdk.Monitor, Bar> bars;

    public App () {
      Object (application_id: "com.arch.Topbar");
    }

    protected override void startup () {
      base.startup ();
      bars = new HashTable<Gdk.Monitor, Bar> (direct_hash, direct_equal);
    }

    protected override void activate () {
      var display = Gdk.Display.get_default ();
      var monitors = display.get_monitors ();

      // Initial bars
      for (uint i = 0; i < monitors.get_n_items (); i++) {
        var monitor = (Gdk.Monitor) monitors.get_item (i);
        add_bar (monitor);
      }

      // Hotplug
      monitors.items_changed.connect (on_monitors_changed);
    }

    private void on_monitors_changed (uint position, uint removed, uint added) {
      var monitors = Gdk.Display.get_default ().get_monitors ();

      // Remove bars
      for (uint i = 0; i < removed; i++) {
        var monitor = bars.get_keys ().nth_data ((int) position);
        if (monitor != null)
          remove_bar (monitor);
      }

      // Add bars
      for (uint i = 0; i < added; i++) {
        var monitor = (Gdk.Monitor) monitors.get_item (position + i);
        add_bar (monitor);
      }
    }

    private void add_bar (Gdk.Monitor monitor) {
      if (bars.contains (monitor))
        return;

      var bar = new Bar (this, monitor);
      bars.insert (monitor, bar);
      bar.present ();
    }

    private void remove_bar (Gdk.Monitor monitor) {
      var bar = bars.lookup (monitor);
      if (bar == null)
        return;

      bar.close ();
      bars.remove (monitor);
    }
  }
}
