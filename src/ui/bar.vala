using Gtk;

namespace Topbar {
  public class Bar : Gtk.ApplicationWindow {

    public Bar (Gtk.Application app, Gdk.Monitor monitor) {
      // Init
      Object (application: app, title: "Topbar");
      set_css_classes ({ "bar-container" });


      // In your activation or setup code:
      try {
        // Load CSS
        var provider = new CssProvider ();
        provider.load_from_path (Utils.get_asset_path ("assets/style.css"));
        Gtk.StyleContext.add_provider_for_display (
          Gdk.Display.get_default (),
          provider,
          Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        // Add icon search path
        var icon_theme = IconTheme.get_for_display (Gdk.Display.get_default ());
        icon_theme.add_search_path (Utils.get_asset_path ("assets"));
      } catch (Error e) {
        stderr.printf ("Error loading assets: %s\n", e.message);
      }

      // Layer shell settings
      GtkLayerShell.init_for_window (this);
      GtkLayerShell.set_monitor (this, monitor);
      GtkLayerShell.set_layer (this, GtkLayerShell.Layer.TOP);

      GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);
      GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
      GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);

      // Height of bar in pixels
      GtkLayerShell.set_exclusive_zone (this, 32);

      // Optional: avoid focus stealing
      GtkLayerShell.set_keyboard_mode (this, GtkLayerShell.KeyboardMode.NONE);


      // Center box
      var cb = new CenterBox ();

      cb.set_start_widget (new BarLeft (monitor));
      cb.set_center_widget (new BarCenter ());
      cb.set_end_widget (new BarRight ());

      // Centerbox as immediate child of Application Window
      set_child (cb);
    }
  }
}
