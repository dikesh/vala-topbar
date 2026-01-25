using Gtk;

namespace Topbar {

  public class App : Gtk.Application {

    public App() {
      Object(application_id: "com.arch.Topbar");
    }

    public override void activate() {
      try {
        // Init Niri events
        var niri_ipc = new Topbar.NiriIPC();

        // Application window for each monitor
        var model = Gdk.Display.get_default().get_monitors();
        for (var i = 0; i < model.get_n_items(); i++) {
          new Bar(this, (Gdk.Monitor) model.get_item(i), niri_ipc).present();
        }
      } catch (Error e) {
        critical("Failed to init Niri IPC: %s", e.message);
      }
    }
  }
}
